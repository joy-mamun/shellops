#!/bin/bash
# lib/backup_schedule.sh — Backup scheduling and management module for ShellOps
# Creates, schedules, and manages tar/gzip backups with rotation

source "$(dirname "${BASH_SOURCE[0]}")/common.sh" || exit 1
source "$(dirname "${BASH_SOURCE[0]}")/config.sh" || exit 1

# ============================================================================
# Backup Functions
# ============================================================================

# Create a backup of specified directories
create_backup() {
    local backup_name="${1:-backup-$(date +%Y%m%d_%H%M%S)}"
    local backup_dirs="${2:-${BACKUP_DIRS:-/home /etc}}"
    
    log_info "Creating backup: $backup_name"
    log_info "Directories to backup: $backup_dirs"
    
    # Ensure backup directory exists and is writable
    if ! require_dir_writable "$BACKUP_DIR"; then
        log_error "Backup directory not writable: $BACKUP_DIR"
        return 1
    fi
    
    # Determine compression command
    local compression_ext="tar"
    local compress_cmd=""
    
    case "$BACKUP_COMPRESSION" in
        gzip)
            compression_ext="tar.gz"
            compress_cmd="gzip"
            ;;
        bzip2)
            compression_ext="tar.bz2"
            compress_cmd="bzip2"
            ;;
        xz)
            compression_ext="tar.xz"
            compress_cmd="xz"
            ;;
        none)
            compression_ext="tar"
            compress_cmd=""
            ;;
        *)
            log_error "Unknown compression method: $BACKUP_COMPRESSION"
            return 1
            ;;
    esac
    
    local backup_file="$BACKUP_DIR/${backup_name}.${compression_ext}"
    local exclude_file="$(dirname "$0")/../config/backup.exclude"
    
    log_info "Creating backup: $backup_file"
    log_info "Compression: ${BACKUP_COMPRESSION:-none}"
    
    # Create backup with appropriate compression and error handling
    if [[ "$compress_cmd" == "gzip" ]]; then
        tar -czf "$backup_file" --exclude-from="$exclude_file" $backup_dirs 2>&1 | grep -v "Cannot open\|Removing leading" || {
            log_error "Backup creation failed"
            rm -f "$backup_file"
            return 1
        }
    elif [[ "$compress_cmd" == "bzip2" ]]; then
        tar -cjf "$backup_file" --exclude-from="$exclude_file" $backup_dirs 2>&1 | grep -v "Cannot open\|Removing leading" || {
            log_error "Backup creation failed"
            rm -f "$backup_file"
            return 1
        }
    elif [[ "$compress_cmd" == "xz" ]]; then
        tar -cJf "$backup_file" --exclude-from="$exclude_file" $backup_dirs 2>&1 | grep -v "Cannot open\|Removing leading" || {
            log_error "Backup creation failed"
            rm -f "$backup_file"
            return 1
        }
    else
        tar -cf "$backup_file" --exclude-from="$exclude_file" $backup_dirs 2>&1 | grep -v "Cannot open\|Removing leading" || {
            log_error "Backup creation failed"
            rm -f "$backup_file"
            return 1
        }
    fi
    
    # Get backup file size
    local size
    size=$(stat -c%s "$backup_file" 2>/dev/null || stat -f%z "$backup_file" 2>/dev/null)
    
    log_success "Backup created successfully"
    log_info "File: $backup_file"
    log_info "Size: $(numfmt --to=iec $size 2>/dev/null || echo $size bytes)"
    
    # Rotate old backups
    rotate_backups
}

# Rotate backups (keep last N)
rotate_backups() {
    local max_backups="${BACKUP_RETENTION_COUNT:-10}"
    
    log_info "Rotating backups (keeping last $max_backups)..."
    
    if [[ ! -d "$BACKUP_DIR" ]]; then
        log_error "Backup directory does not exist: $BACKUP_DIR"
        return 1
    fi
    
    local backup_count
    backup_count=$(find "$BACKUP_DIR" -type f -name "backup-*" 2>/dev/null | wc -l)
    
    if (( backup_count <= max_backups )); then
        log_info "Backup count within limit ($backup_count/$max_backups)"
        return 0
    fi
    
    local to_remove=$((backup_count - max_backups))
    log_warn "Removing $to_remove old backup(s)..."
    
    find "$BACKUP_DIR" -type f -name "backup-*" -printf '%T@ %p\n' | \
        sort -n | head -n "$to_remove" | cut -d' ' -f2- | \
        while read -r old_backup; do
            log_info "Removing: $old_backup"
            rm -f "$old_backup"
        done
    
    log_success "Backup rotation complete"
}

# List existing backups
list_backups() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        log_error "Backup directory does not exist: $BACKUP_DIR"
        return 1
    fi
    
    log_info "Existing backups in: $BACKUP_DIR"
    
    echo "Timestamp              Size        File"
    echo "─────────────────────────────────────────"
    
    find "$BACKUP_DIR" -type f -name "backup-*" -printf '%T@ %Tc %s %p\n' | \
        sort -rn | while read -r timestamp date size file; do
        local readable_size
        readable_size=$(numfmt --to=iec "$size" 2>/dev/null || echo "$size")
        local filename=$(basename "$file")
        printf "%-22s %-12s %s\n" "$(date -d @"${timestamp%.*}" '+%Y-%m-%d %H:%M:%S')" "$readable_size" "$filename"
    done
}

# Generate backup manifest
generate_manifest() {
    local backup_file="$1"
    
    if [[ ! -f "$backup_file" ]]; then
        log_error "Backup file not found: $backup_file"
        return 1
    fi
    
    log_info "Generating manifest for: $backup_file"
    
    local manifest_file="${backup_file}.manifest"
    
    # Try to list contents of tar archive
    if tar -tzf "$backup_file" &>/dev/null; then
        tar -tzf "$backup_file" > "$manifest_file" || {
            log_error "Failed to generate manifest"
            return 1
        }
    elif tar -tjf "$backup_file" &>/dev/null; then
        tar -tjf "$backup_file" > "$manifest_file" || {
            log_error "Failed to generate manifest"
            return 1
        }
    elif tar -tJf "$backup_file" &>/dev/null; then
        tar -tJf "$backup_file" > "$manifest_file" || {
            log_error "Failed to generate manifest"
            return 1
        }
    elif tar -tf "$backup_file" &>/dev/null; then
        tar -tf "$backup_file" > "$manifest_file" || {
            log_error "Failed to generate manifest"
            return 1
        }
    else
        log_error "Could not list backup contents"
        return 1
    fi
    
    log_success "Manifest file created: $manifest_file"
    log_info "Total files in backup: $(wc -l < "$manifest_file")"
}

# Restore from backup
restore_backup() {
    local backup_file="$1"
    local restore_dir="${2:-.}"
    
    if [[ ! -f "$backup_file" ]]; then
        log_error "Backup file not found: $backup_file"
        return 1
    fi
    
    if [[ ! -d "$restore_dir" ]]; then
        log_error "Restore directory does not exist: $restore_dir"
        return 1
    fi
    
    if ! require_dir_writable "$restore_dir"; then
        return 1
    fi
    
    log_warn "⚠ Restoring from backup: $backup_file"
    log_warn "⚠ Restore destination: $restore_dir"
    
    if ! confirm "Are you sure you want to restore this backup?"; then
        log_info "Restore cancelled"
        return 1
    fi
    
    log_info "Restoring backup..."
    
    # Auto-detect compression
    if [[ "$backup_file" =~ \.tar\.gz$ ]]; then
        tar -xzf "$backup_file" -C "$restore_dir" || {
            log_error "Restore failed"
            return 1
        }
    elif [[ "$backup_file" =~ \.tar\.bz2$ ]]; then
        tar -xjf "$backup_file" -C "$restore_dir" || {
            log_error "Restore failed"
            return 1
        }
    elif [[ "$backup_file" =~ \.tar\.xz$ ]]; then
        tar -xJf "$backup_file" -C "$restore_dir" || {
            log_error "Restore failed"
            return 1
        }
    elif [[ "$backup_file" =~ \.tar$ ]]; then
        tar -xf "$backup_file" -C "$restore_dir" || {
            log_error "Restore failed"
            return 1
        }
    else
        log_error "Unknown backup format: $backup_file"
        return 1
    fi
    
    log_success "Restore complete"
}

# Schedule backup via cron
schedule_backup() {
    if [[ -z "${BACKUP_SCHEDULE}" ]]; then
        log_warn "No backup schedule configured"
        return 1
    fi
    
    require_root || {
        log_error "Cron scheduling requires root privileges"
        return 1
    }
    
    local cron_job="$BACKUP_SCHEDULE $(dirname "$0")/../shellops backup --create"
    
    log_info "Adding cron job: $cron_job"
    
    # Check if already exists
    if crontab -l 2>/dev/null | grep -q "shellops backup"; then
        log_warn "ShellOps backup job already in crontab"
        return 0
    fi
    
    # Add to crontab
    (crontab -l 2>/dev/null; echo "$cron_job") | crontab - || {
        log_error "Failed to add cron job"
        return 1
    }
    
    log_success "Cron job scheduled successfully"
}

# ============================================================================
# Main Backup Function
# ============================================================================

backup_schedule_main() {
    local action="${1:-help}"
    
    case "$action" in
        create|--create|-c)
            create_backup "backup-$(date +%Y%m%d_%H%M%S)" "${2:-${BACKUP_DIRS}}"
            ;;
        list|--list|-l)
            list_backups
            ;;
        rotate|--rotate)
            rotate_backups
            ;;
        manifest|--manifest)
            generate_manifest "${2:-.}"
            ;;
        restore|--restore)
            restore_backup "${2:-.}" "${3:-.}"
            ;;
        schedule|--schedule|-s)
            schedule_backup
            ;;
        test|--test)
            log_info "Creating test backup..."
            create_backup "backup-test-$(date +%s)"
            ;;
        *)
            log_error "Unknown action: $action"
            return 1
            ;;
    esac
}

# ============================================================================
# Export functions
# ============================================================================

export -f create_backup rotate_backups list_backups
export -f generate_manifest restore_backup schedule_backup
export -f backup_schedule_main

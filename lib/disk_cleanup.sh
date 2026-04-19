#!/bin/bash
# lib/disk_cleanup.sh — Disk cleanup and analysis module for ShellOps
# Finds large files, duplicates, and manages disk space

source "$(dirname "${BASH_SOURCE[0]}")/common.sh" || exit 1
source "$(dirname "${BASH_SOURCE[0]}")/config.sh" || exit 1

# ============================================================================
# Disk Analysis Functions
# ============================================================================

# Convert bytes to human-readable format
format_size() {
    local bytes="$1"
    
    if (( bytes < 1024 )); then
        echo "${bytes}B"
    elif (( bytes < 1048576 )); then
        echo "$((bytes / 1024))K"
    elif (( bytes < 1073741824 )); then
        echo "$((bytes / 1048576))M"
    else
        echo "$((bytes / 1073741824))G"
    fi
}

# Find large files above threshold
find_large_files() {
    local directory="${1:-.}"
    local threshold="${DISK_CLEANUP_SIZE_THRESHOLD:-104857600}"
    
    if ! require_dir_readable "$directory"; then
        return 1
    fi
    
    log_info "Scanning for files larger than $(format_size "$threshold") in: $directory"
    
    local count=0
    echo "File Size        Location"
    echo "───────────────────────────────────────"
    
    # Find files and display with proper formatting
    find "$directory" -type f -size +${threshold}c 2>/dev/null | while read -r file; do
        local size
        size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null)
        if [[ -n "$size" ]]; then
            printf "%-16s %s\n" "$(format_size "$size")" "$file"
            count=$((count + 1))
        fi
    done
    
    if [[ $count -eq 0 ]]; then
        log_info "No large files found"
    else
        log_info "Found $count large file(s)"
    fi
}

# Analyze disk usage by directory
analyze_disk_usage() {
    local directory="${1:-.}"
    local depth="${2:-1}"
    
    if ! require_dir_readable "$directory"; then
        return 1
    fi
    
    log_info "Analyzing disk usage in: $directory (depth: $depth)"
    
    echo "Used      Directory"
    echo "──────────────────────────────────────"
    
    du -ah --max-depth="$depth" "$directory" 2>/dev/null | sort -rh | head -15 | while read -r size dir; do
        printf "%-10s %s\n" "$size" "$dir"
    done
}

# Find duplicate files (by md5sum)
find_duplicates() {
    local directory="${1:-.}"
    
    if ! require_dir_readable "$directory"; then
        return 1
    fi
    
    if ! require_command find; then
        return 1
    fi
    
    log_info "Scanning for duplicate files in: $directory"
    
    # This is an expensive operation - use a timeout
    local temp_file="/tmp/shellops_duplicates_$$.txt"
    
    find "$directory" -type f -exec md5sum {} \; 2>/dev/null | \
        awk '{print $1}' | sort | uniq -d > "$temp_file"
    
    local dup_count
    dup_count=$(wc -l < "$temp_file")
    
    if (( dup_count > 0 )); then
        log_warn "Found $dup_count duplicate file hashes"
        
        echo "Duplicate Files:"
        echo "───────────────────────────────────────"
        find "$directory" -type f -exec md5sum {} \; 2>/dev/null | \
            grep -f "$temp_file" | awk '{print $2}' | while read -r file; do
            local size
            size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null)
            printf "%-10s %s\n" "$(format_size "$size")" "$file"
        done
    else
        log_success "No duplicate files found"
    fi
    
    rm -f "$temp_file"
}

# Analyze temporary directories
analyze_temp_dirs() {
    log_info "Analyzing temporary directories..."
    
    echo "Directory        Used      File Count"
    echo "───────────────────────────────────────"
    
    for tmpdir in "${DISK_CLEANUP_TEMP_DIRS[@]}"; do
        if [[ ! -d "$tmpdir" ]]; then
            continue
        fi
        
        local size
        local file_count
        
        size=$(du -sb "$tmpdir" 2>/dev/null | awk '{print $1}' || echo 0)
        file_count=$(find "$tmpdir" -type f 2>/dev/null | wc -l)
        
        printf "%-16s %-10s %d\n" "$tmpdir" "$(format_size "$size")" "$file_count"
    done
}

# Clean temporary directories (with dry-run support)
clean_temp_dirs() {
    local dry_run="${1:-true}"
    
    log_info "Cleaning temporary directories (dry_run: $dry_run)..."
    
    for tmpdir in "${DISK_CLEANUP_TEMP_DIRS[@]}"; do
        if [[ ! -d "$tmpdir" ]] || [[ ! -w "$tmpdir" ]]; then
            log_warn "Cannot write to: $tmpdir"
            continue
        fi
        
        log_info "Processing: $tmpdir"
        
        local files_to_clean
        files_to_clean=$(find "$tmpdir" -maxdepth 1 -type f -time +30 2>/dev/null)
        
        if [[ -z "$files_to_clean" ]]; then
            log_info "No files to clean in: $tmpdir"
            continue
        fi
        
        if [[ "$dry_run" == "true" ]]; then
            echo "Would delete:"
            echo "$files_to_clean"
        else
            require_root || return 1
            echo "$files_to_clean" | xargs -r rm -f
            log_success "Cleaned: $tmpdir"
        fi
    done
}

# Get total disk space usage
get_disk_usage() {
    local filesystem="${1:-/}"
    
    if ! require_dir_readable "$filesystem"; then
        return 1
    fi
    
    # Use df to get disk usage percentage
    df -h "$filesystem" | tail -1 | awk '{print $5}' | sed 's/%//'
}

# Show disk usage summary
show_disk_summary() {
    log_info "Disk Usage Summary:"
    
    echo "Filesystem      Size      Used      Avail     Use%  Mount"
    echo "─────────────────────────────────────────────────────────"
    df -h | tail -n +2 | while read -r line; do
        echo "$line" | awk '{printf "%-15s %-10s %-10s %-10s %-6s %s\n", $1, $2, $3, $4, $5, $6}'
    done
}

# ============================================================================
# Cleanup Generation & Recommendations
# ============================================================================

# Generate cleanup recommendations
generate_cleanup_recommendations() {
    local directory="${1:-.}"
    
    log_info "Generating disk cleanup recommendations for: $directory"
    echo ""
    echo "Recommendations:"
    echo "───────────────────────────────────────"
    
    # Large files
    local large_file_count
    large_file_count=$(find "$directory" -type f -size +${DISK_CLEANUP_SIZE_THRESHOLD}c 2>/dev/null | wc -l)
    if (( large_file_count > 0 )); then
        log_info "• Found $large_file_count large files (>$(format_size "$DISK_CLEANUP_SIZE_THRESHOLD"))"
        echo "  Action: Review and compress or archive older files"
    fi
    
    # Duplicates
    local dup_estimate
    dup_estimate=$(find "$directory" -type f -exec md5sum {} \; 2>/dev/null | awk '{print $1}' | sort | uniq -d | wc -l)
    if (( dup_estimate > 0 )); then
        log_warn "• Found ~$dup_estimate duplicate file hashes"
        echo "  Action: Identify and remove duplicate files"
    fi
    
    # Cache directories
    if [[ -d $directory/.cache ]]; then
        local cache_size
        cache_size=$(du -sb "$directory/.cache" 2>/dev/null | awk '{print $1}')
        if (( cache_size > 104857600 )); then  # > 100MB
            log_info "• Cache directory is large: $(format_size "$cache_size")"
            echo "  Action: Safe to clean (can be regenerated)"
        fi
    fi
    
    echo ""
    echo "Use: shellops cleanup --action [find-large|duplicates|analyze|clean-temp] --dry-run"
    echo "for detailed file-by-file analysis before making changes."
}

# ============================================================================
# Main Disk Cleanup Function
# ============================================================================

disk_cleanup_main() {
    local action="${1:-analyze}"
    local target="${2:-.}"
    local dry_run="${DISK_CLEANUP_DRY_RUN:-true}"
    
    # Check for --dry-run flag
    for arg in "$@"; do
        if [[ "$arg" == "--dry-run" ]]; then
            dry_run="true"
        elif [[ "$arg" == "--force" ]] || [[ "$arg" == "--execute" ]]; then
            dry_run="false"
        fi
    done
    
    case "$action" in
        analyze|summary)
            analyze_disk_usage "$target"
            ;;
        find-large|large)
            find_large_files "$target"
            ;;
        duplicates)
            find_duplicates "$target"
            ;;
        temp-dirs|temp)
            analyze_temp_dirs
            ;;
        clean-temp)
            clean_temp_dirs "$dry_run"
            ;;
        recommendations)
            generate_cleanup_recommendations "$target"
            ;;
        disk-summary)
            show_disk_summary
            ;;
        all|full)
            echo "╔════════════════════════════════════════════════════╗"
            echo "║              Disk Cleanup Analysis                 ║"
            echo "╚════════════════════════════════════════════════════╝"
            echo ""
            analyze_disk_usage "$target" 2
            echo ""
            find_large_files "$target"
            echo ""
            analyze_temp_dirs
            echo ""
            generate_cleanup_recommendations "$target"
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

export -f format_size find_large_files analyze_disk_usage find_duplicates
export -f analyze_temp_dirs clean_temp_dirs get_disk_usage show_disk_summary
export -f generate_cleanup_recommendations disk_cleanup_main

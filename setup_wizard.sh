#!/bin/bash
# setup_wizard.sh — Interactive configuration wizard for ShellOps

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh" || exit 1

# ============================================================================
# Wizard Configuration & State
# ============================================================================

CONFIG_DIR="${SCRIPT_DIR}/config"
CONFIG_FILE="$CONFIG_DIR/shellops.conf"
BACKUP_EXCLUDE="$CONFIG_DIR/backup.exclude"

# Configuration values (set by wizard)
declare -A config_values

# ============================================================================
# Wizard Section: Introduction
# ============================================================================

show_welcome() {
    clear
    cat << 'EOF'
╔════════════════════════════════════════════════════════════════════════════╗
║                     ShellOps Setup Wizard                                  ║
║             Educational Linux System Administration Toolkit                ║
└════════════════════════════════════════════════════════════════════════════╝

Welcome! This wizard will guide you through configuring ShellOps for your system.

In the next few minutes, you'll configure:
  • Feature enablement (which features to activate)
  • Monitoring thresholds (when to alert you)
  • Backup settings (directories, schedule, retention)
  • Performance tuning (paths, timeouts)

Tip: You can always edit the generated config file later at:
  $CONFIG_FILE

Let's get started!

EOF
    read -p "Press Enter to continue..."
}

# ============================================================================
# Wizard Sections
# ============================================================================

configure_features() {
    clear
    cat << 'EOF'
┌─ Feature Selection ──────────────────────────────────────────────────────┐
│                                                                           │
│ Configure which ShellOps features you want to use:                      │
│                                                                           │
│ 1. User Monitoring   — Track active users, login history, idle time     │
│ 2. Disk Cleanup      — Find large/duplicate files, clean temp dirs      │
│ 3. Backup Scheduling — Automated backups with rotation                  │
│ 4. Health Checks     — System resource monitoring (CPU/mem/disk)        │
└─────────────────────────────────────────────────────────────────────────┘
EOF

    # User Monitoring
    if confirm "Enable User Monitoring?"; then
        config_values[FEATURE_USER_MONITOR]="true"
        log_info "✓ User Monitoring enabled"
    else
        config_values[FEATURE_USER_MONITOR]="false"
        log_info "✗ User Monitoring disabled"
    fi
    
    # Disk Cleanup
    if confirm "Enable Disk Cleanup?"; then
        config_values[FEATURE_DISK_CLEANUP]="true"
        log_info "✓ Disk Cleanup enabled"
    else
        config_values[FEATURE_DISK_CLEANUP]="false"
        log_info "✗ Disk Cleanup disabled"
    fi
    
    # Backup
    if confirm "Enable Backup Scheduling?"; then
        config_values[FEATURE_BACKUP]="true"
        log_info "✓ Backup Scheduling enabled"
    else
        config_values[FEATURE_BACKUP]="false"
        log_info "✗ Backup Scheduling disabled"
    fi
    
    # Health Check
    if confirm "Enable Health Checks?"; then
        config_values[FEATURE_HEALTH_CHECK]="true"
        log_info "✓ Health Checks enabled"
    else
        config_values[FEATURE_HEALTH_CHECK]="false"
        log_info "✗ Health Checks disabled"
    fi
    
    read -p "Press Enter to continue..."
}

configure_user_monitoring() {
    if [[ "${config_values[FEATURE_USER_MONITOR]}" != "true" ]]; then
        return 0
    fi
    
    clear
    cat << 'EOF'
┌─ User Monitoring Configuration ─────────────────────────────────────────┐
│                                                                         │
│ Configure how user monitoring works:                                   │
│                                                                         │
│ • Idle Time Threshold: Mark users as idle after N seconds              │
│ • Root Login Alerts: Warn when root logs in outside expected times     │
└─────────────────────────────────────────────────────────────────────────┘
EOF

    # Idle threshold
    while true; do
        idle_input=$(prompt_input "Idle time threshold in seconds" "3600")
        if validate_number_range "$idle_input" 60 86400 2>/dev/null; then
            config_values[USER_MONITOR_IDLE_THRESHOLD]="$idle_input"
            log_success "Idle threshold set to $idle_input seconds"
            break
        fi
    done
    
    # Root login alerts
    if confirm "Enable alerts on root logins?"; then
        config_values[USER_MONITOR_ALERT_ROOT_LOGINS]="true"
        log_success "Root login alerts enabled"
    else
        config_values[USER_MONITOR_ALERT_ROOT_LOGINS]="false"
        log_info "Root login alerts disabled"
    fi
    
    read -p "Press Enter to continue..."
}

configure_disk_cleanup() {
    if [[ "${config_values[FEATURE_DISK_CLEANUP]}" != "true" ]]; then
        return 0
    fi
    
    clear
    cat << 'EOF'
┌─ Disk Cleanup Configuration ────────────────────────────────────────────┐
│                                                                         │
│ Configure disk cleanup behavior:                                       │
│                                                                         │
│ • Size Threshold: Identify files larger than N bytes as "large"        │
│ • Dry-Run Mode: Preview changes before making them (recommended)       │
└─────────────────────────────────────────────────────────────────────────┘
EOF

    # Size threshold in MB
    while true; do
        size_input=$(prompt_input "Size threshold in MB" "100")
        if validate_number_range "$size_input" 1 10240 2>/dev/null; then
            # Convert MB to bytes
            local bytes=$((size_input * 1048576))
            config_values[DISK_CLEANUP_SIZE_THRESHOLD]="$bytes"
            log_success "Size threshold set to ${size_input}MB"
            break
        fi
    done
    
    # Dry-run mode
    if confirm "Enable dry-run mode by default? (preview before making changes)"; then
        config_values[DISK_CLEANUP_DRY_RUN]="true"
        log_success "Dry-run mode enabled (recommended for learning)"
    else
        config_values[DISK_CLEANUP_DRY_RUN]="false"
        log_warn "Dry-run disabled — cleanup operations will make actual changes"
    fi
    
    read -p "Press Enter to continue..."
}

configure_backup() {
    if [[ "${config_values[FEATURE_BACKUP]}" != "true" ]]; then
        return 0
    fi
    
    clear
    cat << 'EOF'
┌─ Backup Configuration ──────────────────────────────────────────────────┐
│                                                                         │
│ Configure backup behavior:                                             │
│                                                                         │
│ • Directories to backup (space-separated paths)                         │
│ • Backup retention (keep last N backups)                               │
│ • Compression method (gzip, bzip2, xz)                                 │
│ • Backup schedule (optional cron expression)                           │
└─────────────────────────────────────────────────────────────────────────┘
EOF

    # Backup directories
    local backup_dirs=$(prompt_input "Directories to backup (space-separated)" "/home /etc")
    config_values[BACKUP_DIRS]="$backup_dirs"
    log_success "Backup directories: $backup_dirs"
    
    # Backup retention
    while true; do
        retention_input=$(prompt_input "Number of backups to retain" "10")
        if validate_number_range "$retention_input" 1 100 2>/dev/null; then
            config_values[BACKUP_RETENTION_COUNT]="$retention_input"
            log_success "Backup retention set to $retention_input backups"
            break
        fi
    done
    
    # Compression
    cat << 'EOF'

Compression methods:
  1. gzip    (default, good compression)
  2. bzip2   (better compression, slower)
  3. xz      (best compression, very slow)
  4. none    (no compression, fastest)
EOF
    local compression=$(prompt_input "Compression method" "gzip")
    if [[ ! "$compression" =~ ^(gzip|bzip2|xz|none)$ ]]; then
        log_warn "Invalid compression method, using gzip"
        compression="gzip"
    fi
    config_values[BACKUP_COMPRESSION]="$compression"
    log_success "Compression: $compression"
    
    # Backup schedule
    echo ""
    cat << 'EOF'
Cron schedule examples:
  "0 2 * * *"     — Daily at 2:00 AM
  "0 * * * *"     — Every hour
  "30 3 * * 0"    — Weekly on Sunday at 3:30 AM
  ""              — (disable automatic scheduling for now)
EOF
    local schedule=$(prompt_input "Backup cron schedule (optional)" "")
    config_values[BACKUP_SCHEDULE]="$schedule"
    if [[ -z "$schedule" ]]; then
        log_info "Automatic backup scheduling disabled"
    else
        log_success "Backup schedule: $schedule"
    fi
    
    read -p "Press Enter to continue..."
}

configure_health_check() {
    if [[ "${config_values[FEATURE_HEALTH_CHECK]}" != "true" ]]; then
        return 0
    fi
    
    clear
    cat << 'EOF'
┌─ Health Check Configuration ────────────────────────────────────────────┐
│                                                                         │
│ Configure alerting thresholds for health monitoring:                   │
│                                                                         │
│ When a metric exceeds its threshold, health check alerts you           │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
EOF

    # CPU threshold
    while true; do
        cpu_input=$(prompt_input "CPU usage alert threshold (%)" "80")
        if validate_number_range "$cpu_input" 1 100 2>/dev/null; then
            config_values[HEALTH_CHECK_CPU_THRESHOLD]="$cpu_input"
            log_success "CPU threshold: ${cpu_input}%"
            break
        fi
    done
    
    # Memory threshold
    while true; do
        mem_input=$(prompt_input "Memory usage alert threshold (%)" "80")
        if validate_number_range "$mem_input" 1 100 2>/dev/null; then
            config_values[HEALTH_CHECK_MEMORY_THRESHOLD]="$mem_input"
            log_success "Memory threshold: ${mem_input}%"
            break
        fi
    done
    
    # Disk threshold
    while true; do
        disk_input=$(prompt_input "Disk usage alert threshold (%)" "80")
        if validate_number_range "$disk_input" 1 100 2>/dev/null; then
            config_values[HEALTH_CHECK_DISK_THRESHOLD]="$disk_input"
            log_success "Disk threshold: ${disk_input}%"
            break
        fi
    done
    
    read -p "Press Enter to continue..."
}

configure_logging() {
    clear
    cat << 'EOF'
┌─ Logging Configuration ─────────────────────────────────────────────────┐
│                                                                         │
│ Configure how ShellOps logs its activities:                            │
│                                                                         │
│ Log levels: ERROR (minimal), WARN, INFO (normal), DEBUG (verbose)      │
│ Logs will be written to: /var/log/shellops/shellops.log               │
│ (or ~/. shellops/logs/shellops.log if root access unavailable)         │
└─────────────────────────────────────────────────────────────────────────┘
EOF

    cat << 'EOF'

Log level examples:
  ERROR   — Only errors and critical issues
  WARN    — Warnings and errors
  INFO    — Normal operations (recommended)
  DEBUG   — Detailed debugging information
EOF
    
    local log_level=$(prompt_input "Log level" "INFO")
    if [[ ! "$log_level" =~ ^(ERROR|WARN|INFO|DEBUG)$ ]]; then
        log_warn "Invalid log level, using INFO"
        log_level="INFO"
    fi
    config_values[LOG_LEVEL]="$log_level"
    log_success "Log level: $log_level"
    
    read -p "Press Enter to continue..."
}

# ============================================================================
# Configuration Summary and Generation
# ============================================================================

show_summary() {
    clear
    cat << 'EOF'
◊─────────────────────────────────────────────────────────────────────────◊
│                    Configuration Summary                                │
◊─────────────────────────────────────────────────────────────────────────◊
EOF

    cat << EOF

Features Enabled:
  • User Monitoring:   ${config_values[FEATURE_USER_MONITOR]}
  • Disk Cleanup:      ${config_values[FEATURE_DISK_CLEANUP]}
  • Backup:            ${config_values[FEATURE_BACKUP]}
  • Health Checks:     ${config_values[FEATURE_HEALTH_CHECK]}

Performance Thresholds:
  • Idle timeout:      ${config_values[USER_MONITOR_IDLE_THRESHOLD]:-3600} seconds
  • Large file size:   $((${config_values[DISK_CLEANUP_SIZE_THRESHOLD]:-104857600} / 1048576)) MB
  • Backup retention:  ${config_values[BACKUP_RETENTION_COUNT]:-10} backups
  • CPU alert at:      ${config_values[HEALTH_CHECK_CPU_THRESHOLD]:-80}%
  • Memory alert at:   ${config_values[HEALTH_CHECK_MEMORY_THRESHOLD]:-80}%
  • Disk alert at:     ${config_values[HEALTH_CHECK_DISK_THRESHOLD]:-80}%

Configuration will be saved to:
  $CONFIG_FILE

EOF

    if confirm "Does this configuration look correct?"; then
        return 0
    else
        log_warn "Returning to feature selection..."
        return 1
    fi
}

# ============================================================================
# Configuration File Generation
# ============================================================================

generate_config_file() {
    ensure_dir "$CONFIG_DIR" 755
    
    cat > "$CONFIG_FILE" << 'HEREDOC'
#!/bin/bash
# shellops.conf — ShellOps Configuration
# Generated by setup wizard
# Edit this file to customize ShellOps behavior

# ============================================================================
# Feature Enablement
# ============================================================================

HEREDOC

    # Write feature flags
    echo "FEATURE_USER_MONITOR=${config_values[FEATURE_USER_MONITOR]}" >> "$CONFIG_FILE"
    echo "FEATURE_DISK_CLEANUP=${config_values[FEATURE_DISK_CLEANUP]}" >> "$CONFIG_FILE"
    echo "FEATURE_BACKUP=${config_values[FEATURE_BACKUP]}" >> "$CONFIG_FILE"
    echo "FEATURE_HEALTH_CHECK=${config_values[FEATURE_HEALTH_CHECK]}" >> "$CONFIG_FILE"
    
    cat >> "$CONFIG_FILE" << 'HEREDOC'

# ============================================================================
# User Monitoring Configuration
# ============================================================================

HEREDOC

    echo "USER_MONITOR_IDLE_THRESHOLD=${config_values[USER_MONITOR_IDLE_THRESHOLD]:-3600}" >> "$CONFIG_FILE"
    echo "USER_MONITOR_ALERT_ROOT_LOGINS=${config_values[USER_MONITOR_ALERT_ROOT_LOGINS]:-true}" >> "$CONFIG_FILE"

    cat >> "$CONFIG_FILE" << 'HEREDOC'

# ============================================================================
# Disk Cleanup Configuration
# ============================================================================

HEREDOC

    echo "DISK_CLEANUP_SIZE_THRESHOLD=${config_values[DISK_CLEANUP_SIZE_THRESHOLD]:-104857600}" >> "$CONFIG_FILE"
    echo "DISK_CLEANUP_DRY_RUN=${config_values[DISK_CLEANUP_DRY_RUN]:-true}" >> "$CONFIG_FILE"

    cat >> "$CONFIG_FILE" << 'HEREDOC'

# ============================================================================
# Backup Configuration
# ============================================================================

HEREDOC

    echo "BACKUP_DIRS=\"${config_values[BACKUP_DIRS]:-/home /etc}\"" >> "$CONFIG_FILE"
    echo "BACKUP_RETENTION_COUNT=${config_values[BACKUP_RETENTION_COUNT]:-10}" >> "$CONFIG_FILE"
    echo "BACKUP_COMPRESSION=${config_values[BACKUP_COMPRESSION]:-gzip}" >> "$CONFIG_FILE"
    if [[ -n "${config_values[BACKUP_SCHEDULE]}" ]]; then
        echo "BACKUP_SCHEDULE=\"${config_values[BACKUP_SCHEDULE]}\"" >> "$CONFIG_FILE"
        echo "BACKUP_ENABLED=true" >> "$CONFIG_FILE"
    else
        echo "BACKUP_SCHEDULE=\"\"" >> "$CONFIG_FILE"
        echo "BACKUP_ENABLED=false" >> "$CONFIG_FILE"
    fi

    cat >> "$CONFIG_FILE" << 'HEREDOC'

# ============================================================================
# Health Check Configuration
# ============================================================================

HEREDOC

    echo "HEALTH_CHECK_CPU_THRESHOLD=${config_values[HEALTH_CHECK_CPU_THRESHOLD]:-80}" >> "$CONFIG_FILE"
    echo "HEALTH_CHECK_MEMORY_THRESHOLD=${config_values[HEALTH_CHECK_MEMORY_THRESHOLD]:-80}" >> "$CONFIG_FILE"
    echo "HEALTH_CHECK_DISK_THRESHOLD=${config_values[HEALTH_CHECK_DISK_THRESHOLD]:-80}" >> "$CONFIG_FILE"

    cat >> "$CONFIG_FILE" << 'HEREDOC'

# ============================================================================
# Logging Configuration
# ============================================================================

HEREDOC

    echo "LOG_LEVEL=${config_values[LOG_LEVEL]:-INFO}" >> "$CONFIG_FILE"
    echo "ENABLE_LOGGING=true" >> "$CONFIG_FILE"

    chmod 644 "$CONFIG_FILE"
    log_success "Configuration saved to: $CONFIG_FILE"
}

# Generate backup exclude file
generate_backup_exclude() {
    cat > "$BACKUP_EXCLUDE" << 'EOF'
# backup.exclude — Patterns to exclude from backups
# Specified as paths relative to backup directories

# System/cache directories
.cache/*
.local/share/cache/*

# Temporary files
.tmp/*
*.tmp
*.bak

# Version control (usually backed up separately)
.git/*
.svn/*

# Package manager caches
.npm/*
.composer/cache/*

# Virtual environments
venv/
env/
.venv/

# Large media 
# (uncomment if backing up /home and want to exclude media)
# Videos/*
# Movies/*
# *.mp4
EOF

    chmod 644 "$BACKUP_EXCLUDE"
    log_success "Backup exclude patterns saved to: $BACKUP_EXCLUDE"
}

# ============================================================================
# Main Wizard Flow
# ============================================================================

main() {
    # Check for root/sudo
    if [[ $EUID -ne 0 ]]; then
        log_warn "Setup wizard should be run with sudo for some operations"
        log_info "Continuing with user permissions..."
    fi
    
    # Run wizard sections
    show_welcome
    configure_features
    configure_user_monitoring
    configure_disk_cleanup
    configure_backup
    configure_health_check
    configure_logging
    
    # Show summary and confirm
    while ! show_summary; do
        configure_features
        configure_user_monitoring
        configure_disk_cleanup
        configure_backup
        configure_health_check
    done
    
    # Generate configuration files
    generate_config_file
    generate_backup_exclude
    
    # Show completion
    clear
    cat << 'EOF'
╔════════════════════════════════════════════════════════════════════════════╗
║                    Setup Complete! ✓                                       ║
╚════════════════════════════════════════════════════════════════════════════╝

Your ShellOps configuration has been saved!

Next steps:

1. Review the configuration file:
   cat config/shellops.conf

2. Run the test suite:
   ./test.sh

3. Start using ShellOps:
   ./shellops help
   ./shellops monitor
   ./shellops health
   ./shellops cleanup --dry-run

4. Set up automated backups (if enabled):
   ./shellops backup --schedule

For help and documentation:
   ./shellops help [feature]
   cat docs/quick-start.md

Happy administrating! 🚀

EOF
}

# ============================================================================
# Entry point
# ============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

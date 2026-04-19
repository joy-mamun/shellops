#!/bin/bash
# lib/config.sh — Configuration management for ShellOps
# Handles loading, validating, and exporting configuration

source "$(dirname "${BASH_SOURCE[0]}")/common.sh" || exit 1

# ============================================================================
# Configuration Variables (Defaults)
# ============================================================================

# Paths
CONFIG_DIR="${CONFIG_DIR:-.}"
CONFIG_FILE="${CONFIG_DIR}/shellops.conf"
LOG_DIR="${LOG_DIR:-/var/log/shellops}"
LOG_FILE="${LOG_DIR}/shellops.log"
BACKUP_DIR="${BACKUP_DIR:-./backups}"

# Feature flags
FEATURE_USER_MONITOR="${FEATURE_USER_MONITOR:-true}"
FEATURE_DISK_CLEANUP="${FEATURE_DISK_CLEANUP:-true}"
FEATURE_BACKUP="${FEATURE_BACKUP:-true}"
FEATURE_HEALTH_CHECK="${FEATURE_HEALTH_CHECK:-true}"

# User monitoring
USER_MONITOR_IDLE_THRESHOLD="${USER_MONITOR_IDLE_THRESHOLD:-3600}"  # 1 hour in seconds
USER_MONITOR_ALERT_ROOT_LOGINS="${USER_MONITOR_ALERT_ROOT_LOGINS:-true}"

# Disk cleanup
DISK_CLEANUP_SIZE_THRESHOLD="${DISK_CLEANUP_SIZE_THRESHOLD:-104857600}"  # 100MB in bytes
DISK_CLEANUP_DRY_RUN="${DISK_CLEANUP_DRY_RUN:-true}"
DISK_CLEANUP_TEMP_DIRS=("/tmp" "/var/tmp" "/var/cache/apt")

# Backup configuration
BACKUP_RETENTION_COUNT="${BACKUP_RETENTION_COUNT:-10}"
BACKUP_COMPRESSION="${BACKUP_COMPRESSION:-gzip}"
BACKUP_SCHEDULE="${BACKUP_SCHEDULE:-}"  # e.g., "0 2 * * *" for daily at 2am
BACKUP_ENABLED="${BACKUP_ENABLED:-false}"

# Health check
HEALTH_CHECK_CPU_THRESHOLD="${HEALTH_CHECK_CPU_THRESHOLD:-80}"
HEALTH_CHECK_MEMORY_THRESHOLD="${HEALTH_CHECK_MEMORY_THRESHOLD:-80}"
HEALTH_CHECK_DISK_THRESHOLD="${HEALTH_CHECK_DISK_THRESHOLD:-80}"

# Logging
LOG_LEVEL="${LOG_LEVEL:-INFO}"  # INFO, WARN, ERROR
ENABLE_LOGGING="${ENABLE_LOGGING:-true}"

# ============================================================================
# Configuration Loading & Validation
# ============================================================================

# Load configuration from file
load_config_file() {
    local config_file="${1:-$CONFIG_FILE}"
    
    if [[ ! -f "$config_file" ]]; then
        log_warn "Configuration file not found: $config_file"
        log_info "Using default configuration values"
        return 0
    fi
    
    if [[ ! -r "$config_file" ]]; then
        log_error "Configuration file not readable: $config_file"
        return 1
    fi
    
    # Source the config file in a subshell to validate syntax
    if ! bash -n "$config_file" 2>/dev/null; then
        log_error "Configuration file has syntax errors: $config_file"
        return 1
    fi
    
    # Source the config file (variables will be set in current shell)
    # shellcheck source=/dev/null
    source "$config_file" || {
        log_error "Failed to load configuration file: $config_file"
        return 1
    }
    
    log_info "Configuration loaded from: $config_file"
    return 0
}

# Validate all configuration values
validate_config() {
    local errors=0
    
    # Validate numeric thresholds
    if ! validate_number_range "$USER_MONITOR_IDLE_THRESHOLD" 60 86400 2>/dev/null; then
        log_warn "Invalid USER_MONITOR_IDLE_THRESHOLD, using default (3600)"
        USER_MONITOR_IDLE_THRESHOLD=3600
    fi
    
    if ! validate_number_range "$DISK_CLEANUP_SIZE_THRESHOLD" 1048576 10737418240 2>/dev/null; then
        log_warn "Invalid DISK_CLEANUP_SIZE_THRESHOLD, using default (104857600)"
        DISK_CLEANUP_SIZE_THRESHOLD=104857600
    fi
    
    if ! validate_number_range "$BACKUP_RETENTION_COUNT" 1 100 2>/dev/null; then
        log_warn "Invalid BACKUP_RETENTION_COUNT, using default (10)"
        BACKUP_RETENTION_COUNT=10
    fi
    
    if ! validate_number_range "$HEALTH_CHECK_CPU_THRESHOLD" 1 100 2>/dev/null; then
        log_warn "Invalid HEALTH_CHECK_CPU_THRESHOLD, using default (80)"
        HEALTH_CHECK_CPU_THRESHOLD=80
    fi
    
    if ! validate_number_range "$HEALTH_CHECK_MEMORY_THRESHOLD" 1 100 2>/dev/null; then
        log_warn "Invalid HEALTH_CHECK_MEMORY_THRESHOLD, using default (80)"
        HEALTH_CHECK_MEMORY_THRESHOLD=80
    fi
    
    if ! validate_number_range "$HEALTH_CHECK_DISK_THRESHOLD" 1 100 2>/dev/null; then
        log_warn "Invalid HEALTH_CHECK_DISK_THRESHOLD, using default (80)"
        HEALTH_CHECK_DISK_THRESHOLD=80
    fi
    
    # Validate boolean flags
    for flag in FEATURE_USER_MONITOR FEATURE_DISK_CLEANUP FEATURE_BACKUP \
                FEATURE_HEALTH_CHECK USER_MONITOR_ALERT_ROOT_LOGINS \
                DISK_CLEANUP_DRY_RUN BACKUP_ENABLED ENABLE_LOGGING; do
        if [[ -v "$flag" ]]; then
            local value="${!flag}"
            if [[ ! "$value" =~ ^(true|false)$ ]]; then
                log_warn "Invalid boolean value for $flag, using default"
                errors=$((errors + 1))
            fi
        fi
    done
    
    # Validate compression format
    if [[ ! "$BACKUP_COMPRESSION" =~ ^(gzip|bzip2|xz|none)$ ]]; then
        log_warn "Invalid BACKUP_COMPRESSION, using default (gzip)"
        BACKUP_COMPRESSION="gzip"
    fi
    
    # Validate log level
    if [[ ! "$LOG_LEVEL" =~ ^(INFO|WARN|ERROR|DEBUG)$ ]]; then
        log_warn "Invalid LOG_LEVEL, using default (INFO)"
        LOG_LEVEL="INFO"
    fi
    
    if [[ $errors -gt 0 ]]; then
        log_warn "Configuration validation completed with $errors warning(s)"
    else
        log_info "Configuration validation successful"
    fi
    
    return 0
}

# Export all configuration variables for subshells
export_config() {
    export CONFIG_DIR CONFIG_FILE LOG_DIR LOG_FILE BACKUP_DIR
    export FEATURE_USER_MONITOR FEATURE_DISK_CLEANUP FEATURE_BACKUP FEATURE_HEALTH_CHECK
    export USER_MONITOR_IDLE_THRESHOLD USER_MONITOR_ALERT_ROOT_LOGINS
    export DISK_CLEANUP_SIZE_THRESHOLD DISK_CLEANUP_DRY_RUN DISK_CLEANUP_TEMP_DIRS
    export BACKUP_RETENTION_COUNT BACKUP_COMPRESSION BACKUP_SCHEDULE BACKUP_ENABLED
    export HEALTH_CHECK_CPU_THRESHOLD HEALTH_CHECK_MEMORY_THRESHOLD HEALTH_CHECK_DISK_THRESHOLD
    export LOG_LEVEL ENABLE_LOGGING
}

# ============================================================================
# Configuration Utilities
# ============================================================================

# Initialize logging directory
init_logging() {
    if [[ "$ENABLE_LOGGING" != "true" ]]; then
        return 0
    fi
    
    if [[ ! -d "$LOG_DIR" ]]; then
        if mkdir -p "$LOG_DIR" 2>/dev/null; then
            log_info "Created log directory: $LOG_DIR"
        else
            # Fallback to user's home directory
            LOG_DIR="$HOME/.shellops/logs"
            mkdir -p "$LOG_DIR" || {
                log_error "Failed to create log directory: $LOG_DIR"
                return 1
            }
            LOG_FILE="$LOG_DIR/shellops.log"
            log_warn "Using fallback log directory: $LOG_DIR"
        fi
    fi
    
    # Verify log file is writable
    if ! touch "$LOG_FILE" 2>/dev/null; then
        log_error "Log file not writable: $LOG_FILE"
        return 1
    fi
    
    log_info "Logging initialized: $LOG_FILE"
    return 0
}

# Initialize backup directory
init_backup_dir() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        mkdir -p "$BACKUP_DIR" || {
            log_error "Failed to create backup directory: $BACKUP_DIR"
            return 1
        }
        log_info "Created backup directory: $BACKUP_DIR"
    fi
    
    # Verify backup directory is writable
    if [[ ! -w "$BACKUP_DIR" ]]; then
        log_error "Backup directory not writable: $BACKUP_DIR"
        return 1
    fi
    
    return 0
}

# Get config value with fallback to default
get_config_value() {
    local key="$1"
    local default="${2:-}"
    
    if [[ -v "$key" ]]; then
        echo "${!key}"
    else
        echo "$default"
    fi
}

# Check if feature is enabled
is_feature_enabled() {
    local feature="$1"
    local config_var="FEATURE_${feature^^}"
    
    local value
    value=$(get_config_value "$config_var" "false")
    [[ "$value" == "true" ]]
}

# Print current configuration (for debugging)
print_config() {
    log_info "Current Configuration:"
    log_info "  Config File: $CONFIG_FILE"
    log_info "  Log Level: $LOG_LEVEL"
    log_info "  Features:"
    log_info "    - User Monitor: $FEATURE_USER_MONITOR"
    log_info "    - Disk Cleanup: $FEATURE_DISK_CLEANUP"
    log_info "    - Backup: $FEATURE_BACKUP (enabled: $BACKUP_ENABLED)"
    log_info "    - Health Check: $FEATURE_HEALTH_CHECK"
    log_info "  Directories:"
    log_info "    - Log Dir: $LOG_DIR"
    log_info "    - Backup Dir: $BACKUP_DIR"
}

# ============================================================================
# Main Configuration Initialization
# ============================================================================

# Initialize configuration (call this once at startup)
init_config() {
    local config_file="${1:-$CONFIG_FILE}"
    
    log_info "Initializing configuration..."
    
    # Load configuration file (if exists)
    load_config_file "$config_file" || {
        log_warn "Could not load configuration, using defaults"
    }
    
    # Validate configuration values
    validate_config || {
        log_error "Configuration validation failed"
        return 1
    }
    
    # Initialize logging
    init_logging || {
        log_error "Failed to initialize logging"
        return 1
    }
    
    # Initialize backup directory
    init_backup_dir || {
        log_error "Failed to initialize backup directory"
        return 1
    }
    
    # Export all variables for subshells
    export_config
    
    log_success "Configuration initialization complete"
    return 0
}

# ============================================================================
# Export functions
# ============================================================================

export -f load_config_file validate_config export_config
export -f init_logging init_backup_dir init_config
export -f get_config_value is_feature_enabled print_config

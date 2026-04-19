#!/bin/bash
# lib/common.sh — Shared utility functions for ShellOps
# Provides logging, error handling, validation, and color-coded output

set -euo pipefail

# ============================================================================
# Color Codes for Readability
# ============================================================================

readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_RESET='\033[0m'

# ============================================================================
# Logging Functions
# ============================================================================

# Log informational messages with timestamp
log_info() {
    local message="$1"
    echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $(date '+%Y-%m-%d %H:%M:%S') — $message" >&2
}

# Log warning messages with timestamp
log_warn() {
    local message="$1"
    echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} $(date '+%Y-%m-%d %H:%M:%S') — $message" >&2
}

# Log error messages with timestamp
log_error() {
    local message="$1"
    echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $(date '+%Y-%m-%d %H:%M:%S') — $message" >&2
}

# Log success messages with timestamp
log_success() {
    local message="$1"
    echo -e "${COLOR_GREEN}[OK]${COLOR_RESET} $(date '+%Y-%m-%d %H:%M:%S') — $message" >&2
}

# ============================================================================
# Error Handling & Exit Functions
# ============================================================================

# Exit with error message and exit code
die() {
    local message="$1"
    local exit_code="${2:-1}"
    log_error "$message"
    exit "$exit_code"
}

# Trap errors and log them
trap_error() {
    local line_number=$1
    log_error "Script error on line $line_number"
    exit 1
}

# ============================================================================
# Permission & Privilege Checks
# ============================================================================

# Verify script is running with root/sudo privileges
require_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This operation requires root privileges. Please run with sudo."
        return 1
    fi
    return 0
}

# Check if command exists in PATH
require_command() {
    local cmd="$1"
    if ! command -v "$cmd" > /dev/null 2>&1; then
        log_error "Required command not found: $cmd"
        return 1
    fi
    return 0
}

# ============================================================================
# File & Directory Validation
# ============================================================================

# Verify file exists and is readable
require_file_readable() {
    local file="$1"
    if [[ ! -r "$file" ]]; then
        log_error "File not readable or does not exist: $file"
        return 1
    fi
    return 0
}

# Verify directory exists and is readable
require_dir_readable() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        log_error "Directory does not exist: $dir"
        return 1
    fi
    if [[ ! -r "$dir" ]]; then
        log_error "Directory not readable: $dir"
        return 1
    fi
    return 0
}

# Verify directory exists and is writable
require_dir_writable() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        log_error "Directory does not exist: $dir"
        return 1
    fi
    if [[ ! -w "$dir" ]]; then
        log_error "Directory not writable: $dir"
        return 1
    fi
    return 0
}

# Create directory if it doesn't exist, with optional mode
ensure_dir() {
    local dir="$1"
    local mode="${2:-755}"

    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir" || {
            die "Failed to create directory: $dir"
        }
        chmod "$mode" "$dir" || {
            die "Failed to set permissions on $dir"
        }
        log_info "Created directory: $dir"
    fi
}

# ============================================================================
# Validation Helpers
# ============================================================================

# Validate string matches pattern (regex)
validate_pattern() {
    local string="$1"
    local pattern="$2"
    local error_msg="${3:-Validation failed}"

    if [[ ! $string =~ $pattern ]]; then
        log_error "$error_msg"
        return 1
    fi
    return 0
}

# Validate number is within range
validate_number_range() {
    local number="$1"
    local min="$2"
    local max="$3"

    if ! [[ "$number" =~ ^[0-9]+$ ]]; then
        log_error "Not a valid number: $number"
        return 1
    fi

    if (( number < min || number > max )); then
        log_error "Number out of range ($min-$max): $number"
        return 1
    fi
    return 0
}

# Validate yes/no input
validate_yes_no() {
    local input="$1"
    if [[ ! "$input" =~ ^(y|yes|n|no)$ ]]; then
        log_error "Invalid input. Please use: yes, no, y, or n"
        return 1
    fi
    return 0
}

# ============================================================================
# User Interaction
# ============================================================================

# Prompt user for yes/no confirmation
confirm() {
    local prompt="$1"
    local response

    while true; do
        read -p "$prompt (yes/no): " response
        if validate_yes_no "$response"; then
            if [[ "$response" =~ ^(y|yes)$ ]]; then
                return 0
            else
                return 1
            fi
        fi
    done
}

# Prompt user for input with optional default
prompt_input() {
    local prompt="$1"
    local default="${2:-}"
    local user_input

    if [[ -n "$default" ]]; then
        read -p "$prompt [$default]: " user_input
        user_input="${user_input:-$default}"
    else
        read -p "$prompt: " user_input
        while [[ -z "$user_input" ]]; do
            log_warn "Input cannot be empty"
            read -p "$prompt: " user_input
        done
    fi
    echo "$user_input"
}

# Prompt user for secret input (hidden)
prompt_secret() {
    local prompt="$1"
    local secret

    read -sp "$prompt: " secret
    echo
    echo "$secret"
}

# ============================================================================
# System Information
# ============================================================================

# Get system username (prefer SUDO_USER for sudoed commands)
get_effective_user() {
    if [[ -n "${SUDO_USER:-}" ]]; then
        echo "$SUDO_USER"
    else
        echo "${USER:-$(whoami)}"
    fi
}

# Get system hostname
get_hostname() {
    hostname -f 2> /dev/null || hostname
}

# Get OS type
get_os_type() {
    uname -s
}

# Check if running on specific OS
is_os() {
    local target_os="$1"
    local current_os
    current_os=$(uname -s | tr '[:upper:]' '[:lower:]')
    [[ "$current_os" == "$target_os" ]]
}

# ============================================================================
# Array Utilities
# ============================================================================

# Check if value exists in array
array_contains() {
    local target="$1"
    shift
    local array=("$@")

    for item in "${array[@]}"; do
        if [[ "$item" == "$target" ]]; then
            return 0
        fi
    done
    return 1
}

# Join array elements with delimiter
array_join() {
    local delimiter="$1"
    shift
    local array=("$@")
    local result=""

    for i in "${!array[@]}"; do
        if [[ $i -eq 0 ]]; then
            result="${array[$i]}"
        else
            result="${result}${delimiter}${array[$i]}"
        fi
    done
    echo "$result"
}

# ============================================================================
# String Utilities
# ============================================================================

# Convert string to lowercase
to_lower() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

# Convert string to uppercase
to_upper() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

# Trim leading/trailing whitespace
trim() {
    local var="$1"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    echo "$var"
}

# ============================================================================
# Export functions for subshells
# ============================================================================

export -f log_info log_warn log_error log_success
export -f die
export -f require_root require_command
export -f require_file_readable require_dir_readable require_dir_writable ensure_dir
export -f validate_pattern validate_number_range validate_yes_no
export -f confirm prompt_input prompt_secret
export -f get_effective_user get_hostname get_os_type is_os
export -f array_contains array_join
export -f to_lower to_upper trim

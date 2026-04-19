#!/bin/bash
# lib/user_monitor.sh — User monitoring module for ShellOps
# Tracks active users, login history, idle time, and suspicious activity

source "$(dirname "${BASH_SOURCE[0]}")/common.sh" || exit 1
source "$(dirname "${BASH_SOURCE[0]}")/config.sh" || exit 1

# ============================================================================
# User Monitoring Functions
# ============================================================================

# List all active users with login times
list_active_users() {
    log_info "Active users on $(get_hostname):"
    
    # Use 'who' to get active sessions
    if who | grep -q .; then
        who | awk '{print $1, "logged in at", $3" "$4}' | column -t
    else
        log_warn "No active users found"
    fi
}

# Get user idle time (in seconds)
get_user_idle_time() {
    local username="$1"
    
    # Try to get idle time from 'w' command
    if ! command -v w &> /dev/null; then
        log_warn "Command 'w' not available for idle time calculation"
        return 1
    fi
    
    local idle_time
    idle_time=$(w -hs | grep "^$username" | awk '{print $NF}' | head -1)
    
    if [[ -z "$idle_time" ]]; then
        return 1
    fi
    
    # Convert idle time format (e.g., "5:23" or "1:30m")
    # Returns total seconds
    if [[ "$idle_time" =~ ^([0-9]+):([0-9]+)$ ]]; then
        local mins=${BASH_REMATCH[1]}
        local secs=${BASH_REMATCH[2]}
        echo $((mins * 60 + secs))
    elif [[ "$idle_time" =~ ^([0-9]+):([0-9]+)m$ ]]; then
        local hours=${BASH_REMATCH[1]}
        local mins=${BASH_REMATCH[2]}
        echo $((hours * 3600 + mins * 60))
    else
        return 1
    fi
}

# Show user idle time for active users
show_user_idle_time() {
    if ! command -v w &> /dev/null; then
        log_warn "'w' command not available, cannot show idle times"
        return 1
    fi
    
    log_info "User idle times:"
    echo "User       Terminal  From         Idle"
    echo "───────────────────────────────────────"
    w -hs | awk '{
        printf "%-10s %-9s %-12s %s\n", $1, $2, $3, $NF
    }' | sort -k1
}

# Display last login history
show_last_logins() {
    local count="${1:-10}"
    
    if [[ ! -f /var/log/auth.log ]] && [[ ! -f /var/log/secure ]]; then
        log_warn "Authentication log file not found"
        return 1
    fi
    
    log_info "Last $count logins:"
    echo "User       Date                Hostname/TTY"
    echo "───────────────────────────────────────────"
    
    local auth_log=""
    [[ -f /var/log/auth.log ]] && auth_log="/var/log/auth.log"
    [[ -f /var/log/secure ]] && auth_log="/var/log/secure"
    
    if [[ -n "$auth_log" ]]; then
        grep -i "accepted" "$auth_log" | tail -n "$count" | awk '{
            username = ""; host = ""; date = "";
            for(i=1;i<=NF;i++) {
                if ($i ~ /user=/) {
                    username = substr($i, 6);
                    gsub(/"/, "", username);
                }
                if ($i ~ /rhost=/) {
                    host = substr($i, 7);
                    gsub(/"/, "", host);
                }
            }
            if (username != "") {
                printf "%-10s %s-%s-%s %s\n", username, $1, $2, $3, (host ? host : "local");
            }
        }' | sort -rk2 | uniq
    fi
}

# Alert on suspicious root activity
check_root_activity() {
    if [[ "${USER_MONITOR_ALERT_ROOT_LOGINS}" != "true" ]]; then
        log_info "Root activity monitoring disabled"
        return 0
    fi
    
    log_info "Checking for suspicious root activity..."
    
    # Check for recent root logins
    local root_logins
    if [[ -f /var/log/auth.log ]]; then
        root_logins=$(grep -c "root.*accepted" /var/log/auth.log 2>/dev/null || echo 0)
    elif [[ -f /var/log/secure ]]; then
        root_logins=$(grep -c "root.*accepted" /var/log/secure 2>/dev/null || echo 0)
    else
        log_warn "Could not check auth logs"
        return 1
    fi
    
    if (( root_logins > 0 )); then
        log_warn "⚠ $root_logins root login(s) detected"
        
        # Show recent root logins
        echo "Recent root logins:"
        if [[ -f /var/log/auth.log ]]; then
            grep "root.*accepted" /var/log/auth.log 2>/dev/null | tail -n 5
        elif [[ -f /var/log/secure ]]; then
            grep "root.*accepted" /var/log/secure 2>/dev/null | tail -n 5
        fi
    else
        log_success "No suspicious root activity detected"
    fi
}

# Get summary of active users
get_active_user_count() {
    if command -v who &> /dev/null; then
        who | wc -l
    else
        return 1
    fi
}

# Check for idle users (useful for identifying unused sessions)
show_idle_users() {
    local idle_threshold="${1:-USER_MONITOR_IDLE_THRESHOLD}"
    
    if ! command -v w &> /dev/null; then
        log_error "'w' command not available"
        return 1
    fi
    
    log_info "Users idle for more than $idle_threshold seconds:"
    
    local found=0
    while IFS= read -r line; do
        if [[ -z "$line" ]]; then
            continue
        fi
        found=1
        echo "$line"
    done < <(w -hs 2>/dev/null | while read -r user tty from idle jcpu pcpu what; do
        if [[ -z "$user" ]]; then continue; fi
        
        # Parse idle time
        local idle_seconds=0
        if [[ "$idle" =~ ^([0-9]+):([0-9]+)$ ]]; then
            idle_seconds=$((BASH_REMATCH[1] * 60 + BASH_REMATCH[2]))
        elif [[ "$idle" =~ ^([0-9]+):([0-9]+)m$ ]]; then
            idle_seconds=$((BASH_REMATCH[1] * 3600 + BASH_REMATCH[2] * 60))
        fi
        
        if (( idle_seconds > idle_threshold )); then
            printf "%-15s %-10s %6ds idle\n" "$user" "$tty" "$idle_seconds"
        fi
    done)
    
    if [[ $found -eq 0 ]]; then
        log_info "No idle users found"
    fi
}

# Main user monitoring function
user_monitor_main() {
    local option="${1:-all}"
    
    log_info "Starting user monitoring..."
    
    case "$option" in
        users|active)
            list_active_users
            ;;
        idle)
            show_user_idle_time
            ;;
        history)
            show_last_logins "${2:-10}"
            ;;
        suspicious|alerts)
            check_root_activity
            ;;
        idle-threshold)
            show_idle_users "${2:-3600}"
            ;;
        count)
            local count
            count=$(get_active_user_count)
            if [[ $? -eq 0 ]]; then
                log_success "Active users: $count"
            fi
            ;;
        all|summary)
            echo "╔════════════════════════════════════════════════════╗"
            echo "║            User Monitoring Summary                 ║"
            echo "╚════════════════════════════════════════════════════╝"
            echo ""
            list_active_users
            echo ""
            show_user_idle_time || true
            echo ""
            check_root_activity || true
            echo ""
            show_last_logins 5
            ;;
        *)
            log_error "Unknown option: $option"
            return 1
            ;;
    esac
}

# ============================================================================
# Export functions
# ============================================================================

export -f list_active_users get_user_idle_time show_user_idle_time
export -f show_last_logins check_root_activity get_active_user_count
export -f show_idle_users user_monitor_main

#!/bin/bash
# lib/health_check.sh — System health monitoring module for ShellOps
# Monitors CPU, memory, disk, services, and network connectivity

source "$(dirname "${BASH_SOURCE[0]}")/common.sh" || exit 1
source "$(dirname "${BASH_SOURCE[0]}")/config.sh" || exit 1

# ============================================================================
# System Health Monitoring Functions
# ============================================================================

# Get CPU usage percentage
get_cpu_usage() {
    # Average CPU usage from /proc/stat (all cores combined)
    if [[ -f /proc/stat ]]; then
        local line1 line2
        line1=$(head -n1 /proc/stat)
        sleep 1
        line2=$(head -n1 /proc/stat)
        
        local user1 nice1 system1 idle1 iowait1 rest1
        local user2 nice2 system2 idle2 iowait2 rest2
        
        read -r _ user1 nice1 system1 idle1 iowait1 rest1 <<< "$line1"
        read -r _ user2 nice2 system2 idle2 iowait2 rest2 <<< "$line2"
        
        # Default iowait to 0 if not present
        iowait1=${iowait1:-0}
        iowait2=${iowait2:-0}
        
        local total1=$((user1 + nice1 + system1 + idle1 + iowait1))
        local total2=$((user2 + nice2 + system2 + idle2 + iowait2))
        local idle_delta=$((idle2 - idle1))
        local total_delta=$((total2 - total1))
        
        if (( total_delta > 0 )); then
            echo $((100 * (total_delta - idle_delta) / total_delta))
        fi
    else
        # Fallback using 'top' command
        top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print int(100 - $1)}'
    fi
}

# Get memory usage percentage
get_memory_usage() {
    # Using /proc/meminfo
    if [[ -f /proc/meminfo ]]; then
        local total free buffers cached
        
        total=$(grep "^MemTotal:" /proc/meminfo | awk '{print $2}')
        free=$(grep "^MemFree:" /proc/meminfo | awk '{print $2}')
        buffers=$(grep "^Buffers:" /proc/meminfo | awk '{print $2}')
        cached=$(grep "^Cached:" /proc/meminfo | awk '{print $2}')
        
        local used=$((total - free - buffers - cached))
        echo $((100 * used / total))
    fi
}

# Get load average
get_load_average() {
    # Return in format: 1min 5min 15min
    cat /proc/loadavg | awk '{printf "%.2f %.2f %.2f\n", $1, $2, $3}'
}

# Get disk usage for filesystem
get_disk_usage_percent() {
    local filesystem="${1:-/}"
    
    df "$filesystem" | tail -1 | awk '{gsub(/%/, "", $5); print $5}'
}

# Get system uptime
get_uptime() {
    local uptime_seconds
    uptime_seconds=$(cat /proc/uptime | awk '{print $1}' | cut -d. -f1)
    
    local days=$((uptime_seconds / 86400))
    local hours=$(((uptime_seconds % 86400) / 3600))
    local mins=$(((uptime_seconds % 3600) / 60))
    
    printf "%d days, %d hours, %d minutes\n" "$days" "$hours" "$mins"
}

# Check service status
check_service_status() {
    local service="$1"
    
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        echo "running"
        return 0
    else
        echo "stopped"
        return 1
    fi
}

# Check network connectivity
check_network_connectivity() {
    log_info "Checking network connectivity..."
    
    # Try multiple DNS servers for redundancy
    local hosts=("8.8.8.8" "1.1.1.1" "208.67.222.222")
    
    for host in "${hosts[@]}"; do
        if ping -c 1 -W 2 "$host" &>/dev/null; then
            log_success "Network connectivity: OK (reached $host)"
            return 0
        fi
    done
    
    log_error "Network connectivity: FAILED"
    return 1
}

# Check for available security updates
check_security_updates() {
    log_info "Checking for available security updates..."
    
    if command -v apt &>/dev/null; then
        # Debian/Ubuntu
        local updates
        updates=$(apt list --upgradable 2>/dev/null | wc -l)
        log_info "Available updates: $updates"
    elif command -v yum &>/dev/null; then
        # RHEL/CentOS
        local updates
        updates=$(yum list updates 2>/dev/null | wc -l)
        log_info "Available updates: $updates"
    else
        log_warn "Could not determine system package manager"
        return 1
    fi
}

# ============================================================================
# Health Report Generation
# ============================================================================

# Generate comprehensive health report
generate_health_report() {
    log_info "Generating system health report..."
    
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              System Health Report                              ║"
    echo "║              Generated: $(date '+%Y-%m-%d %H:%M:%S')                     ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    
    # System Information
    echo "┌─ System Information ─────────────────────────────────────────┐"
    echo "  Hostname:  $(get_hostname)"
    echo "  OS:        $(get_os_type)"
    echo "  Kernel:    $(uname -r)"
    echo "  Uptime:    $(get_uptime)"
    echo "└─────────────────────────────────────────────────────────────┘"
    echo ""
    
    # Resource Usage
    echo "┌─ Resource Usage ─────────────────────────────────────────────┐"
    
    local cpu
    cpu=$(get_cpu_usage)
    local cpu_status="OK"
    [[ $cpu -gt ${HEALTH_CHECK_CPU_THRESHOLD} ]] && cpu_status="⚠ HIGH"
    printf "  CPU Usage:         %3d%% %s\n" "$cpu" "$cpu_status"
    
    local mem
    mem=$(get_memory_usage)
    local mem_status="OK"
    [[ $mem -gt ${HEALTH_CHECK_MEMORY_THRESHOLD} ]] && mem_status="⚠ HIGH"
    printf "  Memory Usage:      %3d%% %s\n" "$mem" "$mem_status"
    
    local load
    load=$(get_load_average)
    echo "  Load Average:      $load"
    
    local disk_usage
    disk_usage=$(get_disk_usage_percent "/")
    local disk_status="OK"
    [[ $disk_usage -gt ${HEALTH_CHECK_DISK_THRESHOLD} ]] && disk_status="⚠ HIGH"
    printf "  Disk Usage (/):    %3d%% %s\n" "$disk_usage" "$disk_status"
    
    echo "└─────────────────────────────────────────────────────────────┘"
    echo ""
    
    # Disk Space Details
    echo "┌─ Disk Space ─────────────────────────────────────────────────┐"
    df -h --total | grep -v "^Filesystem" | tail -5 | while read -r line; do
        echo "  $line"
    done
    echo "└─────────────────────────────────────────────────────────────┘"
    echo ""
    
    # Services (if configured)
    echo "┌─ Services ───────────────────────────────────────────────────┐"
    local services=("ssh" "sshd" "apache2" "nginx" "mysql" "postgresql" "cron")
    for service in "${services[@]}"; do
        if systemctl list-unit-files "$service.service" &>/dev/null; then
            local status
            status=$(check_service_status "$service")
            if [[ "$status" == "running" ]]; then
                printf "  %-20s ✓ %s\n" "$service:" "running"
            else
                printf "  %-20s ✗ %s\n" "$service:" "stopped"
            fi
        fi
    done
    echo "└─────────────────────────────────────────────────────────────┘"
    echo ""
    
    # Network
    echo "┌─ Network ────────────────────────────────────────────────────┐"
    local dns_status
    if check_network_connectivity &>/dev/null; then
        dns_status="✓ Online"
    else
        dns_status="✗ Offline"
    fi
    echo "  Connectivity:      $dns_status"
    echo "└─────────────────────────────────────────────────────────────┘"
    echo ""
    
    # Alerts
    local has_alerts=0
    if (( cpu > HEALTH_CHECK_CPU_THRESHOLD )); then
        log_warn "⚠ CPU usage is high: ${cpu}%"
        has_alerts=1
    fi
    if (( mem > HEALTH_CHECK_MEMORY_THRESHOLD )); then
        log_warn "⚠ Memory usage is high: ${mem}%"
        has_alerts=1
    fi
    if (( disk_usage > HEALTH_CHECK_DISK_THRESHOLD )); then
        log_warn "⚠ Disk usage is high: ${disk_usage}%"
        has_alerts=1
    fi
    
    if [[ $has_alerts -eq 0 ]]; then
        log_success "No alerts — system health is normal"
    fi
}

# ============================================================================
# Quick Health Check
# ============================================================================

quick_health_check() {
    local cpu mem disk
    
    cpu=$(get_cpu_usage)
    mem=$(get_memory_usage)
    disk=$(get_disk_usage_percent "/")
    
    echo "CPU: ${cpu}% | Memory: ${mem}% | Disk: ${disk}%"
    
    # Return error if any threshold exceeded
    if (( cpu > HEALTH_CHECK_CPU_THRESHOLD || mem > HEALTH_CHECK_MEMORY_THRESHOLD || disk > HEALTH_CHECK_DISK_THRESHOLD )); then
        return 1
    fi
    return 0
}

# ============================================================================
# Main Health Check Function
# ============================================================================

health_check_main() {
    local action="${1:-report}"
    
    case "$action" in
        report|full)
            generate_health_report
            ;;
        quick)
            quick_health_check
            ;;
        cpu)
            log_info "CPU Usage: $(get_cpu_usage)%"
            ;;
        memory|mem)
            log_info "Memory Usage: $(get_memory_usage)%"
            ;;
        disk)
            log_info "Disk Usage: $(get_disk_usage_percent "/")%"
            ;;
        network)
            check_network_connectivity
            ;;
        uptime)
            log_info "System Uptime: $(get_uptime)"
            ;;
        updates)
            check_security_updates
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

export -f get_cpu_usage get_memory_usage get_load_average
export -f get_disk_usage_percent get_uptime check_service_status
export -f check_network_connectivity check_security_updates
export -f generate_health_report quick_health_check health_check_main

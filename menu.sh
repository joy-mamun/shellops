#!/bin/bash
# interactive_menu.sh — Interactive menu system for ShellOps
# Allows users to select commands by entering numbers at a prompt

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh" || exit 1

# ============================================================================
# Menu Configuration
# ============================================================================

readonly SHELLOPS_VERSION="1.0.0"

# ============================================================================
# Main Menu Display
# ============================================================================

show_main_menu() {
    clear
    cat << 'EOF'
╔════════════════════════════════════════════════════════════════════════════╗
║                                                                            ║
║                  ShellOps — Interactive Menu System                        ║
║          Educational Linux System Administration Toolkit                  ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝

EOF

    echo "MAIN MENU — Select an option:"
    echo ""
    echo "  MODULE MANAGEMENT:"
    echo "    1)  Health Check       — Monitor CPU, Memory, Disk, Network"
    echo "    2)  User Monitoring    — Track active users and login history"
    echo "    3)  Disk Cleanup       — Find large files, analyze usage"
    echo "    4)  Backup Management  — Create and manage backups"
    echo ""
    echo "  UTILITIES:"
    echo "    5)  Setup Wizard       — Configure ShellOps interactively"
    echo "    6)  System Report      — Full system analysis"
    echo "    7)  Help & Information — Show all available commands"
    echo "    8)  About ShellOps     — Version and project info"
    echo ""
    echo "  ACTIONS:"
    echo "    0)  Exit               — Quit ShellOps"
    echo ""
}

# ============================================================================
# Health Check Submenu
# ============================================================================

show_health_menu() {
    clear
    cat << 'EOF'
╔════════════════════════════════════════════════════════════════════════════╗
║                         HEALTH MONITORING                                  ║
╚════════════════════════════════════════════════════════════════════════════╝

EOF

    echo "SELECT AN ACTION:"
    echo ""
    echo "  1)  Quick Health Check     — CPU | Memory | Disk (one-liner)"
    echo "  2)  Full Health Report     — Detailed metrics with alerts"
    echo "  3)  CPU Usage              — Current CPU percentage"
    echo "  4)  Memory Usage           — Current memory percentage"
    echo "  5)  Disk Usage             — Root filesystem usage"
    echo "  6)  Network Connectivity   — Test network connectivity"
    echo "  7)  System Uptime          — How long system has been running"
    echo "  8)  Package Updates        — Check available updates"
    echo ""
    echo "  0)  Back to Main Menu"
    echo ""
}

# ============================================================================
# User Monitor Submenu
# ============================================================================

show_monitor_menu() {
    clear
    cat << 'EOF'
╔════════════════════════════════════════════════════════════════════════════╗
║                         USER MONITORING                                    ║
╚════════════════════════════════════════════════════════════════════════════╝

EOF

    echo "SELECT AN ACTION:"
    echo ""
    echo "  1)  Active Users           — List all currently logged-in users"
    echo "  2)  User Idle Times        — Show idle time per user"
    echo "  3)  Login History          — Display recent login attempts"
    echo "  4)  Suspicious Activity    — Alert on unusual logins"
    echo "  5)  Active User Count      — Total number of active users"
    echo "  6)  Full Summary           — All user monitoring info"
    echo ""
    echo "  0)  Back to Main Menu"
    echo ""
}

# ============================================================================
# Disk Cleanup Submenu
# ============================================================================

show_cleanup_menu() {
    clear
    cat << 'EOF'
╔════════════════════════════════════════════════════════════════════════════╗
║                         DISK CLEANUP & ANALYSIS                            ║
╚════════════════════════════════════════════════════════════════════════════╝

EOF

    echo "SELECT AN ACTION:"
    echo ""
    echo "  1)  Disk Summary           — Show all mounted filesystems"
    echo "  2)  Analyze Disk Usage     — Top directories by size"
    echo "  3)  Find Large Files       — Search for files > 100MB"
    echo "  4)  Find Duplicates        — Locate duplicate files by hash"
    echo "  5)  Analyze Temp Dirs      — Check temporary directory sizes"
    echo "  6)  Clean Temp (preview)   — Preview temp file cleanup"
    echo "  7)  Clean Temp (execute)   — Actually clean temp files"
    echo "  8)  Recommendations        — Get cleanup suggestions"
    echo ""
    echo "  0)  Back to Main Menu"
    echo ""
}

# ============================================================================
# Backup Management Submenu
# ============================================================================

show_backup_menu() {
    clear
    cat << 'EOF'
╔════════════════════════════════════════════════════════════════════════════╗
║                         BACKUP MANAGEMENT                                  ║
╚════════════════════════════════════════════════════════════════════════════╝

EOF

    echo "SELECT AN ACTION:"
    echo ""
    echo "  1)  List Backups           — Show all existing backups"
    echo "  2)  Create Backup          — Create a new backup"
    echo "  3)  Rotate Backups         — Keep last N backups (clean old ones)"
    echo "  4)  Show Backup Contents   — List files in a backup"
    echo "  5)  Restore from Backup    — Extract backup to location"
    echo "  6)  Test Backup System     — Create test backup"
    echo ""
    echo "  0)  Back to Main Menu"
    echo ""
}

# ============================================================================
# Utility Functions
# ============================================================================

press_enter() {
    echo ""
    read -p "Press Enter to continue..."
}

run_command() {
    "$SCRIPT_DIR/shellops" "$@"
    press_enter
}

# ============================================================================
# Input Processing - Health Menu
# ============================================================================

process_health_choice() {
    local choice="$1"
    
    case "$choice" in
        1) run_command health quick ;;
        2) run_command health report ;;
        3) run_command health cpu ;;
        4) run_command health memory ;;
        5) run_command health disk ;;
        6) run_command health network ;;
        7) run_command health uptime ;;
        8) run_command health updates ;;
        0) return 0 ;;
        *) log_error "Invalid choice: $choice" && press_enter ;;
    esac
}

# ============================================================================
# Input Processing - Monitor Menu
# ============================================================================

process_monitor_choice() {
    local choice="$1"
    
    case "$choice" in
        1) run_command monitor users ;;
        2) run_command monitor idle ;;
        3) run_command monitor history ;;
        4) run_command monitor alerts ;;
        5) run_command monitor count ;;
        6) run_command monitor summary ;;
        0) return 0 ;;
        *) log_error "Invalid choice: $choice" && press_enter ;;
    esac
}

# ============================================================================
# Input Processing - Cleanup Menu
# ============================================================================

process_cleanup_choice() {
    local choice="$1"
    
    case "$choice" in
        1) run_command cleanup disk-summary ;;
        2) run_command cleanup analyze ;;
        3) run_command cleanup find-large ;;
        4) run_command cleanup duplicates ;;
        5) run_command cleanup temp-dirs ;;
        6) run_command cleanup clean-temp --dry-run ;;
        7) run_command cleanup clean-temp --execute ;;
        8) run_command cleanup recommendations ;;
        0) return 0 ;;
        *) log_error "Invalid choice: $choice" && press_enter ;;
    esac
}

# ============================================================================
# Input Processing - Backup Menu
# ============================================================================

process_backup_choice() {
    local choice="$1"
    
    case "$choice" in
        1) run_command backup list ;;
        2) run_command backup create ;;
        3) run_command backup rotate ;;
        4) run_command backup manifest ;;
        5) run_command backup restore ;;
        6) run_command backup test ;;
        0) return 0 ;;
        *) log_error "Invalid choice: $choice" && press_enter ;;
    esac
}

# ============================================================================
# Health Menu Loop
# ============================================================================

health_menu_loop() {
    while true; do
        show_health_menu
        read -p "Enter your choice (0-8): " choice
        
        if [[ "$choice" == "0" ]]; then
            break
        fi
        
        process_health_choice "$choice"
    done
}

# ============================================================================
# Monitor Menu Loop
# ============================================================================

monitor_menu_loop() {
    while true; do
        show_monitor_menu
        read -p "Enter your choice (0-6): " choice
        
        if [[ "$choice" == "0" ]]; then
            break
        fi
        
        process_monitor_choice "$choice"
    done
}

# ============================================================================
# Cleanup Menu Loop
# ============================================================================

cleanup_menu_loop() {
    while true; do
        show_cleanup_menu
        read -p "Enter your choice (0-8): " choice
        
        if [[ "$choice" == "0" ]]; then
            break
        fi
        
        process_cleanup_choice "$choice"
    done
}

# ============================================================================
# Backup Menu Loop
# ============================================================================

backup_menu_loop() {
    while true; do
        show_backup_menu
        read -p "Enter your choice (0-6): " choice
        
        if [[ "$choice" == "0" ]]; then
            break
        fi
        
        process_backup_choice "$choice"
    done
}

# ============================================================================
# Main Menu Loop
# ============================================================================

main_menu_loop() {
    while true; do
        show_main_menu
        read -p "Enter your choice (0-8): " choice
        
        case "$choice" in
            1) health_menu_loop ;;
            2) monitor_menu_loop ;;
            3) cleanup_menu_loop ;;
            4) backup_menu_loop ;;
            5) 
                clear
                "$SCRIPT_DIR/setup_wizard.sh"
                press_enter
                ;;
            6)
                clear
                echo "Generating full system report..."
                echo ""
                run_command health report
                echo ""
                run_command monitor summary
                echo ""
                run_command cleanup disk-summary
                press_enter
                ;;
            7)
                clear
                run_command help
                press_enter
                ;;
            8)
                clear
                cat << 'EOF'
╔════════════════════════════════════════════════════════════════════════════╗
║                                                                            ║
║                    ShellOps — Educational Toolkit                          ║
║              Linux System Administration & Monitoring Suite                ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝

VERSION: 1.0.0

FEATURES:
  • Health Monitoring     — Real-time CPU, Memory, Disk, Network metrics
  • User Monitoring       — Track active users, login history, alerts
  • Disk Cleanup          — Find large files, duplicates, optimize storage
  • Backup Management     — Create, rotate, and restore backups

PLATFORMS:
  ✓ Linux (Bash)
  ✓ macOS (Bash - planned adaptations)
  ✓ Windows (PowerShell)

AUTHOR: joy-mamun
REPOSITORY: https://github.com/joy-mamun/shellops
LICENSE: Educational

This toolkit helps system administrators monitor, maintain, and optimize
their systems through an easy-to-use interactive interface.

Type 'shellops help' for command-line documentation.

EOF
                press_enter
                ;;
            0)
                clear
                echo ""
                echo "Thank you for using ShellOps!"
                echo ""
                exit 0
                ;;
            *)
                log_error "Invalid choice: $choice"
                press_enter
                ;;
        esac
    done
}

# ============================================================================
# Main Entry Point
# ============================================================================

main() {
    main_menu_loop
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

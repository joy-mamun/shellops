# interactive_menu.ps1 — Interactive menu system for ShellOps (Windows)
# Allows users to select commands by entering numbers at a prompt

param(
    [string]$Command = ""
)

# Script configuration
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$Version = "1.0.0"

# ============================================================================
# Helper Functions
# ============================================================================

function Show-MainMenu {
    Clear-Host
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                                            ║" -ForegroundColor Cyan
    Write-Host "║                  ShellOps — Interactive Menu System                        ║" -ForegroundColor Cyan
    Write-Host "║          Educational Windows System Administration Toolkit                ║" -ForegroundColor Cyan
    Write-Host "║                                                                            ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "MAIN MENU — Select an option:" -ForegroundColor Green
    Write-Host ""
    Write-Host "  MODULE MANAGEMENT:" -ForegroundColor Yellow
    Write-Host "    1)  Health Check       — Monitor CPU, Memory, Disk, Network"
    Write-Host "    2)  User Monitoring    — Track active users and login history"
    Write-Host "    3)  Disk Cleanup       — Find large files, analyze usage"
    Write-Host "    4)  Backup Management  — Create and manage backups"
    Write-Host ""
    Write-Host "  UTILITIES:" -ForegroundColor Yellow
    Write-Host "    5)  Configuration      — Configure ShellOps settings"
    Write-Host "    6)  System Report      — Full system analysis"
    Write-Host "    7)  Help & Information — Show all available commands"
    Write-Host "    8)  About ShellOps     — Version and project info"
    Write-Host ""
    Write-Host "  ACTIONS:" -ForegroundColor Yellow
    Write-Host "    0)  Exit               — Quit ShellOps"
    Write-Host ""
}

function Show-HealthMenu {
    Clear-Host
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                         HEALTH MONITORING                                  ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "SELECT AN ACTION:" -ForegroundColor Green
    Write-Host ""
    Write-Host "  1)  Quick Health Check     — CPU | Memory | Disk (one-liner)"
    Write-Host "  2)  Full Health Report     — Detailed metrics with alerts"
    Write-Host "  3)  CPU Usage              — Current CPU percentage"
    Write-Host "  4)  Memory Usage           — Current memory percentage"
    Write-Host "  5)  Disk Usage             — All drive usage"
    Write-Host "  6)  Network Connectivity   — Test network connectivity"
    Write-Host "  7)  System Uptime          — How long system has been running"
    Write-Host "  8)  Windows Updates        — Check available updates"
    Write-Host ""
    Write-Host "  0)  Back to Main Menu"
    Write-Host ""
}

function Show-MonitorMenu {
    Clear-Host
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                         USER MONITORING                                    ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "SELECT AN ACTION:" -ForegroundColor Green
    Write-Host ""
    Write-Host "  1)  Active Users           — List all currently logged-in users"
    Write-Host "  2)  User Idle Times        — Show idle time per user"
    Write-Host "  3)  Login History          — Display recent login attempts"
    Write-Host "  4)  Suspicious Activity    — Alert on unusual logins"
    Write-Host "  5)  Active User Count      — Total number of active users"
    Write-Host "  6)  Full Summary           — All user monitoring info"
    Write-Host ""
    Write-Host "  0)  Back to Main Menu"
    Write-Host ""
}

function Show-CleanupMenu {
    Clear-Host
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                         DISK CLEANUP & ANALYSIS                            ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "SELECT AN ACTION:" -ForegroundColor Green
    Write-Host ""
    Write-Host "  1)  Disk Summary           — Show all mounted drives"
    Write-Host "  2)  Analyze Disk Usage     — Top directories by size"
    Write-Host "  3)  Find Large Files       — Search for files > 100MB"
    Write-Host "  4)  Find Duplicates        — Locate duplicate files by hash"
    Write-Host "  5)  Analyze Temp Dirs      — Check temporary directory sizes"
    Write-Host "  6)  Clean Temp (preview)   — Preview temp file cleanup"
    Write-Host "  7)  Clean Temp (execute)   — Actually clean temp files"
    Write-Host "  8)  Recommendations        — Get cleanup suggestions"
    Write-Host ""
    Write-Host "  0)  Back to Main Menu"
    Write-Host ""
}

function Show-BackupMenu {
    Clear-Host
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                         BACKUP MANAGEMENT                                  ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "SELECT AN ACTION:" -ForegroundColor Green
    Write-Host ""
    Write-Host "  1)  List Backups           — Show all existing backups"
    Write-Host "  2)  Create Backup          — Create a new backup"
    Write-Host "  3)  Rotate Backups         — Keep last N backups (clean old ones)"
    Write-Host "  4)  Show Backup Contents   — List files in a backup"
    Write-Host "  5)  Restore from Backup    — Extract backup to location"
    Write-Host "  6)  Test Backup System     — Create test backup"
    Write-Host ""
    Write-Host "  0)  Back to Main Menu"
    Write-Host ""
}

function Press-AnyKey {
    Write-Host ""
    Read-Host "Press Enter to continue"
}

function Run-Command {
    param([string[]]$Args)
    & "$SCRIPT_DIR\shellops.ps1" @Args
    Press-AnyKey
}

function Process-HealthChoice {
    param([string]$Choice)
    
    switch ($Choice) {
        "1" { Run-Command "health", "quick" }
        "2" { Run-Command "health", "report" }
        "3" { Run-Command "health", "cpu" }
        "4" { Run-Command "health", "memory" }
        "5" { Run-Command "health", "disk" }
        "6" { Run-Command "health", "network" }
        "7" { Run-Command "health", "uptime" }
        "8" { Run-Command "health", "updates" }
        "0" { return }
        default { Write-Host "Invalid choice: $Choice" -ForegroundColor Red; Press-AnyKey }
    }
}

function Process-MonitorChoice {
    param([string]$Choice)
    
    switch ($Choice) {
        "1" { Run-Command "monitor", "users" }
        "2" { Run-Command "monitor", "idle" }
        "3" { Run-Command "monitor", "history" }
        "4" { Run-Command "monitor", "suspicious" }
        "5" { Run-Command "monitor", "count" }
        "6" { Run-Command "monitor", "summary" }
        "0" { return }
        default { Write-Host "Invalid choice: $Choice" -ForegroundColor Red; Press-AnyKey }
    }
}

function Process-CleanupChoice {
    param([string]$Choice)
    
    switch ($Choice) {
        "1" { Run-Command "cleanup", "disk-summary" }
        "2" { Run-Command "cleanup", "analyze" }
        "3" { Run-Command "cleanup", "find-large" }
        "4" { Run-Command "cleanup", "duplicates" }
        "5" { Run-Command "cleanup", "temp-dirs" }
        "6" { Run-Command "cleanup", "clean-temp", "--dry-run" }
        "7" { Run-Command "cleanup", "clean-temp", "--force" }
        "8" { Run-Command "cleanup", "recommendations" }
        "0" { return }
        default { Write-Host "Invalid choice: $Choice" -ForegroundColor Red; Press-AnyKey }
    }
}

function Process-BackupChoice {
    param([string]$Choice)
    
    switch ($Choice) {
        "1" { Run-Command "backup", "list" }
        "2" { Run-Command "backup", "create" }
        "3" { Run-Command "backup", "rotate" }
        "4" { Run-Command "backup", "manifest" }
        "5" { Run-Command "backup", "restore" }
        "6" { Run-Command "backup", "test" }
        "0" { return }
        default { Write-Host "Invalid choice: $Choice" -ForegroundColor Red; Press-AnyKey }
    }
}

# ============================================================================
# Menu Loops
# ============================================================================

function Health-MenuLoop {
    while ($true) {
        Show-HealthMenu
        $choice = Read-Host "Enter your choice (0-8)"
        
        if ($choice -eq "0") {
            break
        }
        
        Process-HealthChoice $choice
    }
}

function Monitor-MenuLoop {
    while ($true) {
        Show-MonitorMenu
        $choice = Read-Host "Enter your choice (0-6)"
        
        if ($choice -eq "0") {
            break
        }
        
        Process-MonitorChoice $choice
    }
}

function Cleanup-MenuLoop {
    while ($true) {
        Show-CleanupMenu
        $choice = Read-Host "Enter your choice (0-8)"
        
        if ($choice -eq "0") {
            break
        }
        
        Process-CleanupChoice $choice
    }
}

function Backup-MenuLoop {
    while ($true) {
        Show-BackupMenu
        $choice = Read-Host "Enter your choice (0-6)"
        
        if ($choice -eq "0") {
            break
        }
        
        Process-BackupChoice $choice
    }
}

# ============================================================================
# Main Menu Loop
# ============================================================================

function Main-MenuLoop {
    while ($true) {
        Show-MainMenu
        $choice = Read-Host "Enter your choice (0-8)"
        
        switch ($choice) {
            "1" { Health-MenuLoop }
            "2" { Monitor-MenuLoop }
            "3" { Cleanup-MenuLoop }
            "4" { Backup-MenuLoop }
            "5" {
                Clear-Host
                Write-Host "ShellOps Configuration"
                Write-Host "Edit config directly or use: .\shellops.ps1 init"
                Press-AnyKey
            }
            "6" {
                Clear-Host
                Write-Host "Generating full system report..."
                Write-Host ""
                Run-Command "health", "report"
                Write-Host ""
                Run-Command "monitor", "summary"
                Write-Host ""
                Run-Command "cleanup", "disk-summary"
                Press-AnyKey
            }
            "7" {
                Clear-Host
                Run-Command "help"
                Press-AnyKey
            }
            "8" {
                Clear-Host
                Write-Host ""
                Write-Host "╔════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
                Write-Host "║                                                                            ║" -ForegroundColor Cyan
                Write-Host "║                    ShellOps — Educational Toolkit                          ║" -ForegroundColor Cyan
                Write-Host "║              Windows System Administration & Monitoring Suite              ║" -ForegroundColor Cyan
                Write-Host "║                                                                            ║" -ForegroundColor Cyan
                Write-Host "╚════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
                Write-Host ""
                Write-Host "VERSION: $Version"
                Write-Host ""
                Write-Host "FEATURES:"
                Write-Host "  • Health Monitoring     — Real-time CPU, Memory, Disk, Network metrics"
                Write-Host "  • User Monitoring       — Track active users, login history, alerts"
                Write-Host "  • Disk Cleanup          — Find large files, duplicates, optimize storage"
                Write-Host "  • Backup Management     — Create, rotate, and restore backups"
                Write-Host ""
                Write-Host "PLATFORMS:"
                Write-Host "  ✓ Linux (Bash)"
                Write-Host "  ✓ macOS (Bash - planned adaptations)"
                Write-Host "  ✓ Windows (PowerShell)"
                Write-Host ""
                Write-Host "AUTHOR: joy-mamun"
                Write-Host "REPOSITORY: https://github.com/joy-mamun/shellops"
                Write-Host "LICENSE: Educational"
                Write-Host ""
                Write-Host "This toolkit helps system administrators monitor, maintain, and optimize"
                Write-Host "their systems through an easy-to-use interactive interface."
                Write-Host ""
                Press-AnyKey
            }
            "0" {
                Clear-Host
                Write-Host ""
                Write-Host "Thank you for using ShellOps!" -ForegroundColor Green
                Write-Host ""
                exit 0
            }
            default {
                Write-Host "Invalid choice: $choice" -ForegroundColor Red
                Press-AnyKey
            }
        }
    }
}

# ============================================================================
# Main Entry Point
# ============================================================================

Main-MenuLoop

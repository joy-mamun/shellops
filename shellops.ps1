# shellops.ps1 — Main entry point for ShellOps (PowerShell Windows version)
# System administration toolkit for Windows

param(
    [string]$Command = "",
    [string[]]$Arguments = @()
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = "Continue"

# ============================================================================
# Initialize Script
# ============================================================================

$script:Version = "1.0.0"
$script:ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:LibPath = Join-Path $script:ScriptPath "lib-ps"

# Load modules
$commonModule = Join-Path $script:LibPath "Common.ps1"
$configModule = Join-Path $script:LibPath "Config.ps1"

if (-not (Test-Path $commonModule)) {
    Write-Error "Common module not found: $commonModule"
    exit 1
}

Import-Module $commonModule -Force

if (Test-Path $configModule) {
    Import-Module $configModule -Force
}

# ============================================================================
# Help System
# ============================================================================

function Show-MainHelp {
@"
╔═══════════════════════════════════════════════════════════════╗
║                      ShellOps - Windows Edition              ║
║         Shell-based System Administration Toolkit             ║
║                      Version $script:Version                            ║
╚═══════════════════════════════════════════════════════════════╝

USAGE:
  shellops.ps1 [COMMAND] [ACTION] [OPTIONS]

COMMANDS:
  init              Initialize or reconfigure ShellOps
  setup             Run interactive setup wizard
  monitor           User activity monitoring
  cleanup           Disk analysis and cleanup utilities
  backup            Backup creation and management
  health            System health monitoring
  help              Show help information
  version           Display version information

OPTIONS:
  --help            Show detailed help for a command
  --dry-run         Preview changes without executing
  --force           Execute without confirmation prompts
  --quiet           Suppress verbose output
  --debug           Enable debug mode

EXAMPLES:
  # Check system health
  .\shellops.ps1 health quick

  # List user sessions
  .\shellops.ps1 monitor users

  # Analyze disk usage
  .\shellops.ps1 cleanup analyze

  # Create a backup
  .\shellops.ps1 backup create C:\MyData

  # Show help for specific command
  .\shellops.ps1 help monitor

For more information, see the documentation in the docs/ folder.
"@
}

function Show-CommandHelp {
    param([string]$CommandName)
    
    switch ($CommandName.ToLower()) {
        "monitor" {
            @"
MONITOR - User activity monitoring

USAGE:
  shellops.ps1 monitor [ACTION]

ACTIONS:
  users               List active user sessions
  idle                Show user idle times
  history             Display login history
  suspicious          Show suspicious activity alerts
  idle-threshold      Show idle users above threshold
  count               Get count of active users
  all                 Show all user monitoring information
  summary             Show user activity summary

OPTIONS:
  --threshold SECONDS Set idle time threshold (default: 300)

EXAMPLES:
  .\shellops.ps1 monitor users
  .\shellops.ps1 monitor idle --threshold 600
  .\shellops.ps1 monitor summary
"@
        }
        "cleanup" {
            @"
CLEANUP - Disk analysis and cleanup

USAGE:
  shellops.ps1 cleanup [ACTION] [OPTIONS]

ACTIONS:
  analyze             Analyze disk usage
  find-large          Find large files
  duplicates          Find duplicate files
  temp-dirs           Analyze temporary directories
  clean-temp          Clean temporary files
  recommendations     Generate cleanup recommendations
  disk-summary        Show disk usage summary
  all                 Run full disk analysis

OPTIONS:
  --size SIZE_MB      Set file size threshold (default: 100)
  --dry-run           Show what would be deleted without deleting
  --force             Delete without confirmation

EXAMPLES:
  .\shellops.ps1 cleanup analyze
  .\shellops.ps1 cleanup find-large --size 500
  .\shellops.ps1 cleanup clean-temp --dry-run
"@
        }
        "backup" {
            @"
BACKUP - Backup creation and management

USAGE:
  shellops.ps1 backup [ACTION] [OPTIONS]

ACTIONS:
  create              Create a new backup
  list                List existing backups
  rotate              Remove old backups per retention policy
  manifest            Show backup contents
  restore             Restore from backup
  schedule            Schedule automated backups
  test                Test backup restoration

OPTIONS:
  --path PATH         Source directory to backup
  --retention COUNT   Number of backups to keep (default: 10)
  --compress TYPE     Compression: gzip|bzip2|xz|none
  --dry-run           Preview backup without creating

EXAMPLES:
  .\shellops.ps1 backup create --path C:\Data
  .\shellops.ps1 backup list
  .\shellops.ps1 backup restore
  .\shellops.ps1 backup schedule --compress gzip
"@
        }
        "health" {
            @"
HEALTH - System health monitoring

USAGE:
  shellops.ps1 health [ACTION]

ACTIONS:
  report              Generate comprehensive health report
  quick               Show one-line health status
  cpu                 Show CPU usage percentage
  memory              Show memory usage percentage
  disk                Show disk usage percentage (C:)
  network             Show network connectivity status
  uptime              Show system uptime
  updates             Show pending system updates
  all                 Show all health metrics

EXAMPLES:
  .\shellops.ps1 health report
  .\shellops.ps1 health quick
  .\shellops.ps1 health cpu
  .\shellops.ps1 health network
"@
        }
        default {
            Show-MainHelp
        }
    }
}

# ============================================================================
# Command Execution Functions
# ============================================================================

function Execute-Init {
    Log-Info "Initializing ShellOps..."
    Initialize-Config
    Log-Success "ShellOps initialized successfully"
}

function Execute-Setup {
    Log-Info "Running interactive setup wizard..."
    # This would load and run the setup wizard script
    Write-Host "Setup wizard not yet implemented for PowerShell"
}

function Execute-Monitor {
    param([string[]]$Args)
    
    $healthModule = Join-Path $script:LibPath "UserMonitor.ps1"
    if (Test-Path $healthModule) {
        Import-Module $healthModule -Force
        $action = if ($Args.Count -gt 0) { $Args[0] } else { "summary" }
        Invoke-UserMonitor $action $Args
    }
    else {
        Log-Error "User Monitor module not found: $healthModule"
    }
}

function Execute-Cleanup {
    param([string[]]$Args)
    
    $cleanupModule = Join-Path $script:LibPath "DiskCleanup.ps1"
    if (Test-Path $cleanupModule) {
        Import-Module $cleanupModule -Force
        $action = if ($Args.Count -gt 0) { $Args[0] } else { "analyze" }
        Invoke-DiskCleanup $action $Args
    }
    else {
        Log-Error "Disk Cleanup module not found: $cleanupModule"
    }
}

function Execute-Backup {
    param([string[]]$Args)
    
    $backupModule = Join-Path $script:LibPath "BackupSchedule.ps1"
    if (Test-Path $backupModule) {
        Import-Module $backupModule -Force
        $action = if ($Args.Count -gt 0) { $Args[0] } else { "list" }
        Invoke-BackupSchedule $action $Args
    }
    else {
        Log-Error "Backup Schedule module not found: $backupModule"
    }
}

function Execute-Health {
    param([string[]]$Args)
    
    $healthModule = Join-Path $script:LibPath "HealthCheck.ps1"
    if (Test-Path $healthModule) {
        Import-Module $healthModule -Force
        $action = if ($Args.Count -gt 0) { $Args[0] } else { "report" }
        Initialize-Config  # Ensure config is loaded
        Invoke-HealthCheck $action
    }
    else {
        Log-Error "Health Check module not found: $healthModule"
    }
}

# ============================================================================
# Main Command Router
# ============================================================================

function Invoke-ShellOps {
    param(
        [string]$Command,
        [string[]]$Arguments
    )
    
    # Handle no command - offer interactive menu
    if ([string]::IsNullOrEmpty($Command)) {
        Write-Host ""
        Write-Host "No command specified. Choose an option:" -ForegroundColor Cyan
        Write-Host "  1) Launch Interactive Menu"
        Write-Host "  2) Show Help"
        Write-Host ""
        
        $menuChoice = Read-Host "Enter choice (1-2)"
        
        switch ($menuChoice) {
            "1" {
                # Launch interactive menu
                & (Join-Path $script:ScriptPath "interactive_menu.ps1")
                return
            }
            "2" {
                Show-MainHelp
                return
            }
            default {
                Log-Error "Invalid choice"
                Show-MainHelp
                exit 1
            }
        }
    }
    
    switch ($Command.ToLower()) {
        "init" { Execute-Init }
        "setup" { Execute-Setup }
        "monitor" { Execute-Monitor $Arguments }
        "cleanup" { Execute-Cleanup $Arguments }
        "backup" { Execute-Backup $Arguments }
        "health" { Execute-Health $Arguments }
        "help" {
            if ($Arguments.Count -gt 0) {
                Show-CommandHelp $Arguments[0]
            }
            else {
                Show-MainHelp
            }
        }
        "version" {
            Log-Success "ShellOps Version $script:Version (Windows Edition)"
        }
        "--help" {
            Show-MainHelp
        }
        "--version" {
            Log-Success "ShellOps Version $script:Version (Windows Edition)"
        }
        default {
            Log-Error "Unknown command: $Command"
            Show-MainHelp
            exit 1
        }
    }
}

# ============================================================================
# Entry Point
# ============================================================================

try {
    Invoke-ShellOps $Command $Arguments
}
catch {
    Log-Error "An error occurred: $_"
    exit 1
}

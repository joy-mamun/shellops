# lib-ps/Config.ps1 — Configuration management for ShellOps (PowerShell)
# Handles loading, validating, and exporting configuration

using module .\Common.ps1

# ============================================================================
# Configuration Variables (Defaults)
# ============================================================================

$script:Config = @{
    # Feature Enablement
    USER_MONITOR_ENABLED = $true
    DISK_CLEANUP_ENABLED = $true
    BACKUP_SCHEDULE_ENABLED = $true
    HEALTH_CHECK_ENABLED = $true
    
    # User Monitoring
    USER_MONITOR_IDLE_THRESHOLD = 300  # seconds
    USER_MONITOR_ALERT_ROOT_LOGINS = $true
    
    # Disk Cleanup
    DISK_CLEANUP_SIZE_THRESHOLD = 104857600  # 100 MB in bytes
    DISK_CLEANUP_DRY_RUN = $true
    DISK_CLEANUP_TEMP_DIRS = @("$env:TEMP", "$env:LOCALAPPDATA\Temp", "C:\Windows\Temp")
    
    # Backup Scheduling
    BACKUP_RETENTION_COUNT = 10
    BACKUP_COMPRESSION = "gzip"  # gzip, bzip2, xz, none
    BACKUP_EXCLUDE_PATTERNS = @(".git", ".gitignore", "node_modules", "__pycache__")
    
    # Health Check
    HEALTH_CHECK_CPU_THRESHOLD = 80  # percent
    HEALTH_CHECK_MEMORY_THRESHOLD = 85  # percent
    HEALTH_CHECK_DISK_THRESHOLD = 90  # percent
    
    # Logging
    LOG_LEVEL = "INFO"  # ERROR, WARN, INFO, DEBUG
    LOG_DIR = "$env:USERPROFILE\.shellops\logs"
    
    # Backup Directory
    BACKUP_DIR = ".\backups"
}

$script:CONFIG_FILE = "shellops.conf.ps1"
$script:CONFIG_LOADED = $false

# ============================================================================
# Configuration Loading & Management
# ============================================================================

function Load-ConfigFile {
    param([string]$FilePath)
    
    if (-not (Test-Path $FilePath)) {
        Log-Warn "Configuration file not found: $FilePath"
        return $false
    }
    
    try {
        $configContent = Get-Content -Path $FilePath -Raw
        # Validate syntax by executing in isolated scope
        $testScript = [scriptblock]::Create($configContent)
        
        # Load configuration
        & $testScript
        Log-Success "Configuration loaded from: $FilePath"
        return $true
    }
    catch {
        Log-Error "Failed to load configuration file: $_"
        return $false
    }
}

function Initialize-Config {
    Log-Info "Initializing configuration..."
    
    # Try to load config file if it exists
    if (Test-Path $CONFIG_FILE) {
        if (-not (Load-ConfigFile $CONFIG_FILE)) {
            Log-Info "Using default configuration values"
        }
        else {
            $script:CONFIG_LOADED = $true
        }
    }
    else {
        Log-Info "Using default configuration values"
    }
    
    # Validate configuration
    if (-not (Validate-Config)) {
        Invoke-Die "Configuration validation failed"
    }
    
    # Initialize logging
    Initialize-Logging
    
    # Initialize backup directory
    Initialize-BackupDir
    
    Log-Success "Configuration initialization complete"
    return $true
}

function Validate-Config {
    # Validate feature flags (boolean)
    foreach ($featureFlag in @("USER_MONITOR_ENABLED", "DISK_CLEANUP_ENABLED", "BACKUP_SCHEDULE_ENABLED", "HEALTH_CHECK_ENABLED")) {
        if ($script:Config[$featureFlag] -isnot [bool]) {
            Log-Warn "$featureFlag is not boolean, converting..."
            $script:Config[$featureFlag] = $true
        }
    }
    
    # Validate numeric ranges
    if (-not (Test-NumberInRange $script:Config['USER_MONITOR_IDLE_THRESHOLD'] 60 86400)) {
        Log-Warn "USER_MONITOR_IDLE_THRESHOLD out of range, resetting to default (300)"
        $script:Config['USER_MONITOR_IDLE_THRESHOLD'] = 300
    }
    
    if (-not (Test-NumberInRange $script:Config['HEALTH_CHECK_CPU_THRESHOLD'] 1 100)) {
        Log-Warn "HEALTH_CHECK_CPU_THRESHOLD out of range, resetting to default (80)"
        $script:Config['HEALTH_CHECK_CPU_THRESHOLD'] = 80
    }
    
    if (-not (Test-NumberInRange $script:Config['HEALTH_CHECK_MEMORY_THRESHOLD'] 1 100)) {
        Log-Warn "HEALTH_CHECK_MEMORY_THRESHOLD out of range, resetting to default (85)"
        $script:Config['HEALTH_CHECK_MEMORY_THRESHOLD'] = 85
    }
    
    if (-not (Test-NumberInRange $script:Config['HEALTH_CHECK_DISK_THRESHOLD'] 1 100)) {
        Log-Warn "HEALTH_CHECK_DISK_THRESHOLD out of range, resetting to default (90)"
        $script:Config['HEALTH_CHECK_DISK_THRESHOLD'] = 90
    }
    
    if (-not (Test-NumberInRange $script:Config['BACKUP_RETENTION_COUNT'] 1 100)) {
        Log-Warn "BACKUP_RETENTION_COUNT out of range, resetting to default (10)"
        $script:Config['BACKUP_RETENTION_COUNT'] = 10
    }
    
    Log-Info "Configuration validation successful"
    return $true
}

function Initialize-Logging {
    $logDir = $script:Config['LOG_DIR']
    
    if (-not (Test-Path $logDir)) {
        try {
            Ensure-Directory $logDir
        }
        catch {
            Log-Warn "Could not create log directory: $logDir"
            $logDir = [System.IO.Path]::GetTempPath() + "shellops_logs"
            Ensure-Directory $logDir
            $script:Config['LOG_DIR'] = $logDir
            Log-Warn "Using fallback log directory: $logDir"
        }
    }
    
    $logFile = Join-Path $logDir "shellops.log"
    Log-Info "Logging initialized: $logFile"
}

function Initialize-BackupDir {
    $backupDir = $script:Config['BACKUP_DIR']
    
    try {
        Ensure-Directory $backupDir
        Log-Info "Backup directory ready: $backupDir"
    }
    catch {
        Log-Error "Failed to initialize backup directory: $_"
        return $false
    }
    
    return $true
}

# ============================================================================
# Configuration Query Functions
# ============================================================================

function Get-ConfigValue {
    param([string]$Key)
    if ($script:Config.ContainsKey($Key)) {
        return $script:Config[$Key]
    }
    return $null
}

function Set-ConfigValue {
    param(
        [string]$Key,
        [object]$Value
    )
    $script:Config[$Key] = $Value
}

function Test-FeatureEnabled {
    param([string]$Feature)
    $enabledKey = "$Feature`_ENABLED"
    return $script:Config[$enabledKey] -eq $true
}

# ============================================================================
# Export functions and variables
# ============================================================================

Export-ModuleMember -Function @(
    'Load-ConfigFile', 'Initialize-Config', 'Validate-Config',
    'Initialize-Logging', 'Initialize-BackupDir',
    'Get-ConfigValue', 'Set-ConfigValue', 'Test-FeatureEnabled'
) -Variable 'Config'

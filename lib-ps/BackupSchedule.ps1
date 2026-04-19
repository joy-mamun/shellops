# lib-ps/BackupSchedule.ps1 — Backup creation and management for ShellOps (PowerShell)
# Provides tar-like backup management with retention policies

using module .\Common.ps1
using module .\Config.ps1

# ============================================================================
# Backup Management Functions
# ============================================================================

function New-BackupFile {
    param(
        [string]$SourcePath,
        [string]$BackupDir,
        [string]$CompressionMethod = "zip"
    )
    
    if (-not (Test-Path $SourcePath)) {
        Log-Error "Source path not found: $SourcePath"
        return $null
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $sourceName = Split-Path -Leaf $SourcePath
    $backupFileName = "$sourceName`_$timestamp"
    
    try {
        switch ($CompressionMethod.ToLower()) {
            "zip" {
                $backupPath = Join-Path $BackupDir "$backupFileName.zip"
                Log-Info "Creating ZIP backup: $backupPath"
                Compress-Archive -Path $SourcePath -DestinationPath $backupPath -Force
            }
            "7z" {
                # Requires 7-Zip to be installed
                $backupPath = Join-Path $BackupDir "$backupFileName.7z"
                Log-Info "Creating 7z backup: $backupPath"
                if (Test-CommandExists "7z") {
                    & 7z a $backupPath $SourcePath
                }
                else {
                    Log-Error "7z not found. Please install 7-Zip."
                    return $null
                }
            }
            "none" {
                $backupPath = Join-Path $BackupDir $backupFileName
                Log-Info "Creating uncompressed backup: $backupPath"
                Copy-Item -Path $SourcePath -Destination $backupPath -Recurse
            }
            default {
                Log-Error "Unknown compression method: $CompressionMethod"
                return $null
            }
        }
        
        if (Test-Path $backupPath) {
            $size = (Get-Item $backupPath).Length
            Log-Success "Backup created successfully: $(Format-ByteSize $size)"
            return $backupPath
        }
    }
    catch {
        Log-Error "Failed to create backup: $_"
    }
    
    return $null
}

function Get-BackupFiles {
    param([string]$BackupDir)
    
    if (-not (Test-Path $BackupDir)) {
        Log-Warn "Backup directory not found: $BackupDir"
        return @()
    }
    
    $backups = @()
    Get-ChildItem -Path $BackupDir -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -in @(".zip", ".7z", ".tar") } |
        Sort-Object LastWriteTime -Descending |
        ForEach-Object {
            $backups += @{
                Name = $_.Name
                Path = $_.FullName
                Size = $_.Length
                Created = $_.LastWriteTime
            }
        }
    
    return $backups
}

function Show-BackupList {
    param([string]$BackupDir = ".\backups")
    
    $backups = Get-BackupFiles $BackupDir
    
    if ($backups.Count -eq 0) {
        Write-Host "No backups found in $BackupDir"
        return
    }
    
    Write-Host "`nAvailable Backups:"
    Write-Host "──────────────────────────────────────────────────────────"
    Write-Host "{0,-30} {1,-12} {2}" -f "Filename", "Size", "Created"
    Write-Host "──────────────────────────────────────────────────────────"
    
    foreach ($backup in $backups) {
        $size = Format-ByteSize $backup.Size
        $created = $backup.Created.ToString("yyyy-MM-dd HH:mm:ss")
        Write-Host "{0,-30} {1,-12} {2}" -f $backup.Name, $size, $created
    }
    
    Write-Host "`nTotal backups: $($backups.Count)"
}

function Invoke-BackupRotation {
    param(
        [string]$BackupDir,
        [int]$RetentionCount = 10
    )
    
    $backups = Get-BackupFiles $BackupDir
    
    if ($backups.Count -le $RetentionCount) {
        Log-Info "Backup count ($($backups.Count)) is within retention limit ($RetentionCount)"
        return
    }
    
    $toDelete = $backups | Select-Object -Skip $RetentionCount
    
    Log-Info "Removing $($toDelete.Count) old backup(s) to maintain retention count..."
    
    foreach ($backup in $toDelete) {
        try {
            Remove-Item -Path $backup.Path -Force
            Log-Info "Removed: $($backup.Name)"
        }
        catch {
            Log-Error "Failed to remove $($backup.Name): $_"
        }
    }
}

function Show-BackupManifest {
    param([string]$BackupPath)
    
    if (-not (Test-Path $BackupPath)) {
        Log-Error "Backup file not found: $BackupPath"
        return
    }
    
    try {
        $extension = [System.IO.Path]::GetExtension($BackupPath)
        
        switch ($extension.ToLower()) {
            ".zip" {
                Write-Host "`nContents of $BackupPath`:"
                Write-Host "─────────────────────────────────────"
                Add-Type -AssemblyName System.IO.Compression.FileSystem
                $zip = [System.IO.Compression.ZipFile]::OpenRead($BackupPath)
                foreach ($entry in $zip.Entries) {
                    Write-Host $entry.FullName
                }
                $zip.Dispose()
            }
            ".7z" {
                Write-Host "`nContents of $BackupPath`:"
                Write-Host "─────────────────────────────────────"
                & 7z l $BackupPath
            }
            default {
                Log-Error "Unknown backup format: $extension"
            }
        }
    }
    catch {
        Log-Error "Failed to read backup manifest: $_"
    }
}

function Restore-Backup {
    param(
        [string]$BackupPath,
        [string]$DestinationPath = "."
    )
    
    if (-not (Test-Path $BackupPath)) {
        Log-Error "Backup file not found: $BackupPath"
        return
    }
    
    if (-not (Confirm-Action "Restore from backup: $(Split-Path -Leaf $BackupPath)?")) {
        Log-Info "Restore cancelled"
        return
    }
    
    try {
        $extension = [System.IO.Path]::GetExtension($BackupPath)
        
        switch ($extension.ToLower()) {
            ".zip" {
                Log-Info "Extracting ZIP backup..."
                Expand-Archive -Path $BackupPath -DestinationPath $DestinationPath -Force
            }
            ".7z" {
                Log-Info "Extracting 7z backup..."
                & 7z x $BackupPath -o$DestinationPath
            }
            default {
                Log-Error "Unknown backup format: $extension"
                return
            }
        }
        
        Log-Success "Backup restored successfully to: $DestinationPath"
    }
    catch {
        Log-Error "Failed to restore backup: $_"
    }
}

function New-ScheduledBackup {
    param(
        [string]$BackupPath,
        [string]$ScheduleTime = "02:00:00",  # 2 AM by default
        [string]$CompressionMethod = "zip"
    )
    
    try {
        $taskName = "ShellOps_Backup"
        
        # Check if task already exists
        $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        
        if ($null -ne $existingTask) {
            Log-Warn "Scheduled task '$taskName' already exists"
            return
        }
        
        # Create PowerShell script to run
        $ps1Path = Join-Path $BackupPath "run_backup.ps1"
        
        $scriptContent = @"
# Auto-generated backup script
`$backupDir = "$BackupPath"
`$sourceDir = Read-Host "Enter source directory to backup"
`$date = Get-Date -Format "yyyyMMdd"
`$backupFile = Join-Path `$backupDir "backup_`$date.zip"

if (Test-Path `$sourceDir) {
    Compress-Archive -Path `$sourceDir -DestinationPath `$backupFile -Force
    Write-Host "Backup created: `$backupFile"
}
"@
        
        Set-Content -Path $ps1Path -Value $scriptContent
        
        Log-Info "Backup schedule script created: $ps1Path"
        Log-Info "To complete scheduling, run scheduled task manually or use Windows Task Scheduler"
    }
    catch {
        Log-Error "Failed to create scheduled backup: $_"
    }
}

# ============================================================================
# Backup Router Main Function
# ============================================================================

function Invoke-BackupSchedule {
    param(
        [string]$Action = "list",
        [string[]]$Arguments = @()
    )
    
    $backupDir = Get-ConfigValue 'BACKUP_DIR'
    if ([string]::IsNullOrEmpty($backupDir)) {
        $backupDir = ".\backups"
    }
    
    switch ($Action.ToLower()) {
        "create" {
            if ($Arguments.Count -gt 0) {
                $sourcePath = $Arguments[0]
                $compression = if ($Arguments.Count -gt 1) { $Arguments[1] } else { "zip" }
                New-BackupFile -SourcePath $sourcePath -BackupDir $backupDir -CompressionMethod $compression
            }
            else {
                $sourcePath = Request-Input "Enter source path to backup"
                New-BackupFile -SourcePath $sourcePath -BackupDir $backupDir -CompressionMethod "zip"
            }
        }
        "list" { Show-BackupList $backupDir }
        "rotate" {
            $retention = Get-ConfigValue 'BACKUP_RETENTION_COUNT'
            Invoke-BackupRotation $backupDir $retention
        }
        "manifest" {
            if ($Arguments.Count -gt 0) {
                Show-BackupManifest $Arguments[0]
            }
            else {
                $backups = Get-BackupFiles $backupDir
                if ($backups.Count -gt 0) {
                    $backupFile = Read-Host "Enter backup filename"
                    $fullPath = Join-Path $backupDir $backupFile
                    Show-BackupManifest $fullPath
                }
            }
        }
        "restore" {
            if ($Arguments.Count -gt 0) {
                Restore-Backup $Arguments[0]
            }
            else {
                Show-BackupList $backupDir
                $backupFile = Read-Host "Enter backup filename to restore"
                $fullPath = Join-Path $backupDir $backupFile
                Restore-Backup $fullPath
            }
        }
        "schedule" {
            New-ScheduledBackup $backupDir
        }
        "test" {
            Write-Host "Testing backup functionality..."
            $testSource = ".\test_backup_source"
            if (-not (Test-Path $testSource)) {
                New-Item -ItemType Directory -Path $testSource | Out-Null
                New-Item -ItemType File -Path "$testSource\test.txt" -Value "Test backup content" | Out-Null
            }
            
            $backup = New-BackupFile -SourcePath $testSource -BackupDir $backupDir -CompressionMethod "zip"
            if ($null -ne $backup) {
                Log-Success "✓ Backup test successful"
            }
        }
        default {
            Log-Error "Unknown backup action: $Action"
            Write-Host "Usage: backup {create|list|rotate|manifest|restore|schedule|test}"
        }
    }
}

function Format-ByteSize {
    param([long]$Bytes)
    if ($Bytes -eq 0) { return "0 B" }
    $units = @("B", "KB", "MB", "GB", "TB")
    $unitIndex = 0
    $size = [double]$Bytes
    while ($size -ge 1024 -and $unitIndex -lt $units.Count - 1) {
        $size /= 1024
        $unitIndex++
    }
    return "{0:F1} {1}" -f $size, $units[$unitIndex]
}

# ============================================================================
# Export functions
# ============================================================================

Export-ModuleMember -Function @(
    'New-BackupFile', 'Get-BackupFiles', 'Show-BackupList',
    'Invoke-BackupRotation', 'Show-BackupManifest', 'Restore-Backup',
    'New-ScheduledBackup', 'Invoke-BackupSchedule', 'Format-ByteSize'
)

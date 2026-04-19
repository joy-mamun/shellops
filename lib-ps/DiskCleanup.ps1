# lib-ps/DiskCleanup.ps1 — Disk analysis and cleanup utilities for ShellOps (PowerShell)
# Provides tools for finding large files, duplicates, and temp file cleanup

using module .\Common.ps1
using module .\Config.ps1

# ============================================================================
# Disk Analysis Functions
# ============================================================================

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

function Find-LargeFiles {
    param(
        [string]$RootPath = "C:\",
        [long]$SizeThreshold = 104857600  # 100 MB default
    )
    
    try {
        Write-Host "Searching for files larger than $(Format-ByteSize $SizeThreshold)..."
        
        $largeFiles = Get-ChildItem -Path $RootPath -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.Length -ge $SizeThreshold } |
            Sort-Object Length -Descending |
            Select-Object -First 50
        
        if ($largeFiles.Count -eq 0) {
            Write-Host "No files found larger than $(Format-ByteSize $SizeThreshold)."
            return
        }
        
        Write-Host "`nLarge Files (Top 50):"
        Write-Host "──────────────────────────────────────────────────────"
        Write-Host "{0,-8} {1}" -f "Size", "Path"
        Write-Host "──────────────────────────────────────────────────────"
        
        foreach ($file in $largeFiles) {
            $size = Format-ByteSize $file.Length
            Write-Host "{0,-8} {1}" -f $size, $file.FullName
        }
    }
    catch {
        Log-Error "Error searching for large files: $_"
    }
}

function Analyze-DiskUsage {
    param(
        [string]$RootPath = "C:\",
        [int]$TopCount = 10
    )
    
    try {
        Write-Host "Analyzing disk usage in $RootPath..."
        
        $folderSizes = Get-ChildItem -Path $RootPath -Directory -ErrorAction SilentlyContinue |
            ForEach-Object {
                $folderSize = (Get-ChildItem $_.FullName -Recurse -ErrorAction SilentlyContinue | 
                    Measure-Object -Property Length -Sum).Sum
                [PSCustomObject]@{
                    Name = $_.Name
                    Path = $_.FullName
                    Size = $folderSize
                }
            } |
            Sort-Object Size -Descending |
            Select-Object -First $TopCount
        
        Write-Host "`nTop $TopCount Folders by Size:"
        Write-Host "──────────────────────────────────────────────────────"
        Write-Host "{0,-8} {1}" -f "Size", "Folder"
        Write-Host "──────────────────────────────────────────────────────"
        
        foreach ($folder in $folderSizes) {
            if ($null -ne $folder.Size) {
                $size = Format-ByteSize $folder.Size
                Write-Host "{0,-8} {1}" -f $size, $folder.Path
            }
        }
    }
    catch {
        Log-Error "Error analyzing disk usage: $_"
    }
}

function Find-DuplicateFiles {
    param([string]$RootPath = "C:\Users")
    
    try {
        Write-Host "Scanning for duplicate files in $RootPath..."
        
        $filesByHash = @{}
        $duplicates = @()
        
        Get-ChildItem -Path $RootPath -File -Recurse -ErrorAction SilentlyContinue |
            ForEach-Object {
                try {
                    $hash = (Get-FileHash $_.FullName -Algorithm MD5 -ErrorAction SilentlyContinue).Hash
                    if ($null -ne $hash) {
                        if ($filesByHash.ContainsKey($hash)) {
                            $duplicates += @($_.FullName)
                            $filesByHash[$hash] += @($_.FullName)
                        }
                        else {
                            $filesByHash[$hash] = @($_.FullName)
                        }
                    }
                }
                catch { }
            }
        
        if ($duplicates.Count -eq 0) {
            Write-Host "No duplicate files found."
            return
        }
        
        Write-Host "`nDuplicate Files Found: $($duplicates.Count)"
        Write-Host "──────────────────────────────────────────────────────"
        
        $count = 0
        foreach ($hash in $filesByHash.Keys) {
            $files = $filesByHash[$hash]
            if ($files.Count -gt 1) {
                $count++
                Write-Host "`nGroup $count (Hash: $hash):"
                foreach ($file in $files) {
                    Write-Host "  - $file"
                }
            }
        }
    }
    catch {
        Log-Error "Error finding duplicates: $_"
    }
}

function Analyze-TemporaryDirectories {
    $tempDirs = @(
        $env:TEMP,
        $env:TMP,
        "C:\Windows\Temp",
        "$env:LOCALAPPDATA\Temp"
    )
    
    Write-Host "`nTemporary Directory Analysis:"
    Write-Host "──────────────────────────────────────────────────────"
    
    foreach ($tempDir in $tempDirs) {
        if (Test-Path $tempDir -PathType Container) {
            try {
                $items = Get-ChildItem -Path $tempDir -Recurse -ErrorAction SilentlyContinue
                $totalSize = ($items | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                $size = Format-ByteSize $totalSize
                $fileCount = @($items).Count
                
                Write-Host "`n$tempDir`n  Size: $size | Files: $fileCount"
            }
            catch {
                Write-Host "`n$tempDir - Cannot access"
            }
        }
    }
}

function Clean-TemporaryFiles {
    param(
        [switch]$DryRun = $false,
        [int]$DaysOld = 30
    )
    
    $tempDirs = @($env:TEMP, "C:\Windows\Temp")
    $deletedSize = 0
    $deletedFiles = 0
    
    foreach ($tempDir in $tempDirs) {
        if (Test-Path $tempDir -PathType Container) {
            try {
                $cutoffDate = (Get-Date).AddDays(-$DaysOld)
                $oldFiles = Get-ChildItem -Path $tempDir -File -Recurse -ErrorAction SilentlyContinue |
                    Where-Object { $_.LastWriteTime -lt $cutoffDate }
                
                foreach ($file in $oldFiles) {
                    if ($DryRun) {
                        Write-Host "[DRY-RUN] Would delete: $($file.FullName) | Size: $(Format-ByteSize $file.Length)"
                    }
                    else {
                        try {
                            Remove-Item $file.FullName -Force -ErrorAction SilentlyContinue
                            Write-Host "✓ Deleted: $($file.FullName)"
                        }
                        catch {
                            Write-Host "✗ Failed to delete: $($file.FullName)"
                        }
                    }
                    $deletedSize += $file.Length
                    $deletedFiles++
                }
            }
            catch {
                Log-Error "Error cleaning $tempDir : $_"
            }
        }
    }
    
    Write-Host "`nCleanup Summary:"
    Write-Host "  Files processed: $deletedFiles"
    Write-Host "  Space freed: $(Format-ByteSize $deletedSize)"
    if ($DryRun) {
        Write-Host "  (Dry-run mode - no files actually deleted)"
    }
}

function Get-DiskUsageSummary {
    Write-Host "`nDisk Space Usage Summary:"
    Write-Host "──────────────────────────────────────────────────────"
    
    $drives = Get-Volume | Where-Object { $_.DriveLetter -and $_.Size -gt 0 }
    
    foreach ($drive in $drives) {
        $letter = $drive.DriveLetter
        $totalSize = $drive.Size
        $usedSize = $drive.Size - $drive.SizeRemaining
        $usagePercent = [Math]::Floor(($usedSize / $totalSize) * 100)
        $usedDisplay = Format-ByteSize $usedSize
        $freeDisplay = Format-ByteSize $drive.SizeRemaining
        $totalDisplay = Format-ByteSize $totalSize
        
        Write-Host "$letter`: $usagePercent% used | Used: $usedDisplay | Free: $freeDisplay | Total: $totalDisplay"
    }
}

function Generate-CleanupRecommendations {
    Write-Host "`n╔════════════════════════════════════════════╗"
    Write-Host "║     Cleanup Recommendations               ║"
    Write-Host "╚════════════════════════════════════════════╝`n"
    
    # Check temp directories
    $tempSize = 0
    foreach ($tempDir in @($env:TEMP, "C:\Windows\Temp")) {
        if (Test-Path $tempDir) {
            $tempSize += (Get-ChildItem -Path $tempDir -Recurse -ErrorAction SilentlyContinue | 
                Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
        }
    }
    
    if ($tempSize -gt 1GB) {
        Log-Warn "• Temporary files using $(Format-ByteSize $tempSize) - consider cleanup"
    }
    
    # Check disk usage
    $drives = Get-Volume | Where-Object { $_.DriveLetter -and $_.Size -gt 0 }
    foreach ($drive in $drives) {
        $usagePercent = [Math]::Floor((($drive.Size - $drive.SizeRemaining) / $drive.Size) * 100)
        if ($usagePercent -gt 90) {
            Log-Error "• Drive $($drive.DriveLetter): is $usagePercent% full - urgent cleanup needed"
        }
        elseif ($usagePercent -gt 80) {
            Log-Warn "• Drive $($drive.DriveLetter): is $usagePercent% full - cleanup recommended"
        }
    }
    
    Write-Host "`n✓ Analysis complete"
}

# ============================================================================
# Disk Cleanup Main Router
# ============================================================================

function Invoke-DiskCleanup {
    param(
        [string]$Action = "analyze",
        [string[]]$Arguments = @()
    )
    
    # Parse arguments for options
    $dryRun = $Arguments -contains "--dry-run"
    $force = $Arguments -contains "--force"
    $size = if ($Arguments -contains "--size") { [int]$Arguments[$Arguments.IndexOf("--size") + 1] * 1MB } else { 100MB }
    
    switch ($Action.ToLower()) {
        "analyze" { Analyze-DiskUsage "C:\" 10 }
        "find-large" { Find-LargeFiles "C:\" $size }
        "duplicates" { Find-DuplicateFiles $env:USERPROFILE }
        "temp-dirs" { Analyze-TemporaryDirectories }
        "clean-temp" { 
            if ($force -or (Confirm-Action "Delete temporary files older than 30 days?")) {
                Clean-TemporaryFiles -DryRun:$dryRun -DaysOld 30
            }
        }
        "recommendations" { Generate-CleanupRecommendations }
        "disk-summary" { Get-DiskUsageSummary }
        "all" {
            Analyze-DiskUsage "C:\" 10
            Find-LargeFiles "C:\" $size
            Get-DiskUsageSummary
        }
        default {
            Log-Error "Unknown cleanup action: $Action"
            Write-Host "Usage: cleanup {analyze|find-large|duplicates|temp-dirs|clean-temp|recommendations|disk-summary|all}"
        }
    }
}

# ============================================================================
# Export functions
# ============================================================================

Export-ModuleMember -Function @(
    'Format-ByteSize', 'Find-LargeFiles', 'Analyze-DiskUsage',
    'Find-DuplicateFiles', 'Analyze-TemporaryDirectories',
    'Clean-TemporaryFiles', 'Get-DiskUsageSummary',
    'Generate-CleanupRecommendations', 'Invoke-DiskCleanup'
)

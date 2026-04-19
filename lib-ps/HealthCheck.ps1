# lib-ps/HealthCheck.ps1 — System health monitoring for ShellOps (PowerShell)
# Provides CPU, memory, disk, network, and service health checks

using module .\Common.ps1
using module .\Config.ps1

# ============================================================================
# System Health Monitoring Functions
# ============================================================================

function Get-CPUUsage {
    try {
        $cpuMetric = Get-CimInstance -ClassName Win32_PerfFormattedData_PerfOS_Processor `
            -Filter 'Name="_Total"' -ErrorAction Stop | Select-Object -ExpandProperty PercentProcessorTime
        return [int]$cpuMetric
    }
    catch {
        # Fallback for systems without WMI perf counters
        $loadPercent = (Get-Process | Measure-Object -Property CPU -Sum).Sum / @(Get-CimInstance Win32_ComputerSystemProduct).Count
        return [Math]::Min([int]$loadPercent, 100)
    }
}

function Get-MemoryUsage {
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $totalMemory = $os.TotalVisibleMemorySize
        $freeMemory = $os.FreePhysicalMemory
        $usedMemory = $totalMemory - $freeMemory
        return [int]($usedMemory * 100 / $totalMemory)
    }
    catch {
        Log-Error "Failed to get memory usage: $_"
        return 0
    }
}

function Get-DiskUsagePercent {
    param([string]$DriveLetter = "C:")
    
    try {
        $drive = Get-PSDrive -Name $DriveLetter.Substring(0,1) -ErrorAction Stop
        if ($drive) {
            $total = $drive.Used + $drive.Free
            if ($total -gt 0) {
                return [int]($drive.Used * 100 / $total)
            }
        }
    }
    catch {
        Log-Error "Failed to get disk usage for $DriveLetter : $_"
    }
    return 0
}

function Get-LoadAverage {
    # Windows doesn't have load average like Unix, use CPU usage instead
    $cpu = Get-CPUUsage
    return @{
        OneMin = $cpu
        FiveMin = $cpu
        FifteenMin = $cpu
    }
}

function Get-Uptime {
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $lastBootTime = $os.LastBootUpTime
        $uptime = (Get-Date) - $lastBootTime
        
        return @{
            Days = $uptime.Days
            Hours = $uptime.Hours
            Minutes = $uptime.Minutes
            TotalSeconds = [int]$uptime.TotalSeconds
        }
    }
    catch {
        Log-Error "Failed to get uptime: $_"
        return @{Days = 0; Hours = 0; Minutes = 0; TotalSeconds = 0}
    }
}

function Test-ServiceStatus {
    param([string]$ServiceName)
    
    try {
        $service = Get-Service -Name $ServiceName -ErrorAction Stop
        return @{
            Name = $service.Name
            Status = $service.Status
            IsRunning = $service.Status -eq 'Running'
        }
    }
    catch {
        return @{
            Name = $ServiceName
            Status = "NotFound"
            IsRunning = $false
        }
    }
}

function Test-NetworkConnectivity {
    $dnsServers = @("8.8.8.8", "1.1.1.1", "208.67.222.222")
    $available = 0
    
    foreach ($server in $dnsServers) {
        if (Test-Connection -ComputerName $server -Count 1 -Quiet -ErrorAction SilentlyContinue) {
            $available++
        }
    }
    
    return @{
        ServersTested = $dnsServers.Count
        ServersReachable = $available
        IsConnected = $available -gt 0
    }
}

function Get-SecurityUpdates {
    try {
        # Check for pending updates via Windows Update
        $updateSession = New-Object -ComObject Microsoft.Update.Session
        $updateSearcher = $updateSession.CreateUpdateSearcher()
        $searchResult = $updateSearcher.Search("IsInstalled=0")
        
        return @{
            PendingUpdates = $searchResult.Updates.Count
            HasUpdates = $searchResult.Updates.Count -gt 0
        }
    }
    catch {
        return @{
            PendingUpdates = 0
            HasUpdates = $false
        }
    }
}

function Generate-HealthReport {
    Log-Info "Generating comprehensive health report..."
    
    $cpuUsage = Get-CPUUsage
    $memUsage = Get-MemoryUsage
    $diskUsage = Get-DiskUsagePercent
    $uptime = Get-Uptime
    $network = Test-NetworkConnectivity
    $updates = Get-SecurityUpdates
    $load = Get-LoadAverage
    
    $cpuAlert = if ($cpuUsage -gt (Get-ConfigValue 'HEALTH_CHECK_CPU_THRESHOLD')) { "⚠" } else { "✓" }
    $memAlert = if ($memUsage -gt (Get-ConfigValue 'HEALTH_CHECK_MEMORY_THRESHOLD')) { "⚠" } else { "✓" }
    $diskAlert = if ($diskUsage -gt (Get-ConfigValue 'HEALTH_CHECK_DISK_THRESHOLD')) { "⚠" } else { "✓" }
    $netAlert = if ($network.IsConnected) { "✓" } else { "✗" }
    
    Log-Success "╔═══════════════════════════════════════════════════════════════╗"
    Log-Success "║                   System Health Report                         ║"
    Log-Success "╚═══════════════════════════════════════════════════════════════╝"
    
    Write-Host ""
    Write-Host "CPU Usage:          $cpuAlert  $cpu% (Threshold: $(Get-ConfigValue 'HEALTH_CHECK_CPU_THRESHOLD')%)"
    Write-Host "Memory Usage:       $memAlert  $memUsage% (Threshold: $(Get-ConfigValue 'HEALTH_CHECK_MEMORY_THRESHOLD')%)"
    Write-Host "Disk Usage (C:):    $diskAlert  $diskUsage% (Threshold: $(Get-ConfigValue 'HEALTH_CHECK_DISK_THRESHOLD')%)"
    Write-Host ""
    Write-Host "Load Average:       $($load.OneMin)% (1min) | $($load.FiveMin)% (5min) | $($load.FifteenMin)% (15min)"
    Write-Host "Uptime:             $($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m"
    Write-Host ""
    Write-Host "Network:            $netAlert  $($network.ServersReachable)/$($network.ServersTested) DNS servers reachable"
    Write-Host "Pending Updates:    $($updates.PendingUpdates) update(s)"
    Write-Host ""
    
    if ($updates.HasUpdates) {
        Log-Warn "Security updates are available. Please run Windows Update."
    }
}

function Show-QuickHealthCheck {
    $cpu = Get-CPUUsage
    $mem = Get-MemoryUsage
    $disk = Get-DiskUsagePercent
    
    Write-Host "CPU: $cpu% | Memory: $mem% | Disk: $disk%"
}

# ============================================================================
# Health Check Main Router
# ============================================================================

function Invoke-HealthCheck {
    param([string]$Action = "report")
    
    switch ($Action.ToLower()) {
        "report" { Generate-HealthReport }
        "quick" { Show-QuickHealthCheck }
        "cpu" { Write-Host "CPU Usage: $(Get-CPUUsage)%" }
        "memory" { Write-Host "Memory Usage: $(Get-MemoryUsage)%" }
        "disk" { Write-Host "Disk Usage (C:): $(Get-DiskUsagePercent)%" }
        "network" {
            $net = Test-NetworkConnectivity
            Write-Host "Network: $($net.ServersReachable)/$($net.ServersTested) DNS servers reachable"
        }
        "uptime" {
            $ut = Get-Uptime
            Write-Host "Uptime: $($ut.Days)d $($ut.Hours)h $($ut.Minutes)m"
        }
        "updates" {
            $upd = Get-SecurityUpdates
            Write-Host "Pending Updates: $($upd.PendingUpdates)"
        }
        default {
            Log-Error "Unknown health check action: $Action"
            Write-Host "Usage: health {report|quick|cpu|memory|disk|network|uptime|updates}"
        }
    }
}

# ============================================================================
# Export functions
# ============================================================================

Export-ModuleMember -Function @(
    'Get-CPUUsage', 'Get-MemoryUsage', 'Get-DiskUsagePercent',
    'Get-LoadAverage', 'Get-Uptime',
    'Test-ServiceStatus', 'Test-NetworkConnectivity', 'Get-SecurityUpdates',
    'Generate-HealthReport', 'Show-QuickHealthCheck',
    'Invoke-HealthCheck'
)

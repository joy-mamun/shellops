# lib-ps/UserMonitor.ps1 — User activity monitoring for ShellOps (PowerShell)
# Tracks login sessions, idle time, and suspicious activity

using module .\Common.ps1
using module .\Config.ps1

# ============================================================================
# User Monitoring Functions
# ============================================================================

function Get-ActiveUsers {
    try {
        $sessions = query user 2>$null | Select-Object -Skip 1
        $users = @()
        
        foreach ($line in $sessions) {
            if ($line -match '^\s*>?(.+?)\s+(\S+)\s+(\d+)') {
                $users += @{
                    Username = $matches[1].Trim()
                    SessionName = $matches[2]
                    SessionID = $matches[3]
                }
            }
        }
        
        return $users
    }
    catch {
        Log-Error "Failed to query user sessions: $_"
        return @()
    }
}

function Get-UserIdleTime {
    param([string]$Username)
    
    try {
        # Get idle time using query user
        $userInfo = query user $Username 2>$null
        if ($userInfo -match '\s+(\d+):(\d+)') {
            $idleHours = [int]$matches[1]
            $idleMinutes = [int]$matches[2]
            return $idleHours * 3600 + $idleMinutes * 60
        }
        return 0
    }
    catch {
        return 0
    }
}

function Show-UserIdleTimes {
    $users = Get-ActiveUsers
    
    if ($users.Count -eq 0) {
        Write-Host "No active user sessions found."
        return
    }
    
    Write-Host "`nUser Idle Times:"
    Write-Host "────────────────────────────────────"
    
    foreach ($user in $users) {
        $idleSeconds = Get-UserIdleTime $user.Username
        
        if ($idleSeconds -lt 60) {
            $idleDisplay = "$idleSeconds seconds"
        }
        elseif ($idleSeconds -lt 3600) {
            $idleDisplay = "$([Math]::Floor($idleSeconds / 60)) minutes"
        }
        else {
            $hours = [Math]::Floor($idleSeconds / 3600)
            $minutes = [Math]::Floor(($idleSeconds % 3600) / 60)
            $idleDisplay = "$hours hours $minutes minutes"
        }
        
        Write-Host "$($user.Username): $idleDisplay"
    }
}

function Show-LoginHistory {
    param([int]$Count = 10)
    
    try {
        Write-Host "`nRecent Login History (Last $Count entries):"
        Write-Host "────────────────────────────────────────────"
        
        # Use Windows Event Log for login history
        $events = Get-WinEvent -FilterHashtable @{
            LogName = 'Security'
            ID = @(4624, 4625)  # 4624=Success, 4625=Failure
        } -MaxEvents $Count -ErrorAction SilentlyContinue | 
        Sort-Object TimeCreated -Descending
        
        foreach ($event in $events) {
            $eventData = $event.Message
            $status = if ($event.ID -eq 4624) { "✓ Success" } else { "✗ Failed" }
            Write-Host "$($event.TimeCreated): $status - Event $($event.ID)"
        }
        
        if ($null -eq $events) {
            Write-Host "(Requires administrator privileges to view security logs)"
        }
    }
    catch {
        Log-Warn "Could not retrieve login history: $_"
    }
}

function Show-SuspiciousActivity {
    try {
        Write-Host "`nSuspicious Activity Alerts:"
        Write-Host "────────────────────────────"
        
        # Check for failed login attempts
        $failedLogins = Get-WinEvent -FilterHashtable @{
            LogName = 'Security'
            ID = 4625
            StartTime = (Get-Date).AddHours(-24)
        } -MaxEvents 100 -ErrorAction SilentlyContinue
        
        $failureCount = ($failedLogins | Measure-Object).Count
        
        if ($failureCount -gt 10) {
            Log-Warn "⚠ High number of failed login attempts in last 24 hours: $failureCount"
        }
        else {
            Write-Host "✓ No suspicious login activity detected"
        }
        
        # Check for remote desktop sessions
        $rdpSessions = query session 2>$null | Where-Object { $_ -match 'rdp' }
        if ($rdpSessions) {
            Log-Info "Active RDP sessions detected:"
            foreach ($session in $rdpSessions) {
                Write-Host "  $session"
            }
        }
    }
    catch {
        Log-Warn "Could not check for suspicious activity: $_"
    }
}

function Get-ActiveUserCount {
    $users = Get-ActiveUsers
    return $users.Count
}

function Show-IdleUsers {
    param([int]$ThresholdSeconds = 300)
    
    $users = Get-ActiveUsers
    $idleUsers = @()
    
    foreach ($user in $users) {
        $idleTime = Get-UserIdleTime $user.Username
        if ($idleTime -ge $ThresholdSeconds) {
            $idleUsers += @{
                Username = $user.Username
                IdleSeconds = $idleTime
            }
        }
    }
    
    if ($idleUsers.Count -eq 0) {
        Write-Host "No users idle for more than $ThresholdSeconds seconds."
        return
    }
    
    Write-Host "`nIdle Users (threshold: $ThresholdSeconds seconds):"
    Write-Host "────────────────────────────────────────────────"
    
    foreach ($user in $idleUsers) {
        $minutes = [Math]::Floor($user.IdleSeconds / 60)
        Write-Host "$($user.Username): $minutes minutes idle"
    }
}

# ============================================================================
# User Monitor Main Router
# ============================================================================

function Invoke-UserMonitor {
    param(
        [string]$Action = "summary",
        [string[]]$Arguments = @()
    )
    
    switch ($Action.ToLower()) {
        "users" { 
            $users = Get-ActiveUsers
            if ($users.Count -eq 0) {
                Write-Host "No active user sessions."
            }
            else {
                Write-Host "Active Users:"
                foreach ($user in $users) {
                    Write-Host "  $($user.Username) (Session: $($user.SessionName))"
                }
            }
        }
        "idle" { Show-UserIdleTimes }
        "history" { Show-LoginHistory }
        "suspicious" { Show-SuspiciousActivity }
        "idle-threshold" {
            $threshold = if ($Arguments.Count -gt 1) { [int]$Arguments[1] } else { 300 }
            Show-IdleUsers $threshold
        }
        "count" {
            $count = Get-ActiveUserCount
            Write-Host "Active user count: $count"
        }
        "all" {
            Show-UserIdleTimes
            Show-LoginHistory
            Show-SuspiciousActivity
        }
        "summary" {
            Write-Host "`n╔════════════════════════════════════════╗"
            Write-Host "║     User Activity Summary              ║"
            Write-Host "╚════════════════════════════════════════╝`n"
            
            $count = Get-ActiveUserCount
            Write-Host "Active Users: $count"
            
            Show-UserIdleTimes
            Show-SuspiciousActivity
        }
        default {
            Log-Error "Unknown monitor action: $Action"
            Write-Host "Usage: monitor {users|idle|history|suspicious|idle-threshold|count|all|summary}"
        }
    }
}

# ============================================================================
# Export functions
# ============================================================================

Export-ModuleMember -Function @(
    'Get-ActiveUsers', 'Get-UserIdleTime', 'Show-UserIdleTimes',
    'Show-LoginHistory', 'Show-SuspiciousActivity',
    'Get-ActiveUserCount', 'Show-IdleUsers',
    'Invoke-UserMonitor'
)

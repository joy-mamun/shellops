# lib-ps/Common.ps1 — Shared utility functions for ShellOps (PowerShell)
# Provides logging, error handling, validation, and color-coded output

Set-StrictMode -Version 3.0
$ErrorActionPreference = "Continue"

# ============================================================================
# Color Codes for Readability
# ============================================================================

$script:ColorRed = "Red"
$script:ColorGreen = "Green"
$script:ColorYellow = "Yellow"
$script:ColorBlue = "Cyan"
$script:ColorReset = "White"

# ============================================================================
# Logging Functions
# ============================================================================

function Log-Info {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [INFO] $Message" -ForegroundColor $script:ColorBlue
}

function Log-Warn {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [WARN] $Message" -ForegroundColor $script:ColorYellow
}

function Log-Error {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [ERROR] $Message" -ForegroundColor $script:ColorRed
}

function Log-Success {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [OK] $Message" -ForegroundColor $script:ColorGreen
}

# ============================================================================
# Error Handling & Exit Functions
# ============================================================================

function Invoke-Die {
    param(
        [string]$Message,
        [int]$ExitCode = 1
    )
    Log-Error $Message
    exit $ExitCode
}

# ============================================================================
# Permission & Privilege Checks
# ============================================================================

function Test-ElevatedPrivileges {
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Require-Root {
    if (-not (Test-ElevatedPrivileges)) {
        Log-Error "This operation requires administrator privileges. Please run PowerShell as Administrator."
        return $false
    }
    return $true
}

function Test-CommandExists {
    param([string]$Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

function Require-Command {
    param([string]$Command)
    if (-not (Test-CommandExists $Command)) {
        Log-Error "Required command not found: $Command"
        return $false
    }
    return $true
}

# ============================================================================
# File & Directory Validation
# ============================================================================

function Test-FileReadable {
    param([string]$FilePath)
    if (-not (Test-Path $FilePath -PathType Leaf)) {
        Log-Error "File not readable or does not exist: $FilePath"
        return $false
    }
    return $true
}

function Require-FileReadable {
    param([string]$FilePath)
    return Test-FileReadable $FilePath
}

function Test-DirectoryWritable {
    param([string]$DirectoryPath)
    if (-not (Test-Path $DirectoryPath -PathType Container)) {
        return $false
    }
    try {
        $tempFile = [System.IO.Path]::GetTempFileName()
        Move-Item $tempFile -Destination "$DirectoryPath\test_write.tmp" -ErrorAction Stop
        Remove-Item "$DirectoryPath\test_write.tmp" -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

function Require-DirectoryWritable {
    param([string]$DirectoryPath)
    if (-not (Test-DirectoryWritable $DirectoryPath)) {
        Log-Error "Directory not writable: $DirectoryPath"
        return $false
    }
    return $true
}

function Ensure-Directory {
    param(
        [string]$DirectoryPath,
        [string]$Mode = "755"
    )
    
    if (-not (Test-Path $DirectoryPath -PathType Container)) {
        try {
            $null = New-Item -ItemType Directory -Path $DirectoryPath -Force -ErrorAction Stop
            Log-Info "Created directory: $DirectoryPath"
        }
        catch {
            Invoke-Die "Failed to create directory: $DirectoryPath"
        }
    }
}

# ============================================================================
# Validation Helpers
# ============================================================================

function Test-PatternMatch {
    param(
        [string]$String,
        [string]$Pattern,
        [string]$ErrorMessage = "Validation failed"
    )
    
    if ($String -notmatch $Pattern) {
        Log-Error $ErrorMessage
        return $false
    }
    return $true
}

function Validate-Pattern {
    param(
        [string]$String,
        [string]$Pattern,
        [string]$ErrorMessage = "Validation failed"
    )
    return Test-PatternMatch $String $Pattern $ErrorMessage
}

function Test-NumberInRange {
    param(
        [int]$Number,
        [int]$Min,
        [int]$Max
    )
    
    if ($Number -lt $Min -or $Number -gt $Max) {
        Log-Error "Number out of range ($Min-$Max): $Number"
        return $false
    }
    return $true
}

function Validate-NumberRange {
    param(
        [int]$Number,
        [int]$Min,
        [int]$Max
    )
    return Test-NumberInRange $Number $Min $Max
}

function Test-YesNoInput {
    param([string]$Input)
    $input = $Input.ToLower()
    return $input -in @("y", "yes", "n", "no")
}

function Validate-YesNo {
    param([string]$Input)
    if (-not (Test-YesNoInput $Input)) {
        Log-Error "Invalid input. Please use: yes, no, y, or n"
        return $false
    }
    return $true
}

# ============================================================================
# User Interaction
# ============================================================================

function Confirm-Action {
    param([string]$Prompt)
    
    while ($true) {
        $response = Read-Host "$Prompt (yes/no)"
        if (Validate-YesNo $response) {
            return $response -match "^(y|yes)$"
        }
    }
}

function Request-Input {
    param(
        [string]$Prompt,
        [string]$DefaultValue = ""
    )
    
    if ([string]::IsNullOrEmpty($DefaultValue)) {
        while ($true) {
            $input = Read-Host $Prompt
            if (-not [string]::IsNullOrEmpty($input)) {
                return $input
            }
            Log-Warn "Input cannot be empty"
        }
    }
    else {
        $input = Read-Host "$Prompt [$DefaultValue]"
        if ([string]::IsNullOrEmpty($input)) {
            return $DefaultValue
        }
        return $input
    }
}

function Request-Secret {
    param([string]$Prompt)
    $secret = Read-Host $Prompt -AsSecureString
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToGlobalAllocUnicode($secret)
    $plain = [System.Runtime.InteropServices.Marshal]::PtrToStringUnicode($bstr)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeGlobalAllocUnicode($bstr)
    return $plain
}

# ============================================================================
# System Information
# ============================================================================

function Get-EffectiveUsername {
    return [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
}

function Get-ComputerHostname {
    return [System.Net.Dns]::GetHostName()
}

function Get-OSType {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
    if ($null -ne $os) {
        return $os.Caption
    }
    return [System.Runtime.InteropServices.RuntimeInformation]::OSDescription
}

function Get-OSVersion {
    return [System.Environment]::OSVersion.VersionString
}

function Test-OS {
    param([string]$TargetOS)
    $currentOS = Get-OSType
    return $currentOS -match $TargetOS
}

# ============================================================================
# Array Utilities
# ============================================================================

function Test-ArrayContains {
    param(
        [object]$Target,
        [array]$Array
    )
    return $Target -in $Array
}

function Join-ArrayElements {
    param(
        [string]$Delimiter = ",",
        [array]$Array
    )
    return $Array -join $Delimiter
}

# ============================================================================
# String Utilities
# ============================================================================

function Convert-ToLowercase {
    param([string]$String)
    return $String.ToLower()
}

function Convert-ToUppercase {
    param([string]$String)
    return $String.ToUpper()
}

function Trim-Whitespace {
    param([string]$String)
    return $String.Trim()
}

# ============================================================================
# Export functions for use in other modules
# ============================================================================

Export-ModuleMember -Function @(
    'Log-Info', 'Log-Warn', 'Log-Error', 'Log-Success',
    'Invoke-Die',
    'Test-ElevatedPrivileges', 'Require-Root', 'Test-CommandExists', 'Require-Command',
    'Test-FileReadable', 'Require-FileReadable', 'Test-DirectoryWritable', 'Require-DirectoryWritable', 'Ensure-Directory',
    'Test-PatternMatch', 'Validate-Pattern', 'Test-NumberInRange', 'Validate-NumberRange', 'Test-YesNoInput', 'Validate-YesNo',
    'Confirm-Action', 'Request-Input', 'Request-Secret',
    'Get-EffectiveUsername', 'Get-ComputerHostname', 'Get-OSType', 'Get-OSVersion', 'Test-OS',
    'Test-ArrayContains', 'Join-ArrayElements',
    'Convert-ToLowercase', 'Convert-ToUppercase', 'Trim-Whitespace'
) -Variable @(
    'ColorRed', 'ColorGreen', 'ColorYellow', 'ColorBlue', 'ColorReset'
)

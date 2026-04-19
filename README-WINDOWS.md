# ShellOps — Windows Edition (PowerShell)

**ShellOps Windows Edition** is a complete PowerShell adaptat ion of the educational system administration toolkit, providing native Windows support for user monitoring, disk cleanup, backup scheduling, and health checks.

## Features

### 🔍 User Monitoring
- Track active user sessions and login history
- Monitor user idle time
- Detect suspicious login activity
- Real-time session management

### 💾 Disk Cleanup & Analysis
- Find large files across the system
- Identify duplicate files by hash
- Analyze disk usage by folder
- Safe temporary file cleanup with validation

### 📦 Backup & Archiving
- Create ZIP and 7-Zip backups
- Automatic backup rotation & retention
- Backup  manifest viewing
- Easy restoration from backups
- Scheduled backup support

### 🏥 System Health Monitoring
- Real-time CPU, memory, and disk usage
- Network connectivity testing
- Uptime and system load reporting
- Security update status
- Visual health reports with alerts

## Requirements

- **Windows 10/11 or Windows Server 2016+**
- **PowerShell 5.0+** (5.1 or Core 7.0+ recommended)
- **Administrator privileges** (for privileged operations)
- Optional: 7-Zip for advanced compression

## Installation

### Quick Start

1. **Clone or download the project**
   ```powershell
   git clone https://github.com/joy-mamun/shellops.git
   cd shellops
   ```

2. **Run a health check**
   ```powershell
   .\shellops.ps1 health quick
   ```

3. **View available commands**
   ```powershell
   .\shellops.ps1 help
   ```

### System-wide Installation

For convenience, create a function in your PowerShell profile:

```powershell
function shellops { & 'C:\path\to\shellops\shellops.ps1' @args }
```

Or add the script directory to your PATH.

## Usage

### Basic Syntax

```powershell
.\shellops.ps1 [COMMAND] [ACTION] [OPTIONS]
```

### Health Monitoring

```powershell
# Quick health status
.\shellops.ps1 health quick

# Full health report
.\shellops.ps1 health report

# Check specific metrics
.\shellops.ps1 health cpu
.\shellops.ps1 health memory
.\shellops.ps1 health disk
.\shellops.ps1 health network
.\shellops.ps1 health updates
```

### User Monitoring

```powershell
# List active users
.\shellops.ps1 monitor users

# Check user idle times
.\shellops.ps1 monitor idle

# View login history
.\shellops.ps1 monitor history

# Check for suspicious activity
.\shellops.ps1 monitor suspicious

# Get active user count
.\shellops.ps1 monitor count

# Show activity summary
.\shellops.ps1 monitor summary
```

### Disk Cleanup

```powershell
# Analyze disk usage
.\shellops.ps1 cleanup analyze

# Find large files (>100 MB)
.\shellops.ps1 cleanup find-large --size 500

# Find duplicate files
.\shellops.ps1 cleanup duplicates

# View temporary directories
.\shellops.ps1 cleanup temp-dirs

# Clean temp files (dry-run preview first)
.\shellops.ps1 cleanup clean-temp --dry-run
.\shellops.ps1 cleanup clean-temp --force

# Get cleanup recommendations
.\shellops.ps1 cleanup recommendations

# Full disk analysis
.\shellops.ps1 cleanup disk-summary
```

### Backup & Archiving

```powershell
# Create a backup
.\shellops.ps1 backup create --path C:\MyData

# List existing backups
.\shellops.ps1 backup list

# View backup contents
.\shellops.ps1 backup manifest backup_20240101_120000.zip

# Restore from backup
.\shellops.ps1 backup restore

# Rotate old backups (keep last 10)
.\shellops.ps1 backup rotate

# Test backup functionality
.\shellops.ps1 backup test
```

## Configuration

Create a `config.ps1` file in the script directory to customize settings:

```powershell
# Feature enablement
$Config['USER_MONITOR_ENABLED'] = $true
$Config['DISK_CLEANUP_ENABLED'] = $true
$Config['BACKUP_SCHEDULE_ENABLED'] = $true
$Config['HEALTH_CHECK_ENABLED'] = $true

# User monitoring thresholds
$Config['USER_MONITOR_IDLE_THRESHOLD'] = 300  # seconds
$Config['USER_MONITOR_ALERT_ROOT_LOGINS'] = $true

# Disk cleanup
$Config['DISK_CLEANUP_SIZE_THRESHOLD'] = 104857600  # 100 MB
$Config['DISK_CLEANUP_DRY_RUN'] = $true

# Backup settings
$Config['BACKUP_RETENTION_COUNT'] = 10
$Config['BACKUP_COMPRESSION'] = 'zip'  # zip, 7z, none

# Health check thresholds
$Config['HEALTH_CHECK_CPU_THRESHOLD'] = 80  # percent
$Config['HEALTH_CHECK_MEMORY_THRESHOLD'] = 85
$Config['HEALTH_CHECK_DISK_THRESHOLD'] = 90

# Logging
$Config['LOG_LEVEL'] = 'INFO'  # ERROR, WARN, INFO, DEBUG
$Config['LOG_DIR'] = "$env:USERPROFILE\.shellops\logs"
```

## Architecture

```
shellops.ps1           Main entry point
lib-ps/
  ├── Common.ps1       Shared utilities (logging, validation, etc.)
  ├── Config.ps1       Configuration management
  ├── HealthCheck.ps1  System health monitoring
  ├── UserMonitor.ps1  User activity tracking
  ├── DiskCleanup.ps1  Disk analysis and cleanup
  └── BackupSchedule.ps1 Backup management
```

## Troubleshooting

### "Running scripts is disabled" error

PowerShell script execution is restricted. Enable script execution:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### "Module not found" error

Ensure all modules in `lib-ps/` are present and the relative paths are correct.

### Health check shows WMI errors

Some health checks require administrator privileges:

```powershell
Start-Process powershell -Verb RunAs -ArgumentList '-Command .\shellops.ps1 health report'
```

### SSD/NVMe not detected

Windows calls these "Fixed" drives. The script auto-detects all volumes:

```powershell
.\shellops.ps1 cleanup disk-summary
```

## Comparison: Bash vs PowerShell Edition

| Feature | Bash | PowerShell |
|---------|------|-----------|
| **OS Support** | Linux, macOS | Windows 10/11, Server |
| **User Monitoring** | /var/log parsing | Event Log APIs |
| **System Metrics** | /proc filesystem | WMI/CIM cmdlets |
| **Backup Format** | tar/gzip/bzip2/xz | ZIP/7z |
| **Scheduling** | cron | Windows Task Scheduler |
| **Permissions** | sudo/root | Administrator |

## Limitations on Windows

- **Cron-like scheduling**: Use Windows Task Scheduler instead
- **Inode-based systems**: Windows FILE_ID used instead
- **User/Group model**: Windows SID/domain model differs
- **Permission flags**: NTFS ACLs replace Unix permissions

## Contributing

Contributions welcome! Please:

1. Test on Windows 10/Server 2016+
2. Ensure PowerShell 5.0+ compatibility
3. Use `Set-StrictMode -Version 3.0`
4. Add comment-based help for functions
5. Submit PR with test results

## License

Educational use. See LICENSE file.

## Support

For issues and questions, see the documentation in `/docs` or create an issue on GitHub.

---

**ShellOps** — Making system administration approachable across platforms.

# ShellOps — Cross-Platform System Administration Toolkit

A beginner-friendly, educational system administration toolkit with support for **Linux, macOS, and Windows**. Each platform has a native implementation (Bash for Unix-like systems, PowerShell for Windows) with consistent interfaces and full feature parity.

```
📦 ShellOps
├── Bash Edition (Linux & macOS)
│   ├── shellops          Main entry point
│   ├── setup_wizard.sh   Interactive setup
│   └── lib/              Bash modules
├── PowerShell Edition (Windows)  
│   ├── shellops.ps1      Main entry point
│   └── lib-ps/           PowerShell modules
└── docs/                 Documentation (all platforms)
```

## Platform Quick Start

### Linux & macOS
```bash
# Run the toolkit with bash
cd ~/shellops
./setup_wizard.sh  # Interactive setup
./shellops health quick
./shellops help
```

### Windows (PowerShell)
```powershell
# Run from PowerShell
cd C:\Users\...\shellops
.\shellops.ps1 health quick
.\shellops.ps1 help
```

## How to Run ShellOps (All Platforms)

### Method 1: Interactive Menu (Recommended for Beginners)

**Linux & macOS:**
```bash
cd ~/Desktop/shellops
./interactive_menu.sh
# Or run main entry point and select option 1:
./shellops
# Then enter: 1
```

**Windows (PowerShell):**
```powershell
cd C:\path\to\shellops
.\interactive_menu.ps1
# Or run main entry point and select option 1:
.\shellops.ps1
# Then enter: 1
```

**Features:**
- Number-based menu selection (type 0-8 and press Enter)
- No command syntax needed
- Organized submenus for each feature
- Back/Exit navigation
- Perfect for exploring features

### Method 2: Direct Commands (Recommended for Experienced Users)

**Linux & macOS — General Syntax:**
```bash
./shellops [COMMAND] [ACTION] [OPTIONS]
```

**Examples:**
```bash
# Health Checks
./shellops health quick          # CPU, Memory, Disk in one line
./shellops health report         # Full detailed report
./shellops health cpu            # CPU usage only
./shellops health memory         # Memory usage only
./shellops health disk           # Disk usage only

# User Monitoring
./shellops monitor users         # List active users
./shellops monitor idle          # Show idle times
./shellops monitor history       # Login history
./shellops monitor summary       # Full user summary
./shellops monitor alerts        # Suspicious activity

# Disk Cleanup
./shellops cleanup analyze       # Analyze disk usage
./shellops cleanup find-large    # Find files > 100MB
./shellops cleanup duplicates    # Find duplicate files
./shellops cleanup temp-dirs     # Check temp directories
./shellops cleanup clean-temp --dry-run  # Preview cleanup

# Backups
./shellops backup create         # Create backup
./shellops backup list           # List backups
./shellops backup restore        # Restore from backup
./shellops backup test           # Test backup (dry-run)

# utilities
./shellops help                  # Show all commands
./shellops version               # Show version info
./shellops init                  # Configuration wizard
```

**Windows (PowerShell) — General Syntax:**
```powershell
.\shellops.ps1 [COMMAND] [ACTION] [OPTIONS]
```

**Examples (same as Linux/macOS):**
```powershell
.\shellops.ps1 health quick
.\shellops.ps1 monitor users
.\shellops.ps1 cleanup analyze
.\shellops.ps1 backup create
.\shellops.ps1 help
```

**Common Options:**
```bash
--dry-run         # Preview changes without executing
--verbose, -v     # Detailed output
--help, -h        # Show help for specific command
```

### Method 3: Setup Wizard (For Configuration)

**Linux & macOS:**
```bash
cd ~/Desktop/shellops
sudo ./setup_wizard.sh   # Interactive configuration prompts
# Or via main menu:
./shellops
# Enter: 1 → 5 (Setup Wizard)
```

**Windows (PowerShell):**
```powershell
cd C:\path\to\shellops
.\shellops.ps1 init
# Or via main menu:
.\shellops.ps1
# Enter: 1 → 5 (Setup Wizard)
```

### Complete Usage Examples

**Linux/macOS - Full System Analysis:**
```bash
./interactive_menu.sh     # Start menu
# Select: 6 (System Report) → 1 (Full Analysis)
# Or direct command:
./shellops health report && ./shellops monitor summary && ./shellops cleanup analyze
```

**Windows - Monitor Active Users:**
```powershell
.\interactive_menu.ps1    # Start menu
# Select: 2 (User Monitoring) → 6 (Full Summary)
# Or direct command:
.\shellops.ps1 monitor summary
```

**Linux/macOS - Disk Cleanup Preview:**
```bash
./shellops cleanup analyze
./shellops cleanup find-large
./shellops cleanup duplicates
./shellops cleanup clean-temp --dry-run  # Preview only
./shellops cleanup clean-temp            # Actually clean
```

**Windows - Backup Creation:**
```powershell
.\shellops.ps1 backup test      # Test backup (dry-run)
.\shellops.ps1 backup create    # Create actual backup
.\shellops.ps1 backup list      # View all backups
```

## Features

### Supported on All Platforms
✓ **User Monitoring** — Track active sessions, idle time, login history, suspicious activity
✓ **Disk Cleanup** — Find large files, duplicates, analyze usage
✓ **Backup Scheduling** — Create, manage, and restore backups
✓ **Health Monitoring** — CPU, Memory, Disk, Network, Services, Updates

### Platform Implementation Details

#### Linux & macOS (Bash)
- **Requirements**: Bash 4.0+, standard POSIX utilities
- **User Monitoring**: Parses `/var/log/`, `who`, `w` commands
- **System Metrics**: Reads from `/proc/stat`, `/proc/meminfo`
- **Backups**: Uses `tar` with gzip/bzip2/xz compression
- **Scheduling**: Cron-based automation
- **Documentation**: See [README.md](README.md) + [docs/](docs/)

#### Windows (PowerShell)
- **Requirements**: PowerShell 5.0+, Windows 10/Server 2016+
- **User Monitoring**: Windows Event Log API, `query user` command
- **System Metrics**: WMI/CIM cmdlets for real-time data
- **Backups**: ZIP and 7-Zip compression, native Windows Backup
- **Scheduling**: Windows Task Scheduler integration
- **Documentation**: See [README-WINDOWS.md](README-WINDOWS.md)

#### macOS Adaptations (Planned)
- **System Metrics**: `sysctl` instead of `/proc`
- **Services**: `launchctl` instead of systemctl
- **Auth Logs**: `/var/log/system.log` instead of `/var/log/auth.log`
- **CPU**: Native macOS system tools

## Installation

### Linux & macOS — Bash Version

#### Automated Install
```bash
# Clone repository
git clone https://github.com/joy-mamun/shellops.git
cd shellops

# Run installer
sudo ./install.sh
```

#### Manual Install
```bash
# Create directories
mkdir -p ~/.shellops/bin ~/.shellops/lib ~/.shellops/config

# Copy files
cp shellops ~/.shellops/bin/
cp lib/*.sh ~/.shellops/lib/
cp config/shellops.conf.example ~/.shellops/config/shellops.conf
chmod +x ~/.shellops/bin/shellops ~/.shellops/lib/*.sh

# Add to PATH
export PATH="$PATH:$HOME/.shellops/bin"
```

### Windows — PowerShell Version

1. **Enable script execution** (if needed):
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. **Download repository**
   ```powershell
   git clone https://github.com/joy-mamun/shellops.git
   cd shellops
   ```

3. **Run commands**
   ```powershell
   .\shellops.ps1 health quick
   .\shellops.ps1 help
   ```

4. **Optional: Create alias** (PowerShell profile)
   ```powershell
   # Add to C:\Users\[User]\Documents\PowerShell\$PROFILE
   function shellops { & 'C:\path\to\shellops\shellops.ps1' @args }
   ```

## Quick Start

### Linux/macOS
```bash
# 1. Run setup wizard
sudo ./setup_wizard.sh

# 2. Check system health
./shellops health

# 3. View documentation
cat docs/quick-start.md
```

### Windows
```powershell
# 1. Check system health
.\shellops.ps1 health

# 2. View user monitoring
.\shellops.ps1 monitor summary

# 3. Analyze disk usage
.\shellops.ps1 cleanup analyze
```

## Configuration

### Linux/macOS
```bash
# Interactive setup
sudo ./setup_wizard.sh

# Manual editing
vim config/shellops.conf

# Help
cat docs/configuration.md
```

### Windows
Create `config.ps1` in the script directory or use defaults:
```powershell
$Config['HEALTH_CHECK_CPU_THRESHOLD'] = 80
$Config['BACKUP_RETENTION_COUNT'] = 10
# etc.
```

See [README-WINDOWS.md](README-WINDOWS.md) for full options.

## Usage Examples

### Check System Health
```bash
# Linux/macOS
./shellops health quick
./shellops health report

# Windows
.\shellops.ps1 health quick
.\shellops.ps1 health report
```

### User Monitoring
```bash
# Linux/macOS
./shellops monitor users
./shellops monitor idle
./shellops monitor history

# Windows
.\shellops.ps1 monitor users
.\shellops.ps1 monitor idle
.\shellops.ps1 monitor history
```

### Disk Cleanup
```bash
# Linux/macOS
./shellops cleanup analyze --dry-run
./shellops cleanup find-large --dry-run
./shellops cleanup clean-temp --dry-run

# Windows
.\shellops.ps1 cleanup analyze
.\shellops.ps1 cleanup find-large --dry-run
.\shellops.ps1 cleanup clean-temp --dry-run
```

### Backup Management
```bash
# Linux/macOS
./shellops backup create
./shellops backup list
./shellops backup rotate
./shellops backup restore

# Windows
.\shellops.ps1 backup create
.\shellops.ps1 backup list
.\shellops.ps1 backup rotate
.\shellops.ps1 backup restore
```

### Display Help
```bash
# Linux/macOS
./shellops help
./shellops help monitor
./shellops help cleanup

# Windows
.\shellops.ps1 help
.\shellops.ps1 help monitor
.\shellops.ps1 help cleanup
```

## Project Structure

```
shellops/
├── Linux & macOS (Bash)
│   ├── shellops              # Main entry point
│   ├── setup_wizard.sh       # Interactive configuration
│   ├── install.sh            # Installation helper
│   ├── test.sh               # Testing framework
│   └── lib/
│       ├── common.sh         # Logging, validation, error handling
│       ├── config.sh         # Configuration management
│       ├── user_monitor.sh   # User monitoring
│       ├── disk_cleanup.sh   # Disk cleanup & analysis
│       ├── backup_schedule.sh # Backup management
│       └── health_check.sh   # System health checking
│
├── Windows (PowerShell)
│   ├── shellops.ps1          # Main entry point
│   └── lib-ps/
│       ├── Common.ps1        # Logging, validation error handling
│       ├── Config.ps1        # Configuration management
│       ├── UserMonitor.ps1   # User monitoring
│       ├── DiskCleanup.ps1   # Disk cleanup & analysis
│       ├── BackupSchedule.ps1 # Backup management
│       └── HealthCheck.ps1   # System health checking
│
├── Configuration & Resources
│   ├── config/               # Config templates
│   │   ├── shellops.conf.example
│   │   └── backup.exclude
│   ├── docs/                 # Documentation
│   │   ├── quick-start.md
│   │   ├── features.md
│   │   ├── configuration.md
│   │   ├── cron-setup.md
│   │   └── troubleshooting.md
│   ├── README.md             # Main readme
│   ├── README-WINDOWS.md     # Windows-specific readme
│   ├── CONTRIBUTING.md       # Contribution guidelines
│   ├── .gitignore
│   ├── LICENSE
│   └── Plan.md               # Implementation plan
```

## Documentation

All platforms share documentation, with platform-specific guides:

- **[Main README](README.md)** — Platform overview and quick start
- **[Windows README](README-WINDOWS.md)** — PowerShell-specific guide
- **[Quick Start](docs/quick-start.md)** — Get running in 5 minutes
- **[Features](docs/features.md)** — Feature guide (all platforms)
- **[Configuration](docs/configuration.md)** — Config options
- **[Cron Setup](docs/cron-setup.md)** — Linux/macOS scheduling
- **[Troubleshooting](docs/troubleshooting.md)** — Common issues

## Requirements

### Linux & macOS
- **OS**: Linux or macOS
- **Shell**: Bash 4.0+
- **Utilities**: `awk`, `grep`, `tar`, `find` (pre-installed)
- **Optional**: `gzip`, `bzip2`, `xz` for backup compression

### Windows
- **OS**: Windows 10/11 or Windows Server 2016+
- **Shell**: PowerShell 5.0+ (or 7.0+ for Core)
- **Optional**: 7-Zip for advanced compression

## Testing & Quality Assurance

### Linux/macOS
```bash
./test.sh  # Automated test suite
```

### Windows
```powershell
# Manual functional testing
.\shellops.ps1 health quick
.\shellops.ps1 monitor users
.\shellops.ps1 cleanup analyze
```

Test results (Linux): **55/56 tests passing** ✓

## Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on:
- Code style and shell best practices
- Adding new features
- Writing documentation
- Testing procedures

## Learning Resources

This toolkit is designed as an educational project. You'll learn:
- Bash scripting best practices (error handling, logging, validation)
- System administration concepts (user management, disk usage, backups)
- Shell script modularity and code organization
- Cron job scheduling
- Configuration management patterns

## Security Considerations

- **Run with appropriate privileges**: Operations requiring root will prompt for sudo
- **Backup sensitive data**: Always backup before cleanup operations
- **Review dry-runs**: Use `--dry-run` mode to preview high-impact operations
- **Monitor logs**: Check `/var/log/shellops/` for operation details
- **Update regularly**: Keep the toolkit updated for security fixes

## License

Educational use — modify and extend as needed for learning purposes.

## Support & Feedback

For issues, questions, or feature requests:
1. Check [Troubleshooting](docs/troubleshooting.md)
2. Review existing documentation
3. File an issue with detailed reproduction steps

---

**Next Step**: Run `sudo ./setup_wizard.sh` to configure the toolkit for your system!

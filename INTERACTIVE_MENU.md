# Interactive Menu Guide — ShellOps

## Overview

ShellOps now includes an **interactive menu system** that makes it easy to run commands without memorizing syntax. Simply enter numbers to select options from a menu-driven interface.

## Quick Start

### Linux & macOS (Bash)

```bash
# Launch interactive menu by running without arguments
cd ~/shellops
./shellops

# You'll see a prompt:
# No command specified. Choose an option:
#   1) Launch Interactive Menu
#   2) Show Help
# 
# Enter choice (1-2): 1
```

Or directly run the menu:
```bash
./interactive_menu.sh
```

### Windows (PowerShell)

```powershell
# Launch interactive menu by running without arguments
cd C:\path\to\shellops
.\shellops.ps1

# You'll see a prompt:
# No command specified. Choose an option:
#   1) Launch Interactive Menu
#   2) Show Help
# 
# Enter choice (1-2): 1
```

Or directly run the menu:
```powershell
.\interactive_menu.ps1
```

## Menu Structure

### Main Menu
```
1) Health Check       — Monitor CPU, Memory, Disk, Network
2) User Monitoring    — Track active users and login history
3) Disk Cleanup       — Find large files, analyze usage
4) Backup Management  — Create and manage backups
5) Setup Wizard       — Configure ShellOps interactively
6) System Report      — Full system analysis
7) Help & Information — Show all available commands
8) About ShellOps     — Version and project info
0) Exit               — Quit ShellOps
```

### Health Check Submenu
```
1) Quick Health Check     — CPU | Memory | Disk (one-liner)
2) Full Health Report     — Detailed metrics with alerts
3) CPU Usage              — Current CPU percentage
4) Memory Usage           — Current memory percentage
5) Disk Usage             — Filesystem usage
6) Network Connectivity   — Test network connectivity
7) System Uptime          — How long system has been running
8) Package Updates        — Check available updates
0) Back to Main Menu
```

### User Monitoring Submenu
```
1) Active Users           — List all currently logged-in users
2) User Idle Times        — Show idle time per user
3) Login History          — Display recent login attempts
4) Suspicious Activity    — Alert on unusual logins
5) Active User Count      — Total number of active users
6) Full Summary           — All user monitoring info
0) Back to Main Menu
```

### Disk Cleanup Submenu
```
1) Disk Summary           — Show all mounted filesystems
2) Analyze Disk Usage     — Top directories by size
3) Find Large Files       — Search for files > 100MB
4) Find Duplicates        — Locate duplicate files by hash
5) Analyze Temp Dirs      — Check temporary directory sizes
6) Clean Temp (preview)   — Preview temp file cleanup
7) Clean Temp (execute)   — Actually clean temp files
8) Recommendations        — Get cleanup suggestions
0) Back to Main Menu
```

### Backup Management Submenu
```
1) List Backups           — Show all existing backups
2) Create Backup          — Create a new backup
3) Rotate Backups         — Keep last N backups (clean old ones)
4) Show Backup Contents   — List files in a backup
5) Restore from Backup    — Extract backup to location
6) Test Backup System     — Create test backup
0) Back to Main Menu
```

## Usage Examples

### Example 1: Check System Health
```
$ ./shellops

No command specified. Choose an option:
  1) Launch Interactive Menu
  2) Show Help

Enter choice (1-2): 1

[Main Menu appears]

MAIN MENU — Select an option:
  1) Health Check       — Monitor CPU, Memory, Disk, Network
  ...

Enter your choice (0-8): 1

[Health Menu appears]

SELECT AN ACTION:
  1) Quick Health Check
  2) Full Health Report
  ...

Enter your choice (0-8): 1

[Displays quick health check results]
CPU: 12% | Memory: 45% | Disk: 32%

Press Enter to continue...
```

### Example 2: Monitor Users
```
[From Main Menu]
Enter your choice (0-8): 2

[User Monitoring Menu appears]

SELECT AN ACTION:
  1) Active Users
  2) User Idle Times
  ...

Enter your choice (0-6): 1

[Displays active users]
kali     logged  in  at  2026-04-20  10:30
root     logged  in  at  2026-04-20  08:15

Press Enter to continue...
```

### Example 3: Analyze Disk Space
```
[From Main Menu]
Enter your choice (0-8): 3

[Disk Cleanup Menu appears]

SELECT AN ACTION:
  1) Disk Summary
  2) Analyze Disk Usage
  ...

Enter your choice (0-8): 2

[Displays top directories by size]
Used        Directory
──────────────────────
512M        /home/user
384M        /var
256M        /usr

Press Enter to continue...
```

## Features

### Navigation
- **Number Selection**: Simply enter the menu number and press Enter
- **Back Navigation**: Always enter `0` to go back to the Main Menu
- **Exit**: Enter `0` from Main Menu to exit the application

### Safety
- **Confirmation Prompts**: Destructive operations (like cleanup) ask for confirmation
- **Dry-Run By Default**: Preview modes show what will happen without making changes
- **Help Available**: Every menu includes option descriptions

### Command Execution
- Each menu selection automatically runs the corresponding ShellOps command
- Results display immediately in the menu interface
- After each command, you can return to browse other options

## Comparison: Menu vs Command Line

### Using Interactive Menu
```bash
./shellops
# [Follow menu prompts]
```

### Using Command Line (Still Available)
```bash
./shellops health quick
./shellops monitor users
./shellops cleanup analyze
```

Both approaches work - choose what's most convenient for your workflow!

## Tips & Tricks

### Tip 1: Menu Navigation
Navigate menus backward by entering `0` at any submenu to return to Main Menu. From Main Menu, `0` exits completely.

### Tip 2: Quick Health Check
For a one-line system status, select: Main Menu → 1 → 1 (Quick Health Check)

### Tip 3: Full System Report
Select: Main Menu → 6 (System Report) to get comprehensive monitoring across all features.

### Tip 4: Safe Cleanup
When cleaning temporary files:
1. First select "Clean Temp (preview)" to see what will be deleted
2. Then select "Clean Temp (execute)" to actually delete

### Tip 5: Setup Configuration
Use Main Menu → 5 (Setup Wizard) to configure ShellOps interactively and customize thresholds.

## Troubleshooting

### Menu Doesn't Appear
**Linux/macOS:**
```bash
# Make sure script is executable
chmod +x interactive_menu.sh shellops

# Run directly
./interactive_menu.sh
```

**Windows:**
```powershell
# Check execution policy if needed
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Run directly
.\interactive_menu.ps1
```

### Invalid Choice Error
- The menu will show valid options (like 0-8)
- Only enter numbers within that range
- Press Enter to dismiss error and try again

### Command Not Found
Ensure you're in the ShellOps directory and the shell scripts have correct permissions:
```bash
cd ~/shellops
ls -la shellops interactive_menu.sh  # Should show executable (x) permission
```

## Advanced: Custom Menu Items

To add custom menu items, edit the appropriate menu file:

**Linux/macOS:**
```bash
# Edit the interactive menu
nano interactive_menu.sh

# Find the relevant menu function (e.g., show_health_menu)
# Add new options and corresponding case handlers
```

**Windows:**
```powershell
# Edit the interactive menu
notepad interactive_menu.ps1

# Find the relevant function (e.g., Show-HealthMenu)
# Add new options and corresponding switch cases
```

## Return to Command Line

To go back to pure command-line mode (no interactive menu), use:

```bash
# Linux/macOS - commands still work directly
./shellops health quick
./shellops monitor users

# Windows - commands still work directly
.\shellops.ps1 health quick
.\shellops.ps1 monitor users
```

The interactive menu is always optional - all features remain accessible via command line!

---

**Need Help?**

From any menu, select the "Help & Information" option to view command documentation, or run:
```bash
./shellops help          # Linux/macOS
.\shellops.ps1 help      # Windows
```

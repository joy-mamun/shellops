# Quick Start Guide — ShellOps

Get up and running with ShellOps in 5 minutes!

## Prerequisites

- Linux system (Ubuntu, Debian, RHEL, CentOS)
- Bash 4.0 or later
- Sudo access (for some operations)
- Standard utilities: `awk`, `grep`, `tar`, `cron`

## Installation

Choose one method:

### Option 1: Direct Use (No Installation)

```bash
cd shellops
chmod +x shellops setup_wizard.sh
./shellops health  # Try it immediately
```

### Option 2: System-Wide Installation

```bash
sudo ./install.sh
shellops health  # Available from anywhere
```

## 5-Minute Walkthrough

### 1. Configure ShellOps (2 minutes)

Run the interactive setup wizard:

```bash
sudo ./setup_wizard.sh
```

This wizard will ask you about:
- Which features to enable
- Performance thresholds
- Backup targets
- Logging preferences

**Tip**: Just press Enter to accept defaults!

### 2. Check System Health (1 minute)

```bash
./shellops health
```

You'll see CPU, memory, disk usage, and any alerts.

### 3. Monitor Your Users (1 minute)

```bash
./shellops monitor summary
```

Shows active users, idle times, and login history.

### 4. Analyze Disk Space (1 minute)

```bash
./shellops cleanup analyze
./shellops cleanup find-large /home
```

First shows overall usage; second finds files over 100MB.

## Next Steps

### Create a Backup

```bash
# Preview (dry-run)
./shellops backup test

# Create actual backup
./shellops backup create

# List backups
./shellops backup list
```

### Enable Automated Backups

```bash
# This adds a cron job for automatic backups
sudo ./shellops backup schedule
```

### View Full Documentation

```bash
./shellops help
./shellops help monitor
./shellops help cleanup
./shellops help backup
./shellops help health
```

## Common Tasks

### See Active Users

```bash
shellops monitor users
```

### Find Large Files

```bash
shellops cleanup find-large /home
```

### Get System Status Report

```bash
shellops health report
```

### Clean Temporary Directories

```bash
# Preview mode (safe)
shellops cleanup clean-temp --dry-run

# Actually clean (requires --execute)
sudo shellops cleanup clean-temp --execute
```

### Restore from Backup

```bash
shellops backup list  # See available backups
shellops backup restore backup-20241201_120000.tar.gz /restore/path
```

## Troubleshooting

### Permission Denied

Make sure scripts are executable:

```bash
chmod +x shellops setup_wizard.sh
```

### Command Not Found (after install)

Update your PATH:

```bash
export PATH="$PATH:$HOME/.shellops/bin"
```

Or use full path:

```bash
~/.shellops/bin/shellops health
```

### Logs

Logs are written to:
- `/var/log/shellops/` (system installation)
- `~/.shellops/logs/` (user installation)

View logs:

```bash
cat /var/log/shellops/shellops.log
```

## Learning Tips

✓ **Experiment with `--dry-run`** — Safe way to preview operations

✓ **Read the help text** — `shellops help cleanup` explains each option

✓ **Check logs** — Understand what operations are doing

✓ **Review config** — `cat config/shellops.conf` to see current settings

✓ **Run tests** — `./test.sh` validates your setup

## What You're Learning

By using ShellOps, you're learning:

- **Bash scripting** — How to write maintainable shell scripts
- **System administration** — Managing users, backups, disk space
- **Linux utilities** — Understanding `awk`, `tar`, `cron`, etc.
- **Best practices** — Error handling, logging, configuration management

---

**Next**: Run `sudo ./setup_wizard.sh` to get started!

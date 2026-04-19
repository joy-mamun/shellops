# ShellOps Features Guide

Comprehensive documentation for each ShellOps feature.

## Table of Contents

1. [User Monitoring](#user-monitoring)
2. [Disk Cleanup](#disk-cleanup)
3. [Backup Scheduling](#backup-scheduling)
4. [Health Checks](#health-checks)

---

## User Monitoring

### What It Does

Track active users on your system, monitor idle time, view login history, and detect suspicious activity.

### When to Use

- **Security**: Monitor for unexpected logins
- **Administration**: Track user sessions
- **Resource Management**: Identify idle sessions to free up resources

### Commands

```bash
# List active users
shellops monitor users

# View idle times
shellops monitor idle

# Show recent logins
shellops monitor history         # Last 10
shellops monitor history 20      # Last 20

# Check for suspicious activity
shellops monitor alerts

# Quick summary
shellops monitor summary
```

### Configuration

Edit `config/shellops.conf`:

```bash
# When to mark a user as idle (seconds)
USER_MONITOR_IDLE_THRESHOLD=3600

# Alert when root logs in
USER_MONITOR_ALERT_ROOT_LOGINS=true
```

### Output Examples

```
Active users on myhost:
USER       WHEN
alice      12:34
bob        pts/1 12:45

User idle times:
User       Terminal  From         Idle
alice      pts/0     192.168.1.5  5:23
bob        pts/1     ssh          1:30m
```

### Use Cases

**Check who's logged in:**
```bash
shellops monitor users
```

**Find idle sessions:**
```bash
shellops monitor idle
```

**Investigate suspicious root activity:**
```bash
shellops monitor alerts
```

---

## Disk Cleanup

### What It Does

Analyze disk usage, identify large files and duplicates, manage temporary directories.

### When to Use

- **Space Crisis**: Find out what's taking up space
- **Maintenance**: Clean old temporary files
- **Optimization**: Find duplicate files for deduplication

### Commands

```bash
# Show disk usage breakdown
shellops cleanup analyze /home

# Find large files (>100MB by default)
shellops cleanup find-large /home

# Find duplicate files
shellops cleanup duplicates /home

# Show temp dir sizes
shellops cleanup temp-dirs

# Preview cleanup (safer)
shellops cleanup clean-temp --dry-run

# Actually clean (requires confirmation)
shellops cleanup clean-temp --execute

# Show cleanup recommendations
shellops cleanup recommendations /home

# Full analysis
shellops cleanup all
```

### Configuration

Edit `config/shellops.conf`:

```bash
# Minimum file size to report (bytes)
# 104857600 = 100MB
DISK_CLEANUP_SIZE_THRESHOLD=104857600

# Default to preview mode
DISK_CLEANUP_DRY_RUN=true

# Directories to clean
DISK_CLEANUP_TEMP_DIRS=("/tmp" "/var/tmp" "/var/cache/apt")
```

### Output Examples

```
File Size        Location
─────────────────────────
250G             /home/user/videos/recording.mp4
1.2G             /var/cache/packages
500M             /tmp/old-backup.tar.gz
```

### Workflow

1. **Analyze** — See what's using space
2. **Find Large** — Identify big files
3. **Recommendations** — Get suggestions
4. **Dry-run** — Preview cleanup
5. **Execute** — Safely clean

### Use Cases

**Disk is full:**
```bash
shellops cleanup analyze /
shellops cleanup find-large /home
```

**Find old temp files:**
```bash
shellops cleanup temp-dirs
shellops cleanup clean-temp --dry-run
```

**Cleanup before backup:**
```bash
shellops cleanup recommendations /home
```

---

## Backup Scheduling

### What It Does

Create tar/gzip backups of your important directories, schedule automated backups, and manage backup rotation.

### When to Use

- **Data Protection**: Regular backups prevent data loss
- **Disaster Recovery**: Restore from backup if needed
- **Before Major Changes**: Backup before system updates

### Commands

```bash
# Create a backup now
shellops backup create

# List all backups
shellops backup list

# Automatically clean up old backups
shellops backup rotate

# See files in a backup
shellops backup manifest backup-20241201_120000.tar.gz

# Restore from backup
shellops backup restore backup-20241201_120000.tar.gz /restore/here

# Add to cron for automatic backups
sudo shellops backup schedule

# Test backup system
shellops backup test
```

### Configuration

Edit `config/shellops.conf`:

```bash
# Directories to backup (space-separated)
BACKUP_DIRS="/home /etc /opt"

# Keep this many recent backups
BACKUP_RETENTION_COUNT=10

# Compression: gzip, bzip2, xz, none
BACKUP_COMPRESSION=gzip

# Cron schedule for automatic backups
# "0 2 * * *" = daily at 2am
BACKUP_SCHEDULE="0 2 * * *"

# Enable automatic backups
BACKUP_ENABLED=true
```

### Backup Exclude Patterns

Edit `config/backup.exclude`:

```bash
# Skip cache directories
.cache/*
.local/share/cache/*

# Skip temp files
*.tmp
*.bak

# Skip version control
.git/*
.svn/*
```

### Cron Schedule Examples

| Expression | Meaning |
|-----------|---------|
| `0 2 * * *` | Daily at 2:00 AM |
| `0 * * * *` | Every hour |
| `0 3 * * 0` | Weekly on Sunday at 3 AM |
| `0 4 1 * *` | Monthly on 1st at 4 AM |

### Output Examples

```
Backup created successfully
File: /home/user/shellops/backups/backup-20241201_120000.tar.gz
Size: 2.3G

Existing backups in: ./backups
Timestamp              Size        File
─────────────────────────────────────────
2024-12-01 12:00:00   2.3G        backup-20241201_120000.tar.gz
2024-11-30 02:00:00   2.1G        backup-20241130_020000.tar.gz
```

### Workflow

1. **Configure** — Set backup targets, schedule
2. **Test** — Run `shellops backup test`
3. **Schedule** — Enable with cron
4. **Monitor** — Check `shellops backup list`
5. **Restore** — Use when needed (test first!)

### Use Cases

**First-time setup:**
```bash
shellops backup test
shellops backup create
```

**Enable automatic backups:**
```bash
sudo ./setup_wizard.sh  # Configure during setup
sudo shellops backup schedule
```

**Disaster recovery:**
```bash
shellops backup list
shellops backup restore backup-YYYYMMDD_HHMMSS.tar.gz /restore/path
```

---

## Health Checks

### What It Does

Monitor system health: CPU, memory, disk usage, services, network, and available updates.

### When to Use

- **Daily Monitoring**: Check system status
- **Troubleshooting**: Diagnose performance issues
- **Preventive Maintenance**: Catch problems early
- **Capacity Planning**: Monitor trends

### Commands

```bash
# Full health report with alerts
shellops health report

# Quick status snapshot
shellops health quick

# Check individual metrics
shellops health cpu
shellops health memory
shellops health disk
shellops health network
shellops health uptime
shellops health updates
```

### Configuration

Edit `config/shellops.conf`:

```bash
# Alert thresholds (percentage)
HEALTH_CHECK_CPU_THRESHOLD=80
HEALTH_CHECK_MEMORY_THRESHOLD=80
HEALTH_CHECK_DISK_THRESHOLD=80
```

### Output Examples

```
╔════════════════════════════════════════════════════════════════╗
║              System Health Report                              ║
║              Generated: 2024-12-01 14:30:00                     ║
╚════════════════════════════════════════════════════════════════╝

System Information:
  Hostname:  myhost
  OS:        Linux
  Kernel:    5.15.0-86-generic
  Uptime:    45 days, 3 hours, 22 minutes

Resource Usage:
  CPU Usage:         45% OK
  Memory Usage:      62% OK
  Load Average:      1.23 0.98 0.76
  Disk Usage (/):    72% OK

Services:
  ssh:               ✓ running
  sshd:              ✓ running
  nginx:             ✓ running
```

### Alert Types

- ⚠ **CPU High**: CPU usage exceeds threshold
- ⚠ **Memory High**: RAM usage exceeds threshold  
- ⚠ **Disk High**: Disk usage exceeds threshold
- ✗ **Network Down**: Cannot reach DNS servers

### Workflow

1. **Quick Check** — Run `shellops health quick` regularly
2. **Full Report** — When you see an alert, investigate with `shellops health report`
3. **Troubleshooting** — Check individual metrics (CPU, memory, etc.)
4. **Action** — Clean up, add resources, investigate services

### Use Cases

**Daily monitoring:**
```bash
shellops health quick
```

**Investigate high memory:**
```bash
shellops health memory
ps aux --sort=-%mem | head -10
```

**Check network:**
```bash
shellops health network
```

**Prepare for updates:**
```bash
shellops health report
shellops health updates
```

---

## Combining Features

### Example 1: Pre-Backup System Check

```bash
# 1. Check system health
shellops health report

# 2. If disk space low, cleanup
shellops cleanup recommendations

# 3. Create backup
shellops backup create

# 4. Verify backup
shellops backup list
```

### Example 2: Weekly Maintenance

```bash
# 1. Check who's logged in
shellops monitor summary

# 2. Review disk usage
shellops cleanup analyze /

# 3. Test backups
shellops backup list

# 4. Full health check
shellops health report
```

### Example 3: Troubleshooting High Disk

```bash
# 1. See what's using space
shellops cleanup analyze /

# 2. Find the large files
shellops cleanup find-large /

# 3. Check for duplicates
shellops cleanup duplicates /

# 4. Get recommendations
shellops cleanup recommendations /
```

---

## Best Practices

### User Monitoring
- Check `monitor alerts` weekly for security
- Review `monitor history` after suspicious events
- Set reasonable idle thresholds (1-2 hours)

### Disk Cleanup
- **Always use `--dry-run` first** before executing
- Archives old data before deleting
- Review recommendations before cleanup
- Keep backups before major cleanup

### Backup Scheduling
- Test backups before relying on them
- Verify restoration process works
- Keep backup location separate from main data
- Monitor backup logs regularly
- Test restore procedure annually

### Health Checks
- Run daily for baseline understanding
- Investigate alerts promptly
- Keep logs for trend analysis
- Set thresholds based on your system
- Monitor during maintenance windows

---

## Troubleshooting

### No output from monitor commands
- Check if running on local machine
- Verify auth logs exist: `/var/log/auth.log` or `/var/log/secure`
- Some systems require sudo

### Disk cleanup finds nothing
- Increase file size threshold in config
- Check target directory permissions
- May already be clean!

### Backup fails
- Verify all backup directories are readable
- Check disk space in backup destination
- Run as root/sudo for system directories
- Check for open file handles

### Health check shows false alerts
- Adjust thresholds in config
- Check if services are expected to be running
- Network check requires internet access

---

For more help: `shellops help [command]`

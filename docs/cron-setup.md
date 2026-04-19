# Cron Setup Guide — ShellOps

Learn to schedule ShellOps tasks using cron for automated system administration.

## What is Cron?

Cron is a Linux scheduler that runs commands at specified times. Perfect for:
- Automated backups
- Regular system checks
- Scheduled maintenance

## Quick Start

### Schedule Automatic Backups

```bash
# Let ShellOps add itself to crontab
sudo ./shellops backup schedule

# Verify it was added
crontab -l | grep shellops
```

### Manual Cron Setup

If automatic scheduling doesn't work:

```bash
# Edit your crontab
sudo crontab -e

# Add this line (daily backup at 2 AM)
0 2 * * * /path/to/shellops/shellops backup create

# Save and exit
```

## Cron Format Basics

```
Minute  Hour  Day  Month  Weekday  Command
  0      2     *     *      *       /command
  │      │     │     │      │
  │      │     │     │      └─── 0=Sun, 1=Mon ... 6=Sat
  │      │     │     └────────── 1=Jan, 2=Feb ... 12=Dec  
  │      │     └─────────────── 1-31 (day of month)
  │      └──────────────────── 0-23 (hour)
  └─────────────────────────── 0-59 (minute)
```

## Common Cron Schedules

### Daily Schedules

```bash
# Daily at specified time
0 2 * * *    # 2:00 AM daily
30 3 * * *   # 3:30 AM daily
0 6 * * *    # 6:00 AM daily
0 14 * * *   # 2:00 PM daily
0 2 1 * *    # 2:00 AM on 1st of month
```

### Weekly Schedules

```bash
0 3 * * 0    # Sunday 3:00 AM (0 = Sunday)
0 3 * * 1    # Monday 3:00 AM (1 = Monday)
0 3 * * 1,3,5  # Mon/Wed/Fri 3:00 AM
0 3 * * 1-5  # Weekdays (Mon-Fri) 3:00 AM
0 3 * * 6-0  # Weekends (Sat-Sun) 3:00 AM
```

### Multiple Times Daily

```bash
0 */6 * * *  # Every 6 hours (0:00, 6:00, 12:00, 18:00)
0 */4 * * *  # Every 4 hours
0 * * * *    # Every hour at :00 minutes
*/30 * * * * # Every 30 minutes
*/15 * * * * # Every 15 minutes
```

### Business Hours

```bash
0 9 * * 1-5  # 9:00 AM weekdays only
0 9-17 * * 1-5  # Every hour 9 AM-5 PM on weekdays
```

## Example Cron Jobs for ShellOps

### Daily Backup at 2 AM

```bash
0 2 * * * /home/user/shellops/shellops backup create >> /var/log/shellops-backup.log 2>&1
```

### Weekly Health Check (Sunday 3 AM)

```bash
0 3 * * 0 /home/user/shellops/shellops health report >> /var/log/shellops-health.log 2>&1
```

### Hourly Disk Cleanup Check (preview mode)

```bash
0 * * * * /home/user/shellops/shellops cleanup analyze >> /var/log/shellops-disk.log 2>&1
```

### Nightly User Audit (Daily 11 PM)

```bash
0 23 * * * /home/user/shellops/shellops monitor alerts >> /var/log/shellops-users.log 2>&1
```

### Complete System Maintenance (Monthly)

```bash
# 1st of month at 2 AM - full system check
0 2 1 * * /home/user/shellops/shellops health report >> /var/log/shellops-full.log 2>&1
```

## Setting Up Cron Jobs Manually

### Step 1: Find Full Path to shellops

```bash
which shellops
# Or
readlink -f ./shellops
# Result: /home/user/shellops/shellops
```

### Step 2: Open Crontab

```bash
sudo crontab -e   # Edit root crontab
# OR
crontab -e        # Edit user crontab
```

### Step 3: Add Your Job

```bash
# Example: Daily backup at 2:00 AM
0 2 * * * /home/user/shellops/shellops backup create
```

### Step 4: Save and Exit

- **Vim editor**: Type `:wq` + Enter
- **Nano editor**: Ctrl+O (save), Ctrl+X (exit)

### Step 5: Verify

```bash
crontab -l     # List your cron jobs
```

## Output Redirection

### Ignore output (quiet)

```bash
0 2 * * * /home/user/shellops/shellops backup create > /dev/null 2>&1
```

### Log to file

```bash
0 2 * * * /home/user/shellops/shellops backup create >> /var/log/shellops/backup.log 2>&1
```

### Send output via email (default)

```bash
0 2 * * * /home/user/shellops/shellops backup create
# Output will be emailed if your system has mail configured
```

### Detailed logging

```bash
0 2 * * * /home/user/shellops/shellops backup create >> /var/log/shellops/backup.log 2>&1
# View logs later:
tail -f /var/log/shellops/backup.log
```

## Root vs User Cron

### System-wide (Root)

```bash
sudo crontab -e

# Runs with root privileges (for /var/log access, etc.)
0 2 * * * /home/user/shellops/shellops backup create
```

### User-specific

```bash
crontab -e

# Runs as regular user (for /home backups, etc.)
0 2 * * * /home/user/shellops/shellops backup create
```

### Which to use?

- **Root** — For system-wide backups, full access
- **User** — For user home directories, safer

## Troubleshooting Cron

### Job not running

1. **Verify path**: Use full absolute path, not relative
   ```bash
   # Wrong: crontab entry to "./shellops"
   # Right: crontab entry to "/home/user/shellops/shellops"
   ```

2. **Check permissions**: File must be executable
   ```bash
   chmod +x /home/user/shellops/shellops
   ```

3. **Check cron daemon**: Must be running
   ```bash
   sudo systemctl status cron   # Debian/Ubuntu
   sudo systemctl status crond  # RHEL/CentOS
   ```

4. **View cron logs**: See what cron tried to do
   ```bash
   sudo tail -f /var/log/syslog | grep CRON     # Debian
   sudo tail -f /var/log/cron | grep shellops   # RHEL
   ```

### Cron output in email

If cron can't send email:

```bash
# Redirect to log file instead
0 2 * * * /home/user/shellops/shellops backup create >> /var/log/shellops/backup.log 2>&1
```

### Environment variables missing

Cron jobs run with limited environment. For large PATH needs:

```bash
# Source bashrc before running
0 2 * * * /bin/bash -lc '/home/user/shellops/shellops backup create'
```

### "Permission denied"

```bash
# Use sudo if needed (but be careful with cron + sudo)
0 2 * * * sudo /home/user/shellops/shellops backup create

# Better: Use root crontab
sudo crontab -e
0 2 * * * /home/user/shellops/shellops backup create
```

## Configuration Integration

### Via Setup Wizard

Interactive setup:

```bash
sudo ./setup_wizard.sh
# During backup configuration, choose a cron schedule
# Then run: ./shellops backup schedule
```

### Via Configuration File

Edit `config/shellops.conf`:

```bash
BACKUP_SCHEDULE="0 2 * * *"   # 2 AM daily
BACKUP_ENABLED=true

# Then schedule it
./shellops backup schedule
```

## Monitoring Scheduled Tasks

### View all cron jobs

```bash
crontab -l      # Current user's jobs
sudo crontab -l # Root's jobs
```

### View cron logs

```bash
# Recent cron activity (Debian/Ubuntu)
sudo tail -n 50 /var/log/syslog | grep CRON

# Or (RHEL/CentOS)
sudo tail -n 50 /var/log/cron
```

### Check when job last ran

```bash
ls -l /var/spool/mail/$USER   # Mail shows job ran if output exists
cat /var/log/shellops/backup.log | tail -5  # Check custom log
```

## Best Practices

✓ **Use full absolute paths** — No relative paths in cron

✓ **Redirect output** — To file, not email default

✓ **Schedule off-peak** — 2-3 AM is common

✓ **Set meaningful intervals** — Daily backups usual for important data

✓ **Monitor logs** — Check /var/log/shellops/ regularly

✓ **Test before scheduling** — Run command manually first

✓ **Allow enough time** — Big backups need adequate window

✓ **Consider dependencies** — Don't run parallel tasks if risky

✗ **Don't use unnecessary sudo** — Security risk, use root crontab instead

✗ **Don't ignore cron errors** — Check logs regularly

✗ **Don't set intervals too tight** — Can impact system

## Complete Backup Schedule Example

```bash
# Edit crontab as root
sudo crontab -e

# Add these lines:

# ==========================================
# ShellOps Automated Tasks
# ==========================================

# Daily backup at 2 AM (full backup)
0 2 * * * /home/admin/shellops/shellops backup create >> /var/log/shellops-backup.log 2>&1

# Weekly health check Sunday 3 AM
0 3 * * 0 /home/admin/shellops/shellops health report >> /var/log/shellops-health.log 2>&1

# Monthly maintenance Sunday 1st at 1 AM
0 1 1 * * /home/admin/shellops/shellops cleanup recommendations / >> /var/log/shellops-maint.log 2>&1

# Save and exit (:wq in vim)
```

## Next Steps

For automatic setup: `./shellops backup schedule`

For manual testing: `./shellops backup create`

---

**Remember**: Always test cron jobs manually first before scheduling!

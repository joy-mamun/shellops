# Troubleshooting Guide — ShellOps

Common issues and solutions when using ShellOps.

## Installation & Setup

### "Permission denied" when running shellops

**Solution:**
```bash
# Make scripts executable
chmod +x shellops setup_wizard.sh lib/*.sh

# Or make executable in install
install -m 755 shellops ~/.shellops/bin/
```

### "command not found: shellops"

**Solution:**
```bash
# Add to PATH
export PATH="$PATH:$HOME/.shellops/bin"

# Or use full path
~/.shellops/bin/shellops health

# Or create symlink
sudo ln -s /home/user/shellops/shellops /usr/local/bin/shellops
```

### Setup wizard not running

**Solution:**
```bash
# Ensure it's executable
chmod +x setup_wizard.sh

# Run with explicit bash
bash ./setup_wizard.sh

# Or with sudo if needed
sudo bash ./setup_wizard.sh
```

## Configuration Issues

### "Configuration file not found"

**Solution:**
```bash
# Run setup wizard to generate config
./setup_wizard.sh

# Or copy example
cp config/shellops.conf.example config/shellops.conf
./setup_wizard.sh
```

### Configuration values not being used

**Solution:**
1. Verify file is saved: `cat config/shellops.conf`
2. Check syntax is valid (no typos)
3. Reload config: Run shellops command again
4. Verify both files exist:
   ```bash
   ls -la config/shellops.conf*
   ```

### "Invalid configuration value"

**Solution:**
Check the setting in config file:
```bash
# Example: Invalid threshold
HEALTH_CHECK_CPU_THRESHOLD=150  # Out of range!

# Fix it:
HEALTH_CHECK_CPU_THRESHOLD=80   # Valid: 1-100
```

## User Monitoring

### No users shown by "shellops monitor users"

**Possible causes:**

1. **Running on non-Linux system** — Check:
   ```bash
   uname -s   # Should be "Linux"
   ```

2. **Limited access** — Try with sudo:
   ```bash
   sudo shellops monitor users
   ```

3. **No active users** — This is normal
   ```bash
   # Who command returns nothing
   who
   ```

**Solution:**
```bash
# Try these alternatives
w          # Show active users
last       # Show login history
logname    # Get current user
whoami     # Get current username
```

### "Permission denied" when checking alerts

**Solution:**
```bash
# Root login alerts need sudo access to logs
sudo shellops monitor alerts

# Or grant read access to auth.log
sudo usermod -a -G adm $USER
```

### Idle time shows wrong values

**Solution:**
Idle time depends on `w` command accuracy:
```bash
# Check idle times
w

# If showing weird values, update your system
sudo apt update && sudo apt upgrade
```

## Disk Cleanup

### No large files found

**Solution:**
Try these troubleshooting steps:
```bash
# 1. Check threshold setting
grep DISK_CLEANUP_SIZE_THRESHOLD config/shellops.conf

# 2. Reduce threshold (to 10MB for testing)
# Edit config and change to: 10485760

# 3. Search manually to verify
find /home -size +100M -type f

# 4. Check permissions
sudo shellops cleanup find-large /
```

### "Directory not readable"

**Solution:**
```bash
# Check directory permissions
ls -ld /target/directory

# Grant read access if needed
sudo chmod +rx /target/directory

# Or run with sudo
sudo shellops cleanup analyze /target/directory
```

### Duplicate detection slow or hanging

**Solution:**
```bash
# Limit to smaller directory
shellops cleanup duplicates /home/user  # Not /

# Or check filesystem space
df -h

# Cancel long-running operation
# Press Ctrl+C
```

### Cannot clean temp directories

**Causes:**
1. Permission denied
2. Files still in use
3. Directory doesn't exist

**Solution:**
```bash
# Check permissions
ls -ld /tmp /var/tmp

# Try with sudo
sudo shellops cleanup clean-temp --execute

# Or clean manually
sudo rm -rf /tmp/* 2>/dev/null || true
```

## Backup Issues

### Backup creation fails

**Check these:**

1. **Backup directory writable**:
   ```bash
   touch $BACKUP_DIR/test
   ls -ld $BACKUP_DIR
   ```

2. **Disk space available**:
   ```bash
   df -h
   ```

3. **Source directories readable**:
   ```bash
   for dir in /home /etc; do
     ls -ld "$dir" || echo "Cannot read: $dir"
   done
   ```

**Solution:**
```bash
# Fix permissions
chmod 755 $BACKUP_DIR

# Free up space if needed
df -h | head

# Run as root if needed
sudo shellops backup create
```

### "tar: Cannot open file for writing"

**Solution:**
```bash
# Check backup directory
ls -la config/backups
# or
ls -la ~/.shellops/backups

# Ensure writable
sudo chmod 777 $BACKUP_DIR

# Or use different location
BACKUP_DIR=/backup ./shellops backup create
```

### Backup file corrupted

**Solution:**
```bash
# Verify backup file integrity
tar -tzf backup-20241201_120000.tar.gz > /dev/null

# If fails, backup is corrupted
# Try a new backup
./shellops backup create
```

### Restore not working

**Solution:**
```bash
# 1. Verify backup exists
./shellops backup list

# 2. Check restore destination
mkdir -p /restore/path
chmod 755 /restore/path

# 3. Try restore
./shellops backup restore /path/to/backup.tar.gz /restore/path

# 4. Verify restored files
ls /restore/path
```

### Cron job not running

**Solution:**
```bash
# 1. Check crontab entry
crontab -l | grep shellops

# 2. Verify job executable
ls -l /path/to/shellops

# 3. Check logs
sudo tail /var/log/syslog | grep CRON
tail /var/log/shellops/shellops.log

# 4. Test manually
/path/to/shellops backup create

# 5. Use full paths
# Edit crontab and update path:
# 0 2 * * * /home/user/shellops/shellops backup create
```

## Health Checks

### CPU/Memory shows all zeros

**Cause:** System doesn't support /proc/stat

**Solution:**
```bash
# Check if /proc/stat exists
cat /proc/stat

# Alternative method
top -bn1 | grep Cpu

# Verify system supports it
uname -s
lsb_release -a
```

### Network connectivity always fails

**Cause:** No internet access or firewall

**Solution:**
```bash
# Check internet connection
ping 8.8.8.8
ping 1.1.1.1

# Check firewall
sudo iptables -L

# Try alternate DNS
nslookup google.com

# Or DNS providers work differently
# Health check tries multiple IPs, but if all blocked,
# that's the issue
```

### Health report shows warning for running service

**Cause:** Service not installed or not started

**Solution:**
```bash
# Check if service exists
systemctl list-unit-files | grep sshd

# Start service
sudo systemctl start ssh

# Or ignore warning if service isn't needed
```

### Permissions required

**Solution:**
```bash
# Some features need sudo:
sudo shellops health report  # For full system info

# Or run setup as root:
sudo ./setup_wizard.sh
sudo shellops init
```

## Logging Issues

### No logs being generated

**Check:**
```bash
# 1. Verify logging enabled
grep ENABLE_LOGGING config/shellops.conf

# 2. Check log directory exists
ls -ld /var/log/shellops/
# or
ls -ld ~/.shellops/logs/

# 3. View log file
cat /var/log/shellops/shellops.log
# or
cat ~/.shellops/logs/shellops.log

# 4. Create log directory if missing
mkdir -p /var/log/shellops/
chmod 755 /var/log/shellops/
```

### "Permission denied" writing to log file

**Solution:**
```bash
# Check permissions
ls -l /var/log/shellops/shellops.log

# Make writable
sudo chmod 666 /var/log/shellops/shellops.log

# Or create as user
mkdir -p ~/.shellops/logs
```

### Log file growing too large

**Solution:**
```bash
# Rotate logs manually
cd /var/log/shellops/
ls -lh shellops.log
wc -l shellops.log

# Archive old log
gzip shellops.log
mv shellops.log.gz shellops.log.$(date +%s).gz

# Clean up
rm shellops.log.*.gz
```

## Module Loading Issues

### "Failed to load module"

**Solution:**
```bash
# 1. Verify lib files exist
ls -la lib/

# 2. Check permissions  
chmod +x lib/*.sh

# 3. Verify script paths are correct
head -5 lib/user_monitor.sh | grep source

# 4. Check common.sh for syntax errors
bash -n lib/common.sh
```

### "Unknown command"

**Solution:**
```bash
# List available commands
./shellops help

# Check spelling
# Did you mean?
./shellops monitor   # Not "moniter"
./shellops cleanup   # Not "clean"
./shellops backup    # Not "bak"
./shellops health    # Not "healthcheck"
```

## General Troubleshooting

### Nothing working, just restart

**Solution:**
```bash
# Start fresh
./setup_wizard.sh

# Or reset completely
rm -rf config/shellops.conf logs/
./setup_wizard.sh
```

### Need more debugging info

**Solution:**
```bash
# Set debug log level
sed -i 's/LOG_LEVEL=.*/LOG_LEVEL=DEBUG/' config/shellops.conf

# Run command
./shellops health

# Check verbose logs
cat /var/log/shellops/shellops.log | tail -100
```

### Still stuck?

**Steps:**
1. Check README.md
2. Review docs/
3. Run `./test.sh` for diagnostics
4. Check config file syntax
5. Try simplest operation (`shellops health quick`)

## Performance Issues

### shellops is slow

**Cause:** Usually disk operations on large filesystems

**Solution:**
```bash
# 1. Reduce scan scope
./shellops cleanup analyze /home  # Not /

# 2. Increase file size threshold
# Edit config, increase DISK_CLEANUP_SIZE_THRESHOLD

# 3. Reduce backup directories
# Edit config, limit BACKUP_DIRS

# 4. Skip operations you don't need
# Toggle feature flags in config
```

### High CPU usage

**Solution:**
```bash
# Check what's consuming CPU
top -p $(pgrep -f shellops)

# Monitor during operation
./shellops cleanup find-large / &
top

# Cancel if needed
killall tar
```

---

For more help: `./shellops help` or check README.md

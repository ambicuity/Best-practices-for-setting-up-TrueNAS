# Regular Maintenance

> **Establish routine maintenance procedures to keep your TrueNAS system running optimally, prevent issues, and ensure long-term reliability.**

## 🎯 Maintenance Overview

Regular maintenance is crucial for TrueNAS system health. This guide provides comprehensive maintenance schedules, procedures, and automation to minimize manual work while maximizing system reliability.

**Estimated Time**: 1-2 hours setup, 15-30 minutes weekly ongoing  
**Difficulty**: Beginner to Intermediate  
**Prerequisites**: [Monitoring Setup](monitoring-setup.md) completed

---

## 📅 Maintenance Schedule

### Comprehensive Maintenance Calendar

```
Maintenance Schedule Overview:
├── Daily (Automated)
│   ├── SMART short tests
│   ├── System health checks
│   ├── Backup verification
│   └── Performance monitoring
├── Weekly (Mostly Automated)
│   ├── SMART long tests
│   ├── System updates check
│   ├── Log review and rotation
│   └── Capacity planning review
├── Monthly (Semi-Automated)
│   ├── ZFS pool scrubs
│   ├── System updates (if available)
│   ├── Security review
│   └── Performance analysis
├── Quarterly (Manual)
│   ├── Backup restoration tests
│   ├── Disaster recovery testing
│   ├── Hardware inspection
│   └── Documentation updates
└── Annually (Planned)
    ├── Hardware refresh planning
    ├── Capacity expansion planning
    ├── Major version upgrades
    └── Security audit
```

---

## 📊 Daily Maintenance Tasks

### Automated Daily Health Check

Create a comprehensive daily health check script:

```bash
#!/bin/bash
# Daily Health Check Script
# /root/scripts/daily_health_check.sh

LOGFILE="/var/log/daily_health_check.log"
EMAIL="admin@yourdomain.com"
DATE=$(date)

echo "=== TrueNAS Daily Health Check - $DATE ===" >> $LOGFILE

# Initialize health status
HEALTH_ISSUES=0

# Check system uptime
UPTIME=$(uptime -p)
echo "System Uptime: $UPTIME" >> $LOGFILE

# Check system load
LOAD_1MIN=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | tr -d ' ')
if (( $(echo "$LOAD_1MIN > 4.0" | bc -l) )); then
    echo "WARNING: High system load: $LOAD_1MIN" >> $LOGFILE
    ((HEALTH_ISSUES++))
else
    echo "System load normal: $LOAD_1MIN" >> $LOGFILE
fi

# Check memory usage
MEM_USAGE=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
if (( $(echo "$MEM_USAGE > 85.0" | bc -l) )); then
    echo "WARNING: High memory usage: ${MEM_USAGE}%" >> $LOGFILE
    ((HEALTH_ISSUES++))
else
    echo "Memory usage normal: ${MEM_USAGE}%" >> $LOGFILE
fi

# Check pool status
POOL_STATUS=$(zpool status tank | grep "state:" | awk '{print $2}')
if [ "$POOL_STATUS" != "ONLINE" ]; then
    echo "CRITICAL: Pool status is $POOL_STATUS" >> $LOGFILE
    ((HEALTH_ISSUES+=10))
else
    echo "Pool status: ONLINE" >> $LOGFILE
fi

# Check pool capacity
POOL_CAPACITY=$(zpool list tank -H -o capacity | sed 's/%//')
if [ "$POOL_CAPACITY" -gt "85" ]; then
    echo "WARNING: Pool capacity at ${POOL_CAPACITY}%" >> $LOGFILE
    ((HEALTH_ISSUES++))
elif [ "$POOL_CAPACITY" -gt "95" ]; then
    echo "CRITICAL: Pool capacity at ${POOL_CAPACITY}%" >> $LOGFILE
    ((HEALTH_ISSUES+=5))
else
    echo "Pool capacity normal: ${POOL_CAPACITY}%" >> $LOGFILE
fi

# Check service status
SERVICES=("smbd" "nfs-server" "ssh" "truenas-middlewared")
for service in "${SERVICES[@]}"; do
    if systemctl is-active --quiet $service; then
        echo "Service $service: ACTIVE" >> $LOGFILE
    else
        echo "WARNING: Service $service is not active" >> $LOGFILE
        ((HEALTH_ISSUES++))
    fi
done

# Check recent errors in logs
ERROR_COUNT=$(journalctl --since "24 hours ago" | grep -ci "error\|failed\|critical" | head -1)
if [ "$ERROR_COUNT" -gt "10" ]; then
    echo "WARNING: $ERROR_COUNT errors in last 24 hours" >> $LOGFILE
    ((HEALTH_ISSUES++))
else
    echo "Error count in last 24h: $ERROR_COUNT (normal)" >> $LOGFILE
fi

# Check disk temperatures
echo "Drive Temperatures:" >> $LOGFILE
for drive in $(lsblk -d -n -o NAME | grep -E '^sd|^nvme'); do
    TEMP=$(smartctl -A /dev/$drive 2>/dev/null | grep "Temperature_Celsius" | awk '{print $10}')
    if [ ! -z "$TEMP" ]; then
        if [ "$TEMP" -gt "45" ]; then
            echo "WARNING: Drive $drive temperature: ${TEMP}°C" >> $LOGFILE
            ((HEALTH_ISSUES++))
        else
            echo "Drive $drive temperature: ${TEMP}°C (normal)" >> $LOGFILE
        fi
    fi
done

# Summary and notification
echo "=== Daily Health Check Summary ===" >> $LOGFILE
if [ "$HEALTH_ISSUES" -eq "0" ]; then
    echo "✓ All systems healthy - no issues detected" >> $LOGFILE
    SUBJECT="TrueNAS Daily Health - All Systems Normal"
elif [ "$HEALTH_ISSUES" -lt "3" ]; then
    echo "⚠ Minor issues detected ($HEALTH_ISSUES warnings)" >> $LOGFILE
    SUBJECT="TrueNAS Daily Health - Minor Issues Detected"
else
    echo "🚨 Significant issues detected ($HEALTH_ISSUES total issues)" >> $LOGFILE
    SUBJECT="TrueNAS Daily Health - ATTENTION REQUIRED"
fi

echo "Health check completed at $(date)" >> $LOGFILE
echo "" >> $LOGFILE

# Send summary email (only if issues detected or Monday for weekly summary)
DAY_OF_WEEK=$(date +%u)
if [ "$HEALTH_ISSUES" -gt "0" ] || [ "$DAY_OF_WEEK" -eq "1" ]; then
    tail -30 $LOGFILE | mail -s "$SUBJECT" $EMAIL
fi
```

Schedule the daily health check:
```bash
# Add to root crontab
crontab -e
# Add: 0 7 * * * /root/scripts/daily_health_check.sh
```

---

## 📊 Weekly Maintenance Tasks

### Weekly System Review

Create a weekly maintenance script:

```bash
#!/bin/bash
# Weekly Maintenance Script
# /root/scripts/weekly_maintenance.sh

LOGFILE="/var/log/weekly_maintenance.log"
EMAIL="admin@yourdomain.com"

echo "=== TrueNAS Weekly Maintenance - $(date) ===" >> $LOGFILE

# Check for system updates
echo "Checking for system updates..." >> $LOGFILE
apt list --upgradable 2>/dev/null >> $LOGFILE

# Review log sizes and rotate if needed
echo -e "\nLog file sizes:" >> $LOGFILE
du -sh /var/log/*.log | sort -h >> $LOGFILE

# Analyze system performance trends
echo -e "\nSystem performance over last week:" >> $LOGFILE
echo "Average load:" >> $LOGFILE
uptime >> $LOGFILE

# Check snapshot growth
echo -e "\nSnapshot space usage:" >> $LOGFILE
zfs list -t snapshot -o name,used | tail -10 >> $LOGFILE

# Check replication status
echo -e "\nReplication task status:" >> $LOGFILE
grep "replication" /var/log/messages | grep "$(date -d '7 days ago' +%Y-%m-%d)" | tail -5 >> $LOGFILE

# Check backup task success rate
echo -e "\nBackup task summary:" >> $LOGFILE
SUCCESS_COUNT=$(grep "backup.*SUCCESS" /var/log/messages | grep -c "$(date +%Y-%m)")
FAILED_COUNT=$(grep "backup.*FAILED" /var/log/messages | grep -c "$(date +%Y-%m)")
echo "This month - Successful: $SUCCESS_COUNT, Failed: $FAILED_COUNT" >> $LOGFILE

# Capacity planning
echo -e "\nCapacity planning data:" >> $LOGFILE
zfs list -o name,used,avail,refer | grep -E "tank" >> $LOGFILE

# Security check - failed login attempts
echo -e "\nSecurity review - Failed login attempts this week:" >> $LOGFILE
grep "Failed password" /var/log/auth.log | grep "$(date +%b)" | wc -l >> $LOGFILE

echo -e "\n=== Weekly Maintenance Complete ===" >> $LOGFILE
echo "" >> $LOGFILE

# Send weekly report
tail -50 $LOGFILE | mail -s "TrueNAS Weekly Maintenance Report" $EMAIL
```

Schedule weekly maintenance:
```bash
# Add to root crontab - Sunday at 8 AM
0 8 * * 0 /root/scripts/weekly_maintenance.sh
```

---

## 🔄 Monthly Maintenance Tasks

### System Update Management

**Navigate to**: System → Update

1. **Monthly Update Review Process:**
   ```yaml
   Update Management Process:
   ├── Check for Updates: 1st of every month
   ├── Review Changelog: Understand changes and risks
   ├── Backup Configuration: Before applying updates
   ├── Schedule Downtime: Plan maintenance window
   ├── Apply Updates: During low-usage period
   ├── Verify System: Test all services post-update
   └── Document Changes: Update system documentation
   ```

2. **Pre-Update Checklist:**
   ```bash
   #!/bin/bash
   # Pre-Update Checklist Script
   # /root/scripts/pre_update_checklist.sh
   
   echo "=== Pre-Update System Backup ==="
   
   # Export system configuration
   midclt call system.general.config > /tmp/truenas_config_$(date +%Y%m%d).json
   
   # Create boot environment snapshot
   beadm create pre-update-$(date +%Y%m%d)
   
   # List current boot environments
   beadm list
   
   # Check system health before update
   zpool status
   systemctl --failed
   
   echo "Pre-update backup complete. Ready for update."
   ```

### Security Review

Monthly security assessment:

```bash
#!/bin/bash
# Monthly Security Review Script
# /root/scripts/monthly_security_review.sh

LOGFILE="/var/log/monthly_security_review.log"

echo "=== Monthly Security Review - $(date) ===" >> $LOGFILE

# Check for failed SSH attempts
echo "SSH Security Analysis:" >> $LOGFILE
FAILED_SSH=$(grep "Failed password" /var/log/auth.log | wc -l)
echo "Failed SSH attempts this month: $FAILED_SSH" >> $LOGFILE

# Check for root login attempts (should be none)
ROOT_ATTEMPTS=$(grep "root" /var/log/auth.log | grep -v "sudo" | wc -l)
if [ "$ROOT_ATTEMPTS" -gt "0" ]; then
    echo "WARNING: $ROOT_ATTEMPTS root login attempts detected!" >> $LOGFILE
fi

# Check for unusual network connections
echo -e "\nNetwork Security Analysis:" >> $LOGFILE
netstat -tuln | grep LISTEN >> $LOGFILE

# Review user accounts
echo -e "\nUser Account Review:" >> $LOGFILE
cut -d: -f1,3,6 /etc/passwd | awk -F: '$2 >= 1000 {print}' >> $LOGFILE

# Check file permissions on critical files
echo -e "\nCritical File Permissions:" >> $LOGFILE
ls -la /etc/shadow /etc/passwd /etc/ssh/sshd_config >> $LOGFILE

# Check for available security updates
echo -e "\nSecurity Updates Available:" >> $LOGFILE
apt list --upgradable 2>/dev/null | grep -i security >> $LOGFILE

echo -e "\n=== Security Review Complete ===" >> $LOGFILE
```

### Performance Analysis

Monthly performance review:

```bash
#!/bin/bash
# Monthly Performance Analysis
# /root/scripts/monthly_performance.sh

LOGFILE="/var/log/monthly_performance.log"

echo "=== Monthly Performance Analysis - $(date) ===" >> $LOGFILE

# System resource trends
echo "System Resource Analysis:" >> $LOGFILE
echo "Average load over last month:" >> $LOGFILE
sar -u 1 1 >> $LOGFILE

# Storage performance
echo -e "\nStorage Performance:" >> $LOGFILE
iostat -x 1 1 >> $LOGFILE

# Network performance
echo -e "\nNetwork Statistics:" >> $LOGFILE
cat /proc/net/dev >> $LOGFILE

# ARC efficiency
echo -e "\nARC Efficiency:" >> $LOGFILE
arc_summary | head -20 >> $LOGFILE

# Pool fragmentation
echo -e "\nPool Fragmentation:" >> $LOGFILE
zpool status tank | grep "frag\|scan" >> $LOGFILE

# Capacity growth analysis
echo -e "\nCapacity Growth Analysis:" >> $LOGFILE
zfs list -o name,used,refer | grep tank >> $LOGFILE

echo -e "\n=== Performance Analysis Complete ===" >> $LOGFILE
```

---

## 🧪 Quarterly Maintenance Tasks

### Disaster Recovery Testing

Quarterly disaster recovery drill:

```bash
#!/bin/bash
# Quarterly DR Test Script
# /root/scripts/quarterly_dr_test.sh

LOGFILE="/var/log/quarterly_dr_test.log"
TEST_DIR="/tmp/dr_test_$(date +%Y%m%d)"

echo "=== Quarterly Disaster Recovery Test - $(date) ===" >> $LOGFILE

# Create test directory
mkdir -p $TEST_DIR

# Test 1: Snapshot Restoration
echo "Test 1: Snapshot Restoration" >> $LOGFILE
LATEST_SNAPSHOT=$(zfs list -t snapshot tank/family/documents -o name | tail -1)
echo "Testing restoration from: $LATEST_SNAPSHOT" >> $LOGFILE

# Copy files from snapshot to test directory
cp -r /mnt/tank/family/documents/.zfs/snapshot/*/important_test_file.txt $TEST_DIR/ 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✓ Snapshot restoration: SUCCESS" >> $LOGFILE
else
    echo "✗ Snapshot restoration: FAILED" >> $LOGFILE
fi

# Test 2: Configuration Backup Restore
echo -e "\nTest 2: Configuration Backup" >> $LOGFILE
midclt call system.general.config > $TEST_DIR/config_test.json
if [ -s $TEST_DIR/config_test.json ]; then
    echo "✓ Configuration backup: SUCCESS" >> $LOGFILE
else
    echo "✗ Configuration backup: FAILED" >> $LOGFILE
fi

# Test 3: Cloud Restore (sample files)
echo -e "\nTest 3: Cloud Restore Test" >> $LOGFILE
# Test small restore from cloud backup
rclone copy backblaze:truenas-family-backup-2024/test/ $TEST_DIR/cloud_test/ --max-size 1M
if [ -d "$TEST_DIR/cloud_test" ] && [ "$(ls -A $TEST_DIR/cloud_test)" ]; then
    echo "✓ Cloud restore test: SUCCESS" >> $LOGFILE
else
    echo "✗ Cloud restore test: FAILED" >> $LOGFILE
fi

# Test 4: Network Connectivity Test
echo -e "\nTest 4: Network Connectivity" >> $LOGFILE
ping -c 4 8.8.8.8 > $TEST_DIR/ping_test.txt 2>&1
if [ $? -eq 0 ]; then
    echo "✓ Internet connectivity: SUCCESS" >> $LOGFILE
else
    echo "✗ Internet connectivity: FAILED" >> $LOGFILE
fi

# Cleanup
rm -rf $TEST_DIR

# Generate summary report
echo -e "\n=== DR Test Summary ===" >> $LOGFILE
FAILED_TESTS=$(grep -c "FAILED" $LOGFILE)
PASSED_TESTS=$(grep -c "SUCCESS" $LOGFILE)
echo "Tests Passed: $PASSED_TESTS" >> $LOGFILE
echo "Tests Failed: $FAILED_TESTS" >> $LOGFILE

if [ "$FAILED_TESTS" -gt "0" ]; then
    echo "⚠ DR Test completed with failures - review required" >> $LOGFILE
else
    echo "✓ All DR tests passed successfully" >> $LOGFILE
fi

# Email results
tail -20 $LOGFILE | mail -s "TrueNAS Quarterly DR Test Results" admin@yourdomain.com
```

### Hardware Health Inspection

Quarterly hardware review checklist:

```bash
#!/bin/bash
# Quarterly Hardware Health Check
# /root/scripts/quarterly_hardware_check.sh

LOGFILE="/var/log/quarterly_hardware_check.log"

echo "=== Quarterly Hardware Health Check - $(date) ===" >> $LOGFILE

# Check all drive SMART status
echo "Drive Health Summary:" >> $LOGFILE
for drive in $(lsblk -d -n -o NAME | grep -E '^sd|^nvme'); do
    SMART_STATUS=$(smartctl -H /dev/$drive | grep "SMART overall-health")
    POWER_ON_HOURS=$(smartctl -A /dev/$drive | grep "Power_On_Hours" | awk '{print $10}')
    REALLOCATED=$(smartctl -A /dev/$drive | grep "Reallocated_Sector_Ct" | awk '{print $10}')
    
    echo "Drive $drive:" >> $LOGFILE
    echo "  Health: $SMART_STATUS" >> $LOGFILE
    echo "  Power-on hours: $POWER_ON_HOURS" >> $LOGFILE
    echo "  Reallocated sectors: $REALLOCATED" >> $LOGFILE
done

# Memory test results
echo -e "\nMemory Health:" >> $LOGFILE
if command -v memtester > /dev/null; then
    echo "Running memory test (this may take time)..." >> $LOGFILE
    memtester 1G 1 >> $LOGFILE 2>&1
else
    echo "memtester not available - install for memory testing" >> $LOGFILE
fi

# System temperature monitoring
echo -e "\nSystem Temperatures:" >> $LOGFILE
if command -v sensors > /dev/null; then
    sensors >> $LOGFILE
else
    echo "lm-sensors not configured" >> $LOGFILE
fi

# Network interface statistics
echo -e "\nNetwork Interface Health:" >> $LOGFILE
ethtool eth0 2>/dev/null | grep -E "Speed|Duplex|Link" >> $LOGFILE

echo -e "\n=== Hardware Check Complete ===" >> $LOGFILE
```

---

## 📈 Capacity Planning

### Monthly Capacity Review

```bash
#!/bin/bash
# Monthly Capacity Planning Script
# /root/scripts/capacity_planning.sh

LOGFILE="/var/log/capacity_planning.log"
HISTORY_FILE="/var/log/capacity_history.csv"

echo "=== Monthly Capacity Planning - $(date) ===" >> $LOGFILE

# Current capacity status
CURRENT_DATE=$(date +%Y-%m-%d)
POOL_USED=$(zpool list tank -H -o used | sed 's/[A-Z]//g')
POOL_AVAIL=$(zpool list tank -H -o avail | sed 's/[A-Z]//g')
POOL_CAP=$(zpool list tank -H -o capacity | sed 's/%//')

# Log to CSV for trend analysis
echo "$CURRENT_DATE,$POOL_USED,$POOL_AVAIL,$POOL_CAP" >> $HISTORY_FILE

# Calculate growth rate (simple month-over-month)
if [ -f $HISTORY_FILE ] && [ $(wc -l < $HISTORY_FILE) -gt 1 ]; then
    LAST_MONTH_CAP=$(tail -2 $HISTORY_FILE | head -1 | cut -d, -f4)
    GROWTH_RATE=$((POOL_CAP - LAST_MONTH_CAP))
    
    echo "Current capacity: ${POOL_CAP}%" >> $LOGFILE
    echo "Growth this month: ${GROWTH_RATE}%" >> $LOGFILE
    
    # Project when pool will reach 90% capacity
    if [ "$GROWTH_RATE" -gt "0" ]; then
        MONTHS_TO_90=$((((90 - POOL_CAP) / GROWTH_RATE)))
        if [ "$MONTHS_TO_90" -lt "12" ]; then
            echo "WARNING: Pool will reach 90% capacity in ~$MONTHS_TO_90 months" >> $LOGFILE
        fi
    fi
fi

# Dataset growth analysis
echo -e "\nDataset Growth Analysis:" >> $LOGFILE
zfs list -o name,used | grep tank >> $LOGFILE

# Recommend actions based on capacity
if [ "$POOL_CAP" -gt "75" ]; then
    echo -e "\nRecommended Actions:" >> $LOGFILE
    echo "- Consider adding storage capacity" >> $LOGFILE
    echo "- Review and clean up unnecessary data" >> $LOGFILE
    echo "- Optimize compression settings" >> $LOGFILE
    echo "- Review snapshot retention policies" >> $LOGFILE
fi

echo -e "\n=== Capacity Planning Complete ===" >> $LOGFILE
```

---

## 🛠️ Maintenance Automation

### Master Maintenance Script

Create a master script that coordinates all maintenance tasks:

```bash
#!/bin/bash
# Master Maintenance Coordinator
# /root/scripts/maintenance_coordinator.sh

MAINTENANCE_DIR="/root/scripts"
LOGFILE="/var/log/maintenance_coordinator.log"

echo "=== Maintenance Coordinator - $(date) ===" >> $LOGFILE

# Determine what maintenance to run based on day/date
DAY_OF_WEEK=$(date +%u)  # 1=Monday, 7=Sunday
DAY_OF_MONTH=$(date +%d)

# Daily tasks (run every day)
echo "Running daily maintenance tasks..." >> $LOGFILE
$MAINTENANCE_DIR/daily_health_check.sh

# Weekly tasks (run on Sunday)
if [ "$DAY_OF_WEEK" -eq "7" ]; then
    echo "Running weekly maintenance tasks..." >> $LOGFILE
    $MAINTENANCE_DIR/weekly_maintenance.sh
fi

# Monthly tasks (run on 1st of month)
if [ "$DAY_OF_MONTH" -eq "01" ]; then
    echo "Running monthly maintenance tasks..." >> $LOGFILE
    $MAINTENANCE_DIR/monthly_security_review.sh
    $MAINTENANCE_DIR/monthly_performance.sh
    $MAINTENANCE_DIR/capacity_planning.sh
fi

# Quarterly tasks (run on 1st of quarter)
if [ "$DAY_OF_MONTH" -eq "01" ] && [ "$(date +%m)" -eq "01" -o "$(date +%m)" -eq "04" -o "$(date +%m)" -eq "07" -o "$(date +%m)" -eq "10" ]; then
    echo "Running quarterly maintenance tasks..." >> $LOGFILE
    $MAINTENANCE_DIR/quarterly_dr_test.sh
    $MAINTENANCE_DIR/quarterly_hardware_check.sh
fi

echo "=== Maintenance Coordinator Complete ===" >> $LOGFILE
```

### Maintenance Scheduling

Set up comprehensive maintenance scheduling:

```bash
# Master crontab configuration for maintenance
# Edit with: crontab -e

# Daily health check (7 AM)
0 7 * * * /root/scripts/daily_health_check.sh

# Weekly maintenance (Sunday 8 AM) 
0 8 * * 0 /root/scripts/weekly_maintenance.sh

# Monthly capacity planning (1st of month, 9 AM)
0 9 1 * * /root/scripts/capacity_planning.sh

# Quarterly DR test (1st of quarter, 10 AM)
0 10 1 1,4,7,10 * /root/scripts/quarterly_dr_test.sh

# Master coordinator (runs daily to determine what to execute)
30 6 * * * /root/scripts/maintenance_coordinator.sh
```

---

## 📋 Maintenance Documentation

### Maintenance Log Template

Create standardized maintenance documentation:

```bash
# Maintenance Log Template
# /root/maintenance_logs/maintenance_YYYYMMDD.md

# TrueNAS Maintenance Log
## Date: $(date)
## Technician: [Name]
## Maintenance Type: [Daily/Weekly/Monthly/Quarterly]

### Pre-Maintenance Status
- [ ] System health check completed
- [ ] Backup verification completed  
- [ ] Critical services status confirmed
- [ ] No ongoing maintenance conflicts

### Maintenance Tasks Performed
- [ ] Task 1: Description
- [ ] Task 2: Description
- [ ] Task 3: Description

### Issues Encountered
[Document any problems or unexpected findings]

### Actions Taken
[Document resolution steps]

### Post-Maintenance Verification
- [ ] All services restored to normal operation
- [ ] System health check passed
- [ ] Performance within normal parameters
- [ ] No new alerts generated

### Follow-up Required
[List any items requiring future attention]

### Next Maintenance Due
[Schedule next maintenance activities]
```

---

## ✅ Regular Maintenance Checklist

### Daily Maintenance (Automated):
- [ ] **System health check** script running
- [ ] **SMART short tests** scheduled and executing
- [ ] **Backup verification** automated
- [ ] **Performance monitoring** active
- [ ] **Log rotation** configured
- [ ] **Alert notifications** functioning

### Weekly Maintenance (Semi-Automated):
- [ ] **System updates** checked
- [ ] **SMART long tests** scheduled
- [ ] **Log analysis** performed
- [ ] **Capacity growth** tracked
- [ ] **Security review** basic checks
- [ ] **Performance trends** analyzed

### Monthly Maintenance (Manual):
- [ ] **System updates** applied (if available)
- [ ] **Security review** comprehensive
- [ ] **Performance analysis** detailed
- [ ] **Capacity planning** updated
- [ ] **Documentation** reviewed and updated
- [ ] **Maintenance scripts** reviewed

### Quarterly Maintenance (Manual):
- [ ] **Disaster recovery** testing performed
- [ ] **Hardware health** inspection completed
- [ ] **Full system backup** verified
- [ ] **Security audit** performed
- [ ] **Performance benchmarks** updated
- [ ] **Maintenance procedures** reviewed

---

## 🚀 Next Steps

With regular maintenance established, you're ready for:

**[Common Issues and Troubleshooting](../06-troubleshooting/common-issues.md)** - Handle problems when they arise

---

## 🔧 Maintenance Troubleshooting

### Common Maintenance Issues:

**Problem**: Maintenance scripts not running
- **Solution**: Check crontab syntax, verify script permissions

**Problem**: High maintenance overhead
- **Solution**: Optimize script efficiency, adjust schedules

**Problem**: Maintenance conflicts with production
- **Solution**: Better scheduling, implement maintenance windows

**Problem**: Alert fatigue from maintenance notifications
- **Solution**: Adjust notification levels, filter routine messages

### Maintenance Best Practices:

1. **Document everything** - maintain detailed logs
2. **Test in lab first** - validate procedures safely
3. **Automate routine tasks** - reduce human error
4. **Monitor maintenance effectiveness** - track metrics
5. **Review and improve** - regularly update procedures

---
*Part of the [Complete TrueNAS Setup Guide](../README.md)*
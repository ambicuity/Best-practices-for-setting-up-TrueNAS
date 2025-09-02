# Monitoring Setup

> **Implement comprehensive system health monitoring, alerting, and performance tracking to ensure your TrueNAS system runs reliably 24/7.**

## 🎯 Monitoring Overview

This guide establishes comprehensive monitoring for your TrueNAS system, covering hardware health, storage performance, network activity, and service availability. Proactive monitoring prevents issues and enables quick response to problems.

**Estimated Time**: 2-3 hours  
**Difficulty**: Intermediate  
**Prerequisites**: [Backup Configuration](../04-services/backup-configuration.md) completed

---

## 📊 Monitoring Strategy

### Monitoring Layers

```
TrueNAS Monitoring Stack:
├── Hardware Monitoring
│   ├── SMART drive health tests
│   ├── Temperature monitoring
│   ├── Power supply status
│   └── Network interface health
├── Storage Monitoring  
│   ├── ZFS pool health and scrubs
│   ├── Dataset usage and quotas
│   ├── Snapshot status
│   └── Replication health
├── System Monitoring
│   ├── CPU, memory, and load
│   ├── Network throughput
│   ├── Service availability
│   └── Log analysis
└── Application Monitoring
    ├── Share availability
    ├── Backup task status
    ├── Update status
    └── Security events
```

### Monitoring Objectives

```
Key Performance Indicators (KPIs):
├── Availability: >99.9% uptime
├── Performance: Response time <100ms
├── Capacity: <80% storage utilization
├── Data Integrity: 0 checksum errors
├── Backup Success: >99% successful backups
└── Security: 0 unauthorized access attempts
```

---

## 🔧 SMART Drive Monitoring

### SMART Test Configuration

**Navigate to**: Data Protection → S.M.A.R.T. Tests

#### Daily Short SMART Tests

1. **Short Test Configuration:**
   ```yaml
   SMART Test - Daily Short:
   ├── Disks: Select All Data Drives
   ├── Type: Short
   ├── Description: Daily SMART short test
   ├── Schedule: Daily at 3:00 AM
   ├── Enabled: Yes
   ```

2. **Test Schedule Rationale:**
   - **Short tests**: 5-10 minutes, minimal performance impact
   - **Daily frequency**: Catch issues early
   - **3:00 AM**: Low usage time

#### Weekly Long SMART Tests

1. **Long Test Configuration:**
   ```yaml
   SMART Test - Weekly Long:
   ├── Disks: Select All Data Drives  
   ├── Type: Long
   ├── Description: Weekly SMART extended test
   ├── Schedule: Weekly - Sunday at 2:00 AM
   ├── Enabled: Yes
   ```

2. **Long Test Benefits:**
   - **Comprehensive surface scan**: Detects bad sectors
   - **2-8 hours duration**: Scheduled during low activity
   - **Weekly frequency**: Balances thoroughness with performance

### SMART Monitoring Script

Create automated SMART monitoring:

```bash
#!/bin/bash
# SMART Drive Health Monitoring Script
# /root/scripts/smart_monitor.sh

LOGFILE="/var/log/smart_monitor.log"
EMAIL="admin@yourdomain.com"
ALERT_THRESHOLD=5  # Number of reallocated sectors to trigger alert

echo "=== SMART Drive Health Check - $(date) ===" >> $LOGFILE

# Check all drives
for drive in $(lsblk -d -n -o NAME | grep -E '^sd|^nvme'); do
    echo "Checking drive: /dev/$drive" >> $LOGFILE
    
    # Get SMART status
    SMART_STATUS=$(smartctl -H /dev/$drive | grep "SMART overall-health")
    echo "$drive: $SMART_STATUS" >> $LOGFILE
    
    # Check for reallocated sectors
    REALLOCATED=$(smartctl -A /dev/$drive | grep "Reallocated_Sector_Ct" | awk '{print $10}')
    
    if [ ! -z "$REALLOCATED" ] && [ "$REALLOCATED" -gt "$ALERT_THRESHOLD" ]; then
        echo "WARNING: Drive $drive has $REALLOCATED reallocated sectors!" >> $LOGFILE
        echo "WARNING: Drive $drive has $REALLOCATED reallocated sectors!" | \
            mail -s "TrueNAS SMART Alert - Drive $drive" $EMAIL
    fi
    
    # Check temperature
    TEMP=$(smartctl -A /dev/$drive | grep "Temperature_Celsius" | awk '{print $10}')
    if [ ! -z "$TEMP" ] && [ "$TEMP" -gt "45" ]; then
        echo "WARNING: Drive $drive temperature is ${TEMP}°C" >> $LOGFILE
    fi
done

echo "=== SMART Check Complete ===" >> $LOGFILE
echo "" >> $LOGFILE
```

Make script executable and schedule:
```bash
chmod +x /root/scripts/smart_monitor.sh

# Add to crontab
crontab -e
# Add line: 0 4 * * * /root/scripts/smart_monitor.sh
```

---

## 🏊 ZFS Pool Health Monitoring

### Scrub Configuration

**Navigate to**: Data Protection → Scrub Tasks

1. **Monthly Pool Scrub:**
   ```yaml
   Pool Scrub Configuration:
   ├── Pool: tank
   ├── Threshold days: 35 (skip if recent scrub)
   ├── Description: Monthly pool scrub for data integrity
   ├── Schedule: Monthly - 1st Sunday at 1:00 AM
   ├── Enabled: Yes
   ```

2. **Scrub Monitoring:**
   ```bash
   #!/bin/bash
   # ZFS Scrub Status Monitoring
   
   echo "=== ZFS Pool Health Check - $(date) ==="
   
   # Check pool status
   zpool status
   
   # Check scrub status
   zpool status tank | grep -A5 "scan:"
   
   # Check for errors
   ERROR_COUNT=$(zpool status tank | grep "errors:" | awk '{print $2}')
   if [ "$ERROR_COUNT" != "No" ]; then
       echo "ERROR: Pool has errors - $ERROR_COUNT" | \
           mail -s "TrueNAS Pool Error Alert" admin@yourdomain.com
   fi
   
   # Check pool capacity
   CAPACITY=$(zpool list tank -H -o capacity | sed 's/%//')
   if [ "$CAPACITY" -gt "80" ]; then
       echo "WARNING: Pool capacity at ${CAPACITY}%" | \
           mail -s "TrueNAS Capacity Warning" admin@yourdomain.com
   fi
   ```

### ZFS Event Monitoring

Enable ZFS Event Daemon (ZED) for real-time monitoring:

```bash
# Configure ZFS Event Daemon
# Edit /etc/zfs/zed.d/zed.rc

# Email notifications
ZED_EMAIL_ADDR="admin@yourdomain.com"
ZED_EMAIL_PROG="/usr/bin/mail"
ZED_EMAIL_OPTS=""

# Notification settings
ZED_NOTIFY_INTERVAL_SECS=3600
ZED_NOTIFY_VERBOSE=1

# Enable specific notifications
ZED_RESILVER_MIN_TIME_MS=900000
ZED_SCRUB_MIN_TIME_MS=1800000

# Restart ZED service
systemctl restart zfs-zed
systemctl enable zfs-zed
```

---

## 📈 System Performance Monitoring

### Built-in TrueNAS Monitoring

**Navigate to**: System → Reporting

1. **Enable System Reporting:**
   - **Reporting Database**: Enable
   - **Graph Points**: 1200 (higher resolution)
   - **Confirm RRD Destroy**: Understand data loss implications

2. **Available Metrics:**
   - **CPU Usage**: Per-core utilization
   - **Memory**: ARC, system memory usage
   - **Network**: Interface throughput and errors
   - **Storage**: Disk I/O, pool operations
   - **Load Average**: System load over time

### Custom System Monitoring Script

```bash
#!/bin/bash
# System Performance Monitoring Script
# /root/scripts/system_monitor.sh

LOGFILE="/var/log/system_monitor.log"

echo "=== System Performance Check - $(date) ===" >> $LOGFILE

# CPU Load
LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
echo "Load Average (1m): $LOAD_AVG" >> $LOGFILE

# Memory Usage
MEM_USAGE=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
echo "Memory Usage: ${MEM_USAGE}%" >> $LOGFILE

# ARC Usage
ARC_SIZE=$(arc_summary | grep "ARC size" | awk '{print $4, $5}')
ARC_HIT_RATIO=$(arc_summary | grep "Cache hit ratio" | awk '{print $4}')
echo "ARC Size: $ARC_SIZE" >> $LOGFILE
echo "ARC Hit Ratio: $ARC_HIT_RATIO" >> $LOGFILE

# Disk I/O
echo "Disk I/O Statistics:" >> $LOGFILE
iostat -x 1 1 | grep -E "^sd|^nvme" >> $LOGFILE

# Network Statistics
echo "Network Interface Statistics:" >> $LOGFILE
cat /proc/net/dev | grep -E "eth|enp" >> $LOGFILE

# Service Status
echo "Critical Services Status:" >> $LOGFILE
systemctl is-active smbd >> $LOGFILE 2>&1
systemctl is-active nfs-server >> $LOGFILE 2>&1
systemctl is-active ssh >> $LOGFILE 2>&1

echo "=== Performance Check Complete ===" >> $LOGFILE
echo "" >> $LOGFILE

# Check for performance issues
if (( $(echo "$LOAD_AVG > 4.0" | bc -l) )); then
    echo "HIGH LOAD ALERT: Load average is $LOAD_AVG" | \
        mail -s "TrueNAS High Load Alert" admin@yourdomain.com
fi

if (( $(echo "$MEM_USAGE > 90" | bc -l) )); then
    echo "HIGH MEMORY USAGE: Memory at ${MEM_USAGE}%" | \
        mail -s "TrueNAS Memory Alert" admin@yourdomain.com
fi
```

---

## 🚨 Alert Configuration

### Email Alert Setup

**Navigate to**: System → Email

Ensure email is properly configured (completed in Initial Setup), then configure alerts.

### Alert Services Configuration

**Navigate to**: System → Alert Services

1. **Email Alert Service:**
   ```yaml
   Email Alert Configuration:
   ├── Name: Primary Email Alerts
   ├── Type: Email
   ├── Level: INFO (or WARNING for fewer alerts)
   ├── To: admin@yourdomain.com, backup@yourdomain.com
   └── Enabled: Yes
   ```

2. **Slack Integration (Optional):**
   ```yaml
   Slack Alert Configuration:
   ├── Name: Slack Notifications
   ├── Type: Slack
   ├── Level: WARNING
   ├── Webhook URL: https://hooks.slack.com/your-webhook
   ├── Channel: #truenas-alerts
   ├── Username: TrueNAS-Bot
   └── Enabled: Yes
   ```

### Alert Rules Configuration

**Navigate to**: System → Alert Settings

1. **Critical Alert Rules:**
   ```yaml
   Critical Alerts (Always Enable):
   ├── Pool status is not healthy: CRITICAL
   ├── Disk temperature is above threshold: WARNING
   ├── SMART test failed: CRITICAL
   ├── Scrub finished: INFO
   ├── Resilver finished: INFO
   ├── Pool space usage > 80%: WARNING
   ├── Pool space usage > 95%: CRITICAL
   ├── Replication task failed: WARNING
   └── System update available: INFO
   ```

2. **Custom Alert Thresholds:**
   - **Pool Capacity Warning**: 80%
   - **Pool Capacity Critical**: 95%
   - **Drive Temperature Warning**: 45°C
   - **Drive Temperature Critical**: 50°C
   - **Load Average Warning**: 4.0
   - **Memory Usage Warning**: 90%

---

## 📊 Advanced Monitoring with External Tools

### Prometheus and Grafana Integration

#### TrueNAS SCALE Prometheus Exporter

1. **Enable Prometheus Exporter:**
   ```bash
   # Install node_exporter for system metrics
   apt update
   apt install prometheus-node-exporter
   
   # Start and enable service
   systemctl start prometheus-node-exporter
   systemctl enable prometheus-node-exporter
   
   # Verify exporter is running
   curl http://localhost:9100/metrics
   ```

2. **ZFS Prometheus Exporter:**
   ```bash
   #!/bin/bash
   # ZFS Metrics Exporter Script
   # /root/scripts/zfs_exporter.sh
   
   METRICS_FILE="/tmp/zfs_metrics.prom"
   
   # Pool health metrics
   echo "# HELP zfs_pool_health Pool health status (1=online, 0=offline)" > $METRICS_FILE
   echo "# TYPE zfs_pool_health gauge" >> $METRICS_FILE
   
   zpool list -H -o name,health | while read name health; do
       if [ "$health" = "ONLINE" ]; then
           echo "zfs_pool_health{pool=\"$name\"} 1" >> $METRICS_FILE
       else
           echo "zfs_pool_health{pool=\"$name\"} 0" >> $METRICS_FILE
       fi
   done
   
   # Pool capacity metrics
   echo "# HELP zfs_pool_capacity_percent Pool capacity percentage" >> $METRICS_FILE
   echo "# TYPE zfs_pool_capacity_percent gauge" >> $METRICS_FILE
   
   zpool list -H -o name,capacity | while read name capacity; do
       capacity_num=$(echo $capacity | sed 's/%//')
       echo "zfs_pool_capacity_percent{pool=\"$name\"} $capacity_num" >> $METRICS_FILE
   done
   
   # Serve metrics via simple HTTP server
   python3 -m http.server 9101 --directory /tmp &
   ```

#### Grafana Dashboard Configuration

Sample Grafana dashboard JSON for TrueNAS monitoring:

```json
{
  "dashboard": {
    "title": "TrueNAS System Monitoring",
    "panels": [
      {
        "title": "Pool Health Status",
        "type": "stat",
        "targets": [
          {
            "expr": "zfs_pool_health",
            "legendFormat": "{{pool}}"
          }
        ]
      },
      {
        "title": "Pool Capacity",
        "type": "graph",
        "targets": [
          {
            "expr": "zfs_pool_capacity_percent",
            "legendFormat": "{{pool}}"
          }
        ]
      },
      {
        "title": "System Load",
        "type": "graph", 
        "targets": [
          {
            "expr": "node_load1",
            "legendFormat": "1m load"
          }
        ]
      },
      {
        "title": "Memory Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "100 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes * 100)",
            "legendFormat": "Memory Usage %"
          }
        ]
      }
    ]
  }
}
```

### SNMP Monitoring Integration

**Navigate to**: Services → SNMP

1. **Enable SNMP Service:**
   ```yaml
   SNMP Configuration:
   ├── Location: Server Room A
   ├── Contact: admin@yourdomain.com
   ├── Community: public (change for security)
   ├── SNMP v3 Support: Enable (preferred)
   ├── Username: snmp-monitor
   ├── Authentication Type: SHA
   ├── Privacy Protocol: AES
   └── Enabled: Yes
   ```

2. **SNMP Monitoring with LibreNMS/Zabbix:**
   ```bash
   # Test SNMP connectivity
   snmpwalk -v2c -c public 192.168.1.100 1.3.6.1.2.1.1
   
   # Get system information
   snmpget -v2c -c public 192.168.1.100 1.3.6.1.2.1.1.1.0
   ```

---

## 📱 Mobile Monitoring

### TrueNAS Mobile App

1. **Install TrueNAS Mobile App:**
   - iOS: Download from App Store
   - Android: Download from Google Play Store

2. **Configure Mobile Access:**
   - **Server Address**: https://192.168.1.100
   - **Username**: admin
   - **Password**: Your admin password
   - **Two-Factor Authentication**: Enable for security

3. **Mobile Monitoring Features:**
   - Real-time system status
   - Pool health and capacity
   - Active alerts and notifications
   - Basic system controls
   - Push notifications (configure in app)

### SMS Alerts (Advanced)

Configure SMS alerts for critical issues:

```bash
#!/bin/bash
# SMS Alert Script using Twilio API
# /root/scripts/sms_alert.sh

TWILIO_SID="your-account-sid"
TWILIO_TOKEN="your-auth-token"
FROM_NUMBER="+1234567890"
TO_NUMBER="+0987654321"

MESSAGE="$1"

curl -X POST https://api.twilio.com/2010-04-01/Accounts/$TWILIO_SID/Messages.json \
    --data-urlencode "To=$TO_NUMBER" \
    --data-urlencode "From=$FROM_NUMBER" \
    --data-urlencode "Body=$MESSAGE" \
    --user $TWILIO_SID:$TWILIO_TOKEN
```

Integrate with monitoring scripts:
```bash
# In critical alert sections
if [ "$CRITICAL_CONDITION" = true ]; then
    /root/scripts/sms_alert.sh "CRITICAL: TrueNAS pool failure detected!"
fi
```

---

## 📋 Monitoring Dashboard

### Daily Monitoring Checklist

Create a daily health check dashboard:

```bash
#!/bin/bash
# Daily Health Dashboard
# /root/scripts/daily_dashboard.sh

echo "============================================"
echo "TrueNAS Daily Health Dashboard - $(date)"
echo "============================================"

# System Uptime
echo -e "\n=== SYSTEM STATUS ==="
echo "Uptime: $(uptime -p)"
echo "Load: $(uptime | awk -F'load average:' '{print $2}')"

# Pool Status
echo -e "\n=== STORAGE STATUS ==="
zpool list
echo -e "\nPool Health:"
zpool status | grep -E "pool:|state:|errors:"

# Recent Alerts
echo -e "\n=== RECENT ALERTS ==="
journalctl --since "24 hours ago" | grep -i "error\|warning\|failed" | tail -5

# Backup Status
echo -e "\n=== BACKUP STATUS ==="
echo "Last Snapshots:"
zfs list -t snapshot | tail -3

echo "Recent Replication Tasks:"
grep "replication" /var/log/messages | tail -3

# Network Status
echo -e "\n=== NETWORK STATUS ==="
echo "Interface Status:"
ip link show | grep -E "eth|enp" | grep -o "^[0-9]*: [^:]*" | grep -o "[^:]*$"

# Service Status
echo -e "\n=== SERVICE STATUS ==="
services=("smbd" "nfs-server" "ssh" "truenas-middlewared")
for service in "${services[@]}"; do
    status=$(systemctl is-active $service)
    echo "$service: $status"
done

# Disk Usage
echo -e "\n=== DISK USAGE ==="
df -h | grep -E "tank|boot"

echo -e "\n============================================"
echo "Dashboard Generation Complete"
echo "============================================"
```

Schedule daily dashboard:
```bash
# Add to crontab
0 8 * * * /root/scripts/daily_dashboard.sh | mail -s "TrueNAS Daily Report" admin@yourdomain.com
```

---

## 🎯 Performance Baselines

### Establish Performance Benchmarks

Create baseline performance tests:

```bash
#!/bin/bash
# Performance Baseline Test
# /root/scripts/performance_baseline.sh

RESULTS_DIR="/root/performance_baselines"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $RESULTS_DIR

echo "Starting performance baseline test - $DATE"

# CPU Baseline
echo "Running CPU benchmark..."
sysbench cpu --cpu-max-prime=20000 run > "$RESULTS_DIR/cpu_$DATE.txt"

# Memory Baseline  
echo "Running memory benchmark..."
sysbench memory --memory-total-size=10G run > "$RESULTS_DIR/memory_$DATE.txt"

# Disk I/O Baseline
echo "Running disk I/O benchmark..."
sysbench fileio --file-total-size=1G prepare
sysbench fileio --file-total-size=1G --file-test-mode=rndrw run > "$RESULTS_DIR/disk_$DATE.txt"
sysbench fileio cleanup

# Network Baseline (if iperf3 available)
if command -v iperf3 > /dev/null; then
    echo "Running network benchmark..."
    timeout 30 iperf3 -s > /dev/null 2>&1 &
    sleep 2
    iperf3 -c localhost -t 10 > "$RESULTS_DIR/network_$DATE.txt"
    killall iperf3
fi

echo "Baseline test complete. Results saved to $RESULTS_DIR/"
```

### Performance Trend Analysis

```bash
#!/bin/bash
# Performance Trend Analysis
# /root/scripts/performance_trends.sh

echo "=== Performance Trend Analysis ==="
echo "Date: $(date)"

# Analyze recent performance data
BASELINE_DIR="/root/performance_baselines"
RECENT_TESTS=$(ls -t $BASELINE_DIR/cpu_*.txt | head -5)

echo -e "\nRecent CPU Performance Trends:"
for test in $RECENT_TESTS; do
    date=$(basename $test | cut -d'_' -f2-3 | cut -d'.' -f1)
    result=$(grep "events per second" $test | awk '{print $4}')
    echo "$date: $result events/sec"
done

# Similar analysis for memory, disk, network...
```

---

## ✅ Monitoring Setup Checklist

### Hardware Monitoring:
- [ ] **SMART tests** scheduled (daily short, weekly long)
- [ ] **Temperature monitoring** configured with thresholds
- [ ] **Drive health alerts** enabled
- [ ] **Power supply monitoring** active (if supported)
- [ ] **Network interface monitoring** enabled

### Storage Monitoring:
- [ ] **ZFS scrubs** scheduled monthly
- [ ] **Pool health alerts** configured
- [ ] **Capacity monitoring** with 80%/95% thresholds
- [ ] **Snapshot monitoring** for backup verification
- [ ] **Replication status** monitoring active

### System Monitoring:
- [ ] **Performance baselines** established
- [ ] **Load average monitoring** configured
- [ ] **Memory usage alerts** set up
- [ ] **Network throughput monitoring** active
- [ ] **Service availability** monitoring enabled

### Alert and Notification:
- [ ] **Email alerts** properly configured and tested
- [ ] **Alert thresholds** set appropriately
- [ ] **Critical vs warning** levels configured
- [ ] **Mobile notifications** set up (if desired)
- [ ] **Escalation procedures** documented

### Reporting and Analysis:
- [ ] **Daily health dashboard** automated
- [ ] **Weekly performance reports** scheduled
- [ ] **Monthly capacity planning** review
- [ ] **Performance trends** analysis active
- [ ] **Documentation** updated with procedures

---

## 🚀 Next Steps

With monitoring configured, you're ready to:

**[Regular Maintenance](regular-maintenance.md)** - Establish maintenance schedules and procedures

---

## 🔧 Monitoring Troubleshooting

### Common Monitoring Issues:

**Problem**: SMART tests not running
- **Solution**: Check disk compatibility, verify test schedules

**Problem**: Email alerts not sending
- **Solution**: Test SMTP configuration, check spam filters

**Problem**: High false positive alerts
- **Solution**: Adjust alert thresholds, review notification levels

**Problem**: Performance degradation not detected
- **Solution**: Lower monitoring intervals, add more metrics

### Alert Tuning:

**Reducing Alert Fatigue:**
1. **Prioritize alerts** by business impact
2. **Group similar alerts** to reduce noise
3. **Use escalation levels** (info → warning → critical)
4. **Regular threshold review** and adjustment
5. **Document alert response** procedures

---
*Part of the [Complete TrueNAS Setup Guide](../README.md)*
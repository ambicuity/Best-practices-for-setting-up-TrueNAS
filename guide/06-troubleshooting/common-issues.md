# Common Issues

> **Comprehensive troubleshooting guide for the most frequent TrueNAS problems, with step-by-step solutions and prevention strategies.**

## 🎯 Troubleshooting Overview

This guide covers the most common issues encountered with TrueNAS systems, providing systematic approaches to diagnosis and resolution. Each issue includes symptoms, causes, solutions, and prevention strategies.

**Difficulty**: Beginner to Advanced  
**Prerequisites**: Basic TrueNAS knowledge

---

## 🚨 Emergency Troubleshooting Quick Reference

### Critical Issue Priority Matrix

```
Issue Severity Levels:
├── CRITICAL (System Down)
│   ├── Pool failed/offline
│   ├── System won't boot
│   ├── All services unavailable
│   └── Data corruption detected
├── HIGH (Major Service Impact)
│   ├── Primary service down (SMB/NFS)
│   ├── Network connectivity lost
│   ├── Drive failure in degraded pool
│   └── Backup failures
├── MEDIUM (Performance/Feature Impact)
│   ├── Performance degradation
│   ├── Non-critical service issues
│   ├── Warning alerts
│   └── Scheduled task failures
└── LOW (Cosmetic/Minor Issues)
    ├── UI glitches
    ├── Information alerts
    ├── Minor configuration issues
    └── Documentation updates needed
```

### Emergency Response Steps

1. **Assess Scope**: Determine impact and affected systems
2. **Immediate Stabilization**: Stop further damage
3. **Root Cause Analysis**: Identify underlying issue
4. **Implement Solution**: Apply appropriate fix
5. **Verify Resolution**: Test functionality
6. **Document**: Record issue and resolution

---

## 💾 Storage and Pool Issues

### Pool Won't Import/Mount

**Symptoms:**
- Pool shows as "UNAVAIL" or not visible
- Error messages about missing devices
- Data inaccessible through shares

**Common Causes:**
- Drive connection issues
- Drive failure
- Corrupted pool metadata
- Hardware changes

**Diagnosis Steps:**
```bash
# Check physical drive detection
lsblk
dmesg | grep -i error

# Check pool import status
zpool import

# Check pool status
zpool status

# Check for force import options
zpool import -f tank
```

**Solutions:**

1. **Drive Connection Issues:**
   ```bash
   # Check all SATA/SAS connections
   # Reseat cables and drives
   
   # Scan for new devices
   echo "- - -" > /sys/class/scsi_host/host*/scan
   
   # Check if drives are now detected
   lsblk
   
   # Try importing pool again
   zpool import tank
   ```

2. **Single Drive Failure in Redundant Pool:**
   ```bash
   # Check pool status
   zpool status tank
   
   # If pool is degraded but functional
   # Replace failed drive immediately
   zpool replace tank old-device new-device
   
   # Monitor resilver progress
   watch zpool status tank
   ```

3. **Pool Corruption (Use Carefully):**
   ```bash
   # Only if you understand the risks and have backups
   zpool import -f -R /mnt tank
   
   # If successful, immediately backup critical data
   # Then run scrub to check integrity
   zpool scrub tank
   ```

**Prevention:**
- Use redundant pool configurations (RAIDZ1/2, mirrors)
- Monitor drive health with SMART tests
- Maintain hot spares
- Regular pool scrubs

### Pool Performance Issues

**Symptoms:**
- Slow file transfers
- High I/O wait times
- Timeouts in applications
- Poor ARC hit ratios

**Diagnosis:**
```bash
# Check current I/O activity
iostat -x 1 5

# Check pool I/O stats
zpool iostat tank 1 5

# Check ARC statistics
arc_summary

# Check for fragmentation
zpool status tank | grep frag

# Check for ongoing operations
zpool status tank | grep scan
```

**Solutions:**

1. **Poor ARC Hit Ratio:**
   ```bash
   # Check current ARC usage
   arc_summary | head -20
   
   # If ARC is too small, increase it
   # Edit /etc/modprobe.d/zfs.conf
   options zfs zfs_arc_max=8589934592  # 8GB example
   
   # Restart system or reload ZFS module
   ```

2. **High Fragmentation:**
   ```bash
   # Check fragmentation level
   zpool status tank
   
   # If fragmentation >30%, consider:
   # - Adding L2ARC devices for read cache
   # - Scheduling regular scrubs
   # - Optimizing record sizes for workload
   ```

3. **Record Size Mismatch:**
   ```bash
   # Check current record sizes
   zfs get recordsize tank/dataset
   
   # Optimize for workload:
   # Large files (photos, videos): 1M
   zfs set recordsize=1M tank/media
   
   # Small files (databases): 16K
   zfs set recordsize=16K tank/apps
   
   # Mixed workloads: 128K
   zfs set recordsize=128K tank/general
   ```

### Drive Failures

**Symptoms:**
- SMART test failures
- Pool degraded state
- I/O errors in logs
- Unusual drive noises

**Immediate Actions:**
```bash
# Check pool status immediately
zpool status

# Check SMART status of all drives
for drive in $(lsblk -d -n -o NAME | grep -E '^sd|^nvme'); do
    echo "=== Drive: $drive ==="
    smartctl -H /dev/$drive
    smartctl -a /dev/$drive | grep -E "Reallocated|Current_Pending|Offline_Uncorrectable"
done

# Check system logs for drive errors
dmesg | grep -i error
journalctl | grep -i "I/O error\|drive\|disk"
```

**Drive Replacement Process:**
```bash
# 1. Identify failed drive by serial number
zpool status -v tank

# 2. Physically identify drive (use LED identification if available)
# 3. Power down system (if hot-swap not supported)
# 4. Replace physical drive
# 5. Boot system and verify new drive detection
lsblk

# 6. Replace drive in pool
zpool replace tank old-device-id /dev/new-device

# 7. Monitor resilver progress
watch "zpool status tank"

# 8. Verify pool health after resilver
zpool status tank
zpool scrub tank
```

---

## 🌐 Network Connectivity Issues

### Cannot Access Web Interface

**Symptoms:**
- Browser cannot connect to TrueNAS
- Connection timeout errors
- SSL certificate errors
- Wrong IP address displayed

**Diagnosis:**
```bash
# From TrueNAS console:
# Check IP configuration
ip addr show

# Check if web service is running
systemctl status truenas-middlewared

# Check listening ports
netstat -tuln | grep :80
netstat -tuln | grep :443

# Test network connectivity
ping 8.8.8.8
ping gateway-ip

# From client machine:
# Test basic connectivity
ping truenas-ip

# Test specific ports
telnet truenas-ip 80
telnet truenas-ip 443
```

**Solutions:**

1. **IP Configuration Issues:**
   ```bash
   # From TrueNAS console menu
   # Select: Configure Network Interfaces
   # Reconfigure IP address if incorrect
   
   # Or manually:
   ip addr add 192.168.1.100/24 dev eth0
   route add default gw 192.168.1.1
   ```

2. **Web Service Not Running:**
   ```bash
   # Restart web services
   systemctl restart truenas-middlewared
   
   # Check for errors
   journalctl -u truenas-middlewared -f
   ```

3. **Firewall Blocking Access:**
   ```bash
   # Temporarily disable firewall for testing
   ufw disable
   
   # Or add specific rules
   ufw allow from 192.168.1.0/24 to any port 443
   ```

### SMB/NFS Share Access Issues

**Symptoms:**
- Shares not visible in network browser
- Access denied errors
- Authentication failures
- Mount timeouts

**SMB Troubleshooting:**
```bash
# Check SMB service status
systemctl status smbd nmbd

# Test SMB connectivity locally
smbclient -L localhost -U username

# Check SMB configuration
testparm -s

# Check SMB logs
tail -f /var/log/samba/smbd.log

# Test from client
smbclient //truenas-ip/sharename -U username
```

**NFS Troubleshooting:**
```bash
# Check NFS service status
systemctl status nfs-server

# Check NFS exports
exportfs -v
showmount -e localhost

# Check NFS logs
journalctl -u nfs-server -f

# Test from client
showmount -e truenas-ip
mount -t nfs truenas-ip:/path/to/export /mnt/test
```

**Common Solutions:**

1. **Permission Issues:**
   ```bash
   # Check dataset permissions
   ls -la /mnt/tank/sharename
   
   # Fix ownership
   chown -R user:group /mnt/tank/sharename
   
   # Fix permissions
   chmod -R 755 /mnt/tank/sharename
   ```

2. **Service Configuration:**
   ```bash
   # Restart services
   systemctl restart smbd nmbd
   systemctl restart nfs-server
   
   # Check service binding
   netstat -tuln | grep -E ":445|:2049"
   ```

---

## 🔐 Authentication and Access Issues

### Cannot Login to Web Interface

**Symptoms:**
- Login credentials rejected
- Two-factor authentication not working
- Account locked messages
- Session timeout issues

**Diagnosis:**
```bash
# Check user account status
midclt call user.query '[["username","=","admin"]]'

# Check authentication logs
tail -f /var/log/auth.log

# Check web interface logs
journalctl -u truenas-middlewared | grep -i auth

# Check 2FA status (if enabled)
midclt call auth.twofactor.config
```

**Solutions:**

1. **Password Reset from Console:**
   ```bash
   # From TrueNAS console menu
   # Select: Reset Root Password
   # Follow prompts to reset
   
   # Or reset specific user
   passwd username
   ```

2. **Disable 2FA (Emergency):**
   ```bash
   # From console/SSH
   midclt call auth.twofactor.update '{"enabled": false}'
   
   # Restart middleware
   systemctl restart truenas-middlewared
   ```

3. **Clear Failed Login Attempts:**
   ```bash
   # Check for account lockouts
   midclt call user.query '[["username","=","admin"]]' | grep locked
   
   # Unlock account if locked
   midclt call user.update admin '{"locked": false}'
   ```

### SSH Connection Issues

**Symptoms:**
- SSH connection refused
- Authentication failures
- Key authentication not working
- Connection timeouts

**Diagnosis:**
```bash
# Check SSH service status
systemctl status ssh

# Check SSH configuration
sshd -T

# Check SSH logs
tail -f /var/log/auth.log | grep ssh

# Test SSH locally
ssh localhost

# Check listening ports
netstat -tuln | grep :22
```

**Solutions:**

1. **SSH Service Issues:**
   ```bash
   # Restart SSH service
   systemctl restart ssh
   
   # Check configuration syntax
   sshd -t
   
   # If configuration errors, restore default:
   cp /etc/ssh/sshd_config.backup /etc/ssh/sshd_config
   ```

2. **Key Authentication Problems:**
   ```bash
   # Check authorized_keys file
   ls -la ~/.ssh/authorized_keys
   cat ~/.ssh/authorized_keys
   
   # Fix permissions
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/authorized_keys
   chown user:user ~/.ssh ~/.ssh/authorized_keys
   ```

3. **Connection Refused:**
   ```bash
   # Check if SSH is listening
   ss -tlnp | grep :22
   
   # Check firewall
   ufw status | grep 22
   
   # Check hosts.deny/hosts.allow
   cat /etc/hosts.deny
   cat /etc/hosts.allow
   ```

---

## ⚡ Performance Problems

### System Running Slowly

**Symptoms:**
- High system load
- Slow response times
- Application timeouts
- UI sluggishness

**Diagnosis:**
```bash
# Check system load
uptime
top
htop

# Check memory usage
free -h
vmstat 1 5

# Check I/O wait
iostat -x 1 5

# Check processes
ps aux --sort=-%cpu | head -20
ps aux --sort=-%mem | head -20

# Check ZFS ARC usage
arc_summary
```

**Solutions:**

1. **High CPU Usage:**
   ```bash
   # Identify CPU-intensive processes
   top -o %CPU
   
   # If ZFS-related, check for ongoing operations
   zpool status | grep scan
   
   # Consider process priority adjustments
   renice -n 10 -p process-id
   ```

2. **Memory Issues:**
   ```bash
   # Check for memory leaks
   free -h
   vmstat 1 5
   
   # Adjust ARC size if needed
   echo 4294967296 > /sys/module/zfs/parameters/zfs_arc_max
   
   # Add swap if none exists (emergency)
   fallocate -l 2G /swapfile
   chmod 600 /swapfile
   mkswap /swapfile
   swapon /swapfile
   ```

3. **I/O Bottlenecks:**
   ```bash
   # Check which processes are causing I/O
   iotop
   
   # Check pool performance
   zpool iostat tank 1 5
   
   # Check for fragmentation
   zpool status tank | grep frag
   
   # Consider adding L2ARC or SLOG devices
   ```

### Network Performance Issues

**Symptoms:**
- Slow file transfers
- Network timeouts
- High latency
- Packet loss

**Diagnosis:**
```bash
# Check network interface status
ip link show
ethtool eth0

# Check network statistics
cat /proc/net/dev
netstat -i

# Test bandwidth
iperf3 -s  # On server
iperf3 -c server-ip -t 30  # From client

# Check for errors
dmesg | grep -i network
journalctl | grep -i network
```

**Solutions:**

1. **Interface Configuration:**
   ```bash
   # Check duplex and speed settings
   ethtool eth0
   
   # Force specific settings if auto-negotiation fails
   ethtool -s eth0 speed 1000 duplex full autoneg on
   
   # Check MTU settings
   ip link show eth0
   
   # Set jumbo frames if supported
   ip link set dev eth0 mtu 9000
   ```

2. **Network Optimization:**
   ```bash
   # Optimize TCP settings
   echo 'net.core.rmem_max = 16777216' >> /etc/sysctl.conf
   echo 'net.core.wmem_max = 16777216' >> /etc/sysctl.conf
   echo 'net.ipv4.tcp_rmem = 4096 16384 16777216' >> /etc/sysctl.conf
   echo 'net.ipv4.tcp_wmem = 4096 16384 16777216' >> /etc/sysctl.conf
   
   sysctl -p
   ```

---

## 🔄 Backup and Replication Failures

### Snapshot Creation Failures

**Symptoms:**
- Snapshot tasks showing failed status
- "Out of space" errors
- Snapshot inconsistencies
- Old snapshots not cleaning up

**Diagnosis:**
```bash
# Check snapshot task logs
journalctl | grep snapshot

# Check available space
zfs list -o name,used,avail

# Check snapshot space usage
zfs list -t snapshot -o name,used,refer

# Check for holds on snapshots
zfs holds
```

**Solutions:**

1. **Space Issues:**
   ```bash
   # Clean up old snapshots manually
   zfs list -t snapshot | grep old-pattern | awk '{print $1}' | xargs -n1 zfs destroy
   
   # Adjust retention policies
   # Navigate to Data Protection → Periodic Snapshot Tasks
   # Reduce retention periods
   
   # Check for datasets with no space limit
   zfs get quota,reservation
   ```

2. **Snapshot Task Configuration:**
   ```bash
   # Review snapshot task configuration
   midclt call pool.snapshottask.query
   
   # Check for conflicting schedules
   # Ensure tasks don't overlap
   
   # Test manual snapshot creation
   zfs snapshot tank/dataset@test-$(date +%Y%m%d)
   ```

### Replication Task Failures

**Symptoms:**
- Replication tasks showing failed
- Authentication errors
- Network timeouts
- Target dataset issues

**Diagnosis:**
```bash
# Check replication task logs
journalctl | grep replication

# Test SSH connectivity to remote system
ssh replication-user@remote-host

# Check target system availability
ping remote-host

# Check available space on target
ssh replication-user@remote-host 'zfs list -o name,used,avail'
```

**Solutions:**

1. **Authentication Issues:**
   ```bash
   # Regenerate SSH keys
   ssh-keygen -t ed25519 -f /root/.ssh/replication_key
   
   # Copy public key to remote system
   ssh-copy-id -i /root/.ssh/replication_key.pub replication-user@remote-host
   
   # Test key authentication
   ssh -i /root/.ssh/replication_key replication-user@remote-host
   ```

2. **Network Issues:**
   ```bash
   # Test network connectivity
   ping remote-host
   traceroute remote-host
   
   # Test bandwidth
   iperf3 -c remote-host
   
   # Adjust bandwidth limits if needed
   # Navigate to Data Protection → Replication Tasks
   ```

---

## 📊 System Update Issues

### Update Installation Failures

**Symptoms:**
- Update process hangs or fails
- System becomes unbootable after update
- Services not working after update
- New features not available

**Diagnosis:**
```bash
# Check update status
midclt call system.update.get_pending

# Check update logs
journalctl | grep update

# Check boot environments
beadm list

# Check system version
cat /etc/version
```

**Solutions:**

1. **Failed Update Recovery:**
   ```bash
   # Boot from previous boot environment
   # At boot menu, select previous BE
   
   # Or activate previous BE manually
   beadm list
   beadm activate previous-be-name
   reboot
   ```

2. **Stuck Update Process:**
   ```bash
   # Check for hung processes
   ps aux | grep update
   
   # Kill hung update processes (carefully)
   kill -9 update-process-id
   
   # Restart update service
   systemctl restart truenas-middlewared
   ```

3. **Post-Update Issues:**
   ```bash
   # Check service status
   systemctl --failed
   
   # Restart failed services
   systemctl restart service-name
   
   # Check configuration compatibility
   testparm -s  # For SMB
   exportfs -v  # For NFS
   ```

---

## 🔧 Hardware Problems

### Drive Not Detected

**Symptoms:**
- Drive missing from storage list
- BIOS doesn't see drive
- Pool shows missing device
- New drive not appearing

**Diagnosis:**
```bash
# Check physical connections
# Verify power and data cables

# Check BIOS/UEFI detection
# Boot into BIOS and check storage devices

# Check system detection
lsblk
fdisk -l
dmesg | grep -i sata
dmesg | grep -i nvme

# Check for driver issues
lsmod | grep -E "sata|nvme|scsi"
```

**Solutions:**

1. **Connection Issues:**
   - Reseat power and SATA/SAS cables
   - Try different SATA ports
   - Test drive in different system
   - Check cable integrity

2. **BIOS/UEFI Configuration:**
   - Enable AHCI mode
   - Disable RAID mode
   - Check for drive size limitations
   - Update BIOS/UEFI if needed

3. **Driver Issues:**
   ```bash
   # Update system
   apt update && apt upgrade
   
   # Check for hardware-specific drivers
   lspci | grep -i storage
   
   # Reload SATA modules
   modprobe -r ahci
   modprobe ahci
   ```

### Overheating Issues

**Symptoms:**
- High drive temperatures
- System shutdowns
- Performance throttling
- Temperature warnings

**Diagnosis:**
```bash
# Check system temperatures
sensors

# Check drive temperatures
for drive in $(lsblk -d -n -o NAME | grep -E '^sd|^nvme'); do
    smartctl -A /dev/$drive | grep -i temperature
done

# Check system load
uptime
top
```

**Solutions:**

1. **Immediate Cooling:**
   - Increase fan speeds
   - Improve airflow
   - Remove dust from components
   - Check ambient temperature

2. **Long-term Solutions:**
   - Add case fans
   - Improve cable management
   - Consider drive spacing
   - Monitor room temperature

---

## ✅ Troubleshooting Best Practices

### Systematic Approach:
- [ ] **Document symptoms** thoroughly before starting
- [ ] **Create backups** before making changes
- [ ] **Test in isolation** when possible
- [ ] **Make one change at a time**
- [ ] **Verify resolution** completely
- [ ] **Document solution** for future reference

### Prevention Strategies:
- [ ] **Regular monitoring** and maintenance
- [ ] **Proactive alerting** for early detection
- [ ] **Capacity planning** to avoid resource issues
- [ ] **Regular testing** of backup/recovery procedures
- [ ] **Documentation updates** after changes
- [ ] **Knowledge sharing** within team

---

## 🚀 Next Steps

For additional troubleshooting resources:

**[Recovery Procedures](recovery-procedures.md)** - Advanced recovery techniques and disaster scenarios

---

## 📞 When to Seek Help

### Escalation Criteria:
- **Data loss risk** is high
- **Multiple systems** affected
- **Solution unclear** after initial troubleshooting
- **Critical business impact**
- **Hardware failure** suspected

### Resources:
- TrueNAS Community Forums
- Official TrueNAS Documentation
- Professional Support Services
- Local IT Support Services

---
*Part of the [Complete TrueNAS Setup Guide](../README.md)*
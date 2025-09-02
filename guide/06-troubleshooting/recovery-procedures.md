# Recovery Procedures

> **Advanced disaster recovery techniques for critical failures, data restoration, and system rebuild scenarios when standard troubleshooting isn't sufficient.**

## 🎯 Recovery Overview

This guide covers advanced recovery scenarios beyond common troubleshooting, including pool failures, system corruption, hardware disasters, and complete data restoration procedures.

**Difficulty**: Advanced  
**Prerequisites**: [Common Issues](common-issues.md) troubleshooting attempted  
**⚠️ Warning**: These procedures can result in data loss if performed incorrectly

---

## 🚨 Emergency Response Framework

### Disaster Classification

```
Recovery Scenario Matrix:
├── Level 1: System Unavailable (System Recovery)
│   ├── Boot failure
│   ├── OS corruption
│   ├── Configuration corruption
│   └── Hardware failure (non-storage)
├── Level 2: Data Inaccessible (Pool Recovery)  
│   ├── Pool import failures
│   ├── Multiple drive failures
│   ├── Metadata corruption
│   └── Controller failures
├── Level 3: Data Loss (Data Recovery)
│   ├── Accidental deletion
│   ├── Ransomware/corruption
│   ├── Multiple backup failures
│   └── Physical destruction
└── Level 4: Complete Rebuild (Disaster Recovery)
    ├── Site disaster (fire, flood, etc.)
    ├── Complete hardware failure
    ├── Facility loss
    └── Multiple system failures
```

### Recovery Decision Tree

```bash
#!/bin/bash
# Recovery Decision Assessment Script
# /root/recovery/assess_situation.sh

echo "=== TrueNAS Recovery Assessment ==="
echo "Answer the following questions to determine recovery path:"
echo

read -p "Can you access the TrueNAS console? (y/n): " console_access
read -p "Can the system boot to TrueNAS? (y/n): " boot_status
read -p "Are storage pools visible? (y/n): " pool_status
read -p "Can you access data through shares? (y/n): " data_access
read -p "Are recent backups available? (y/n): " backup_available

echo -e "\n=== Recovery Recommendation ==="

if [ "$boot_status" = "n" ]; then
    echo "LEVEL 1: Boot/System Recovery Required"
    echo "Proceed to: Boot Environment Recovery"
elif [ "$pool_status" = "n" ]; then
    echo "LEVEL 2: Storage Pool Recovery Required" 
    echo "Proceed to: Pool Import/Recovery Procedures"
elif [ "$data_access" = "n" ]; then
    echo "LEVEL 2: Service Recovery Required"
    echo "Proceed to: Service Restoration Procedures"
else
    echo "LEVEL 0: System appears functional"
    echo "Proceed to: Standard troubleshooting procedures"
fi

if [ "$backup_available" = "n" ]; then
    echo "⚠️  WARNING: Limited recovery options without backups"
fi
```

---

## 🔄 Boot Environment Recovery (Level 1)

### Boot Failure Scenarios

#### System Won't Boot - Boot Environment Issues

**Symptoms:**
- System hangs at boot
- Boot loop conditions
- "No bootable device" errors
- GRUB/boot loader errors

**Recovery Steps:**

1. **Access Boot Menu:**
   ```
   Boot Menu Options:
   ├── Default Boot Environment (current)
   ├── Previous Boot Environments (recovery options)
   ├── Recovery/Rescue Mode
   └── Manual Boot Options
   ```

2. **Boot from Previous Environment:**
   ```bash
   # From TrueNAS boot menu:
   # Select previous boot environment
   # Should boot to last known working state
   
   # Once booted, check current BE status
   beadm list
   
   # Activate stable boot environment
   beadm activate stable-be-name
   reboot
   ```

3. **Manual Boot Environment Management:**
   ```bash
   # If system boots but BE is corrupted
   # Create new boot environment
   beadm create recovery-$(date +%Y%m%d)
   
   # Clone from working BE
   beadm create -e stable-be recovery-new
   
   # Set as default
   beadm activate recovery-new
   ```

#### Complete Boot Drive Failure

**Symptoms:**
- BIOS/UEFI doesn't detect boot drives
- "No bootable device found"
- Boot drives show errors in SMART

**Recovery Procedure:**

1. **Immediate Assessment:**
   ```bash
   # Boot from TrueNAS installation media
   # Select "Shell" option
   
   # Check drive detection
   lsblk
   fdisk -l
   
   # Check drive health
   smartctl -a /dev/sda  # Boot drive
   smartctl -a /dev/sdb  # Mirror boot drive (if exists)
   ```

2. **Single Boot Drive Recovery:**
   ```bash
   # If data drives are intact, reinstall TrueNAS
   # 1. Boot from installation media
   # 2. Install on new boot drive
   # 3. Import existing pools
   
   # After installation, import configuration
   midclt call config.upload /path/to/config/backup.db
   ```

3. **Mirrored Boot Drive Recovery:**
   ```bash
   # If one boot drive failed but mirror exists
   # Boot system normally (should work from surviving drive)
   
   # Check boot pool status
   zpool status boot-pool
   
   # Replace failed boot drive
   zpool replace boot-pool old-device new-device
   
   # Wait for resilver to complete
   watch "zpool status boot-pool"
   ```

### Configuration Recovery

#### Configuration Database Corruption

**Symptoms:**
- System boots but configuration is lost
- Services won't start
- Web interface shows factory defaults
- User accounts missing

**Recovery Steps:**

1. **Restore from Configuration Backup:**
   ```bash
   # From console menu or SSH
   # Option 1: Web interface restore
   # Navigate to System → General → Save Config
   # Upload configuration backup file
   
   # Option 2: Command line restore
   midclt call config.upload /path/to/backup/config.db
   
   # Restart middleware
   systemctl restart truenas-middlewared
   ```

2. **Manual Configuration Reconstruction:**
   ```bash
   # If no config backup available
   # Manually recreate critical settings:
   
   # Network configuration
   # System → Network Interfaces
   
   # User accounts
   # Credentials → Local Users
   
   # Import existing pools
   zpool import tank
   
   # Recreate shares
   # Based on existing dataset structure
   ```

---

## 💾 Storage Pool Recovery (Level 2)

### Pool Import Failures

#### Pool Shows as UNAVAIL

**Symptoms:**
- Pool not visible in TrueNAS interface
- `zpool import` shows pool as UNAVAIL
- "Insufficient replicas" errors
- Multiple drive failures

**Advanced Recovery Techniques:**

1. **Force Pool Import (Use with Caution):**
   ```bash
   # Check pool import status
   zpool import
   
   # Attempt force import with read-only mode
   zpool import -f -R /mnt -o readonly=on tank
   
   # If successful, immediately backup critical data
   rsync -av /mnt/tank/critical-data /backup/location/
   
   # Check pool integrity
   zpool scrub tank
   ```

2. **Metadata Recovery:**
   ```bash
   # If pool metadata is corrupted
   # Try importing with alternative root
   zpool import -R /tmp tank
   
   # Check for multiple pool copies
   zpool import -d /dev/disk/by-id tank
   
   # Import specific device path if needed
   zpool import -d /dev/disk/by-id -f tank
   ```

3. **Partial Pool Recovery:**
   ```bash
   # If some VDEVs are available
   # Import degraded pool
   zpool import -f -m tank
   
   # Check what data is accessible
   find /mnt/tank -type f -ls | head -20
   
   # Backup accessible data immediately
   ```

### Multiple Drive Failure Recovery

#### RAIDZ Pool with Excessive Failures

**Scenarios:**
- RAIDZ1 with 2+ drive failures
- RAIDZ2 with 3+ drive failures  
- All mirrors in a set failed

**Recovery Attempt (Last Resort):**

```bash
# ⚠️ WARNING: These procedures may cause data loss
# Only attempt if you understand the risks

# 1. Attempt to bring one failed drive back online
# Check if any "failed" drives are actually recoverable
for drive in $(zpool status tank | grep FAULTED | awk '{print $1}'); do
    echo "Checking drive: $drive"
    smartctl -H /dev/disk/by-id/$drive
    
    # If drive responds, try to clear errors
    zpool clear tank $drive
done

# 2. If drives respond but have errors, try force online
zpool online -f tank drive-id

# 3. Export and re-import with force
zpool export tank
zpool import -f tank

# 4. If import succeeds, immediately scrub and backup
zpool scrub tank
rsync -av /mnt/tank/ /backup/emergency/
```

### ZFS Send/Receive Recovery

#### Restore from ZFS Replication

**Use Case:** Primary pool failed, but replicated data exists

```bash
# 1. Create new pool for restoration
zpool create recovery-tank mirror sda sdb

# 2. Receive replicated data
# From local replication
zfs receive recovery-tank/family < /backup/tank-family-latest.zfs

# From remote replication  
ssh backup-server 'zfs send tank/family@latest' | zfs receive recovery-tank/family

# 3. Verify restored data
zfs list recovery-tank
ls -la /mnt/recovery-tank/family/

# 4. Update shares to point to new pool
# Navigate to Sharing → Windows (SMB)
# Update path from /mnt/tank/family to /mnt/recovery-tank/family
```

---

## 🔄 Data Recovery (Level 3)

### Accidental Data Deletion

#### File-Level Recovery from Snapshots

**Scenario:** Critical files accidentally deleted

```bash
# 1. Check available snapshots
zfs list -t snapshot tank/family/documents | head -10

# 2. Browse snapshot for deleted files
ls -la /mnt/tank/family/documents/.zfs/snapshot/daily-2024-01-15/

# 3. Restore specific files
cp /mnt/tank/family/documents/.zfs/snapshot/daily-2024-01-15/important.doc \
   /mnt/tank/family/documents/important-recovered.doc

# 4. Restore entire directory
cp -r /mnt/tank/family/documents/.zfs/snapshot/daily-2024-01-15/project/ \
      /mnt/tank/family/documents/project-recovered/

# 5. Roll back entire dataset (destructive - loses recent changes)
zfs rollback tank/family/documents@daily-2024-01-15
```

#### Dataset-Level Recovery

**Scenario:** Entire dataset corrupted or lost

```bash
# 1. Create new dataset for recovery
zfs create tank/family/documents-recovery

# 2. Restore from most recent snapshot
zfs send tank/family/documents@daily-2024-01-15 | \
zfs receive tank/family/documents-recovery

# 3. Verify restored data
diff -r /mnt/tank/family/documents-recovery/ /mnt/tank/family/documents/

# 4. If verification successful, rename datasets
zfs rename tank/family/documents tank/family/documents-corrupted
zfs rename tank/family/documents-recovery tank/family/documents
```

### Ransomware Recovery

#### Encrypted/Corrupted Data Recovery

**Immediate Response:**

```bash
# 1. IMMEDIATELY DISCONNECT from network
ip link set dev eth0 down

# 2. Stop all services to prevent further encryption
systemctl stop smbd nmbd nfs-server

# 3. Create read-only snapshot of current state (forensics)
zfs snapshot tank/family@ransomware-$(date +%Y%m%d_%H%M%S)

# 4. Assess damage scope
find /mnt/tank -name "*.encrypted" -o -name "*.locked" -o -name "*ransom*" | head -20

# 5. Check for clean snapshots (before infection)
zfs list -t snapshot tank/family | tail -10
```

**Recovery Process:**

```bash
# 1. Identify last clean snapshot
# Look for snapshot before infection time
zfs list -t snapshot tank/family

# 2. Roll back to clean snapshot
# ⚠️ WARNING: This destroys all changes after snapshot
zfs rollback tank/family@daily-2024-01-14

# 3. Alternative: Selective restore
# Create new dataset and restore from clean snapshot
zfs create tank/family-recovered
zfs send tank/family@daily-2024-01-14 | zfs receive tank/family-recovered

# 4. Verify restored data is clean
file /mnt/tank/family-recovered/documents/* | head -10

# 5. Once verified, replace infected dataset
zfs destroy tank/family
zfs rename tank/family-recovered tank/family
```

### Cloud Backup Recovery

#### Restore from Cloud Storage

**Use Case:** Local and replicated backups also affected

```bash
# 1. List available cloud backups
rclone ls backblaze:truenas-family-backup-2024/ | head -20

# 2. Restore critical files first
rclone copy backblaze:truenas-family-backup-2024/documents/ \
           /mnt/tank/family/documents/

# 3. Verify restoration
ls -la /mnt/tank/family/documents/

# 4. Full restoration (may take hours/days)
rclone copy backblaze:truenas-family-backup-2024/ \
           /mnt/tank/family/ --progress

# 5. Check file integrity
md5sum /mnt/tank/family/documents/important.doc
# Compare with known good checksum
```

---

## 🏗️ Complete System Rebuild (Level 4)

### Site Disaster Recovery

#### Rebuild at New Location

**Scenario:** Complete site loss, rebuilding from off-site backups

**Phase 1: Hardware Setup**
```bash
# 1. Procure replacement hardware
# - Compatible server/components
# - Sufficient drive capacity  
# - Network infrastructure

# 2. Install TrueNAS SCALE
# - Boot from installation media
# - Install on new boot drives
# - Configure basic network settings

# 3. Initial configuration
# - Set timezone and NTP
# - Configure network interfaces
# - Set up basic security
```

**Phase 2: Data Recovery**
```bash
# 1. Create new storage pool
zpool create tank raidz2 sda sdb sdc sdd sde sdf

# 2. Restore from cloud backups
rclone copy cloud-provider:backup-bucket/ /mnt/tank/ --progress

# 3. Alternative: Restore from shipped drives
# If using physical backup drives
mount /dev/external-backup /mnt/backup
rsync -av /mnt/backup/tank/ /mnt/tank/

# 4. Restore configuration
midclt call config.upload /mnt/tank/backups/config/truenas-config-latest.db
systemctl restart truenas-middlewared
```

**Phase 3: Service Restoration**
```bash
# 1. Verify pool health
zpool status tank
zfs list

# 2. Configure shares (if not restored from config)
# SMB shares
# NFS exports  
# iSCSI targets

# 3. Test connectivity
smbclient -L localhost
showmount -e localhost

# 4. Notify users of restoration
# Update DNS if necessary
# Test access from client machines
```

### Backup Infrastructure Recovery

#### Rebuild Backup Systems

**Scenario:** Primary system recovered but backup infrastructure lost

```bash
# 1. Re-establish replication targets
# Set up new remote TrueNAS system
# Configure SSH authentication
ssh-keygen -t ed25519
ssh-copy-id backup-system

# 2. Recreate replication tasks
# Data Protection → Replication Tasks
# Configure push replication to new remote system

# 3. Re-establish cloud backups
# Credentials → Cloud Credentials
# Add cloud storage providers
# Data Protection → Cloud Sync Tasks

# 4. Rebuild snapshot schedules
# Data Protection → Periodic Snapshot Tasks
# Recreate hourly/daily/weekly snapshots

# 5. Test backup systems
# Verify snapshots are being created
# Test replication functionality
# Verify cloud uploads working
```

---

## 🧪 Recovery Testing and Validation

### Recovery Drill Procedures

#### Monthly Recovery Test

```bash
#!/bin/bash
# Monthly Recovery Drill Script
# /root/recovery/monthly_drill.sh

DRILL_LOG="/var/log/recovery_drill.log"
TEST_DIR="/tmp/recovery_test_$(date +%Y%m%d)"

echo "=== Monthly Recovery Drill - $(date) ===" >> $DRILL_LOG

# Test 1: Snapshot Recovery
echo "Testing snapshot recovery..." >> $DRILL_LOG
mkdir -p $TEST_DIR/snapshot_test
LATEST_SNAP=$(zfs list -t snapshot tank/family/documents -o name | tail -1)
cp /mnt/tank/family/documents/.zfs/snapshot/*/test_file.txt $TEST_DIR/snapshot_test/ 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✓ Snapshot recovery: PASS" >> $DRILL_LOG
else
    echo "✗ Snapshot recovery: FAIL" >> $DRILL_LOG
fi

# Test 2: Configuration Backup
echo "Testing configuration backup..." >> $DRILL_LOG
midclt call system.general.config > $TEST_DIR/config_test.json
if [ -s $TEST_DIR/config_test.json ]; then
    echo "✓ Configuration backup: PASS" >> $DRILL_LOG
else
    echo "✗ Configuration backup: FAIL" >> $DRILL_LOG
fi

# Test 3: Boot Environment Creation
echo "Testing boot environment..." >> $DRILL_LOG
beadm create drill-test-$(date +%Y%m%d)
if [ $? -eq 0 ]; then
    echo "✓ Boot environment creation: PASS" >> $DRILL_LOG
    beadm destroy drill-test-$(date +%Y%m%d)
else
    echo "✗ Boot environment creation: FAIL" >> $DRILL_LOG
fi

# Test 4: Network Connectivity
echo "Testing network connectivity..." >> $DRILL_LOG
ping -c 4 8.8.8.8 > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✓ Network connectivity: PASS" >> $DRILL_LOG
else
    echo "✗ Network connectivity: FAIL" >> $DRILL_LOG
fi

# Cleanup and Summary
rm -rf $TEST_DIR
FAILED_TESTS=$(grep -c "FAIL" $DRILL_LOG)
echo "Recovery drill completed. Failed tests: $FAILED_TESTS" >> $DRILL_LOG

# Email results if failures
if [ $FAILED_TESTS -gt 0 ]; then
    tail -20 $DRILL_LOG | mail -s "Recovery Drill FAILURES" admin@yourdomain.com
fi
```

### Recovery Documentation Maintenance

#### Recovery Runbook Template

```markdown
# TrueNAS Recovery Runbook

## Contact Information
- Primary Administrator: [Name, Phone, Email]
- Secondary Administrator: [Name, Phone, Email]  
- Hardware Vendor: [Contact Information]
- Network Provider: [Contact Information]

## System Information
- TrueNAS Version: [Version]
- Hardware Model: [Make/Model]
- Pool Configuration: [RAID level, drive count]
- Network Configuration: [IP addresses, VLANs]

## Recovery Scenarios

### Scenario 1: Boot Failure
- **Symptoms**: [List symptoms]
- **Recovery Steps**: [Step-by-step procedure]
- **Estimated Time**: [Recovery duration]
- **Required Resources**: [Personnel, hardware, etc.]

### Scenario 2: Pool Failure  
- **Symptoms**: [List symptoms]
- **Recovery Steps**: [Step-by-step procedure]
- **Estimated Time**: [Recovery duration]
- **Required Resources**: [Personnel, hardware, etc.]

## Backup Locations
- Configuration Backups: [Location/method]
- Data Backups: [Location/method]
- Off-site Backups: [Location/method]

## Recovery Checklist
- [ ] Assess situation severity
- [ ] Contact appropriate personnel
- [ ] Document issue thoroughly  
- [ ] Attempt recovery procedures
- [ ] Verify system functionality
- [ ] Update documentation
- [ ] Conduct post-incident review
```

---

## ✅ Recovery Preparedness Checklist

### Prevention and Preparation:
- [ ] **Regular backups** tested and verified
- [ ] **Recovery procedures** documented and current
- [ ] **Emergency contacts** maintained and accessible
- [ ] **Spare hardware** available for critical components
- [ ] **Recovery tools** prepared and accessible
- [ ] **Recovery drills** performed regularly

### During Recovery:
- [ ] **Situation assessed** and documented thoroughly
- [ ] **Safety precautions** taken to prevent further damage
- [ ] **Expert help** engaged when needed
- [ ] **Recovery steps** documented as performed
- [ ] **Progress tracked** and communicated to stakeholders

### Post-Recovery:
- [ ] **System functionality** fully verified
- [ ] **Data integrity** confirmed through testing
- [ ] **Security measures** re-implemented
- [ ] **Monitoring** re-enabled and tested
- [ ] **Documentation** updated with lessons learned
- [ ] **Post-incident review** conducted with team

---

## 📞 Emergency Resources

### TrueNAS Community Support:
- **Forums**: https://www.truenas.com/community/
- **Documentation**: https://www.truenas.com/docs/
- **IRC**: #freenas on freenode

### Professional Support:
- **iXsystems Support**: For enterprise users
- **Local Data Recovery**: For physical drive failures
- **Disaster Recovery Services**: For major incidents

### Emergency Supplies:
- **Installation Media**: TrueNAS USB installer
- **Network Cables**: For connectivity troubleshooting  
- **SATA Cables**: For drive connection issues
- **Spare Drives**: For immediate replacement
- **Console Access**: Serial/KVM for remote troubleshooting

---

## 🎯 Recovery Success Metrics

### Key Performance Indicators:
- **Recovery Time Objective (RTO)**: Maximum acceptable downtime
- **Recovery Point Objective (RPO)**: Maximum acceptable data loss
- **Mean Time to Recovery (MTTR)**: Average recovery duration
- **Recovery Success Rate**: Percentage of successful recoveries

### Continuous Improvement:
- **Regular review** of recovery procedures
- **Update procedures** based on lessons learned
- **Test new recovery methods** as they become available
- **Train team members** on recovery procedures

---

*Part of the [Complete TrueNAS Setup Guide](../README.md)*

**Remember**: The best recovery is the one you never need. Invest in prevention, monitoring, and regular backups to minimize the need for these advanced recovery procedures.
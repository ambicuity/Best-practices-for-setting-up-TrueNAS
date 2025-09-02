# Backup Configuration

> **Implement a comprehensive 3-2-1 backup strategy using snapshots, replication, and cloud storage to protect your data against any disaster.**

## 🎯 Backup Strategy Overview

This guide implements the gold standard 3-2-1 backup rule:
- **3 copies** of your data (1 primary + 2 backups)
- **2 different media types** (local drives + cloud/offsite)
- **1 offsite copy** (geographically separated)

**Estimated Time**: 3-4 hours  
**Difficulty**: Intermediate to Advanced  
**Prerequisites**: [Shares and Datasets](shares-and-datasets.md) configured

---

## 📚 Backup Fundamentals

### Understanding TrueNAS Backup Types

```
TrueNAS Backup Hierarchy:
├── Snapshots (Point-in-time copies)
│   ├── Instant creation/restoration
│   ├── Space-efficient (copy-on-write)
│   └── Same pool storage
├── Replication (Dataset copies)
│   ├── Local replication (different pool)
│   ├── Remote replication (different TrueNAS)
│   └── Cloud replication (S3, B2, etc.)
└── Traditional Backups (File-based)
    ├── Rsync to external storage
    ├── Tar/zip archives
    └── Third-party backup software
```

### Recovery Time vs Recovery Point Objectives

```
Backup Strategy Planning:
├── RTO (Recovery Time Objective): How fast can you restore?
│   ├── Snapshots: Seconds to minutes
│   ├── Local replication: Minutes to hours
│   └── Cloud restore: Hours to days
├── RPO (Recovery Point Objective): How much data can you lose?
│   ├── Hourly snapshots: Max 1 hour data loss
│   ├── Daily replication: Max 24 hours data loss
│   └── Weekly cloud sync: Max 7 days data loss
└── Retention Policy: How long to keep backups?
    ├── Snapshots: 48 hours to 30 days
    ├── Local replication: 30-90 days
    └── Cloud storage: 1-7 years
```

---

## 📸 Snapshot Configuration

### Snapshot Strategy Design

**Navigate to**: Data Protection → Periodic Snapshot Tasks

Plan snapshot frequency based on data criticality:

```
Snapshot Schedule Example:
├── Critical Data (Documents, Photos):
│   ├── Every 15 minutes (keep 48)
│   ├── Hourly (keep 72)
│   ├── Daily (keep 30)
│   └── Weekly (keep 12)
├── Media Data (Movies, Music):
│   ├── Daily (keep 7)
│   └── Weekly (keep 8)
└── System Data (Apps, Configs):
    ├── Hourly (keep 24)
    ├── Daily (keep 14)
    └── Weekly (keep 8)
```

### Creating Snapshot Tasks

#### Critical Data Snapshots

**Navigate to**: Data Protection → Periodic Snapshot Tasks → Add

1. **Family Documents - Frequent Snapshots:**
   ```yaml
   Snapshot Task Configuration:
   ├── Dataset: tank/family/documents
   ├── Recursive: Enabled
   ├── Exclude: (none)
   ├── Naming Schema: auto-%Y-%m-%d_%H-%M
   ├── Schedule: Every 15 minutes
   ├── Begin: 00:00
   ├── End: 23:45
   ├── Enabled: Yes
   └── Lifetime: 2 days (48 snapshots)
   ```

2. **Family Photos - Daily Snapshots:**
   ```yaml
   Photos Snapshot Task:
   ├── Dataset: tank/family/photos
   ├── Recursive: Enabled
   ├── Naming Schema: daily-%Y-%m-%d
   ├── Schedule: Daily
   ├── Begin: 02:00 AM
   ├── Enabled: Yes
   └── Lifetime: 30 days
   ```

3. **Media Content - Weekly Snapshots:**
   ```yaml
   Media Snapshot Task:
   ├── Dataset: tank/media
   ├── Recursive: Enabled
   ├── Naming Schema: weekly-%Y-%W
   ├── Schedule: Weekly (Sunday)
   ├── Begin: 01:00 AM
   ├── Enabled: Yes
   └── Lifetime: 8 weeks
   ```

#### Application Data Snapshots

1. **Application Data - Hourly Snapshots:**
   ```yaml
   Apps Snapshot Task:
   ├── Dataset: tank/apps
   ├── Recursive: Enabled
   ├── Exclude: tank/apps/temp, tank/apps/cache
   ├── Naming Schema: app-hourly-%Y-%m-%d_%H
   ├── Schedule: Hourly
   ├── Begin: 00:00
   ├── End: 23:00
   ├── Enabled: Yes
   └── Lifetime: 72 hours (3 days)
   ```

### Snapshot Management

**Viewing and Managing Snapshots:**

**Navigate to**: Storage → Snapshots

1. **Snapshot Browser:**
   - View all snapshots by dataset
   - Check space usage per snapshot
   - Sort by date, size, or retention policy
   - Delete specific snapshots if needed

2. **Snapshot Access:**
   ```bash
   # Snapshots are accessible via hidden .zfs directory
   ls /mnt/tank/family/photos/.zfs/snapshot/
   
   # Browse snapshot contents
   ls /mnt/tank/family/photos/.zfs/snapshot/daily-2024-01-15/
   
   # Restore single file from snapshot
   cp /mnt/tank/family/photos/.zfs/snapshot/daily-2024-01-15/vacation.jpg \
      /mnt/tank/family/photos/vacation_restored.jpg
   ```

### Snapshot Monitoring

Create snapshot health monitoring:

```bash
#!/bin/bash
# Snapshot monitoring script

echo "=== Snapshot Health Check ==="
echo "Date: $(date)"
echo

# Check recent snapshots
echo "Recent snapshots per dataset:"
zfs list -t snapshot -o name,creation,used | head -20

echo -e "\nSnapshot space usage:"
zfs list -t snapshot -o name,used,refer | sort -k2 -h | tail -10

echo -e "\nDatasets with most snapshots:"
zfs list -t snapshot | cut -d@ -f1 | sort | uniq -c | sort -nr | head -5

# Check for failed snapshot tasks
echo -e "\nChecking for failed snapshot tasks..."
grep -i "snapshot.*fail" /var/log/messages | tail -5
```

---

## 🔄 Replication Configuration

### Local Replication Setup

**Use Case**: Protect against pool failure by replicating to second pool

**Prerequisites**: Second storage pool or external drive

#### Creating Local Replication

**Navigate to**: Data Protection → Replication Tasks → Add

1. **Critical Data Local Replication:**
   ```yaml
   Local Replication Task:
   ├── Name: family-to-backup-pool
   ├── Direction: Push
   ├── Transport: Local
   ├── Source Location: On this System
   ├── Source: tank/family
   ├── Target Location: On this System
   ├── Target: backup-pool/family-replica
   ├── Recursive: Enabled
   ├── Replicate Snapshots: Enabled
   ├── Snapshot Retention Policy: Same as source
   ├── Schedule: Daily at 3:00 AM
   └── Enabled: Yes
   ```

2. **Replication Properties:**
   - **Include Dataset Properties**: Enabled
   - **Include Snapshot Properties**: Enabled
   - **Full Filesystem Replication**: Enabled
   - **Encryption**: Inherit from target

### Remote Replication Setup

**Use Case**: Replicate to another TrueNAS system at different location

#### SSH Key Setup for Replication

**Navigate to**: Credentials → Backup Credentials

1. **Generate SSH Key Pair:**
   ```bash
   # On source TrueNAS system
   ssh-keygen -t ed25519 -C "replication@truenas-primary"
   ```

2. **Configure SSH Connection:**
   - **Name**: `remote-truenas-backup`
   - **Provider**: SSH
   - **Host**: `backup.example.com`
   - **Port**: 22
   - **Username**: `replication-user`
   - **Private Key**: Upload generated private key
   - **Connect Timeout**: 10

#### Remote Replication Task

**Navigate to**: Data Protection → Replication Tasks → Add

1. **Remote Replication Configuration:**
   ```yaml
   Remote Replication Task:
   ├── Name: family-to-remote-site
   ├── Direction: Push
   ├── Transport: SSH
   ├── SSH Connection: remote-truenas-backup
   ├── Source: tank/family
   ├── Target: backup-tank/primary-site-replica
   ├── Recursive: Enabled
   ├── Replicate Snapshots: Enabled
   ├── Schedule: Daily at 11:00 PM
   ├── Bandwidth Limit: 50 Mbps (adjust for WAN)
   └── Enabled: Yes
   ```

2. **Advanced Replication Options:**
   ```yaml
   Advanced Settings:
   ├── Stream Compression: lz4 (reduce network usage)
   ├── Include Dataset Properties: Enabled
   ├── Include Snapshot Properties: Enabled
   ├── Partial File Replication: Disabled
   ├── Large Block: Enabled
   ├── Embed Data: Enabled
   └── Compressed: Enabled
   ```

---

## ☁️ Cloud Backup Configuration

### Cloud Storage Provider Setup

#### Backblaze B2 Configuration

**Navigate to**: Credentials → Cloud Credentials → Add

1. **B2 Cloud Credential:**
   ```yaml
   Backblaze B2 Setup:
   ├── Name: backblaze-b2-family
   ├── Provider: Backblaze B2
   ├── Account ID: (from B2 console)
   ├── Application Key: (from B2 console)
   └── Test Connection: Verify before saving
   ```

2. **Create B2 Bucket:**
   - **Bucket Name**: `truenas-family-backup-2024`
   - **Encryption**: Enable (B2-managed or customer-managed)
   - **Lifecycle Rules**: Configure for cost optimization

#### Amazon S3 Configuration

**Navigate to**: Credentials → Cloud Credentials → Add

1. **S3 Cloud Credential:**
   ```yaml
   Amazon S3 Setup:
   ├── Name: aws-s3-backup
   ├── Provider: Amazon S3
   ├── Access Key ID: (IAM user key)
   ├── Secret Access Key: (IAM user secret)
   ├── Bucket: truenas-backup-bucket
   ├── Region: us-west-2
   └── Storage Class: Standard-IA or Glacier
   ```

### Cloud Sync Tasks

**Navigate to**: Data Protection → Cloud Sync Tasks → Add

#### Family Photos Cloud Backup

1. **B2 Sync Configuration:**
   ```yaml
   Cloud Sync Task - Photos:
   ├── Description: Family Photos to B2
   ├── Credential: backblaze-b2-family
   ├── Bucket: truenas-family-backup-2024
   ├── Bucket Path: photos/
   ├── Direction: Push
   ├── Transfer Mode: Sync
   ├── Local Path: /mnt/tank/family/photos
   ├── Remote Path: photos/
   ├── Schedule: Weekly (Sunday 4:00 AM)
   ├── Enabled: Yes
   └── Encryption: Enabled
   ```

2. **Advanced Cloud Sync Options:**
   ```yaml
   Advanced Settings:
   ├── Exclude: .DS_Store, Thumbs.db, *.tmp
   ├── Include: *.jpg, *.png, *.mp4, *.mov
   ├── Bandwidth Limit: 25 Mbps (adjust for upload speed)
   ├── Transfers: 4 (concurrent uploads)
   ├── Checkers: 8 (file verification threads)
   ├── Delete Policy: Don't delete (safer)
   └── Dry Run: Test first
   ```

#### Document Archive Cloud Backup

1. **Documents to S3 Glacier:**
   ```yaml
   Cloud Sync Task - Documents:
   ├── Description: Documents Archive to S3 Glacier
   ├── Credential: aws-s3-backup
   ├── Bucket: truenas-backup-bucket
   ├── Directory: documents/
   ├── Direction: Push
   ├── Transfer Mode: Copy (archive mode)
   ├── Local Path: /mnt/tank/family/documents
   ├── Storage Class: Glacier Deep Archive
   ├── Schedule: Monthly (1st Sunday 1:00 AM)
   └── Encryption: AES256
   ```

### Cloud Sync Monitoring

```bash
#!/bin/bash
# Cloud sync monitoring script

echo "=== Cloud Sync Status Check ==="
echo "Date: $(date)"

# Check recent cloud sync tasks
echo -e "\nRecent cloud sync tasks:"
grep "cloud_sync" /var/log/messages | tail -10

# Check available cloud storage
echo -e "\nCloud storage usage:"
# This would need to be customized per provider
rclone about backblaze:truenas-family-backup-2024

# Check bandwidth usage
echo -e "\nNetwork usage during last sync:"
grep "cloud_sync" /var/log/messages | grep "bytes" | tail -5
```

---

## 💾 Traditional Backup Methods

### Rsync to External Storage

**Use Case**: Additional backup to USB drives or NAS devices

#### External Drive Backup

**Navigate to**: Data Protection → Rsync Tasks → Add

1. **USB Drive Backup Task:**
   ```yaml
   Rsync Task Configuration:
   ├── Path: /mnt/tank/family/
   ├── Remote Host: (empty for local)
   ├── Remote SSH Port: (empty)
   ├── Rsync Mode: Module
   ├── Remote Module Name: (empty for local)
   ├── Remote Path: /mnt/usb-backup/family/
   ├── Direction: Push
   ├── Description: Family data to USB drive
   ├── Schedule: Weekly (Saturday 6:00 AM)
   ├── Recursive: Enabled
   ├── Times: Enabled (preserve timestamps)
   ├── Compress: Enabled
   ├── Archive: Enabled
   ├── Delete: Enabled (mirror mode)
   ├── Preserve Permissions: Enabled
   ├── Preserve Extended Attributes: Enabled
   └── Enabled: Yes (when USB connected)
   ```

2. **Rsync Exclusion Patterns:**
   ```bash
   # Add to auxiliary parameters
   --exclude='.DS_Store'
   --exclude='Thumbs.db'
   --exclude='*.tmp'
   --exclude='*.cache'
   --exclude='lost+found'
   ```

### Archive Creation

#### Automated Archive Scripts

Create custom backup scripts for specific needs:

```bash
#!/bin/bash
# Custom archive backup script

BACKUP_DATE=$(date +%Y%m%d)
ARCHIVE_DIR="/mnt/tank/backups/archives"
SOURCE_DIR="/mnt/tank/family/documents"

echo "Creating document archive for $BACKUP_DATE"

# Create compressed archive
tar -czf "$ARCHIVE_DIR/documents-$BACKUP_DATE.tar.gz" \
    -C "$SOURCE_DIR" \
    --exclude="*.tmp" \
    --exclude=".DS_Store" \
    .

# Verify archive integrity
if tar -tzf "$ARCHIVE_DIR/documents-$BACKUP_DATE.tar.gz" > /dev/null; then
    echo "Archive created successfully: documents-$BACKUP_DATE.tar.gz"
    
    # Upload to cloud (optional)
    rclone copy "$ARCHIVE_DIR/documents-$BACKUP_DATE.tar.gz" \
        backblaze:truenas-family-backup-2024/archives/
    
    echo "Archive uploaded to cloud storage"
else
    echo "ERROR: Archive verification failed!"
    exit 1
fi

# Clean up old archives (keep 12 months)
find "$ARCHIVE_DIR" -name "documents-*.tar.gz" -mtime +365 -delete
```

---

## 🔍 Backup Testing and Validation

### Regular Backup Tests

#### Quarterly Restore Tests

Create a restore testing schedule:

```bash
#!/bin/bash
# Backup restore test script

echo "=== Backup Restore Test ==="
echo "Date: $(date)"

TEST_DIR="/tmp/restore-test-$(date +%Y%m%d)"
mkdir -p "$TEST_DIR"

echo "Testing snapshot restore..."
# Test snapshot restore
cp -r /mnt/tank/family/documents/.zfs/snapshot/daily-$(date -d "1 day ago" +%Y-%m-%d)/* \
   "$TEST_DIR/snapshot-test/"

echo "Testing cloud restore..."
# Test cloud restore (sample files)
rclone copy backblaze:truenas-family-backup-2024/documents/important/ \
   "$TEST_DIR/cloud-test/" --max-size 10M

echo "Verifying restored files..."
# Verify file integrity
if [ -d "$TEST_DIR/snapshot-test" ] && [ -d "$TEST_DIR/cloud-test" ]; then
    echo "✓ Restore test PASSED"
    
    # Compare file counts and sizes
    echo "Snapshot files: $(find $TEST_DIR/snapshot-test -type f | wc -l)"
    echo "Cloud files: $(find $TEST_DIR/cloud-test -type f | wc -l)"
else
    echo "✗ Restore test FAILED"
fi

# Cleanup
rm -rf "$TEST_DIR"
```

### Backup Health Monitoring

#### Daily Backup Health Check

```bash
#!/bin/bash
# Daily backup health check

echo "=== Daily Backup Health Check ==="
echo "Date: $(date)"
echo

# Check snapshot tasks
echo "Snapshot Task Status:"
grep "snapshot.*SUCCESS\|snapshot.*FAILED" /var/log/messages | tail -5

# Check replication tasks  
echo -e "\nReplication Task Status:"
grep "replication.*SUCCESS\|replication.*FAILED" /var/log/messages | tail -5

# Check cloud sync tasks
echo -e "\nCloud Sync Status:"
grep "cloud_sync.*SUCCESS\|cloud_sync.*FAILED" /var/log/messages | tail -5

# Check available space
echo -e "\nStorage Space Check:"
zfs list -o name,used,avail,refer | grep -E "tank|backup-pool"

# Check backup integrity
echo -e "\nLast Successful Backups:"
zfs list -t snapshot | tail -5

# Generate summary
FAILED_TASKS=$(grep "FAILED" /var/log/messages | grep -E "snapshot|replication|cloud_sync" | wc -l)
if [ $FAILED_TASKS -eq 0 ]; then
    echo -e "\n✓ All backup tasks completed successfully"
else
    echo -e "\n⚠ $FAILED_TASKS backup tasks failed - investigate immediately"
fi
```

---

## 📊 Backup Performance Optimization

### Replication Performance Tuning

1. **Network Optimization:**
   ```yaml
   Replication Performance Settings:
   ├── Compression: lz4 (CPU vs network trade-off)
   ├── Bandwidth Limiting: Set appropriate limits
   ├── Large Block Support: Enable for large files
   ├── Embedded Data: Enable for small files
   └── Stream Compression: Enable for WAN replication
   ```

2. **Schedule Optimization:**
   ```bash
   # Stagger backup tasks to avoid conflicts
   02:00 - Snapshots (family/documents)
   03:00 - Local replication start
   04:00 - Cloud sync (photos) start
   05:00 - Rsync to external drive
   23:00 - Remote replication (off-peak hours)
   ```

### Cloud Sync Optimization

1. **Upload Optimization:**
   ```yaml
   Cloud Sync Performance:
   ├── Concurrent Transfers: 4-8 (based on bandwidth)
   ├── Chunk Size: 96M (balance memory vs performance)
   ├── Bandwidth Limit: 80% of available upload
   ├── Exclude Patterns: Filter unnecessary files
   └── Delta Sync: Only upload changed files
   ```

---

## ✅ Backup Configuration Checklist

### Snapshot Configuration:
- [ ] **Critical data snapshots** configured (15min/hourly/daily)
- [ ] **Media snapshots** configured (daily/weekly)
- [ ] **Application snapshots** configured with exclusions
- [ ] **Snapshot retention** policies appropriate for recovery needs
- [ ] **Snapshot monitoring** scripts created and scheduled
- [ ] **Snapshot access** tested (file-level recovery)

### Replication Configuration:
- [ ] **Local replication** configured to secondary pool
- [ ] **Remote replication** configured to offsite TrueNAS
- [ ] **SSH authentication** properly secured
- [ ] **Bandwidth limiting** configured for WAN links
- [ ] **Replication monitoring** and alerting active
- [ ] **Recovery procedures** tested and documented

### Cloud Backup Configuration:
- [ ] **Cloud provider** accounts and credentials configured
- [ ] **Cloud sync tasks** scheduled for critical data
- [ ] **Encryption** enabled for cloud storage
- [ ] **Bandwidth management** configured
- [ ] **Cloud restore procedures** tested
- [ ] **Cost monitoring** and optimization implemented

### Backup Testing and Validation:
- [ ] **Restore testing** scheduled and automated
- [ ] **Backup verification** scripts running regularly
- [ ] **Recovery procedures** documented and tested
- [ ] **RTO/RPO objectives** met by current strategy
- [ ] **Backup monitoring** integrated with alerting
- [ ] **Documentation** maintained and current

---

## 🚀 Next Steps

With comprehensive backups configured, you're ready to:

**[Monitoring Setup](../05-maintenance/monitoring-setup.md)** - Implement system health monitoring and alerting

---

## 🔧 Backup Troubleshooting

### Common Backup Issues:

**Problem**: Snapshots consuming too much space
- **Solution**: Adjust retention policies, check for large file changes

**Problem**: Replication tasks failing
- **Solution**: Check SSH connectivity, verify target dataset permissions

**Problem**: Cloud sync uploading slowly
- **Solution**: Adjust concurrent transfer settings, check bandwidth limits

**Problem**: Cannot restore from snapshots
- **Solution**: Verify snapshot exists, check file system permissions

### Recovery Procedures:

**Emergency Data Recovery:**
1. **Assess scope of data loss**
2. **Identify most recent good backup**
3. **Test restore in isolated environment** 
4. **Document recovery process**
5. **Implement improvements** to prevent recurrence

---
*Part of the [Complete TrueNAS Setup Guide](../README.md)*
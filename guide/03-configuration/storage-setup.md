# Storage Setup

> **Create ZFS pools, configure datasets, and establish the storage architecture that will serve as the foundation for all your data services.**

## 🎯 Storage Setup Overview

This guide covers creating ZFS storage pools and datasets, which form the core of your TrueNAS system. Proper storage design is critical for performance, reliability, and data protection.

**Estimated Time**: 2-4 hours  
**Difficulty**: Intermediate  
**Prerequisites**: [Initial Setup](../02-installation/initial-setup.md) completed

---

## 📚 ZFS Fundamentals

### Understanding ZFS Structure

ZFS organizes storage in a hierarchical structure:

```
Pool (tank)                          # Top-level storage container
├── VDEV 1 (RAIDZ1)                 # Virtual device with fault tolerance
│   ├── Drive 1 (4TB)               # Physical drives in the VDEV
│   ├── Drive 2 (4TB)
│   ├── Drive 3 (4TB)
│   └── Drive 4 (4TB)
├── Dataset: /tank/family           # Logical storage unit
│   ├── /tank/family/photos        # Child datasets
│   ├── /tank/family/videos
│   └── /tank/family/documents
└── Dataset: /tank/media            # Another top-level dataset
    ├── /tank/media/movies
    └── /tank/media/music
```

### VDEV Types and RAID Levels

| VDEV Type | Drives | Fault Tolerance | Capacity | Use Case |
|-----------|---------|-----------------|----------|-----------|
| **Mirror** | 2+ | N-1 drives | ~50% | High performance, small pools |
| **RAIDZ1** | 3+ | 1 drive | ~75% | Balanced performance/capacity |
| **RAIDZ2** | 4+ | 2 drives | ~66% | High reliability, large pools |
| **RAIDZ3** | 5+ | 3 drives | ~60% | Maximum reliability |

> 💡 **Golden Rule**: All drives in a VDEV should be the same size and speed for optimal performance.

---

## 🔍 Pre-Setup Drive Assessment

### Drive Inventory and Health Check

**Navigate to**: Storage → Disks

1. **Identify Available Drives:**
   ```
   Available Data Drives:
   ├── da2: 4TB WD Red WD40EFRX (Serial: WD-WCC4...)
   ├── da3: 4TB WD Red WD40EFRX (Serial: WD-WCC4...)
   ├── da4: 4TB WD Red WD40EFRX (Serial: WD-WCC4...)
   └── da5: 4TB WD Red WD40EFRX (Serial: WD-WCC4...)
   ```

2. **Run SMART Tests on All Drives:**
   - Select each drive → **SMART Tests**
   - Run **Short Test** on all drives
   - Wait for completion and check results
   - Address any failures before proceeding

3. **Verify Drive Specifications:**
   - All drives should be same capacity
   - Preferably same model/manufacturer
   - Check that none are SMR (Shingled Magnetic Recording)

### Wipe Existing Data (If Needed)

**Navigate to**: Storage → Disks

For drives that were previously used:

1. **Select Drive** → **Wipe**
2. **Choose Wipe Method:**
   - **Quick**: Erases partition table (fast)
   - **Full with zeros**: Overwrites entire drive (secure, slow)
   - **Full with random data**: Most secure (very slow)

> ⚠️ **Warning**: Wiping permanently destroys all data on the drive. Ensure backups exist.

---

## 🏗️ Creating Your First Pool

### Basic Home Setup: 4-Drive RAIDZ1

This example creates a pool with 4x4TB drives in RAIDZ1 configuration.

**Navigate to**: Storage → Pools

1. **Click "Create Pool"**

2. **Pool Creation Wizard:**
   
   **Step 1: Pool Name and Encryption**
   - **Name**: `tank` (traditional ZFS pool name)
   - **Encryption**: Consider carefully
     - ✅ **Enable** for sensitive data (requires password on boot)
     - ❌ **Disable** for convenience and performance
   - **Encryption Standard**: `AES-256-GCM` (if enabling)

   **Step 2: Data VDEV Configuration**
   - **Layout**: Select `RAIDZ1`
   - **Available Disks**: You'll see your data drives listed
   - **Drag drives** from Available Disks to the RAIDZ1 VDEV
   - Add all 4 drives to the VDEV

   ```
   Pool Configuration:
   ┌─────────────────────────────────────────────┐
   │ Pool Name: tank                             │
   │ Encryption: [✓] Enabled / [ ] Disabled     │
   │                                             │
   │ Data VDEVs:                                 │
   │ ┌─────────────────────────────────────────┐ │
   │ │ RAIDZ1                                  │ │
   │ │ ├── da2 (4TB WD Red)                    │ │
   │ │ ├── da3 (4TB WD Red)                    │ │
   │ │ ├── da4 (4TB WD Red)                    │ │
   │ │ └── da5 (4TB WD Red)                    │ │
   │ │                                         │ │
   │ │ Estimated Capacity: 12TB                │ │
   │ │ Fault Tolerance: 1 drive                │ │
   │ └─────────────────────────────────────────┘ │
   └─────────────────────────────────────────────┘
   ```

   **Step 3: Cache and Log VDEVs (Optional)**
   - **Cache (L2ARC)**: Skip for now, add later if needed
   - **Log (SLOG)**: Skip for now unless you have specific requirements
   - **Hot Spare**: Skip initially, can add later

   **Step 4: Review and Create**
   - Review the configuration summary
   - **Estimated capacity**: ~12TB usable from 16TB raw
   - **Performance**: Good for home use
   - **Fault tolerance**: Can lose 1 drive without data loss

3. **Confirm Pool Creation:**
   - Read the warnings carefully
   - Type **"CONFIRM"** to proceed
   - Pool creation takes 5-30 minutes depending on drive size

### Advanced Setup: 6-Drive RAIDZ2

For higher reliability with 6 drives:

```
Pool Configuration: tank
├── VDEV: RAIDZ2 (6 drives)
│   ├── da2 (8TB)  ├── da3 (8TB)  ├── da4 (8TB)
│   ├── da5 (8TB)  ├── da6 (8TB)  └── da7 (8TB)
├── Raw Capacity: 48TB
├── Usable Capacity: ~32TB
├── Fault Tolerance: 2 drives
└── Performance: Excellent
```

### Enterprise Setup: Multiple VDEVs

For maximum performance and capacity:

```
Pool Configuration: tank
├── VDEV 1: RAIDZ2 (6x8TB drives) → 32TB usable
├── VDEV 2: RAIDZ2 (6x8TB drives) → 32TB usable  
├── Total Usable: ~64TB
├── Fault Tolerance: 2 drives per VDEV
├── Performance: High throughput
└── Expansion: Add more VDEVs as needed
```

---

## 📊 Pool Verification and Initial Settings

### Verify Pool Creation

**Navigate to**: Storage → Pools

1. **Pool Status Check:**
   - Pool should show **"Online"** status
   - All drives should show **"Online"**
   - Check **"Health"** indicator (should be green)
   - Note the **"Used"** space (minimal initially)

2. **Pool Properties Review:**
   - **Capacity**: Verify expected usable space
   - **Allocated**: Should be very low initially  
   - **Free**: Should show ~90%+ available
   - **Compression**: Note current setting
   - **Deduplication**: Should be off initially

### Configure Pool Settings

**Navigate to**: Storage → Pools → Select Pool → Edit

1. **Basic Pool Settings:**
   - **Compression**: `LZ4` (recommended - low CPU overhead, good compression)
   - **Enable Atime**: `Off` (improves performance, breaks some applications)
   - **ZFS Deduplication**: `Off` (requires massive RAM, rarely beneficial)

2. **Advanced Pool Settings:**
   - **Sync**: `Standard` (change only if you understand implications)
   - **Compression Level**: Default (good balance)
   - **Copies**: `1` (ZFS automatically handles redundancy)

💡 **Recommended Pool Settings:**
```yaml
Compression: lz4          # Good compression, low CPU cost
Atime: off               # Better performance
Deduplication: off       # Avoid unless you understand RAM requirements
Sync: standard           # Default behavior
Checksum: sha256         # Data integrity verification
```

---

## 📁 Dataset Architecture Planning

### Design Your Dataset Structure

Before creating datasets, plan your data organization:

**Home/Family Use Example:**
```
/tank/                              # Pool root
├── family/                         # Family data
│   ├── photos/                     # Photo collection
│   │   ├── 2023/                   # Year-based organization
│   │   └── 2024/
│   ├── videos/                     # Video collection  
│   ├── documents/                  # Important documents
│   └── archives/                   # Long-term storage
├── media/                          # Media server content
│   ├── movies/                     # Movie files
│   ├── tv-shows/                   # TV series
│   ├── music/                      # Music library
│   └── audiobooks/                 # Audiobook collection
├── backups/                        # Backup destinations
│   ├── laptops/                    # Computer backups
│   ├── phones/                     # Mobile device backups
│   └── system/                     # System backups
└── apps/                           # Application data
    ├── nextcloud/                  # Cloud storage app
    ├── plex/                       # Media server data
    └── homeassistant/              # Home automation
```

### Dataset Property Planning

Different datasets need different properties:

| Dataset | Compression | Record Size | Atime | Use Case |
|---------|------------|-------------|-------|----------|
| **photos** | `lz4` | `1M` | `off` | Large image files |
| **documents** | `gzip` | `128K` | `off` | Text/Office files |
| **media** | `lz4` | `1M` | `off` | Video files |
| **backups** | `gzip-9` | `128K` | `off` | Maximum compression |
| **apps** | `lz4` | `16K` | `on` | Database/app files |

---

## 🗂️ Creating Datasets

### Create Top-Level Datasets

**Navigate to**: Storage → Pools → tank → Add Dataset

1. **Family Dataset:**
   - **Name**: `family`
   - **Dataset Preset**: `Generic`
   - **Compression**: `lz4`
   - **Record Size**: `1M` (good for photos/videos)
   - **Atime**: `off`
   - **Case Sensitivity**: `sensitive`

2. **Media Dataset:**
   - **Name**: `media`
   - **Dataset Preset**: `Multimedia`
   - **Compression**: `lz4`
   - **Record Size**: `1M`
   - **Atime**: `off`

3. **Backups Dataset:**
   - **Name**: `backups`
   - **Compression**: `gzip-9` (maximum compression)
   - **Record Size**: `128K`
   - **Atime**: `off`

4. **Apps Dataset:**
   - **Name**: `apps`
   - **Compression**: `lz4`
   - **Record Size**: `16K` (good for databases)
   - **Atime**: `on` (some apps need this)

### Create Child Datasets

For each top-level dataset, create relevant subdirectories:

**Family subdirectories:**
- `tank/family/photos`
- `tank/family/videos`
- `tank/family/documents`

**Media subdirectories:**
- `tank/media/movies`
- `tank/media/tv-shows`
- `tank/media/music`

**Example Dataset Creation:**
```
Create Dataset: tank/family/photos
┌─────────────────────────────────────────────┐
│ Name: photos                                │
│ Parent: tank/family                         │
│ Compression: lz4                           │
│ Record Size: 1M                            │
│ Atime: off                                 │
│ Quota: unlimited                           │
│ Reserved: 0                                │
└─────────────────────────────────────────────┘
```

---

## 🔧 Advanced Dataset Configuration

### Quotas and Reservations

**Use quotas to prevent runaway disk usage:**

1. **Dataset Quotas:**
   ```
   tank/family/photos: 2TB quota     # Limit photo storage
   tank/media: 8TB quota             # Limit media collection
   tank/backups: No quota            # Allow full backup usage
   tank/apps: 500GB quota            # Limit application data
   ```

2. **Reservations:**
   ```
   tank/apps: 100GB reservation      # Guarantee space for apps
   tank/backups: 1TB reservation     # Ensure backup space
   ```

### Compression Testing

Test compression effectiveness on your data:

```bash
# Check compression ratio
zfs get compressratio tank/family/photos

# Expected results:
# photos: ~1.2x (images don't compress much)
# documents: ~3-5x (text compresses well)
# media: ~1.1x (videos already compressed)
```

### Dataset Permissions and ACLs

**Navigate to**: Storage → Pools → tank → Datasets → Select Dataset

1. **Basic UNIX Permissions:**
   - **Owner**: `admin` (your admin user)
   - **Group**: `family-users`
   - **Mode**: `755` (owner full, group/other read-execute)

2. **Advanced ACLs** (for complex permissions):
   - Enable **ACL** support if needed
   - Configure **NFSv4 ACLs** for fine-grained control
   - Set **inheritance** for child directories

---

## 📈 Performance Optimization

### Record Size Optimization

Choose record size based on workload:

```bash
# For large files (photos, videos)
zfs set recordsize=1M tank/media

# For small files (documents, databases)  
zfs set recordsize=16K tank/apps

# For mixed workloads
zfs set recordsize=128K tank/family
```

### ARC (Adaptive Replacement Cache) Tuning

**Navigate to**: System → Advanced

1. **Check Current ARC Usage:**
   ```bash
   # From TrueNAS shell
   arc_summary
   ```

2. **ARC Size Guidelines:**
   ```
   System RAM: 16GB → Max ARC: ~8GB (leave 8GB for system/apps)
   System RAM: 32GB → Max ARC: ~16GB
   System RAM: 64GB → Max ARC: ~32GB
   ```

3. **Set ARC Limits (if needed):**
   - **Minimum ARC Size**: 512MB
   - **Maximum ARC Size**: Leave 50% RAM for system

### Monitoring Pool Performance

**Navigate to**: Storage → Pools → tank → Dataset

Monitor key metrics:
- **IOPS** (Input/Output Operations Per Second)
- **Throughput** (MB/s)
- **Latency** (response time)
- **Queue depth**

---

## 📊 Pool Health Monitoring

### Scrub Configuration

**Navigate to**: Data Protection → Scrub Tasks

1. **Create Scrub Schedule:**
   - **Pool**: `tank`
   - **Schedule**: `Monthly` on 1st Sunday at 2:00 AM
   - **Description**: "Monthly data integrity check"

2. **Scrub Process:**
   - Reads all data and verifies checksums
   - Detects and corrects bit rot
   - Takes hours/days depending on pool size
   - Can run during normal operations (impacts performance)

### SMART Testing Schedule

**Navigate to**: Data Protection → S.M.A.R.T. Tests

1. **Short Tests** (5-10 minutes):
   - **Schedule**: Daily at 3:00 AM
   - **Disks**: All data drives
   - **Description**: "Daily SMART short test"

2. **Long Tests** (2-8 hours):
   - **Schedule**: Weekly on Saturday at 2:00 AM  
   - **Disks**: All data drives
   - **Description**: "Weekly SMART extended test"

### Pool Status Monitoring

Regular health checks:

```bash
# Pool status overview
zpool status

# Detailed pool information
zpool list -v

# Pool I/O statistics  
zpool iostat tank 5

# ARC statistics
arc_summary | head -20
```

---

## ✅ Storage Setup Verification Checklist

### Pool Configuration Verified:
- [ ] **Pool created successfully** with expected capacity
- [ ] **All drives online** and healthy
- [ ] **RAID level appropriate** for fault tolerance needs
- [ ] **Pool properties optimized** (compression, atime, etc.)
- [ ] **Pool health** shows green/healthy status

### Dataset Structure Implemented:
- [ ] **Top-level datasets** created with logical organization
- [ ] **Child datasets** created for specific data types
- [ ] **Dataset properties** optimized for content type
- [ ] **Quotas and reservations** set where appropriate
- [ ] **Permissions** configured correctly

### Monitoring and Maintenance Configured:
- [ ] **Scrub schedule** established (monthly recommended)
- [ ] **SMART testing** configured (daily short, weekly long)
- [ ] **Pool monitoring** dashboard accessible
- [ ] **Alert thresholds** configured for storage issues
- [ ] **Performance baselines** established

### Documentation Updated:
- [ ] **Pool configuration** documented
- [ ] **Dataset structure** mapped and explained  
- [ ] **Performance settings** recorded
- [ ] **Maintenance schedules** documented
- [ ] **Capacity planning** notes created

---

## 🚀 Next Steps

With storage configured, you're ready to:

**[Network Configuration](network-configuration.md)** - Configure VLANs, advanced networking, and prepare for services

---

## 🔧 Troubleshooting Storage Setup

### Common Pool Creation Issues:

**Problem**: Pool creation fails with "devices are busy"
- **Solution**: Wipe drives first, check for existing partitions

**Problem**: Pool shows degraded status
- **Solution**: Check individual drive health, replace failed drives

**Problem**: Poor performance after pool creation
- **Solution**: Check record size settings, verify compression ratios, monitor ARC usage

**Problem**: Pool won't mount after reboot
- **Solution**: Check encryption passwords, verify drive connections, review system logs

### Dataset Creation Issues:

**Problem**: Cannot create dataset with desired name
- **Solution**: Check for naming conflicts, verify parent dataset exists

**Problem**: Permissions issues with dataset access
- **Solution**: Review UNIX permissions, check ACL settings, verify user/group membership

**Problem**: Dataset properties not taking effect
- **Solution**: Check inheritance settings, verify property syntax, restart services if needed

---
*Part of the [Complete TrueNAS Setup Guide](../README.md)*
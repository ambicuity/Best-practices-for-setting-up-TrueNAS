# Hardware Requirements

> **Choosing the right hardware is crucial for a reliable TrueNAS system. This guide helps you select components based on your use case and budget.**

## 🎯 Use Case Categories

### Basic Home Setup (Entry Level)
**Perfect for**: Families, personal media storage, simple file sharing  
**Budget**: $600-$1,500  
**Use Cases**: Photo/video storage, document sharing, Plex media server

### Advanced Home/SOHO (Prosumer)
**Perfect for**: Power users, small businesses, content creators  
**Budget**: $1,500-$4,000  
**Use Cases**: Multiple VMs, advanced backup, high-performance workloads

### Enterprise (Business Critical)
**Perfect for**: Businesses, production environments, high availability  
**Budget**: $4,000+  
**Use Cases**: Business applications, database storage, compliance requirements

---

## 💻 System Requirements

### Minimum Specifications
| Component | Minimum | Recommended | Enterprise |
|-----------|---------|-------------|------------|
| **CPU** | 2 cores, 2GHz | 4+ cores, 3GHz+ | 8+ cores, high-performance |
| **RAM** | 8GB | 16GB | 32GB+ |
| **Boot Storage** | 1x 32GB SSD | 2x 60GB SSD (mirrored) | 2x 120GB+ SSD (mirrored) |
| **Data Storage** | 2x drives | 4+ drives | 6+ drives, hot spares |
| **Network** | 1x Gigabit | 1x Gigabit | 2x Gigabit+ (bonded) |

### Operating System Support
- **TrueNAS SCALE** (Recommended) - Debian-based, actively developed
- **TrueNAS CORE** (Legacy) - FreeBSD-based, limited updates

> 💡 **Tip**: Always choose TrueNAS SCALE for new installations. CORE is end-of-life and no longer actively developed.

---

## 🖥️ Hardware Component Guide

### CPU (Processor)
Modern multi-core processors provide the compute power for ZFS operations and applications.

#### Recommendations by Use Case:

**Basic Home Setup:**
- Intel: Core i3-12100, i5-12400
- AMD: Ryzen 5 5600G, Ryzen 7 5700G
- *Features*: Integrated graphics helpful for troubleshooting

**Advanced Home/SOHO:**
- Intel: Core i5-12600, i7-12700
- AMD: Ryzen 5 7600X, Ryzen 7 7700X
- *Features*: Higher core counts for VMs and applications

**Enterprise:**
- Intel: Xeon E-series, Core i9
- AMD: EPYC, Threadripper PRO
- *Features*: ECC memory support, high core counts

#### Key Considerations:
- **AES-NI Support**: Required for encryption performance
- **Virtualization**: Intel VT-x/AMD-V for running VMs
- **Power Efficiency**: Important for 24/7 operation

---

### Memory (RAM)
ZFS uses RAM extensively for the Adaptive Replacement Cache (ARC).

#### Sizing Guidelines:
```
Basic Formula: 1GB RAM per 1TB of storage (minimum 8GB)
With Applications: Add 2-4GB per concurrent app/VM
High Performance: 1GB RAM per 100GB of frequently accessed data
```

#### Memory Types:
- **ECC (Error-Correcting Code)**: Preferred for data integrity
- **Non-ECC**: Acceptable for home use
- **Speed**: DDR4-3200 or DDR5-4800+ recommended

#### Recommendations:
**Basic Home**: 16GB DDR4 (2x8GB)
**Advanced**: 32GB DDR4 (4x8GB) or 64GB for heavy VM usage
**Enterprise**: 64GB+ ECC memory

> ⚠️ **Warning**: ZFS can be memory-hungry. Insufficient RAM will severely impact performance.

---

### Storage Drives

#### Boot Drives
**Purpose**: Host the TrueNAS operating system  
**Requirements**: Fast, reliable, separate from data storage

**Recommended Configuration:**
- **2x SATA/NVMe SSDs in mirror** (RAID-1)
- **Capacity**: 60GB minimum, 120GB+ recommended
- **Type**: Quality SSDs (Samsung, Crucial, Intel)

💡 **Why mirrored boot drives?** Single points of failure are bad. If one boot drive fails, the system continues running on the other.

#### Data Drives
**Purpose**: Store your actual data in ZFS pools

##### Drive Types:
1. **Hard Disk Drives (HDDs)**
   - **Best for**: Mass storage, backup, archival
   - **Capacity**: 4TB-22TB+
   - **Recommendations**: WD Red, Seagate IronWolf, Toshiba N300

2. **Solid State Drives (SSDs)**
   - **Best for**: High-performance applications, databases
   - **Capacity**: 1TB-8TB+
   - **Recommendations**: Samsung 980 PRO, WD Black SN850

3. **NVMe SSDs**
   - **Best for**: Cache drives, high-IOPS workloads
   - **Usage**: L2ARC (cache) or SLOG (sync writes)

##### Pool Configuration Examples:

**Basic Home (4-drive RAIDZ1):**
```yaml
Pool: tank
VDEV: 4x 4TB HDDs in RAIDZ1
Capacity: ~12TB usable
Fault Tolerance: 1 drive failure
Performance: Good for home use
```

**Advanced (6-drive RAIDZ2):**
```yaml
Pool: tank
VDEV: 6x 8TB HDDs in RAIDZ2
Capacity: ~32TB usable
Fault Tolerance: 2 drive failures
Performance: Excellent resilience
```

**Enterprise (Multiple VDEVs):**
```yaml
Pool: tank
VDEV 1: 6x 8TB HDDs in RAIDZ2
VDEV 2: 6x 8TB HDDs in RAIDZ2
Capacity: ~64TB usable
Performance: High throughput + resilience
```

---

### Network Interface

#### Basic Requirements:
- **1x Gigabit Ethernet** minimum
- **Quality**: Intel-based NICs preferred
- **Built-in**: Most modern motherboards include good NICs

#### Advanced Configurations:
- **Link Aggregation (LAGG)**: 2+ NICs bonded for redundancy/speed
- **10 Gigabit**: For high-performance environments
- **Multiple VLANs**: Separate networks for management, storage, clients

#### Recommended NICs:
- **Intel**: I225-V, I226-V (2.5GbE)
- **10GbE**: Intel X710, Mellanox ConnectX series

---

## 🏗️ Complete Build Examples

### Basic Home Setup ($800-1,200)

**Motherboard + CPU:**
- AMD Ryzen 5 5600G + B450/B550 motherboard
- OR Intel i5-12400 + B660 motherboard

**Memory:**
- 2x8GB DDR4-3200 (16GB total)

**Boot Storage:**
- 2x 60GB SATA SSD (Samsung 980, Crucial MX)

**Data Storage:**
- 4x 4TB WD Red or Seagate IronWolf HDDs

**Case + PSU:**
- Mid-tower case with good airflow
- 600W 80+ Bronze PSU

**Expected Performance:**
- 12TB usable capacity (RAIDZ1)
- 1 drive fault tolerance
- 100MB/s+ sequential throughput

### Advanced Home/SOHO ($2,000-3,500)

**Motherboard + CPU:**
- AMD Ryzen 7 7700X + X670 motherboard
- OR Intel i7-13700 + Z690 motherboard

**Memory:**
- 4x8GB DDR4-3600 (32GB total)
- ECC support if available

**Boot Storage:**
- 2x 120GB NVMe SSD (Samsung 980 PRO)

**Data Storage:**
- 6x 8TB enterprise HDDs (WD Red Pro, Seagate IronWolf Pro)
- Optional: 2x 1TB NVMe for cache

**Network:**
- 2x Gigabit NICs (built-in + PCIe)
- OR 1x 10GbE NIC

**Case + PSU:**
- Full tower or 4U rackmount
- 750W+ 80+ Gold PSU

**Expected Performance:**
- 32TB usable capacity (RAIDZ2)
- 2 drive fault tolerance
- 200MB/s+ sequential throughput

---

## 🔧 Hardware Selection Tips

### Drive Selection Guidelines:

1. **Match Drive Specifications**
   - Same capacity within a VDEV
   - Same or similar speed/performance
   - Preferably same model/manufacturer

2. **Enterprise vs. Consumer Drives**
   - **Enterprise**: Higher reliability, longer warranty, TLER support
   - **Consumer**: Lower cost, adequate for home use
   - **NAS-specific**: Optimized for 24/7 operation

3. **Avoid SMR Drives**
   - Shingled Magnetic Recording (SMR) performs poorly with ZFS
   - Check specifications - avoid drives with SMR technology
   - CMR (Conventional Magnetic Recording) is preferred

### Power and Cooling:

1. **Power Supply Sizing**
   ```
   Formula: (CPU TDP + Drive Count × 10W + 100W base) × 1.3 safety margin
   Example: (65W + 6×10W + 100W) × 1.3 = 293W minimum
   ```

2. **Cooling Requirements**
   - HDDs: Keep below 40°C for longevity
   - SSDs: Monitor thermal throttling
   - CPU: Adequate cooling for sustained loads

3. **UPS (Uninterruptible Power Supply)**
   - **Minimum**: 15-30 minutes runtime
   - **Capacity**: 1.5x total system power draw
   - **Features**: USB monitoring for graceful shutdown

---

## ✅ Hardware Compatibility

### Verified Compatible Hardware:

**Motherboards:**
- Most modern AMD B450/B550/X570/B650/X670
- Intel B460/B560/B660/Z590/Z690/Z790
- Supermicro server boards

**RAID Controllers:**
- **Avoid**: Hardware RAID controllers
- **Use**: HBA mode or direct SATA/SAS connections
- **Good**: LSI SAS controllers in IT mode

**Network Cards:**
- Intel-based NICs (excellent Linux support)
- Realtek NICs (adequate, built into most motherboards)
- Mellanox (for 10GbE and higher)

### Hardware to Avoid:

❌ **Fake/Counterfeit Drives**: Always buy from reputable sources  
❌ **SMR Hard Drives**: Poor ZFS performance  
❌ **Hardware RAID Controllers**: ZFS needs direct drive access  
❌ **Very Old Hardware**: May lack modern CPU features  
❌ **Unreliable PSUs**: Can cause data corruption  

---

## 📋 Pre-Purchase Checklist

Before buying hardware:

- [ ] **Budget defined** and aligned with use case
- [ ] **Power consumption** calculated and acceptable
- [ ] **Space requirements** measured (rack vs. tower)
- [ ] **Cooling plan** adequate for components
- [ ] **Network integration** planned
- [ ] **UPS capacity** sufficient for graceful shutdown
- [ ] **Component compatibility** verified
- [ ] **Expansion plans** considered for future growth

---

**Next Step**: Once you have your hardware selected and purchased, move on to the [Preparation Checklist](preparation-checklist.md) to get ready for installation.

---
*Part of the [Complete TrueNAS Setup Guide](../README.md)*
# Shares and Datasets

> **Configure file sharing services (SMB, NFS, iSCSI) and establish secure data access for users and applications.**

## 🎯 Shares and Services Overview

This guide covers configuring TrueNAS sharing services to provide secure, high-performance access to your stored data. We'll set up SMB for Windows compatibility, NFS for Unix/Linux systems, and iSCSI for block-level storage.

**Estimated Time**: 2-3 hours  
**Difficulty**: Intermediate  
**Prerequisites**: [Security Hardening](../03-configuration/security-hardening.md) completed

---

## 📁 Dataset Review and Organization

### Current Dataset Structure

Review your existing dataset structure before configuring shares:

**Navigate to**: Storage → Pools → tank

```
Dataset Structure Example:
tank/                               # Pool root
├── family/                         # Family data (SMB shares)
│   ├── photos/                     # Photo collection
│   ├── videos/                     # Video collection
│   ├── documents/                  # Important documents
│   └── archives/                   # Long-term storage
├── media/                          # Media server content
│   ├── movies/                     # Movie files (SMB/NFS)
│   ├── tv-shows/                   # TV series
│   ├── music/                      # Music library
│   └── audiobooks/                 # Audiobook collection
├── backups/                        # Backup storage
│   ├── laptops/                    # Computer backups
│   ├── phones/                     # Mobile device backups
│   └── system/                     # System backups
└── apps/                           # Application data
    ├── nextcloud/                  # Cloud storage app
    ├── plex/                       # Media server data
    └── databases/                  # Database storage (iSCSI)
```

### Dataset Permissions Review

Ensure proper permissions are set before sharing:

**Navigate to**: Storage → Datasets → Select Dataset → Edit Permissions

1. **Family Dataset Permissions:**
   - **Owner**: `admin` (administrative user)
   - **Group**: `family-users`
   - **Mode**: `755` (owner: rwx, group: r-x, other: r-x)
   - **ACL**: Enabled for fine-grained control

2. **Media Dataset Permissions:**
   - **Owner**: `media-admin` 
   - **Group**: `family-users`
   - **Mode**: `755`
   - **ACL**: Enabled for service accounts

---

## 🖥️ SMB/CIFS Configuration

### SMB Service Setup

**Navigate to**: Services → SMB

1. **Basic SMB Configuration:**
   ```yaml
   SMB Service Settings:
   ├── NetBIOS Name: TRUENAS-HOME
   ├── NetBIOS Alias: (empty)
   ├── Workgroup: WORKGROUP
   ├── Description: "TrueNAS Family Storage"
   ├── Enable SMB1 support: DISABLED (security)
   ├── NTLMv1 Auth: DISABLED (security)
   ├── Unix Charset: UTF-8
   └── Log Level: Minimum
   ```

2. **Advanced SMB Settings:**
   - **Bind IP Addresses**: Select specific interfaces if using VLANs
   - **Auxiliary Parameters**:
   ```bash
   # Performance and security optimizations
   socket options = TCP_NODELAY IPTOS_LOWDELAY
   deadtime = 15
   use sendfile = yes
   aio read size = 16384
   aio write size = 16384
   server min protocol = SMB2
   server max protocol = SMB3
   ```

3. **Start SMB Service:**
   - **Start Automatically**: Enabled
   - **Enable Service**: Click to start immediately

### Creating SMB Shares

**Navigate to**: Sharing → Windows (SMB)

#### Family Photos Share

1. **Basic Share Settings:**
   - **Path**: `/mnt/tank/family/photos`
   - **Name**: `Family-Photos`
   - **Purpose**: `Multi-user time machine`
   - **Description**: `Family photo collection`

2. **Access Settings:**
   - **Enabled**: Checked
   - **Export Read Only**: Unchecked
   - **Browsable to Network Clients**: Checked
   - **Access Based Share Enumeration**: Checked (security)
   - **Hosts Allow**: Leave empty for all network access
   - **Hosts Deny**: Leave empty

3. **Advanced Options:**
   ```yaml
   Advanced SMB Share Options:
   ├── Use as Home Share: Disabled
   ├── Time Machine: Disabled (unless macOS backup)
   ├── Legacy AFP Compatibility: Disabled
   ├── Enable Shadow Copies: Enabled (snapshot access)
   ├── Export Recycle Bin: Enabled (accidental deletion protection)
   └── Use Apple-style Character Encoding: Enabled (macOS compatibility)
   ```

#### Media Share for Plex

1. **Media Share Configuration:**
   - **Path**: `/mnt/tank/media`
   - **Name**: `Media`
   - **Purpose**: `Multi-protocol sharing`
   - **Description**: `Media server content`

2. **Performance Optimization:**
   ```yaml
   Media Share Settings:
   ├── Export Read Only: Enabled (content protection)
   ├── Browsable: Enabled
   ├── Access Based Share Enumeration: Enabled
   ├── Shadow Copies: Disabled (performance)
   └── Recycle Bin: Disabled (performance)
   ```

#### Administrative Share

1. **Admin Share Configuration:**
   - **Path**: `/mnt/tank/admin`
   - **Name**: `admin$` (hidden share)
   - **Purpose**: `No presets`
   - **Description**: `Administrative access`

2. **Security Settings:**
   ```yaml
   Admin Share Security:
   ├── Browsable: DISABLED (hidden share)
   ├── Access Based Share Enumeration: Enabled
   ├── Hosts Allow: 192.168.1.0/24 (management network only)
   ├── Valid Users: admin
   └── Admin Users: admin
   ```

### SMB User Authentication

**Navigate to**: Directory Services → Active Directory (if joining domain)

**For Workgroup Authentication:**

1. **Local User SMB Access:**
   **Navigate to**: Credentials → Local Users → Select User
   
   - **Microsoft Account**: Disabled
   - **SMB Authentication**: Enabled
   - **Samba Schema**: Enabled

2. **SMB User Testing:**
   ```bash
   # Test SMB connectivity from Windows
   net use Z: \\192.168.1.100\Family-Photos /user:admin
   
   # Test from Linux
   smbclient //192.168.1.100/Family-Photos -U admin
   
   # Test with PowerShell
   New-SmbMapping -LocalPath Z: -RemotePath \\192.168.1.100\Family-Photos
   ```

---

## 🐧 NFS Configuration

### NFS Service Setup

**Navigate to**: Services → NFS

1. **Basic NFS Configuration:**
   ```yaml
   NFS Service Settings:
   ├── Number of servers: 4 (match CPU cores)
   ├── Bind IP Addresses: (select specific interfaces if using VLANs)
   ├── Enable NFSv4: Enabled
   ├── NFSv3 ownership model for NFSv4: Disabled
   ├── Require Kerberos for NFSv4: Disabled (enable if security required)
   ├── Mountd Port: 618 (static for firewall)
   ├── RPC Lockd Port: 32803 (static for firewall)
   └── RPC Statd Port: 662 (static for firewall)
   ```

2. **Advanced NFS Settings:**
   ```yaml
   NFS Advanced Options:
   ├── Support >16 groups: Enabled
   ├── Log mountd requests: Disabled (performance)
   ├── Log file operations: Disabled (performance)
   ├── Serve UDP NFS clients: Disabled (use TCP)
   └── Allow non-root mount: Disabled (security)
   ```

3. **Start NFS Service:**
   - **Start Automatically**: Enabled
   - **Enable Service**: Click to start

### Creating NFS Shares

**Navigate to**: Sharing → Unix (NFS)

#### Media NFS Share for Linux Clients

1. **Basic NFS Share:**
   - **Path**: `/mnt/tank/media`
   - **Description**: `Media content for Linux clients`
   - **All Directories**: Checked
   - **Quiet**: Unchecked
   - **Enabled**: Checked

2. **Access Control:**
   ```yaml
   NFS Share Access:
   ├── Read Only: Enabled (content protection)
   ├── Maproot User: nobody
   ├── Maproot Group: nogroup
   ├── Mapall User: (empty - preserve user mapping)
   ├── Mapall Group: (empty - preserve group mapping)
   ├── Authorized Networks: 192.168.1.0/24
   └── Authorized Hosts: (specific hosts if needed)
   ```

3. **Security Options:**
   ```yaml
   NFS Security Settings:
   ├── Security: SYS (basic) or KRB5 (if Kerberos)
   └── Network: 192.168.1.0/24, 10.0.20.0/24 (storage VLAN)
   ```

#### Application Data NFS Share

1. **Application NFS Share:**
   - **Path**: `/mnt/tank/apps`
   - **Description**: `Application data storage`
   - **All Directories**: Checked
   - **Read Only**: Unchecked

2. **Performance Settings:**
   ```yaml
   App Data NFS Settings:
   ├── Maproot User: root (for system services)
   ├── Maproot Group: wheel
   ├── Authorized Networks: 10.0.20.0/24 (storage network)
   └── Security: SYS
   ```

### NFS Client Configuration Examples

**Linux NFS Client:**
```bash
# Install NFS client
sudo apt install nfs-common  # Debian/Ubuntu
sudo yum install nfs-utils    # RHEL/CentOS

# Create mount point
sudo mkdir -p /mnt/truenas/media

# Mount NFS share
sudo mount -t nfs 192.168.1.100:/mnt/tank/media /mnt/truenas/media

# Permanent mount (add to /etc/fstab)
echo "192.168.1.100:/mnt/tank/media /mnt/truenas/media nfs defaults 0 0" >> /etc/fstab
```

**macOS NFS Client:**
```bash
# Create mount point
sudo mkdir -p /Volumes/TrueNAS-Media

# Mount NFS share
sudo mount -t nfs -o resvport 192.168.1.100:/mnt/tank/media /Volumes/TrueNAS-Media
```

---

## 🎯 iSCSI Configuration

### iSCSI Overview

iSCSI provides block-level storage access, perfect for:
- **Virtual machine storage**
- **Database applications**
- **High-performance applications requiring raw block access**

### iSCSI Service Configuration

**Navigate to**: Services → iSCSI

1. **Enable iSCSI Service:**
   - **Start Automatically**: Enabled
   - **Enable Service**: Click to start

### Creating iSCSI Storage

#### Step 1: Create Block Device (Zvol)

**Navigate to**: Storage → Pools → tank → Add Zvol

1. **Zvol Configuration:**
   ```yaml
   iSCSI Zvol Settings:
   ├── Zvol name: vm-storage-01
   ├── Comments: "Virtual machine storage"
   ├── Size: 500 GiB
   ├── Force size: Unchecked
   ├── Sync: Standard
   ├── Compression level: lz4
   ├── ZFS Deduplication: off
   ├── Sparse: Unchecked (better performance)
   └── Block size: 16K (good for VMs)
   ```

#### Step 2: Create iSCSI Target

**Navigate to**: Sharing → Block (iSCSI) → Targets

1. **Target Configuration:**
   - **Target Name**: `iqn.2024-01.local.truenas:vm-storage-01`
   - **Target Alias**: `VM Storage 01`

2. **Target Groups:**
   - Create or select appropriate target group
   - Associate with portals and initiators

#### Step 3: Create Portal

**Navigate to**: Sharing → Block (iSCSI) → Portals

1. **Portal Configuration:**
   ```yaml
   iSCSI Portal Settings:
   ├── Description: Primary iSCSI Portal
   ├── IP Address: 0.0.0.0 (all interfaces) or specific storage network IP
   ├── Port: 3260 (standard iSCSI port)
   └── Authentication Method: CHAP (recommended)
   ```

#### Step 4: Create Initiator

**Navigate to**: Sharing → Block (iSCSI) → Initiators

1. **Initiator Configuration:**
   - **Initiators**: `iqn.1993-08.org.debian:01:client-hostname`
   - **Authorized Network**: `192.168.1.0/24`
   - **Description**: `Linux client access`

#### Step 5: Create Authorized Access

**Navigate to**: Sharing → Block (iSCSI) → Authorized Access

1. **CHAP Authentication:**
   ```yaml
   iSCSI Authentication:
   ├── Group ID: 1
   ├── User: iscsi-user
   ├── Secret: [strong password 12-16 chars]
   ├── Peer User: (for mutual authentication)
   └── Peer Secret: (for mutual authentication)
   ```

#### Step 6: Associate Extent

**Navigate to**: Sharing → Block (iSCSI) → Extents

1. **Extent Configuration:**
   ```yaml
   iSCSI Extent Settings:
   ├── Extent Name: vm-storage-01-extent
   ├── Description: VM Storage Extent
   ├── Enabled: Checked
   ├── Extent Type: Device
   ├── Device: zvol/tank/vm-storage-01
   ├── Logical Block Size: 512 (compatibility) or 4096 (performance)
   └── Disable Physical Block Size Reporting: Unchecked
   ```

#### Step 7: Create Associated Target

**Navigate to**: Sharing → Block (iSCSI) → Associated Targets

1. **Target Association:**
   - **Target**: Select created target
   - **LUN ID**: 0
   - **Extent**: Select created extent

### iSCSI Client Configuration

**Linux iSCSI Initiator:**
```bash
# Install iSCSI initiator
sudo apt install open-iscsi  # Debian/Ubuntu
sudo yum install iscsi-initiator-utils  # RHEL/CentOS

# Configure initiator name (edit /etc/iscsi/initiatorname.iscsi)
InitiatorName=iqn.1993-08.org.debian:01:client-hostname

# Configure CHAP authentication (edit /etc/iscsi/iscsid.conf)
node.session.auth.authmethod = CHAP
node.session.auth.username = iscsi-user
node.session.auth.password = your-secret-password

# Discover targets
sudo iscsiadm -m discovery -t st -p 192.168.1.100:3260

# Login to target
sudo iscsiadm -m node --targetname iqn.2024-01.local.truenas:vm-storage-01 --portal 192.168.1.100:3260 --login

# Format and mount the device
sudo fdisk /dev/sdb  # Create partition
sudo mkfs.ext4 /dev/sdb1  # Format
sudo mkdir /mnt/iscsi-storage
sudo mount /dev/sdb1 /mnt/iscsi-storage
```

---

## 🔧 Service Performance Optimization

### SMB Performance Tuning

1. **SMB Auxiliary Parameters:**
   ```bash
   # Add to SMB auxiliary parameters for performance
   socket options = TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=65536 SO_SNDBUF=65536
   use sendfile = yes
   min receivefile size = 16384
   aio read size = 16384
   aio write size = 16384
   server multi channel support = yes
   ```

2. **Network Optimization:**
   - **Jumbo Frames**: Enable if network supports (MTU 9000)
   - **SMB Multichannel**: Enable for multiple network interfaces
   - **VLAN Separation**: Use dedicated storage network

### NFS Performance Tuning

1. **NFS Server Optimization:**
   - **Server Threads**: Match CPU core count
   - **Read/Write Size**: Test with different values (32K-64K)
   - **UDP Support**: Disable (use TCP only)

2. **Client-side Optimization:**
   ```bash
   # Optimized NFS mount options
   mount -t nfs -o rsize=32768,wsize=32768,intr,hard,bg,tcp 192.168.1.100:/mnt/tank/media /mnt/truenas
   ```

### iSCSI Performance Tuning

1. **Zvol Optimization:**
   - **Block Size**: 16K for VMs, 128K for databases
   - **Compression**: LZ4 (good balance)
   - **Sync**: Consider `disabled` for performance (data loss risk)

2. **Network Optimization:**
   - **Dedicated Network**: Use storage VLAN
   - **Jumbo Frames**: Enable for high throughput
   - **Multiple Sessions**: Configure multipath for redundancy

---

## 📊 Monitoring and Troubleshooting

### Service Status Monitoring

```bash
# Check service status
systemctl status smbd nmbd
systemctl status nfs-server
systemctl status iscsid

# Monitor active connections
smbstatus
showmount -a
iscsiadm -m session -o show

# Performance monitoring
nfsstat
iostat -x 5
iftop -i eth0
```

### Common Share Issues

**SMB Connection Problems:**
```bash
# Test SMB connectivity
smbclient -L 192.168.1.100 -U admin
testparm -s  # Check SMB configuration

# Check SMB logs
tail -f /var/log/samba/smbd.log
```

**NFS Mount Issues:**
```bash
# Check NFS exports
showmount -e 192.168.1.100
exportfs -v

# Test NFS connectivity
rpcinfo -p 192.168.1.100
```

**iSCSI Connection Problems:**
```bash
# Check iSCSI status
systemctl status iscsid
iscsiadm -m session

# Debug iSCSI connections
tail -f /var/log/messages | grep iscsi
```

---

## ✅ Shares and Services Checklist

### SMB Configuration:
- [ ] **SMB service** enabled and running
- [ ] **Security settings** hardened (SMB2+, NTLMv1 disabled)
- [ ] **Family shares** configured with appropriate permissions
- [ ] **Media shares** configured for content access
- [ ] **Administrative shares** secured and hidden
- [ ] **User authentication** working correctly
- [ ] **Performance optimizations** applied

### NFS Configuration:
- [ ] **NFS service** enabled and running (NFSv4 preferred)
- [ ] **Media shares** configured for Unix/Linux clients
- [ ] **Application shares** configured with proper security
- [ ] **Static ports** configured for firewall rules
- [ ] **Client access** tested and working
- [ ] **Performance settings** optimized

### iSCSI Configuration:
- [ ] **iSCSI service** enabled and running
- [ ] **Block devices (zvols)** created with appropriate settings
- [ ] **Targets and portals** configured correctly
- [ ] **CHAP authentication** implemented
- [ ] **Client connectivity** tested and working
- [ ] **Performance optimizations** applied

### Security and Access:
- [ ] **Share permissions** follow principle of least privilege
- [ ] **Network restrictions** implemented where appropriate
- [ ] **Service binding** limited to appropriate interfaces
- [ ] **Authentication mechanisms** properly configured
- [ ] **Access logging** enabled for audit trails

---

## 🚀 Next Steps

With shares and services configured, you're ready to:

**[Backup Configuration](backup-configuration.md)** - Implement comprehensive 3-2-1 backup strategy with snapshots and replication

---
*Part of the [Complete TrueNAS Setup Guide](../README.md)*
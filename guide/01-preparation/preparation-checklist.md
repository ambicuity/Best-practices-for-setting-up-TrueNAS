# Preparation Checklist

> **Proper preparation prevents poor performance. Use this comprehensive checklist to ensure you're ready for a successful TrueNAS installation.**

## 🎯 Overview

This checklist covers everything you need to prepare before installing TrueNAS. Taking time to plan and prepare will save hours of troubleshooting later.

---

## 🔧 Hardware Preparation

### Physical Assembly
- [ ] **Hardware assembled** and powered on successfully
- [ ] **All drives connected** and detected in BIOS/UEFI
- [ ] **Memory installed** and running at correct speeds
- [ ] **Boot drive(s) prepared** (ideally 2 SSDs for mirroring)
- [ ] **Network cable connected** to primary NIC
- [ ] **Monitor and keyboard** connected for initial setup

### BIOS/UEFI Settings
- [ ] **AHCI mode enabled** (not IDE mode)
- [ ] **Hardware RAID disabled** (use AHCI/JBOD mode)
- [ ] **Virtualization enabled** (Intel VT-x/AMD-V) if running VMs
- [ ] **UEFI boot mode** enabled (preferred over Legacy BIOS)
- [ ] **Secure Boot disabled** (TrueNAS compatibility)
- [ ] **Memory settings optimized** (XMP/DOCP enabled if applicable)

💡 **BIOS Configuration Example:**
```
Storage Configuration:
├── SATA Mode: AHCI
├── RAID Support: Disabled
└── Hot Plug: Enabled

CPU Configuration:
├── Intel VT-x: Enabled
├── AMD-V: Enabled
└── IOMMU: Enabled (for PCIe passthrough)

Boot Configuration:
├── Boot Mode: UEFI
├── Secure Boot: Disabled
└── CSM Support: Disabled
```

---

## 🌐 Network Planning

### Network Information Collection
Document your network configuration:

**Basic Network Settings:**
- [ ] **Router IP address**: ________________
- [ ] **Subnet mask**: ________________  
- [ ] **DNS servers**: ________________
- [ ] **Available IP range**: ________________
- [ ] **Preferred static IP for TrueNAS**: ________________

**Advanced Network Settings:**
- [ ] **VLAN configuration** (if used): ________________
- [ ] **Gateway configuration**: ________________
- [ ] **Domain name** (if applicable): ________________
- [ ] **NTP servers** (if custom): ________________

### Network Access Plan
- [ ] **Administrative access method** planned (local vs. remote)
- [ ] **VPN requirements** identified for remote access
- [ ] **Firewall rules** planned for services
- [ ] **Client device compatibility** verified (SMB versions, etc.)

💡 **Network Planning Worksheet:**
```
TrueNAS Network Configuration:
┌─────────────────────────────────────────────┐
│ Primary Interface: eth0                     │
│ IP Address: 192.168.1.100                   │
│ Subnet Mask: 255.255.255.0 (/24)           │
│ Gateway: 192.168.1.1                        │
│ DNS: 8.8.8.8, 1.1.1.1                      │
│ Domain: local.domain                        │
└─────────────────────────────────────────────┘

Additional Interfaces (if applicable):
┌─────────────────────────────────────────────┐
│ VLAN 10 (Management): 10.0.10.100          │
│ VLAN 20 (Storage): 10.0.20.100             │
│ VLAN 30 (Backup): 10.0.30.100              │
└─────────────────────────────────────────────┘
```

---

## 💾 Storage Planning

### Drive Inventory
Document all storage devices:

**Boot Drives:**
- [ ] **Drive 1**: ________________ (Model, Serial, Size)
- [ ] **Drive 2**: ________________ (Model, Serial, Size)

**Data Drives:**
- [ ] **Drive 1**: ________________ (Model, Serial, Size)
- [ ] **Drive 2**: ________________ (Model, Serial, Size)
- [ ] **Drive 3**: ________________ (Model, Serial, Size)
- [ ] **Drive 4**: ________________ (Model, Serial, Size)
- [ ] **Additional drives** as needed...

### Pool Planning
Design your storage pools:

**Pool Configuration Decision:**
- [ ] **Pool name chosen**: ________________
- [ ] **RAID level selected**: ________________ (RAIDZ1/RAIDZ2/Mirror)
- [ ] **Expected usable capacity**: ________________
- [ ] **Fault tolerance**: ________________ drive failures
- [ ] **Hot spare plan**: ________________

💡 **Pool Planning Examples:**

**Basic Home Setup (RAIDZ1):**
```yaml
Pool Name: tank
Configuration: RAIDZ1
Drives: 4x 4TB HDDs
Raw Capacity: 16TB
Usable Capacity: ~12TB
Fault Tolerance: 1 drive
Expansion Plan: Replace all drives with larger ones
```

**Advanced Setup (RAIDZ2):**
```yaml
Pool Name: tank
Configuration: RAIDZ2  
Drives: 6x 8TB HDDs
Raw Capacity: 48TB
Usable Capacity: ~32TB
Fault Tolerance: 2 drives
Hot Spares: 1x 8TB HDD
Expansion Plan: Add second VDEV
```

---

## 📁 Data Organization Planning

### Dataset Structure Design
Plan your dataset hierarchy:

**Basic Structure Example:**
```
tank/                           # Root dataset
├── family/                     # Family data
│   ├── photos/                 # Photo collection
│   ├── videos/                 # Video collection
│   └── documents/              # Important documents
├── media/                      # Media server content
│   ├── movies/                 # Movie files
│   ├── tv-shows/              # TV series
│   └── music/                 # Music collection
├── backups/                   # System backups
│   ├── laptops/               # Laptop backups
│   └── phones/                # Phone backups
└── apps/                      # Application data
    ├── nextcloud/             # Cloud storage
    └── plex/                  # Media server
```

### User and Permission Planning
- [ ] **User accounts needed**: ________________
- [ ] **Group structure planned**: ________________
- [ ] **Access permissions defined**: ________________
- [ ] **Administrative users identified**: ________________

💡 **Permission Planning Example:**
```
Users and Groups:
┌─────────────────────────────────────────────┐
│ admin-group: alice, bob                     │
│ ├── Full system access                      │
│ └── SSH access enabled                      │
│                                             │
│ family-users: alice, bob, charlie, diana    │
│ ├── Read/write to family/ datasets          │
│ └── Read-only to media/ datasets            │
│                                             │
│ media-admin: alice                          │
│ ├── Manage media/ datasets                  │
│ └── Plex administration                     │
└─────────────────────────────────────────────┘
```

---

## 🔐 Security Planning

### Access Control
- [ ] **SSH key pair generated** for secure access
- [ ] **Strong admin passwords** created and stored securely
- [ ] **Two-factor authentication** method chosen
- [ ] **VPN solution selected** for remote access (WireGuard/OpenVPN)

### Security Policies
- [ ] **Firewall rules planned** for each service
- [ ] **Network segmentation** strategy defined
- [ ] **Backup encryption** requirements identified
- [ ] **Update schedule** planned (security vs. stability)

### Access Method Planning
**Local Access:**
- [ ] Console/direct access available
- [ ] Local network Web UI access planned
- [ ] Emergency access procedure defined

**Remote Access:**
- [ ] VPN server configuration planned
- [ ] Remote backup access method defined
- [ ] Emergency remote access procedure planned

> ⚠️ **Security Golden Rule**: Never expose the TrueNAS Web UI directly to the Internet. Always use VPN for remote access.

---

## 💿 Installation Media Preparation

### TrueNAS ISO Download
- [ ] **Latest TrueNAS SCALE ISO downloaded** from official source
- [ ] **ISO checksum verified** for integrity
- [ ] **USB installer created** (8GB+ USB drive)
- [ ] **Installation media tested** on target hardware

### Installation Media Creation

**Using Rufus (Windows):**
1. Download Rufus from rufus.ie
2. Select TrueNAS ISO file
3. Choose target USB drive
4. Use DD image mode
5. Create bootable USB

**Using Balena Etcher (Cross-platform):**
1. Download from balena.io/etcher
2. Select TrueNAS ISO
3. Select USB drive
4. Flash image

**Using dd (Linux/macOS):**
```bash
# Find USB device
lsblk  # or diskutil list on macOS

# Flash ISO (replace /dev/sdX with your USB device)
sudo dd if=TrueNAS-SCALE-22.12.0.iso of=/dev/sdX bs=4M status=progress
```

---

## 📊 Documentation Preparation

### System Documentation Template
Create a system documentation file with:

**System Information:**
```
TrueNAS System Documentation
============================

Hardware Configuration:
- CPU: ________________
- RAM: ________________
- Motherboard: ________________
- Boot Drives: ________________
- Data Drives: ________________

Network Configuration:
- Management IP: ________________
- Subnet/VLAN: ________________
- Gateway: ________________
- DNS: ________________

Storage Configuration:
- Pool Name: ________________
- RAID Level: ________________
- Capacity: ________________
- Fault Tolerance: ________________

Installed Date: ________________
Administrator: ________________
```

### Maintenance Schedule Template
- [ ] **SMART test schedule** planned
- [ ] **Scrub schedule** defined
- [ ] **Backup verification** schedule set
- [ ] **Update schedule** planned
- [ ] **Monitor check** frequency defined

---

## 🛠️ Tools and Utilities

### Required Tools
- [ ] **Web browser** for TrueNAS Web UI access
- [ ] **SSH client** (PuTTY, OpenSSH, etc.)
- [ ] **Text editor** for configuration files
- [ ] **Network scanner** (Advanced IP Scanner, nmap)
- [ ] **Drive health monitoring** tools

### Optional but Recommended
- [ ] **Ansible** (for automation)
- [ ] **Git** (for configuration version control)
- [ ] **Monitoring tools** (Grafana, Prometheus)
- [ ] **Backup verification tools**

---

## ☁️ Backup and Recovery Preparation

### Existing Data Backup
- [ ] **All important data backed up** to external location
- [ ] **Backup integrity verified** before proceeding
- [ ] **Recovery procedure tested** and documented
- [ ] **Backup storage secured** and accessible

### Recovery Planning
- [ ] **Recovery media prepared** (USB installer)
- [ ] **Configuration backup plan** defined
- [ ] **Emergency contact information** documented
- [ ] **Recovery time objectives** defined

### Off-site Backup Planning
- [ ] **Cloud storage accounts** prepared (if using)
- [ ] **Off-site location** identified for physical backups
- [ ] **Network bandwidth** calculated for initial sync
- [ ] **Encryption keys** planned and secured

---

## 🧪 Testing Environment (Recommended)

### Lab Setup
- [ ] **Virtual machine** prepared for testing (if possible)
- [ ] **Test data** prepared for validation
- [ ] **Network isolation** planned for testing
- [ ] **Rollback procedures** tested

### Validation Plan
- [ ] **Installation procedure** tested in lab
- [ ] **Basic configuration** validated
- [ ] **Performance benchmarks** established
- [ ] **Recovery procedures** tested

---

## ✅ Final Pre-Installation Checklist

### System Readiness
- [ ] **Hardware assembled** and tested
- [ ] **BIOS configured** optimally
- [ ] **Network planned** and documented
- [ ] **Storage design** finalized
- [ ] **Security plan** in place

### Documentation Ready
- [ ] **System documentation** template prepared
- [ ] **Network configuration** documented
- [ ] **User accounts** planned
- [ ] **Maintenance schedules** defined

### Installation Ready
- [ ] **TrueNAS ISO** downloaded and verified
- [ ] **Boot USB** created and tested
- [ ] **Console access** available
- [ ] **Network access** confirmed

### Safety Measures
- [ ] **Existing data backed up**
- [ ] **Recovery plan** documented
- [ ] **Emergency contacts** available
- [ ] **Time allocated** for installation (4-8 hours minimum)

---

## 🚀 Ready to Install!

Once all items in this checklist are complete, you're ready to proceed to the **[Basic Installation](../02-installation/basic-installation.md)** section.

> 💡 **Pro Tip**: Keep this checklist handy during installation. You'll reference network settings, storage plans, and user accounts throughout the setup process.

---

## 📋 Troubleshooting Preparation Issues

### Common Preparation Problems:

**Hardware Not Detected:**
- Verify BIOS settings (AHCI mode)
- Check cable connections
- Update BIOS/UEFI firmware
- Test components individually

**Network Planning Confusion:**
- Use network discovery tools
- Consult router/switch documentation
- Test with simple static IP first
- Verify cable connectivity

**Storage Planning Uncertainty:**
- Use TrueNAS documentation calculator
- Consult ZFS capacity planning guides
- Consider future growth needs
- Plan for failure scenarios

---
*Part of the [Complete TrueNAS Setup Guide](../README.md)*
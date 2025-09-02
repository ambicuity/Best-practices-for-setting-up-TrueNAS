# Basic Installation

> **This guide walks you through installing TrueNAS SCALE step-by-step, from first boot to initial system access.**

## 🎯 Installation Overview

The TrueNAS installation process is straightforward but requires careful attention to drive selection and initial configuration. This guide covers a clean installation on new hardware.

**Estimated Time**: 1-2 hours  
**Difficulty**: Beginner  
**Prerequisites**: [Preparation Checklist](../01-preparation/preparation-checklist.md) completed

---

## ⚠️ Pre-Installation Warnings

> **CRITICAL**: The installation process will **erase all data** on the selected drives. Ensure you have:
> - ✅ Backed up all important data
> - ✅ Selected the correct drives for installation
> - ✅ Console/local access to the system

### Drive Selection Safety:
- **Boot drives**: Separate from data drives (use SSDs)
- **Data drives**: Will be configured later, not during OS installation
- **Verification**: Double-check drive serial numbers if unsure

---

## 💿 Boot from Installation Media

### 1. Insert Installation Media
- Insert the TrueNAS installation USB drive
- Connect monitor and keyboard to the system
- Power on the system

### 2. Boot from USB
Most systems will automatically detect the USB drive. If not:
- Access BIOS/UEFI setup (usually F2, F12, or DEL during boot)
- Navigate to Boot Menu or Boot Priority
- Select the USB drive as primary boot device
- Save and exit BIOS

### 3. TrueNAS Boot Menu
You should see the TrueNAS boot menu:

```
TrueNAS Installer
┌─────────────────────────────────────────────┐
│ 1. Install/Upgrade TrueNAS                 │
│ 2. Shell (for recovery/advanced users)     │
│ 3. Boot from first hard drive              │
│ 4. Reboot                                   │
└─────────────────────────────────────────────┘
```

- Select **"1. Install/Upgrade TrueNAS"**
- Press Enter to continue

---

## 🔧 Installation Wizard

### Step 1: Welcome Screen
The installer will display a welcome message and system information.

- Review the detected hardware
- Verify RAM and network interfaces are detected
- Press **Enter** to continue

### Step 2: Drive Selection
**This is the most critical step** - selecting where to install TrueNAS.

```
Available Drives:
┌─────────────────────────────────────────────┐
│ [ ] da0: 60GB SSD (Samsung 980)            │
│ [ ] da1: 60GB SSD (Samsung 980)            │
│ [ ] da2: 4TB HDD (WD Red WD40EFRX)         │
│ [ ] da3: 4TB HDD (WD Red WD40EFRX)         │
│ [ ] da4: 4TB HDD (WD Red WD40EFRX)         │
│ [ ] da5: 4TB HDD (WD Red WD40EFRX)         │
└─────────────────────────────────────────────┘
```

**For Basic Single Boot Drive:**
- Select only one SSD (e.g., da0)
- Use arrow keys to navigate, spacebar to select
- Press Enter to continue

**For Mirrored Boot Drives (Recommended):**
- Select both SSDs (e.g., da0 and da1)
- This creates a mirrored boot environment
- Higher reliability - if one SSD fails, system continues

> 💡 **Tip**: Always use SSDs for boot drives. They're faster and more reliable than HDDs for the operating system.

> ⚠️ **Warning**: Do NOT select your data drives (large HDDs). These will be configured later for ZFS pools.

### Step 3: Installation Confirmation
The installer will show your selections:

```
Installation Summary:
┌─────────────────────────────────────────────┐
│ Install Location: da0, da1 (Mirrored)      │
│ Installation Type: Fresh Install           │
│ Selected Drives: 2                         │
│ This will ERASE all data on selected drives│
└─────────────────────────────────────────────┘

Proceed with installation? [yes/No]:
```

- Type **"yes"** to confirm (case-sensitive)
- Press Enter to begin installation

### Step 4: Installation Progress
The installer will:
1. Format the selected drives
2. Copy TrueNAS system files
3. Configure boot environment
4. Install bootloader

```
Installing TrueNAS...
┌─────────────────────────────────────────────┐
│ [████████████████████████████████████] 100% │
│ Status: Installing boot environment         │
│ Time Remaining: ~2 minutes                  │
└─────────────────────────────────────────────┘
```

**Installation typically takes 10-20 minutes** depending on drive speed.

### Step 5: Set Root Password
After installation completes, you'll be prompted to set the root password:

```
Set Root Password:
┌─────────────────────────────────────────────┐
│ The root password is used for console       │
│ access and emergency recovery.              │
│                                             │
│ Password: [        ]                        │
│ Confirm:  [        ]                        │
└─────────────────────────────────────────────┘
```

**Password Requirements:**
- Minimum 8 characters
- Mix of letters, numbers, symbols
- Avoid dictionary words
- Store securely - needed for emergency access

> 💡 **Example Strong Password**: `TrueNAS2024!Setup`

### Step 6: Installation Complete
You'll see a completion message:

```
Installation Complete!
┌─────────────────────────────────────────────┐
│ TrueNAS has been successfully installed     │
│                                             │
│ Please remove the installation media and    │
│ reboot the system.                          │
│                                             │
│ Press Enter to reboot                       │
└─────────────────────────────────────────────┘
```

- Remove the USB installation drive
- Press Enter to reboot

---

## 🔄 First Boot

### 1. System Startup
After rebooting, the system will:
1. Boot from the newly installed TrueNAS
2. Initialize system services
3. Configure network interfaces
4. Start the web interface

### 2. Console Display
You should see the TrueNAS console screen:

```
TrueNAS SCALE Console
┌─────────────────────────────────────────────┐
│ TrueNAS SCALE 22.12.0                       │
│ https://www.truenas.com                     │
│                                             │
│ Web Interface: http://192.168.1.100        │
│                https://192.168.1.100       │
│                                             │
│ Console Menu                                │
│ 1) Configure Network Interfaces            │
│ 2) Configure Link Aggregation              │
│ 3) Configure VLAN Interface                │
│ 4) Configure Default Route                 │
│ 5) Configure Static Routes                 │
│ 6) Configure DNS                           │
│ 7) Reset Root Password                     │
│ 8) Reset to Factory Defaults               │
│ 9) Shell                                   │
│ 10) System Update                          │
│ 11) Reboot                                 │
│ 12) Shutdown                               │
└─────────────────────────────────────────────┘
```

### 3. Note the IP Address
The console shows the current IP address for web access:
- **HTTP**: `http://192.168.1.100` (replace with actual IP)
- **HTTPS**: `https://192.168.1.100` (preferred)

> 💡 **Note**: The IP address shown depends on your network configuration. It might be different from the example.

---

## 🌐 Initial Network Configuration

### Option 1: Use DHCP (Easiest)
If your router provides DHCP, TrueNAS should automatically receive an IP address. This is shown on the console screen.

### Option 2: Configure Static IP
For more control, set a static IP address:

1. From the console menu, select **"1) Configure Network Interfaces"**
2. Select your network interface (usually `eth0` or `enp0s3`)
3. Choose **"Configure IPv4 Address"**
4. Select **"Static"**
5. Enter your planned IP configuration:
   - **IP Address**: `192.168.1.100` (from your planning)
   - **Netmask**: `255.255.255.0` (or `/24`)
   - **Gateway**: `192.168.1.1` (your router IP)

💡 **Network Configuration Example:**
```
Network Interface Configuration:
┌─────────────────────────────────────────────┐
│ Interface: eth0                             │
│ Configuration: Static                       │
│ IP Address: 192.168.1.100                   │
│ Netmask: 255.255.255.0                     │
│ Gateway: 192.168.1.1                       │
│ DNS Servers: 8.8.8.8, 1.1.1.1             │
└─────────────────────────────────────────────┘
```

### Verify Network Connectivity
Test network access from another computer:
```bash
# Test basic connectivity
ping 192.168.1.100

# Test HTTP access
curl -I http://192.168.1.100

# Test HTTPS access (may show certificate warning)
curl -I https://192.168.1.100
```

---

## 💻 First Web Interface Access

### 1. Open Web Browser
From a computer on the same network:
- Open your web browser
- Navigate to the IP address shown on console
- Use HTTPS for secure connection: `https://192.168.1.100`

### 2. Certificate Warning
You may see a security warning about the certificate:
```
This site's security certificate is not trusted!
The certificate is self-signed.
```

This is normal for initial setup:
- Click **"Advanced"** or **"More Information"**
- Click **"Proceed to site"** or **"Continue to website"**
- The warning appears because TrueNAS uses a self-signed certificate initially

### 3. Login Screen
You should see the TrueNAS login page:

```
TrueNAS SCALE
┌─────────────────────────────────────────────┐
│               Welcome to TrueNAS            │
│                                             │
│ Username: [root      ]                      │
│ Password: [          ]                      │
│                                             │
│ [ ] Remember me                             │
│                                             │
│        [    Login    ]                      │
└─────────────────────────────────────────────┘
```

**Login Credentials:**
- **Username**: `root`
- **Password**: The password you set during installation

### 4. First Login Success
After successful login, you'll see the TrueNAS dashboard with:
- System overview and status
- Quick setup wizard (may appear)
- Navigation menu on the left
- System health indicators

---

## 📊 Post-Installation Verification

### System Status Check
Verify the installation is working correctly:

**Dashboard Checks:**
- [ ] **System version** displays correctly
- [ ] **Uptime** shows recent boot time
- [ ] **CPU usage** is reasonable (<50% idle)
- [ ] **Memory usage** shows available RAM
- [ ] **Network status** shows active interface

### Console Access Verification
Ensure console access works:
1. Go back to the server console
2. Try logging in with root credentials
3. Test basic commands:
```bash
# Check system status
systemctl status truenas

# Check memory usage
free -h

# Check disk status
lsblk

# Check network interfaces
ip addr show
```

### Network Services Check
Verify essential services are running:
```bash
# Check if SSH is running (will be enabled in next steps)
systemctl status ssh

# Check if web interface is running
systemctl status truenas-middlewared
```

---

## 🔧 Installation Troubleshooting

### Common Installation Issues:

**Problem**: Installer doesn't boot from USB
- **Solution**: Check BIOS boot order, try different USB port, recreate installation media

**Problem**: No drives detected during installation
- **Solution**: Enable AHCI mode in BIOS, check SATA cable connections

**Problem**: Installation fails with error
- **Solution**: Check drive health, verify sufficient disk space, try different drives

**Problem**: System won't boot after installation
- **Solution**: Check BIOS boot order, ensure installation drive is selected

**Problem**: Can't access web interface
- **Solution**: Check network configuration, verify IP address, test from different device

### Network Access Issues:

**Problem**: IP address not showing on console
- **Solution**: Check network cable, verify DHCP/static configuration

**Problem**: Can't reach web interface from browser
- **Solution**: Ping test the IP, check firewall settings, verify same network segment

**Problem**: Certificate warnings preventing access
- **Solution**: Accept security exception, use HTTP instead of HTTPS temporarily

---

## 📋 Installation Completion Checklist

Before proceeding to initial setup:

- [ ] **TrueNAS installed successfully** on boot drive(s)
- [ ] **System boots** and shows console menu
- [ ] **Network configured** with accessible IP address
- [ ] **Web interface accessible** from browser
- [ ] **Login successful** with root credentials
- [ ] **System status** shows healthy on dashboard
- [ ] **Installation media removed** and stored safely
- [ ] **Root password documented** and stored securely

---

## 🚀 Next Steps

Congratulations! You've successfully installed TrueNAS. Now proceed to:

**[Initial Setup](initial-setup.md)** - Configure basic system settings, users, and security

---

## 📚 Additional Resources

### TrueNAS Documentation:
- [Official Installation Guide](https://www.truenas.com/docs/scale/gettingstarted/install/)
- [Hardware Requirements](https://www.truenas.com/docs/scale/gettingstarted/scalehardwareguide/)

### Community Resources:
- [TrueNAS Community Forums](https://www.truenas.com/community/)
- [TrueNAS Reddit Community](https://www.reddit.com/r/truenas/)

---
*Part of the [Complete TrueNAS Setup Guide](../README.md)*
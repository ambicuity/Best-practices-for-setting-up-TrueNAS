# Initial Setup

> **Configure essential system settings, create users, and establish secure access methods for your new TrueNAS system.**

## 🎯 Initial Setup Overview

After successful installation, this guide covers the critical first configuration steps that establish a secure and functional TrueNAS system.

**Estimated Time**: 1-2 hours  
**Difficulty**: Beginner to Intermediate  
**Prerequisites**: [Basic Installation](basic-installation.md) completed successfully

---

## 🔧 System Configuration Wizard

### 1. First Login Dashboard

After logging in for the first time, you may see the **Initial Setup Wizard**. This wizard helps configure basic settings:

```
TrueNAS Setup Wizard
┌─────────────────────────────────────────────┐
│ Welcome to TrueNAS!                         │
│                                             │
│ This wizard will help you configure:       │
│ • System timezone and localization         │
│ • Administrative users and groups          │
│ • Network settings and security            │
│ • Basic system preferences                 │
│                                             │
│     [Skip Wizard]    [Continue Setup]      │
└─────────────────────────────────────────────┘
```

**Recommendation**: Follow the wizard for guided setup, or skip if you prefer manual configuration.

---

## 🌍 System Localization

### Configure Timezone and Locale

**Navigate to**: System → General

1. **Timezone Configuration:**
   - Click the timezone dropdown
   - Select your geographic location (e.g., `America/New_York`)
   - This affects log timestamps and scheduled tasks

2. **Date and Time Format:**
   - Choose date format preference
   - 24-hour vs. 12-hour time format
   - Language and locale settings

3. **NTP (Network Time Protocol):**
   - Keep default NTP servers or add custom ones
   - Enable automatic time synchronization
   - Verify time synchronization is working

💡 **NTP Configuration Example:**
```
NTP Servers:
├── 0.pool.ntp.org
├── 1.pool.ntp.org  
├── 2.pool.ntp.org
└── 3.pool.ntp.org
```

**Save Settings** and verify the system time is correct.

---

## 👥 User Account Management

### Create Administrative User Account

**Navigate to**: Credentials → Local Users

Creating a dedicated admin account is a security best practice:

1. **Click "Add" to create new user**

2. **Basic User Information:**
   - **Full Name**: `System Administrator` (or your name)
   - **Username**: `admin` (avoid using `root` for daily tasks)
   - **Email**: Your email address for notifications
   - **Password**: Strong, unique password
   - **Confirm Password**: Re-enter password

3. **User ID Settings:**
   - **User ID**: Accept default (usually 1000+)
   - **Primary Group**: Create new group or use existing
   - **Auxiliary Groups**: Add to `wheel` group for sudo access

4. **Home Directory:**
   - **Home Directory**: `/mnt/tank/home/admin` (will create after storage setup)
   - **Home Directory Mode**: `755`

5. **Authentication Settings:**
   - **Disable Password**: Unchecked (for now)
   - **Lock User**: Unchecked
   - **Permit Sudo**: **Checked** (important for administrative access)
   - **SSH Public Key**: Add your SSH key if available

### Configure Groups

**Navigate to**: Credentials → Local Groups

1. **Create Administrative Group:**
   - **Name**: `truenas-admins`
   - **GID**: Accept default
   - **Permit Sudo**: Enabled
   - **SMB**: Disabled initially

2. **Create Standard User Group:**
   - **Name**: `family-users` (or relevant for your use case)
   - **GID**: Accept default
   - **Members**: Add family members or regular users

💡 **User Structure Example:**
```
User Account Hierarchy:
├── root (emergency access only)
├── admin (primary administrative account)
│   ├── Groups: truenas-admins, wheel
│   └── Permissions: Full system access
└── family-users group
    ├── alice (family member)
    ├── bob (family member)
    └── Permissions: Data access only
```

---

## 🔐 Security Configuration

### SSH Access Setup

**Navigate to**: System → SSH

SSH provides secure command-line access to your TrueNAS system:

1. **Enable SSH Service:**
   - **Start SSH Service**: Checked
   - **Start Automatically**: Checked

2. **Security Settings:**
   - **TCP Port**: `22` (default) or custom port for security
   - **Login as Root with Password**: **Unchecked** (security best practice)
   - **Allow Password Authentication**: Checked initially, disable after key setup
   - **Allow Kerberos Authentication**: Unchecked unless needed

3. **SSH Key Authentication (Recommended):**
   - **Generate SSH Key Pair** on your local machine:
   ```bash
   # On your local computer (Linux/Mac/Windows WSL)
   ssh-keygen -t ed25519 -C "your-email@example.com"
   
   # View the public key
   cat ~/.ssh/id_ed25519.pub
   ```
   
   - **Copy the public key** to TrueNAS user account
   - **Test SSH access** before disabling password authentication

4. **Advanced SSH Settings:**
   - **SFTP Log Level**: `ERROR` or `INFO`
   - **SFTP Log Facility**: `AUTH`
   - **Weak Ciphers**: Disabled (security)

### Test SSH Connection

From your local machine:
```bash
# Test SSH connection
ssh admin@192.168.1.100

# Test with specific key
ssh -i ~/.ssh/id_ed25519 admin@192.168.1.100

# Test SFTP access
sftp admin@192.168.1.100
```

### Web Interface Security

**Navigate to**: System → General

1. **HTTPS Certificate:**
   - Initially uses self-signed certificate
   - Plan to replace with proper certificate later
   - Enable **HTTPS Redirect** for security

2. **Session Settings:**
   - **Session Timeout**: 1-2 hours (balance security vs. convenience)
   - **Token Lifetime**: Default or shorter for high-security environments

3. **Web Interface Access:**
   - Document the management IP for future reference
   - Consider setting up DNS name for easier access

---

## 📧 Notification Setup

### Email Configuration

**Navigate to**: System → Email

Setting up email notifications is crucial for system health monitoring:

1. **Outgoing Mail Server:**
   - **Outgoing Server**: Your SMTP server (Gmail: `smtp.gmail.com`)
   - **Mail Server Port**: `587` (TLS) or `465` (SSL)
   - **Security**: TLS/SSL encryption

2. **Authentication:**
   - **Username**: Your email address
   - **Password**: Email password or app-specific password
   - **From Email**: Same as username usually

3. **Gmail Configuration Example:**
   ```
   SMTP Settings for Gmail:
   ├── Server: smtp.gmail.com
   ├── Port: 587
   ├── Security: TLS
   ├── Username: your-email@gmail.com
   ├── Password: app-specific-password
   └── From: your-email@gmail.com
   ```

4. **Test Email Configuration:**
   - Use **"Send Test Mail"** button
   - Check your email for the test message
   - Troubleshoot connection issues if needed

### Alert Settings

**Navigate to**: System → Alerts

Configure which alerts you want to receive:

1. **Critical Alerts** (always enable):
   - Disk failures
   - Pool errors
   - System overheating
   - Memory errors

2. **Warning Alerts** (recommended):
   - High disk usage
   - Network connectivity issues
   - Update availability
   - Certificate expiration

3. **Information Alerts** (optional):
   - Successful backups
   - Scheduled task completion
   - System statistics

---

## 🌐 Network Fine-Tuning

### Static IP Configuration

**Navigate to**: Network → Interfaces

If you haven't already configured a static IP:

1. **Select Primary Interface** (usually eth0)

2. **Configure IPv4:**
   - **DHCP**: Disabled
   - **IP Address**: `192.168.1.100/24` (your planned address)
   - **Additional IPs**: Add if needed for services

3. **Configure IPv6** (if used):
   - **Auto**: Disabled for static configuration
   - **IPv6 Address**: Your IPv6 address if applicable

### DNS Configuration

**Navigate to**: Network → Global Configuration

1. **DNS Servers:**
   - **Nameserver 1**: `8.8.8.8` (Google DNS)
   - **Nameserver 2**: `1.1.1.1` (Cloudflare DNS)
   - **Nameserver 3**: Your ISP DNS (optional)

2. **Domain Settings:**
   - **Domain**: Your local domain name
   - **Hostname**: Unique hostname for this TrueNAS system

### Network Testing

Verify network configuration:
```bash
# From TrueNAS console or SSH
ping -c 4 8.8.8.8          # Test internet connectivity
ping -c 4 google.com       # Test DNS resolution
ip addr show               # Verify IP configuration
route -n                   # Check routing table
```

---

## 💾 Initial Storage Assessment

### View Available Drives

**Navigate to**: Storage → Disks

Review all detected storage devices:

1. **Boot Drives:**
   - Should show your SSD(s) with TrueNAS installed
   - Check health status and temperature
   - Verify they're not included in data pools

2. **Data Drives:**
   - List all available HDDs for pool creation
   - Note model numbers, serial numbers, sizes
   - Check SMART status for any issues

### Drive Health Check

**Navigate to**: Storage → Disks → Select Drive → SMART Tests

For each data drive:
1. **Run Short SMART Test** to verify basic health
2. **Review SMART Data** for any warning indicators
3. **Note drive temperatures** (should be <40°C typically)
4. **Check power-on hours** for drive age assessment

💡 **Drive Health Assessment:**
```
Healthy Drive Indicators:
├── SMART Status: PASSED
├── Reallocated Sectors: 0
├── Current Pending Sectors: 0  
├── Offline Uncorrectable Sectors: 0
├── Temperature: <40°C
└── No critical warnings in SMART data
```

---

## 🔄 System Update

### Check for Updates

**Navigate to**: System → Update

1. **Check Available Updates:**
   - Click **"Check for Updates"**
   - Review available updates and changelog
   - Note any breaking changes or requirements

2. **Update Strategy:**
   - **Stable Updates**: Apply promptly for security fixes
   - **Major Updates**: Test in lab environment first if possible
   - **Update Timing**: Schedule during low-usage periods

3. **Apply Updates:**
   - Create manual backup of configuration before major updates
   - **Download and Install** updates
   - **Reboot** as required

### Boot Environment Management

**Navigate to**: System → Boot

TrueNAS uses boot environments for safe updates:

1. **Review Boot Environments:**
   - Current active environment
   - Previous environments (rollback options)
   - Available disk space

2. **Create Manual Snapshot:**
   - Before major configuration changes
   - Name descriptively: `pre-storage-setup-2024-01-15`

---

## 📋 Configuration Backup

### Export System Configuration

**Navigate to**: System → General → Save Config

1. **Download Configuration:**
   - **Include Password Secret Seed**: Consider carefully (security vs. convenience)
   - **Download** the configuration file
   - Store securely - contains sensitive system information

2. **Configuration Management:**
   - Save with descriptive filename: `truenas-config-initial-setup-2024-01-15.db`
   - Store in multiple locations (local, cloud backup)
   - Document any custom settings not included in backup

### Documentation Update

Update your system documentation with:

```
TrueNAS Initial Configuration - COMPLETED
═══════════════════════════════════════════════

System Information:
├── Hostname: truenas-home
├── Management IP: 192.168.1.100
├── Admin Users: admin, root
└── Timezone: America/New_York

Network Configuration:
├── Interface: eth0
├── IP Address: 192.168.1.100/24
├── Gateway: 192.168.1.1
├── DNS: 8.8.8.8, 1.1.1.1

Security Settings:
├── SSH Enabled: Yes (Port 22)
├── Root SSH: Disabled
├── Admin User: admin (sudo enabled)
└── SSH Keys: Configured

Notifications:
├── Email: Configured (Gmail SMTP)
├── Alerts: Critical and Warning enabled
└── Test Email: Successful

Completion Date: 2024-01-15
Next Step: Storage Setup
```

---

## ✅ Initial Setup Verification Checklist

### System Settings Verified:
- [ ] **Timezone and locale** configured correctly
- [ ] **System time** synchronized via NTP
- [ ] **Hostname and domain** set appropriately
- [ ] **Email notifications** working (test sent successfully)

### User Management Configured:
- [ ] **Administrative user** created with sudo access
- [ ] **User groups** defined for different access levels
- [ ] **Root account** secured (SSH disabled)
- [ ] **Password policies** established

### Security Measures Implemented:
- [ ] **SSH service** enabled with key authentication
- [ ] **Password SSH access** disabled (after key setup)
- [ ] **HTTPS** enabled for web interface
- [ ] **Alert notifications** configured

### Network Configuration Verified:
- [ ] **Static IP address** assigned and accessible
- [ ] **DNS resolution** working correctly
- [ ] **Internet connectivity** verified
- [ ] **Local network access** confirmed

### System Maintenance Prepared:
- [ ] **System updates** checked and applied
- [ ] **Configuration backup** created and stored
- [ ] **Documentation** updated with current settings
- [ ] **Boot environments** reviewed

---

## 🚀 Next Steps

With initial setup complete, you're ready to:

**[Storage Setup](../03-configuration/storage-setup.md)** - Create ZFS pools, datasets, and configure your storage architecture

---

## 🔧 Troubleshooting Initial Setup

### Common Setup Issues:

**Problem**: Can't create admin user
- **Solution**: Check username uniqueness, verify password requirements

**Problem**: SSH connection refused
- **Solution**: Verify SSH service is started, check firewall settings, confirm port

**Problem**: Email notifications not working
- **Solution**: Check SMTP settings, verify app-specific passwords, test network connectivity

**Problem**: Time/timezone incorrect
- **Solution**: Check NTP configuration, verify internet connectivity, manually sync if needed

**Problem**: Can't access web interface after configuration
- **Solution**: Check IP address changes, clear browser cache, verify network settings

---
*Part of the [Complete TrueNAS Setup Guide](../README.md)*
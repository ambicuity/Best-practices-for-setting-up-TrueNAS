# Security Hardening

> **Implement comprehensive security measures to protect your TrueNAS system and data from unauthorized access and threats.**

## 🎯 Security Hardening Overview

This guide implements multiple layers of security following the principle of defense in depth. These measures protect against both internal and external threats while maintaining system usability.

**Estimated Time**: 2-4 hours  
**Difficulty**: Intermediate to Advanced  
**Prerequisites**: [Network Configuration](network-configuration.md) completed

---

## 🛡️ Security Philosophy and Approach

### Defense in Depth Strategy

```
Security Layers:
├── Physical Security (Hardware access control)
├── Network Security (Firewalls, VLANs, VPN)
├── System Security (OS hardening, updates)
├── Access Control (Authentication, authorization)
├── Data Security (Encryption, backups)
├── Monitoring (Logging, alerting)
└── Incident Response (Recovery procedures)
```

### Security Golden Rules

> ⚠️ **Critical Security Rules**:
> 1. **Never expose TrueNAS Web UI directly to the Internet**
> 2. **Always use VPN for remote access**
> 3. **Disable root SSH access**
> 4. **Enable two-factor authentication**
> 5. **Keep system updated**
> 6. **Monitor and log access**

---

## 🔐 Access Control Hardening

### SSH Security Configuration

**Navigate to**: Services → SSH

1. **Basic SSH Hardening:**
   ```yaml
   SSH Security Settings:
   ├── TCP Port: 2222 (non-standard port)
   ├── Login as Root: DISABLED
   ├── Allow Password Authentication: DISABLED (after key setup)
   ├── Allow Kerberos Authentication: DISABLED
   ├── Allow TCP Port Forwarding: DISABLED
   ├── Compression: DISABLED (slight security improvement)
   ├── SFTP Log Level: INFO
   └── SFTP Log Facility: AUTH
   ```

2. **Advanced SSH Configuration:**
   - **SSH Auxiliary Parameters**:
   ```bash
   # Add to SSH auxiliary parameters
   MaxAuthTries 3
   ClientAliveInterval 300
   ClientAliveCountMax 2
   AllowUsers admin
   Protocol 2
   HostKeyAlgorithms ssh-ed25519,rsa-sha2-512,rsa-sha2-256
   KexAlgorithms curve25519-sha256@libssh.org
   Ciphers aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
   MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com
   ```

### SSH Key Management

1. **Generate Strong SSH Keys:**
   ```bash
   # On client machine - Ed25519 (preferred)
   ssh-keygen -t ed25519 -b 521 -C "admin@truenas-$(date +%Y%m%d)"
   
   # Or RSA (if Ed25519 not supported)
   ssh-keygen -t rsa -b 4096 -C "admin@truenas-$(date +%Y%m%d)"
   ```

2. **Deploy SSH Keys:**
   **Navigate to**: Credentials → Local Users → admin → Edit
   - Add your **SSH Public Key** to the admin user account
   - Test SSH key authentication before disabling passwords

3. **Test SSH Key Access:**
   ```bash
   # Test SSH key authentication
   ssh -i ~/.ssh/id_ed25519 admin@192.168.1.100 -p 2222
   
   # Should connect without password prompt
   ```

### Multi-Factor Authentication (2FA)

**Navigate to**: Credentials → 2FA

1. **Enable TOTP (Time-based One-Time Password):**
   - **Enable Two-Factor Authentication**: Checked
   - **Window**: 1 (30-second window)
   - **SSH**: Enable for SSH access (recommended)

2. **Configure TOTP Apps:**
   - **Google Authenticator** (mobile)
   - **Authy** (multi-device)
   - **Microsoft Authenticator**
   - **1Password** (with TOTP support)

3. **Emergency Recovery Codes:**
   - Save emergency recovery codes securely
   - Store in password manager or secure location
   - Test recovery process

---

## 🌐 Network Security Configuration

### Web Interface Security

**Navigate to**: System → General

1. **HTTPS Configuration:**
   - **Web Interface HTTP → HTTPS Redirect**: Enabled
   - **Web Interface HTTPS Certificate**: Use proper certificate
   - **Web Interface HTTPS Port**: 443 (or custom for security)

2. **Session Security:**
   - **Session Timeout**: 3600 seconds (1 hour)
   - **Token Lifetime**: 72 hours maximum

3. **Certificate Management:**
   **Navigate to**: Credentials → Certificates

   **Option 1: Self-Signed Certificate (Development)**
   - Create new self-signed certificate
   - Use for internal/testing environments only

   **Option 2: Let's Encrypt (If exposing services)**
   - **Never for Web UI management interface**
   - Only for specific services through reverse proxy

   **Option 3: Internal CA Certificate**
   - Create internal Certificate Authority
   - Issue certificates for internal services

### Firewall Configuration

**Navigate to**: Network → Firewall (if available) or use system firewall

1. **Default Firewall Rules:**
   ```bash
   # Basic firewall rules (via system configuration)
   # Allow SSH from management network only
   iptables -A INPUT -p tcp -s 192.168.1.0/24 --dport 2222 -j ACCEPT
   
   # Allow HTTPS from local network only  
   iptables -A INPUT -p tcp -s 192.168.1.0/24 --dport 443 -j ACCEPT
   
   # Block everything else to management ports
   iptables -A INPUT -p tcp --dport 2222 -j DROP
   iptables -A INPUT -p tcp --dport 443 -j DROP
   ```

2. **Service-Specific Firewall Rules:**
   - **SMB**: Allow from trusted networks only
   - **NFS**: Restrict to specific client IPs
   - **iSCSI**: Dedicated network/VLAN preferred

### VPN Setup for Remote Access

**Choose VPN Solution:**

#### Option 1: WireGuard (Recommended)

**Setup on Router/Separate Server:**
```bash
# WireGuard client configuration for TrueNAS access
[Interface]
PrivateKey = CLIENT_PRIVATE_KEY
Address = 10.0.100.2/24
DNS = 192.168.1.100

[Peer]
PublicKey = SERVER_PUBLIC_KEY  
AllowedIPs = 192.168.1.0/24
Endpoint = your-public-ip:51820
PersistentKeepalive = 25
```

#### Option 2: OpenVPN

**Server Configuration:**
```bash
# OpenVPN server config (on separate system)
port 1194
proto udp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh.pem
server 10.0.100.0 255.255.255.0
push "route 192.168.1.0 255.255.255.0"
keepalive 10 120
comp-lzo
persist-key
persist-tun
```

### Network Segmentation

1. **VLAN Security Implementation:**
   ```
   Network Segmentation:
   ├── VLAN 10 (Management): Admin access only
   │   ├── TrueNAS Web UI: 10.0.10.100
   │   └── SSH Access: 10.0.10.100:2222
   ├── VLAN 20 (Storage): High-speed data access
   │   ├── SMB Services: 10.0.20.100
   │   ├── NFS Services: 10.0.20.100  
   │   └── iSCSI Services: 10.0.20.100
   ├── VLAN 30 (Backup): Backup traffic isolation
   │   └── Replication: 10.0.30.100
   └── VLAN 1 (Users): General user access
       └── Limited services: 192.168.1.100
   ```

---

## 🔒 System Security Hardening

### User Account Security

**Navigate to**: Credentials → Local Users

1. **Root Account Security:**
   - **Password**: Strong, unique password (emergency use only)
   - **SSH Login**: DISABLED
   - **Lock User**: Consider locking if admin account sufficient

2. **Administrative User Security:**
   - **Strong Passwords**: Minimum 16 characters, complex
   - **Password Expiry**: Consider 90-day rotation for high-security environments
   - **Account Lockout**: Enable failed login protection
   - **Audit Trail**: Enable login logging

3. **Service Accounts:**
   - **Minimal Privileges**: Only necessary permissions
   - **No Interactive Login**: Disable shell access where possible
   - **Unique Credentials**: No shared service account passwords

### System Update Security

**Navigate to**: System → Update

1. **Update Policy:**
   ```yaml
   Update Security Strategy:
   ├── Security Updates: Apply within 48 hours
   ├── Stable Updates: Apply within 1 week (after testing)
   ├── Major Updates: Test in lab first (1-2 weeks)
   ├── Update Window: During low-usage periods
   └── Backup Before: Always backup before major updates
   ```

2. **Automated Update Configuration:**
   - **Check for Updates**: Daily
   - **Download Updates**: Automatic
   - **Install Updates**: Manual (for control)
   - **Notification**: Email admin on available updates

### File System Security

1. **Dataset Permissions:**
   **Navigate to**: Storage → Pools → Datasets
   
   ```
   Security-focused Permissions:
   ├── Admin-only datasets: 700 (owner only)
   ├── Family shared: 755 (owner full, group read)
   ├── Service datasets: 750 (owner full, group read-only)
   └── Backup datasets: 600 (owner read-write only)
   ```

2. **Advanced Access Controls (ACLs):**
   - **Enable NFSv4 ACLs** for fine-grained control
   - **Inheritance**: Configure proper ACL inheritance
   - **Audit**: Enable access logging for sensitive data

---

## 🔐 Data Encryption

### Pool-Level Encryption

**Navigate to**: Storage → Pools

1. **Encryption Decision Matrix:**
   ```
   Encryption Recommendations:
   ├── Home Use: Consider for sensitive data
   ├── Business Use: Strongly recommended
   ├── Compliance: Required (GDPR, HIPAA, etc.)
   ├── Performance Impact: ~5-10% overhead
   └── Key Management: Critical for recovery
   ```

2. **Encryption Configuration:**
   - **Encryption Algorithm**: AES-256-GCM (recommended)
   - **Key Format**: Passphrase (easier) vs. Key file (more secure)
   - **Key Storage**: Secure offline storage essential

### Dataset-Level Encryption

**Navigate to**: Storage → Datasets

1. **Selective Encryption Strategy:**
   ```
   Dataset Encryption Plan:
   ├── /tank/family/documents: ENCRYPTED (sensitive documents)
   ├── /tank/family/photos: ENCRYPTED (personal data)
   ├── /tank/media: NOT ENCRYPTED (already protected, performance)
   ├── /tank/backups: ENCRYPTED (backup security)
   └── /tank/apps: SELECTIVE (based on app data sensitivity)
   ```

2. **Encryption Key Management:**
   ```bash
   # Export encryption keys (secure storage)
   zfs get -r encryptionroot,keystatus tank
   
   # Lock encrypted datasets
   zfs unload-key tank/family/documents
   
   # Unlock encrypted datasets  
   zfs load-key tank/family/documents
   ```

---

## 📊 Security Monitoring and Logging

### Log Configuration

**Navigate to**: System → System Dataset

1. **System Logging:**
   - **System Dataset**: Store on encrypted dataset
   - **Log Rotation**: Configure appropriate retention
   - **Remote Logging**: Send logs to external syslog server

2. **Security Log Monitoring:**
   ```bash
   # Important log files to monitor
   /var/log/auth.log          # Authentication attempts
   /var/log/syslog            # System messages
   /var/log/nginx/access.log  # Web interface access
   /var/log/messages          # General system messages
   ```

### Security Alert Configuration

**Navigate to**: System → Alerts

1. **Critical Security Alerts:**
   ```yaml
   Security Alert Priorities:
   ├── CRITICAL: Failed login attempts (>5)
   ├── CRITICAL: Root login attempts
   ├── WARNING: SSH connections from new IPs
   ├── WARNING: Certificate expiration (30 days)
   ├── INFO: Successful admin logins
   └── INFO: System configuration changes
   ```

2. **Log Analysis Script:**
   ```bash
   #!/bin/bash
   # Security monitoring script
   
   # Check for failed SSH attempts
   grep "Failed password" /var/log/auth.log | tail -10
   
   # Check for root login attempts
   grep "root" /var/log/auth.log | grep -v "sudo" | tail -5
   
   # Check for new SSH connections
   grep "Accepted" /var/log/auth.log | tail -10
   
   # Check for web interface access
   tail -20 /var/log/nginx/access.log | grep -v "200"
   ```

### Intrusion Detection

1. **File Integrity Monitoring:**
   ```bash
   # Monitor critical system files for changes
   find /etc -type f -name "*.conf" -exec md5sum {} \; > /tmp/config_checksums.md5
   
   # Create monitoring script for configuration changes
   #!/bin/bash
   md5sum -c /tmp/config_checksums.md5 --quiet || echo "Configuration files changed!"
   ```

2. **Network Monitoring:**
   ```bash
   # Monitor network connections
   netstat -tuln | grep LISTEN
   
   # Check for unusual network activity
   ss -tupln | grep -E "(ssh|https|smb)"
   ```

---

## 🔧 Service-Specific Security

### SMB/CIFS Security

**Navigate to**: Services → SMB

1. **SMB Security Settings:**
   ```yaml
   SMB Security Configuration:
   ├── NetBIOS Name Server: Disabled
   ├── NTLM Auth: Disabled (use Kerberos if possible)
   ├── Min Protocol: SMB2
   ├── Max Protocol: SMB3
   ├── Encryption: Required for sensitive shares
   └── Guest Account: Disabled
   ```

2. **Share-Level Security:**
   - **Access Control**: Use specific user/group permissions
   - **Hidden Shares**: Enable for administrative shares
   - **Encryption**: Enable for sensitive data shares

### NFS Security

**Navigate to**: Services → NFS

1. **NFS Security Settings:**
   ```yaml
   NFS Security Configuration:
   ├── NFSv4 Only: Preferred (better security)
   ├── Kerberos: Enable if possible
   ├── Root Squash: Enabled (map root to nobody)
   ├── All Squash: Consider for high-security environments
   └── Host Restrictions: Limit to specific client IPs
   ```

### Web Interface Security

1. **Additional Web Security Headers:**
   ```bash
   # Add security headers to nginx configuration
   add_header X-Frame-Options "SAMEORIGIN";
   add_header X-Content-Type-Options "nosniff";
   add_header X-XSS-Protection "1; mode=block";
   add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";
   ```

---

## 📋 Security Hardening Checklist

### Access Control Security:
- [ ] **SSH hardened** (keys only, non-standard port, root disabled)
- [ ] **Two-factor authentication** enabled for admin accounts
- [ ] **Strong passwords** implemented (16+ characters)
- [ ] **Root SSH access** completely disabled
- [ ] **User privileges** follow least-privilege principle
- [ ] **Session timeouts** configured appropriately

### Network Security:
- [ ] **Web UI not exposed** to Internet (VPN-only access)
- [ ] **HTTPS enabled** with proper certificates
- [ ] **VPN solution** implemented for remote access
- [ ] **Network segmentation** implemented with VLANs
- [ ] **Firewall rules** configured and tested
- [ ] **Service binding** restricted to appropriate interfaces

### System Security:
- [ ] **System updates** automated and current
- [ ] **Boot environments** managed properly
- [ ] **File permissions** set according to security policy
- [ ] **Encryption enabled** for sensitive datasets
- [ ] **Security logging** configured and monitored
- [ ] **Intrusion detection** basic measures implemented

### Service Security:
- [ ] **SMB security** hardened (SMB3, encryption)
- [ ] **NFS security** configured (NFSv4, root squash)
- [ ] **Service accounts** use minimal privileges
- [ ] **Default passwords** changed on all services
- [ ] **Unused services** disabled
- [ ] **Security headers** configured for web services

---

## 🚀 Next Steps

With security hardening complete, you're ready to:

**[Shares and Datasets](../04-services/shares-and-datasets.md)** - Configure secure file sharing services and data access

---

## 🔧 Security Troubleshooting

### Common Security Issues:

**Problem**: Locked out of system after security changes
- **Solution**: Use console access, check SSH keys, verify firewall rules

**Problem**: Cannot connect via VPN
- **Solution**: Check VPN server status, verify firewall ports, test connectivity

**Problem**: Two-factor authentication not working
- **Solution**: Check time synchronization, regenerate codes, use backup codes

**Problem**: Performance degraded after encryption
- **Solution**: Monitor CPU usage, consider AES-NI support, optimize record sizes

### Security Incident Response:

**Suspected Compromise:**
1. **Immediate Actions:**
   - Change all passwords immediately
   - Review recent login logs
   - Check for unauthorized configuration changes
   - Isolate system if necessary

2. **Investigation:**
   - Analyze system logs thoroughly
   - Check for unusual network activity
   - Verify file integrity
   - Review user account activities

3. **Recovery:**
   - Restore from known-good backups
   - Patch identified vulnerabilities
   - Update security configurations
   - Monitor for further suspicious activity

---
*Part of the [Complete TrueNAS Setup Guide](../README.md)*
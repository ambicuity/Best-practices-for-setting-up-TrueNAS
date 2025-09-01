# Basic Home Setup - Step-by-Step Deployment Guide

This guide walks you through the complete deployment of a TrueNAS SCALE system for home use, from initial hardware setup to production readiness.

## 📋 Pre-Deployment Checklist

### Hardware Requirements ✅
- [ ] 4-core 64-bit CPU (Intel/AMD)
- [ ] 16GB RAM minimum (32GB recommended)
- [ ] 2x 120GB+ SSDs for mirrored boot (SATA/NVMe)
- [ ] 4x 4TB SATA drives for data storage
- [ ] Gigabit Ethernet connection
- [ ] UPS for power protection (recommended)

### Network Requirements ✅
- [ ] Static IP address available (192.168.1.100 in this example)
- [ ] Network switch/router with available ports
- [ ] Internet connection for updates and cloud backup
- [ ] DHCP reservation configured for TrueNAS

### Prerequisites ✅
- [ ] TrueNAS SCALE ISO downloaded and prepared
- [ ] Ansible control machine available (laptop/desktop)
- [ ] SSH keys generated for admin access
- [ ] Basic understanding of ZFS concepts
- [ ] Backup strategy planned (3-2-1 methodology)

## 🚀 Phase 1: Hardware Installation and Initial Setup

### 1.1 Physical Installation
1. **Install Boot Drives**
   ```bash
   # Connect 2x SSDs to SATA ports 0 and 1
   # These will be mirrored for redundancy
   ```

2. **Install Data Drives**  
   ```bash
   # Connect 4x data drives to SATA ports 2-5
   # These will form a RAIDZ1 pool
   ```

3. **Network Connection**
   ```bash
   # Connect primary NIC to network switch
   # Ensure network has internet access
   ```

### 1.2 TrueNAS SCALE Installation
1. **Boot from USB**
   - Create TrueNAS SCALE USB installer
   - Boot system from USB drive
   - Follow installation wizard

2. **Configure Boot Pool**
   ```bash
   # Select both SSDs for mirrored boot pool
   # Choose guided installation
   # Set root password (will be disabled later)
   ```

3. **Initial Network Setup**
   ```bash
   # Configure static IP: 192.168.1.100/24
   # Gateway: 192.168.1.1  
   # DNS: 192.168.1.1, 1.1.1.1
   # Domain: home.local
   ```

4. **First Boot Verification**
   ```bash
   # Access web UI: https://192.168.1.100
   # Verify all drives are detected
   # Check network connectivity
   ```

## 🔧 Phase 2: Automated Bootstrap

### 2.1 Prepare Control Machine
```bash
# Install Ansible on your laptop/desktop
sudo apt update && sudo apt install ansible git

# Clone the repository
git clone <repository-url>
cd examples/basic-home-setup

# Generate SSH keys if you don't have them
ssh-keygen -t rsa -b 4096 -f ~/.ssh/truenas_key

# Copy public key content for configuration
cat ~/.ssh/truenas_key.pub
```

### 2.2 Configure Deployment
```bash
# Edit inventory file
vi ansible/inventory/hosts

# Update with your specifics:
# - TrueNAS IP address
# - SSH key path  
# - Drive names (verify with lsblk)
# - Network settings

# Edit variables file
vi ansible/vars/home-config.yml

# Customize:
# - User names and email addresses
# - Network configuration
# - Storage drive names
# - Timezone and locale
```

### 2.3 Run Bootstrap
```bash
# Test connectivity first
ansible truenas_home -i ansible/inventory/hosts -m ping

# Run bootstrap playbook (sets up users, SSH, firewall)
ansible-playbook -i ansible/inventory/hosts ansible/bootstrap.yml

# Verify bootstrap completed
ssh john@192.168.1.100 "cat /root/bootstrap-completed.txt"
```

## 💾 Phase 3: Storage Provisioning  

### 3.1 Pre-Provisioning Checks
```bash
# Verify drives are detected
ssh john@192.168.1.100 "lsblk"

# Check available space
ssh john@192.168.1.100 "sudo fdisk -l"

# Ensure no existing pools conflict
ssh john@192.168.1.100 "sudo zpool status"
```

### 3.2 Run Storage Provisioning
```bash
# Deploy storage configuration
ansible-playbook -i ansible/inventory/hosts ansible/provision.yml

# This creates:
# - ZFS pool with RAIDZ1 configuration
# - Dataset hierarchy for users and shared data
# - SMB and NFS shares
# - Snapshot schedules
# - Basic monitoring
```

### 3.3 Verify Storage Setup
```bash
# Check pool status
ssh john@192.168.1.100 "sudo zpool status tank"

# List all datasets
ssh john@192.168.1.100 "sudo zfs list"

# Test share access
smbclient -L //192.168.1.100 -U john
```

## 👥 Phase 4: User Configuration and Testing

### 4.1 User Access Setup
```bash
# Test user logins
ssh john@192.168.1.100  # Admin user
ssh susan@192.168.1.100  # Family user

# Verify home directories exist
ls -la /mnt/tank/home/

# Test sudo access for admin
ssh john@192.168.1.100 "sudo zpool status"
```

### 4.2 Share Access Testing
```bash
# Test SMB shares from Windows/Mac
net use Z: \\192.168.1.100\family-media
# Enter username: john
# Enter password: [use SSH key or set SMB password]

# Test NFS from Linux
sudo mount -t nfs 192.168.1.100:/mnt/tank/shared/media /mnt/test

# Test web access
curl -k https://192.168.1.100/
```

## 🔒 Phase 5: Security Hardening

### 5.1 Verify Security Settings
```bash
# Check firewall status
ssh john@192.168.1.100 "sudo ufw status"

# Verify SSH configuration  
ssh john@192.168.1.100 "sudo grep -E '^(PermitRootLogin|PasswordAuthentication)' /etc/ssh/sshd_config"

# Test root access is disabled
ssh root@192.168.1.100  # Should fail
```

### 5.2 Set Up VPN Access (Optional)
```bash
# Install WireGuard on TrueNAS
ssh john@192.168.1.100 "sudo apt install wireguard"

# Generate server keys
ssh john@192.168.1.100 "wg genkey | sudo tee /etc/wireguard/privatekey"
ssh john@192.168.1.100 "sudo cat /etc/wireguard/privatekey | wg pubkey | sudo tee /etc/wireguard/publickey"

# Configure client access for remote administration
# (Follow detailed VPN setup guide)
```

## 💾 Phase 6: Backup Configuration

### 6.1 Set Up Cloud Backup
```bash
# Install backup tools
ssh john@192.168.1.100 "sudo apt install rclone"

# Configure Backblaze B2
ssh john@192.168.1.100 "rclone config"
# Follow prompts to set up B2 backend

# Test cloud connectivity
ssh john@192.168.1.100 "rclone ls b2:truenas-home-backup"
```

### 6.2 Configure Local Backup
```bash
# Connect external USB drive
# Format and mount for backup use

# Set up automated USB backup script
# Schedule weekly full backups
```

### 6.3 Test Backup and Restore
```bash
# Run backup verification script
./tests/verify-backup.sh

# Create test snapshot
ssh john@192.168.1.100 "sudo zfs snapshot tank/home/john@test-$(date +%s)"

# Test file restore from snapshot
# Document restore procedures
```

## 📊 Phase 7: Monitoring and Alerting

### 7.1 Configure Email Alerts
```bash
# Set up SMTP relay
ssh john@192.168.1.100 "sudo vi /etc/postfix/main.cf"

# Configure system to send alerts
# Test email delivery
ssh john@192.168.1.100 "echo 'Test alert' | mail -s 'TrueNAS Test' admin@home.local"
```

### 7.2 Set Up Dashboard Access
```bash
# Access TrueNAS web interface
# Configure dashboard widgets
# Set up user accounts for family members
# Configure appropriate permissions
```

## ✅ Phase 8: Validation and Go-Live

### 8.1 Run Complete Validation
```bash
# Execute validation script
./tests/validate-deployment.sh --host 192.168.1.100 --user john

# Review all test results
# Fix any failed tests before production use
```

### 8.2 Performance Testing
```bash
# Test network throughput
iperf3 -c 192.168.1.100

# Test storage performance  
ssh john@192.168.1.100 "sudo fio --name=test --ioengine=libaio --size=1G --filename=/mnt/tank/test_file --bs=1M --rw=write"

# Test concurrent access
# Simulate family usage patterns
```

### 8.3 User Training and Documentation
```bash
# Create user guides for family members
# Document access procedures
# Provide backup contact information
# Schedule quarterly maintenance reviews
```

## 🎯 Production Checklist

Before declaring the system production-ready:

### System Health ✅
- [ ] All drives healthy (no SMART errors)
- [ ] Pool status ONLINE with no errors  
- [ ] System load and temperature acceptable
- [ ] Network connectivity stable
- [ ] All services running and accessible

### Security ✅  
- [ ] Firewall active and configured
- [ ] SSH key-only authentication working
- [ ] Root login disabled
- [ ] User permissions tested and appropriate
- [ ] VPN configured for remote access (if needed)

### Backup Strategy ✅
- [ ] Automatic snapshots configured and working
- [ ] Cloud backup tested and functional
- [ ] Local backup procedures documented
- [ ] Restore procedures tested
- [ ] 3-2-1 backup methodology implemented

### Monitoring ✅
- [ ] Email alerts configured and tested  
- [ ] SMART monitoring active
- [ ] Pool scrub scheduled
- [ ] Capacity monitoring in place
- [ ] Performance baseline established

### Documentation ✅
- [ ] System configuration documented
- [ ] User access procedures written
- [ ] Backup/restore procedures tested
- [ ] Emergency contact information available
- [ ] Maintenance schedule established

## 🔄 Ongoing Maintenance

### Daily (Automated)
- SMART short tests
- Snapshot creation  
- System health monitoring
- Log review

### Weekly (Automated)
- SMART long tests
- Backup verification
- Security scan
- Performance monitoring

### Monthly (Manual)
- Pool scrub review
- Capacity planning  
- User access review
- Backup restore test

### Quarterly (Manual)  
- Full system review
- Hardware health check
- Software updates
- Disaster recovery test

## 🆘 Troubleshooting Common Issues

### Pool Issues
```bash
# Pool degraded
sudo zpool status -v
# Replace failed drive if needed

# High capacity
sudo zfs list -o space
# Clean up old snapshots or add storage
```

### Network Issues
```bash
# Service not accessible
sudo systemctl status smbd nmbd nfs-server
# Restart services if needed

# Firewall blocking
sudo ufw status verbose
# Adjust rules as needed
```

### Performance Issues  
```bash
# High load
htop
# Check for runaway processes

# Slow I/O
sudo zpool iostat
# Look for bottlenecks
```

## 📞 Getting Help

- **System Issues**: Check logs in `/var/log/`
- **ZFS Problems**: Use `zpool status` and `zfs list`  
- **Network Issues**: Verify firewall and service status
- **Backup Problems**: Run `./tests/verify-backup.sh`
- **Community**: TrueNAS community forums
- **Documentation**: Official TrueNAS documentation

## 🎉 Success!

Your TrueNAS home system is now ready for production use! You have:

✅ **Robust Storage**: RAIDZ1 pool with 1-drive fault tolerance  
✅ **User Management**: Proper permissions and access control  
✅ **Network Shares**: SMB and NFS for all your devices  
✅ **Backup Strategy**: 3-2-1 methodology with cloud and local backups  
✅ **Security**: Firewall, SSH keys, VPN-ready for remote access  
✅ **Monitoring**: Automated health checks and alerting  

Enjoy your new TrueNAS system!
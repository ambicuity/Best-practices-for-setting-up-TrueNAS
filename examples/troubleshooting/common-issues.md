# Common TrueNAS Issues and Solutions

This guide covers the most common issues encountered during and after TrueNAS deployment, with step-by-step solutions.

## 🔧 System Issues

### Cannot SSH to TrueNAS After Bootstrap
**Symptoms**: SSH connections fail or are rejected

**Common Causes**:
- SSH keys not properly configured
- Firewall blocking SSH
- Wrong username or IP address
- SSH service not running

**Solutions**:
```bash
# Check if host is reachable
ping 192.168.1.100

# Test SSH service
nmap -p 22 192.168.1.100

# Try with verbose output to see error details
ssh -v john@192.168.1.100

# If using wrong key, specify correct one
ssh -i ~/.ssh/truenas_key john@192.168.1.100

# From TrueNAS console, check SSH status
systemctl status ssh

# From TrueNAS console, check firewall
ufw status verbose
```

### Web UI Not Accessible
**Symptoms**: Cannot access https://192.168.1.100

**Solutions**:
```bash  
# Check if web service is running
ssh john@192.168.1.100 "sudo systemctl status nginx"

# Check if firewall is blocking
ssh john@192.168.1.100 "sudo ufw status | grep 443"

# Try HTTP instead of HTTPS temporarily
curl -k http://192.168.1.100

# Check certificate issues
openssl s_client -connect 192.168.1.100:443 -servername 192.168.1.100
```

## 💾 Storage Issues

### Pool Creation Fails
**Symptoms**: ZFS pool creation fails during provisioning

**Common Causes**:
- Drives already have partitions
- Drive names changed
- Insufficient permissions
- Hardware issues

**Solutions**:
```bash
# Check actual drive names
lsblk

# Wipe drives if they have existing partitions
sudo wipefs -a /dev/sda
sudo wipefs -a /dev/sdb
sudo wipefs -a /dev/sdc  
sudo wipefs -a /dev/sdd

# Check drive health
sudo smartctl -H /dev/sda
sudo smartctl -H /dev/sdb
sudo smartctl -H /dev/sdc
sudo smartctl -H /dev/sdd

# Try manual pool creation to test
sudo zpool create -f tank raidz1 sda sdb sdc sdd
```

### Pool Shows as DEGRADED
**Symptoms**: `zpool status` shows DEGRADED state

**Solutions**:
```bash
# Check which drive failed
sudo zpool status -v tank

# If drive is temporarily offline, try to online it
sudo zpool online tank sda

# If drive failed, replace it
# 1. Shutdown system
# 2. Replace physical drive  
# 3. Boot system
# 4. Resilver the pool
sudo zpool replace tank old-drive-id new-drive-id
```

### Dataset Mount Issues
**Symptoms**: Datasets exist but are not mounted

**Solutions**:
```bash
# Check mount status
zfs list -o name,mounted,mountpoint

# Mount specific dataset
sudo zfs mount tank/home/john

# Check for mount point conflicts
ls -la /mnt/tank/

# Set correct mount point
sudo zfs set mountpoint=/mnt/tank/home/john tank/home/john
```

## 🌐 Network Issues

### SMB Shares Not Accessible
**Symptoms**: Cannot access \\192.168.1.100\share-name

**Solutions**:
```bash
# Check SMB service status
sudo systemctl status smbd nmbd

# Test SMB configuration
sudo testparm

# Check if ports are open
sudo netstat -tlnp | grep :445
sudo netstat -tlnp | grep :139

# Test from Linux client
smbclient -L //192.168.1.100 -U john

# Check share permissions
sudo ls -la /mnt/tank/shared/media

# Restart SMB services
sudo systemctl restart smbd nmbd
```

### NFS Mounts Fail
**Symptoms**: NFS mount commands fail

**Solutions**:
```bash
# Check NFS service
sudo systemctl status nfs-server

# Check exports
sudo exportfs -v

# Test from client
showmount -e 192.168.1.100

# Check NFS ports
sudo netstat -tlnp | grep :2049

# Refresh exports
sudo exportfs -ra

# Check client-side issues
sudo mount -t nfs 192.168.1.100:/mnt/tank/shared/media /mnt/test -v
```

### Firewall Blocking Services
**Symptoms**: Services work locally but not remotely

**Solutions**:
```bash
# Check current firewall rules
sudo ufw status verbose

# Allow specific service through firewall
sudo ufw allow from 192.168.1.0/24 to any port 445
sudo ufw allow from 192.168.1.0/24 to any port 2049

# Temporarily disable firewall to test
sudo ufw disable
# Test your connection
# Re-enable firewall
sudo ufw enable

# Check for conflicting rules
sudo iptables -L -n
```

## 👥 User and Permission Issues

### User Cannot Access Home Directory
**Symptoms**: Permission denied accessing /mnt/tank/home/username

**Solutions**:
```bash
# Check directory ownership and permissions
ls -la /mnt/tank/home/

# Fix ownership
sudo chown john:john /mnt/tank/home/john
sudo chmod 750 /mnt/tank/home/john

# Check user exists and is in correct groups
id john
groups john

# Check dataset permissions
sudo zfs get -r acltype,aclinherit,aclmode tank/home
```

### Cannot Write to Shared Folders
**Symptoms**: Read access works but writes fail

**Solutions**:
```bash
# Check share permissions
ls -la /mnt/tank/shared/media/

# Fix group ownership
sudo chgrp family /mnt/tank/shared/media
sudo chmod g+w /mnt/tank/shared/media

# Add user to correct group
sudo usermod -a -G family alice

# Check SMB user account
sudo smbpasswd -a alice

# Verify ACL settings
getfacl /mnt/tank/shared/media
```

## 🔒 Security Issues

### SSH Key Authentication Not Working
**Symptoms**: SSH still prompts for password despite key setup

**Solutions**:
```bash
# Check SSH key permissions on client
chmod 600 ~/.ssh/truenas_key
chmod 700 ~/.ssh/

# Check authorized_keys on server
ssh john@192.168.1.100 "ls -la ~/.ssh/"
ssh john@192.168.1.100 "cat ~/.ssh/authorized_keys"

# Verify SSH configuration
ssh john@192.168.1.100 "sudo grep -E '^(PasswordAuthentication|PubkeyAuthentication)' /etc/ssh/sshd_config"

# Check SSH log for errors
ssh john@192.168.1.100 "sudo tail -f /var/log/auth.log"
```

### Firewall Rules Not Working
**Symptoms**: UFW rules configured but connections still blocked/allowed unexpectedly

**Solutions**:
```bash
# Check rule order (first match wins)
sudo ufw status numbered

# Reset firewall and reconfigure
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Add rules in correct order
sudo ufw allow from 192.168.1.0/24 to any port 22
sudo ufw allow from 192.168.1.0/24 to any port 443
sudo ufw enable
```

## 💾 Backup Issues

### Snapshots Not Creating
**Symptoms**: No automatic snapshots being created

**Solutions**:
```bash
# Check if zfs-auto-snapshot is installed
which zfs-auto-snapshot

# Install if missing
sudo apt install zfs-auto-snapshot

# Check cron jobs
sudo crontab -l | grep snapshot

# Manually create snapshot to test
sudo zfs snapshot tank/home/john@manual-test

# Check snapshot creation logs
sudo journalctl -u zfs-auto-snapshot
```

### Cloud Backup Failing
**Symptoms**: Cloud backup jobs fail or don't run

**Solutions**:
```bash
# Test cloud connectivity
ping 8.8.8.8

# Test backup tool configuration
rclone config show
rclone lsd b2:truenas-home-backup

# Check backup cron job
sudo crontab -l | grep rclone

# Test manual backup
rclone copy /mnt/tank/home/john b2:truenas-home-backup/home/john --progress

# Check backup logs
tail -f /var/log/backup.log
```

## 📊 Performance Issues

### Slow File Transfer Performance
**Symptoms**: File transfers much slower than expected

**Solutions**:
```bash
# Check network interface status
ip link show
ethtool eno1

# Test network speed
iperf3 -s  # On TrueNAS
iperf3 -c 192.168.1.100 -t 60  # On client

# Check ZFS performance
sudo zpool iostat -v tank 1

# Check system resources
htop
iostat -x 1

# Optimize recordsize for workload
sudo zfs set recordsize=1M tank/shared/media  # For large files
sudo zfs set recordsize=128K tank/shared/documents  # For mixed files

# Check network settings
sudo sysctl net.core.rmem_max
sudo sysctl net.core.wmem_max
```

### High CPU Usage
**Symptoms**: System showing high CPU utilization

**Solutions**:
```bash
# Identify CPU-intensive processes
top
htop

# Check ZFS compression impact
sudo zpool get all tank | grep compress
sudo zfs get compression tank

# Consider different compression algorithm
sudo zfs set compression=lz4 tank  # Faster compression
sudo zfs set compression=off tank  # Disable if CPU limited

# Check scrub/resilver operations
sudo zpool status tank
```

## 🔧 Maintenance Issues

### SMART Tests Failing
**Symptoms**: SMART test failures reported

**Solutions**:
```bash
# Check SMART status for all drives
for drive in sda sdb sdc sdd; do
  echo "=== /dev/$drive ==="
  sudo smartctl -a /dev/$drive | grep -E "(test result|health)"
done

# Review detailed SMART data
sudo smartctl -a /dev/sda

# Run manual SMART test
sudo smartctl -t short /dev/sda

# If drive is failing, plan replacement
sudo smartctl -A /dev/sda | grep -E "(Reallocated|Pending|Offline)"
```

### Pool Scrub Takes Too Long  
**Symptoms**: Monthly scrub takes more than 24 hours

**Solutions**:
```bash
# Check scrub progress
sudo zpool status tank

# Pause scrub if needed
sudo zpool scrub -p tank

# Resume scrub later
sudo zpool scrub tank

# Consider scheduling scrub during off-hours
# Edit crontab to run at different time
sudo crontab -e
```

## 🆘 Emergency Procedures

### Complete System Recovery
If system becomes unbootable:

1. **Boot from TrueNAS USB installer**
2. **Import existing pool**:
   ```bash
   sudo zpool import tank
   ```
3. **Mount datasets**:
   ```bash
   sudo zfs mount -a
   ```
4. **Backup critical data** before attempting repairs

### Data Recovery from Failed Pool
If pool cannot be imported:

1. **Try force import**:
   ```bash
   sudo zpool import -f tank
   ```
2. **Try read-only import**:
   ```bash
   sudo zpool import -o readonly=on tank
   ```
3. **If successful, immediately backup data**
4. **Recreate pool and restore from backup**

### Network Recovery
If locked out of system:

1. **Access via console (IPMI/physical)**
2. **Reset network configuration**:
   ```bash
   sudo netplan apply
   sudo systemctl restart networking
   ```
3. **Disable firewall temporarily**:
   ```bash
   sudo ufw disable
   ```
4. **Re-enable SSH access**:
   ```bash
   sudo systemctl restart ssh
   ```

## 📞 Getting Additional Help

### Information to Collect Before Asking for Help
```bash
# System information
uname -a
cat /etc/version

# Hardware information  
lscpu
free -h
lsblk

# Pool and dataset status
sudo zpool status -v
sudo zfs list

# Service status
sudo systemctl status smbd nmbd nfs-server ssh

# Network configuration
ip addr show
sudo ufw status verbose

# Recent logs
sudo journalctl --since "1 hour ago" --no-pager
```

### Support Resources
- **TrueNAS Community Forums**: https://www.truenas.com/community/
- **TrueNAS Documentation**: https://www.truenas.com/docs/
- **ZFS Documentation**: https://openzfs.github.io/openzfs-docs/
- **This Repository**: Create an issue with the system information above

## 🔄 Prevention Tips

### Regular Monitoring
- Check system status weekly
- Monitor pool capacity monthly
- Review SMART data quarterly
- Test backups quarterly

### Proactive Maintenance
- Keep system updated
- Replace aging drives before failure
- Monitor performance trends
- Document all changes

### Backup Strategy
- Maintain 3-2-1 backup strategy
- Test restore procedures regularly
- Keep emergency boot media updated
- Document recovery procedures

Remember: **Prevention is better than cure!** Regular monitoring and maintenance prevent most issues.
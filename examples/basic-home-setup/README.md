# Basic Home Setup - Complete Example

This example demonstrates a complete TrueNAS SCALE deployment for home or small office use. It follows the **Basic** deployment tier from the multi-agent framework, providing a resilient, safely managed single-node system.

## 🏠 Scenario Overview

**Target Environment**: Home office with 4-6 users
- **Primary Use**: File sharing, media storage, basic apps
- **Storage**: 8TB usable capacity with redundancy  
- **Users**: Family members with different access levels
- **Remote Access**: Secure VPN-only admin access
- **Backup**: Local snapshots + cloud backup for critical data

## 📋 Hardware Requirements

### Minimum Specifications
- **CPU**: 4-core 64-bit processor (Intel/AMD)
- **RAM**: 16GB (recommended for running apps)
- **Boot**: 2x 120GB SATA SSDs (mirrored)
- **Storage**: 4x 4TB SATA drives (RAIDZ1 configuration)
- **Network**: Gigabit Ethernet

### Example Build
```
- Motherboard: Basic ATX with 6+ SATA ports
- CPU: Intel i5 or AMD Ryzen 5
- RAM: 16GB DDR4 
- Boot drives: 2x Samsung 870 EVO 120GB SSD
- Data drives: 4x WD Red 4TB (WD40EFAX) 
- Case: Fractal Design Node 304 (6 drive bays)
```

## 🗂️ Directory Structure

```
basic-home-setup/
├── README.md                   # This file
├── specs/                      # Configuration specifications
│   ├── pools/                  
│   ├── datasets/               
│   ├── users-groups/           
│   ├── shares/                 
│   ├── network/                
│   ├── backup/                 
│   └── monitoring/             
├── ansible/                    # Automation playbooks
│   ├── inventory/              
│   ├── bootstrap.yml           
│   ├── provision.yml           
│   └── vars/                   
├── tests/                      # Validation and testing
│   ├── validate-deployment.sh  
│   └── verify-backup.sh        
└── docs/                       # Documentation
    ├── deployment-guide.md     
    ├── user-guide.md           
    └── maintenance.md          
```

## 🚀 Quick Deployment

### 1. Pre-requisites Check
```bash
# Ensure TrueNAS SCALE is installed and accessible
ssh admin@your-truenas-ip "uname -a"

# Verify storage devices are detected
ssh admin@your-truenas-ip "lsblk"
```

### 2. Deploy Configuration
```bash
# Clone this repository
git clone <repository-url>
cd examples/basic-home-setup

# Review and customize configurations
vi specs/pools/home-pool.yaml        # Adjust disk names
vi specs/users-groups/family.yaml    # Set up your users
vi ansible/inventory/hosts           # Set your TrueNAS IP

# Deploy
ansible-playbook -i ansible/inventory ansible/bootstrap.yml
ansible-playbook -i ansible/inventory ansible/provision.yml
```

### 3. Validate Deployment
```bash
# Run validation tests
./tests/validate-deployment.sh

# Test backup functionality  
./tests/verify-backup.sh
```

## 👥 User Scenarios

### Family Structure
- **Dad**: `john` - Storage admin, full access
- **Mom**: `susan` - Media management, shared folders
- **Kids**: `alice`, `bob` - Personal folders, limited shared access  
- **Guest**: `guest` - Read-only access to public shares

### Access Patterns
- **Personal folders**: Each user has private space
- **Family sharing**: Photos, documents, media
- **Backup**: Critical data auto-backed up to cloud
- **Apps**: Plex for media, Nextcloud for file sync

## 🔧 Key Features Implemented

### Storage Strategy
- **Pool**: Single RAIDZ1 pool (3-drive parity, 1-drive fault tolerance)
- **Datasets**: Separate datasets for different data types
- **Compression**: LZ4 compression enabled for space savings
- **Snapshots**: Automatic hourly/daily/weekly snapshots

### Security 
- **VPN Access**: Admin UI only accessible via VPN
- **User Isolation**: Proper ACLs and dataset permissions  
- **SSH Keys**: Key-based authentication, no passwords
- **Firewall**: Minimal open ports, internal-only services

### Backup Strategy (3-2-1)
- **3 copies**: Original + 2 backups
- **2 locations**: Local snapshots + cloud backup  
- **1 offsite**: Encrypted backup to Backblaze B2

### Monitoring
- **SMART**: Daily short tests, weekly long tests
- **Scrub**: Monthly pool scrubs
- **Alerts**: Email notifications for issues
- **Health**: Dashboard for system status

## 📊 Expected Performance

With the example hardware:
- **Sequential Read**: ~400 MB/s (Gigabit network limited)
- **Sequential Write**: ~300 MB/s  
- **IOPS**: 150-200 (mechanical drives)
- **Capacity**: 12TB raw → 9TB usable (RAIDZ1)

## 🚨 Operational Procedures

### Daily Operations
- Monitor system health dashboard
- Check email alerts for any issues
- Verify backup jobs completed successfully

### Weekly Tasks  
- Review storage usage and cleanup
- Check long SMART test results
- Verify snapshot retention policies

### Monthly Tasks
- Pool scrub results review
- Update system packages
- Test restore procedures
- Review user access logs

## ⚠️ Important Notes

### What's Included ✅
- Complete working configuration
- Automated deployment
- Essential monitoring
- Backup strategy
- User management
- Security hardening

### What's NOT Included ❌
- High availability (single point of failure)
- Advanced caching (L2ARC/SLOG)
- Complex networking (single NIC)
- Enterprise features (clustering, etc.)

### Upgrade Path 
To move to advanced features:
1. Add L2ARC cache drives for performance
2. Implement proper VPN server setup  
3. Add redundant networking
4. Scale to multiple nodes for HA

## 💡 Customization Tips

### Adapting to Your Hardware
- **Different drive counts**: Adjust vdev configuration in `pools/home-pool.yaml`
- **More RAM**: Increase ARC size in performance tuning
- **Faster drives**: Consider different recordsize settings for datasets
- **Network**: Configure link aggregation if multiple NICs available

### Scaling Users
- **More users**: Add to `users-groups/family.yaml`
- **Different roles**: Create additional groups with specific permissions
- **Guest access**: Configure read-only shares for visitors

## 🔗 Next Steps

After successful deployment:
1. **User Training**: Share the `docs/user-guide.md` with family members
2. **Monitoring**: Set up the dashboard and alerts
3. **Backup Testing**: Schedule quarterly restore tests
4. **Documentation**: Keep deployment notes for future reference

## 📞 Support

- **Issues**: Use the GitHub issue template
- **Questions**: Consult the main framework documentation
- **Community**: Join the TrueNAS community forums
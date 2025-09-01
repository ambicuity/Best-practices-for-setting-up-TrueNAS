# Integration Examples

This directory demonstrates how different components of the TrueNAS framework work together to create complete solutions.

## 🔗 Component Integration Examples

### Storage + Backup Integration
Shows how storage specifications work with backup policies:

```yaml
# specs/pools/example-pool.yaml
pool: data
vdevs:
  - type: raidz2
    disks: [sda, sdb, sdc, sdd, sde]

# specs/datasets/example-data.yaml  
datasets:
  - name: data/critical
    properties:
      compression: zstd
      recordsize: 128K
    
# specs/backup/example-backup.yaml
snapshots:
  - dataset: data/critical
    schedule: hourly
    keep: 48
replication:
  - from: data/critical
    to: cloud://backup/critical
    schedule: daily
```

**Result**: Critical data gets optimized storage with frequent snapshots and daily cloud backup.

### Users + Shares + Security Integration
Shows how user management integrates with share permissions and security:

```yaml
# specs/users-groups/example-users.yaml
groups:
  - name: managers
    gid: 1001
  - name: employees  
    gid: 1002
    
users:
  - name: alice
    groups: [managers]
  - name: bob
    groups: [employees]

# specs/shares/example-shares.yaml
smb_shares:
  - name: management
    path: /mnt/data/management
    valid_groups: ["managers"]
    read_only: false
  - name: public
    path: /mnt/data/public  
    valid_groups: ["employees", "managers"]
    read_only: false

# specs/network/example-security.yaml
firewall:
  rules:
    - name: allow-smb-internal
      protocol: tcp
      port: 445
      source: 10.0.0.0/8
```

**Result**: Managers get access to management share, all employees get public share, external access blocked.

### Monitoring + Backup + Alerting Integration  
Shows how monitoring detects issues and alerts administrators:

```yaml
# specs/monitoring/example-monitoring.yaml
storage_monitoring:
  smart_monitoring:
    enabled: true
    alert_on_failure: true
    
backup_monitoring:
  job_monitoring:
    enabled: true
    alert_on_failure: true
    
alerting:
  email:
    enabled: true
    recipients: ["admin@company.com"]

# specs/backup/example-policies.yml
snapshots:
  - dataset: data/critical
    schedule: hourly
    validation: true
    
monitoring:
  backup_jobs:
    check_interval: 3600
    alert_on:
      - job_failed
      - snapshot_missing
      - unusual_size
```

**Result**: System monitors backups, SMART health, and sends email alerts when issues occur.

## 🏗️ Multi-Component Scenarios

### Complete Home Office Setup
Integrates all components for a home office environment:

```bash
examples/integrations/home-office/
├── specs/
│   ├── pools/office-storage.yaml      # 4-drive RAIDZ1 pool
│   ├── datasets/office-data.yaml      # User homes + shared areas
│   ├── users-groups/office-users.yaml # Family + work separation
│   ├── shares/office-shares.yaml      # SMB/NFS with proper ACLs
│   ├── network/office-network.yaml    # Firewall + VPN ready
│   ├── backup/office-backup.yaml      # 3-2-1 backup strategy
│   └── monitoring/office-monitor.yaml # Health monitoring + alerts
├── ansible/
│   ├── site.yml                       # Complete deployment playbook
│   └── inventory/office-hosts         # Target environment
└── tests/
    └── validate-office.sh             # End-to-end testing
```

### Small Business Setup  
Shows enterprise-grade features for small business:

```bash
examples/integrations/small-business/
├── specs/
│   ├── pools/business-storage.yaml    # Mirrored vdevs for performance
│   ├── datasets/business-data.yaml    # Department separation
│   ├── users-groups/business-users.yaml # Role-based access control
│   ├── shares/business-shares.yaml    # Department shares + guest access
│   ├── network/business-network.yaml  # VLANs + advanced firewall
│   ├── backup/business-backup.yaml    # Multi-tier backup strategy
│   └── monitoring/business-monitor.yaml # Comprehensive monitoring
└── compliance/
    └── security-policy.yaml           # Security compliance requirements
```

## 🔄 Workflow Integration Examples

### Development to Production Pipeline
Shows how to progress from development to production:

1. **Development Environment**:
   ```yaml
   # specs/environments/dev.yaml
   environment: development
   pool_name: dev-pool
   backup_retention: minimal
   monitoring: basic
   ```

2. **Staging Environment**:
   ```yaml
   # specs/environments/staging.yaml  
   environment: staging
   pool_name: staging-pool
   backup_retention: standard
   monitoring: enhanced
   ```

3. **Production Environment**:
   ```yaml
   # specs/environments/prod.yaml
   environment: production
   pool_name: prod-pool
   backup_retention: comprehensive
   monitoring: full
   high_availability: true
   ```

### Multi-Agent Deployment Integration
Shows how different agents collaborate:

```yaml
# .github/workflows/deploy.yml
name: TrueNAS Deployment
on:
  pull_request:
    paths: ['specs/**']

jobs:
  validate:
    runs-on: ubuntu-latest  
    steps:
      - name: QA Agent - Validate Specs
        run: ./tests/schema/validate.sh
        
  security-check:
    runs-on: ubuntu-latest
    steps:
      - name: Security Agent - Policy Check  
        run: ./tests/policy/check.sh
        
  deploy:
    needs: [validate, security-check]
    runs-on: ubuntu-latest
    steps:
      - name: Systems Agent - Bootstrap
        run: ansible-playbook ansible/bootstrap.yml
        
      - name: Storage Agent - Provision
        run: ansible-playbook ansible/provision.yml
        
      - name: Apps Agent - Configure Services
        run: ansible-playbook ansible/services.yml
        
  test:
    needs: deploy
    runs-on: ubuntu-latest
    steps:
      - name: QA Agent - Validate Deployment
        run: ./tests/validate-deployment.sh
```

## 🎯 Real-World Integration Scenarios

### Media Server + Backup + Monitoring
Complete Plex media server with comprehensive backup:

```yaml
# Dataset optimized for media
datasets:
  - name: tank/media
    properties:
      recordsize: 1M        # Large files
      compression: lz4      # Fast compression
      atime: off           # No access time updates
      
# Plex application configuration  
apps:
  plex:
    dataset: tank/apps/plex
    media_path: /mnt/tank/media
    transcoding: enabled
    
# Backup strategy for media
backup:
  snapshots:
    - dataset: tank/media
      schedule: weekly      # Media changes less frequently
      keep: 4
  cloud_backup:
    enabled: false         # Too expensive for large media
    
# Monitoring for media server
monitoring:
  plex_monitoring:
    enabled: true
    check_transcoding: true
    disk_space_alert: 80%
```

### Remote Work Setup with VPN
Secure remote access to home office data:

```yaml
# VPN configuration
network:
  wireguard:
    enabled: true
    port: 51820
    network: 10.0.0.0/24
    peers:
      - name: laptop
        public_key: "..."
        allowed_ips: ["10.0.0.2/32"]
        
# Firewall rules for VPN
firewall:
  rules:
    - name: allow-wireguard
      protocol: udp
      port: 51820
      source: any
    - name: allow-vpn-smb
      protocol: tcp  
      port: 445
      source: 10.0.0.0/24
      
# Shares accessible via VPN
shares:
  smb:
    - name: work-files
      path: /mnt/tank/work
      valid_users: ["@remote-workers"]
      encryption: required
```

### Family Photo Backup Strategy
Comprehensive backup for irreplaceable family photos:

```yaml
# Photo storage optimization
datasets:
  - name: tank/photos
    properties:
      recordsize: 1M        # Large image files
      compression: lz4      # Some compression benefit
      copies: 2            # Extra local redundancy
      
# Multi-tier backup strategy
backup:
  snapshots:
    - dataset: tank/photos
      hourly: {keep: 48}    # Frequent local snapshots
      daily: {keep: 30}     # Monthly local retention
      
  replication:
    # Cloud backup (Backblaze B2)
    - name: photos-to-cloud
      from: tank/photos
      to: b2://family-backup/photos
      schedule: daily
      encryption: true
      
    # Friend's NAS (reciprocal backup)  
    - name: photos-to-friend
      from: tank/photos
      to: ssh://friend-nas/backup/photos
      schedule: weekly
      bandwidth_limit: 10Mbps
      
# Photo management integration
apps:
  nextcloud:
    photo_sync: enabled
    dataset: tank/apps/nextcloud
    linked_folders: ["/mnt/tank/photos"]
```

## 🧪 Testing Integration

### End-to-End Testing Strategy
Complete testing that validates all integrations:

```bash
#!/bin/bash
# tests/integration/full-stack-test.sh

echo "=== Full Stack Integration Test ==="

# Test 1: Storage + User Integration
echo "Testing storage and user integration..."
./tests/validate-deployment.sh

# Test 2: Backup Integration
echo "Testing backup integration..."
./tests/verify-backup.sh

# Test 3: Network + Security Integration  
echo "Testing network security..."
./tests/security-scan.sh

# Test 4: Monitoring Integration
echo "Testing monitoring integration..."
./tests/validate-monitoring.sh

# Test 5: Performance Integration
echo "Testing performance with load..."
./tests/performance-test.sh

# Generate integration report
echo "Generating integration test report..."
./tests/generate-report.sh
```

### Continuous Integration Testing
Automated testing in CI/CD pipeline:

```yaml
# .github/workflows/integration-test.yml
name: Integration Tests
on:
  schedule:
    - cron: '0 6 * * 1'  # Weekly full integration test
    
jobs:
  integration:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        scenario: [basic-home, small-business, media-server]
        
    steps:
      - uses: actions/checkout@v4
        
      - name: Deploy ${{ matrix.scenario }}
        run: |
          cd examples/integrations/${{ matrix.scenario }}
          ansible-playbook -i inventory site.yml
          
      - name: Run Integration Tests
        run: |
          cd examples/integrations/${{ matrix.scenario }}
          ./tests/integration-test.sh
          
      - name: Generate Report
        run: |
          ./tests/generate-integration-report.sh ${{ matrix.scenario }}
          
      - name: Upload Results
        uses: actions/upload-artifact@v4
        with:
          name: integration-results-${{ matrix.scenario }}
          path: reports/
```

## 📊 Integration Benefits

### Reduced Complexity
- **Single Source of Truth**: All configuration in version-controlled YAML
- **Consistent Patterns**: Same approach across all components
- **Automated Validation**: Ensures configurations work together

### Improved Reliability  
- **Tested Combinations**: Known-good component combinations
- **Automated Testing**: CI/CD validates all changes
- **Rollback Capability**: Version control enables quick rollbacks

### Enhanced Security
- **Defense in Depth**: Multiple security layers work together
- **Consistent Policies**: Security applied uniformly across all components
- **Audit Trail**: All changes tracked and logged

### Operational Excellence
- **Monitoring Integration**: All components monitored consistently  
- **Automated Response**: Issues detected and resolved automatically
- **Knowledge Sharing**: Documented patterns enable team collaboration

## 🚀 Next Steps

1. **Choose Your Scenario**: Start with the integration example that matches your use case
2. **Customize Configuration**: Adapt the example to your specific requirements
3. **Deploy Incrementally**: Start with core components, add features gradually  
4. **Validate Integration**: Use provided tests to ensure everything works together
5. **Monitor and Improve**: Use monitoring data to optimize your configuration

The integration examples demonstrate the power of the multi-agent framework - components working together seamlessly to deliver complete solutions that are greater than the sum of their parts.
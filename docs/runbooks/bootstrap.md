# TrueNAS Bootstrap Runbook

## Overview
This runbook provides step-by-step instructions for bootstrapping a new TrueNAS SCALE system using the multi-agent framework.

## Prerequisites
- TrueNAS SCALE installed on mirrored boot SSDs (≥60GB each)
- Network connectivity established
- Administrative access via console or SSH
- Ansible control machine configured

## Bootstrap Process

### Phase 1: Initial System Setup
1. **Verify Installation**
   ```bash
   # Check system status
   systemctl status truenas
   zpool status
   ```

2. **Update System**
   ```bash
   # Apply latest updates
   apt update && apt upgrade -y
   ```

3. **Configure Network**
   - Set static IP address
   - Configure VLANs if required
   - Test connectivity

### Phase 2: Security Hardening
1. **Run Ansible Bootstrap**
   ```bash
   cd /path/to/repository
   ansible-playbook -i inventory/hosts ansible/bootstrap.yml
   ```

2. **Verify Security Settings**
   - SSH key authentication enabled
   - Root login disabled
   - Sudo configured for admin group

### Phase 3: Storage Provisioning
1. **Review Storage Specifications**
   - Validate `specs/pools/pool-main.yaml`
   - Confirm disk layout matches physical hardware

2. **Run Provisioning Playbook**
   ```bash
   ansible-playbook -i inventory/hosts ansible/provision.yml
   ```

3. **Verify Pool Creation**
   ```bash
   zpool status
   zfs list
   ```

### Phase 4: Service Configuration
1. **Configure Datasets**
   - Create application-specific datasets
   - Set appropriate permissions and ACLs

2. **Set Up Backup Policies**
   - Configure snapshot schedules
   - Set up replication tasks
   - Test restore procedures

### Phase 5: Monitoring and Maintenance
1. **Configure SMART Tests**
   - Verify daily short tests
   - Confirm weekly long tests

2. **Set Up Scrub Schedule**
   - Monthly pool scrubs
   - Alert configuration

## Rollback Procedures
If bootstrap fails, use these recovery steps:

1. **Revert Network Changes**
   ```bash
   # Restore original network configuration
   cp /etc/netplan/01-netcfg.yaml.backup /etc/netplan/01-netcfg.yaml
   netplan apply
   ```

2. **Re-enable Root Access** (emergency only)
   ```bash
   # From console
   passwd root
   sed -i 's/PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config
   systemctl restart sshd
   ```

## Validation Checklist
- [ ] System updated and secure
- [ ] SSH access working with keys
- [ ] Storage pools created and healthy
- [ ] Datasets configured with proper permissions
- [ ] Backup policies implemented
- [ ] Monitoring and alerting active
- [ ] VPN access configured (if remote management required)
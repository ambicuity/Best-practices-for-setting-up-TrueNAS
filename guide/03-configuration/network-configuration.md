# Network Configuration

> **Configure advanced networking, VLANs, link aggregation, and network security to optimize your TrueNAS deployment.**

## 🎯 Network Configuration Overview

This guide covers advanced network configuration beyond the basic setup completed during initial installation. These configurations optimize performance, security, and functionality.

**Estimated Time**: 1-3 hours  
**Difficulty**: Intermediate to Advanced  
**Prerequisites**: [Storage Setup](storage-setup.md) completed

---

## 🌐 Network Planning Review

### Current Network Assessment

Before making changes, document your current configuration:

**Navigate to**: Network → Interfaces

1. **Current Interface Status:**
   ```
   Network Interfaces:
   ├── eth0 (Primary)
   │   ├── Status: UP
   │   ├── IP: 192.168.1.100/24  
   │   ├── Gateway: 192.168.1.1
   │   └── Speed: 1000 Mbps
   ├── eth1 (Secondary - if available)
   │   └── Status: DOWN
   └── lo (Loopback)
       └── Status: UP
   ```

2. **Test Current Network Performance:**
   ```bash
   # Test from TrueNAS shell
   iperf3 -s    # Start server mode on TrueNAS
   
   # From client machine:
   iperf3 -c 192.168.1.100 -t 30    # Test throughput
   ```

---

## 🔗 Advanced Interface Configuration

### Static IP Configuration Optimization

**Navigate to**: Network → Interfaces → Select Interface

1. **IPv4 Configuration:**
   - **DHCP**: Disabled
   - **IP Address**: `192.168.1.100`
   - **Netmask**: `24` (255.255.255.0)
   - **Additional IPs**: Add service-specific IPs if needed

2. **IPv6 Configuration (if used):**
   - **Auto**: Disabled for static configuration
   - **IPv6 Address**: Your IPv6 address
   - **Prefix Length**: Typically `64`

3. **Advanced Options:**
   - **MTU**: `1500` (standard) or `9000` (jumbo frames on compatible networks)
   - **Options**: Custom interface options if needed

### Jumbo Frames Configuration

For high-performance environments with compatible switches:

1. **Enable Jumbo Frames:**
   - **MTU**: `9000`
   - **Verify switch support** before enabling
   - **Test thoroughly** - can break connectivity if not supported

2. **Jumbo Frame Testing:**
   ```bash
   # Test large packet transmission
   ping -M do -s 8972 192.168.1.1
   
   # If successful, jumbo frames are working
   # If fragmentation occurs, reduce MTU
   ```

---

## 🔀 Link Aggregation (LAGG)

### LAGG Benefits and Use Cases

Link aggregation provides:
- **Increased bandwidth** (multiple NICs combined)
- **Redundancy** (failover if one NIC fails)
- **Load balancing** across multiple connections

### Creating LAGG Interface

**Navigate to**: Network → Link Aggregation

**Prerequisites**: 2+ network interfaces and compatible switch

1. **LAGG Configuration:**
   - **LAGG Protocol**: `LACP` (recommended for managed switches)
   - **LAGG Interfaces**: Select `eth0` and `eth1`
   - **Description**: `Primary LAGG - 2x1GbE`

2. **LACP Configuration on Switch:**
   ```
   Switch Configuration Required:
   ├── Port 1 (eth0): Add to LACP group
   ├── Port 2 (eth1): Add to LACP group  
   ├── LACP Mode: Active
   └── Load Balance: Source+Destination MAC
   ```

3. **IP Configuration:**
   - Move IP configuration from individual interfaces to LAGG interface
   - **IP Address**: `192.168.1.100/24`
   - **Gateway**: `192.168.1.1`

### LAGG Testing and Verification

```bash
# Check LAGG status
ifconfig lagg0

# Test aggregate bandwidth
iperf3 -c 192.168.1.100 -P 4 -t 30

# Monitor individual interface usage
netstat -i
```

---

## 🏷️ VLAN Configuration

### VLAN Planning

VLANs segment network traffic for security and organization:

```
VLAN Design Example:
├── VLAN 1 (Native): General network traffic
├── VLAN 10 (Management): TrueNAS management interface
├── VLAN 20 (Storage): High-performance storage traffic  
├── VLAN 30 (Backup): Backup and replication traffic
└── VLAN 40 (DMZ): External-facing services
```

### Creating VLAN Interfaces

**Navigate to**: Network → VLANs

1. **Management VLAN (VLAN 10):**
   - **VLAN Tag**: `10`
   - **Parent Interface**: `eth0` or `lagg0`
   - **Description**: `Management Network`

2. **Storage VLAN (VLAN 20):**
   - **VLAN Tag**: `20`
   - **Parent Interface**: `eth0` or `lagg0`
   - **Description**: `High-Performance Storage`

### Configuring VLAN IP Addresses

**Navigate to**: Network → Interfaces

For each VLAN, create a network interface:

1. **Management VLAN Interface:**
   - **Interface**: `vlan10`
   - **IP Address**: `10.0.10.100/24`
   - **Description**: `Management Interface`

2. **Storage VLAN Interface:**
   - **Interface**: `vlan20`
   - **IP Address**: `10.0.20.100/24`
   - **Description**: `Storage Network`

### VLAN Testing

```bash
# Test VLAN connectivity
ping -I vlan10 10.0.10.1    # Test management VLAN
ping -I vlan20 10.0.20.1    # Test storage VLAN

# Check VLAN interface status
ip addr show vlan10
ip addr show vlan20
```

---

## 🌍 Global Network Configuration

### DNS Configuration

**Navigate to**: Network → Global Configuration

1. **Domain Configuration:**
   - **Hostname**: `truenas-primary`
   - **Domain**: `home.local` (or your domain)
   - **Additional Domains**: Add search domains if needed

2. **DNS Server Configuration:**
   ```
   DNS Server Priority:
   ├── Primary: 1.1.1.1 (Cloudflare)
   ├── Secondary: 8.8.8.8 (Google)  
   ├── Tertiary: 192.168.1.1 (Router - optional)
   └── IPv6: 2606:4700:4700::1111 (if using IPv6)
   ```

3. **DNS Testing:**
   ```bash
   # Test DNS resolution
   nslookup google.com
   dig @1.1.1.1 truenas.com
   
   # Test reverse DNS
   nslookup 192.168.1.100
   ```

### Static Route Configuration

**Navigate to**: Network → Static Routes

For complex network topologies:

1. **Example Static Route:**
   - **Destination**: `10.0.50.0/24`
   - **Gateway**: `192.168.1.1`
   - **Description**: `Route to remote office network`

### Network Summary Configuration

**Navigate to**: Network → Global Configuration

1. **Default Gateway:**
   - **IPv4 Gateway**: `192.168.1.1`
   - **IPv6 Gateway**: Your IPv6 gateway (if applicable)

2. **Host Name Database:**
   - Add entries for frequently accessed systems
   - Useful for systems without proper DNS

---

## 🔒 Network Security Configuration

### Firewall Configuration

TrueNAS SCALE uses `nftables` for firewall functionality:

**Navigate to**: System → Services → SSH

1. **SSH Security:**
   - **TCP Port**: Consider changing from `22` to non-standard port
   - **Login as Root**: Disabled
   - **Allow Password Authentication**: Disable after setting up keys

### Network Access Control

1. **Management Interface Restrictions:**
   ```
   Security Best Practices:
   ├── Management VLAN: Restricted to admin devices
   ├── Storage VLAN: High-speed, isolated traffic
   ├── Main Network: General access with restrictions
   └── DMZ VLAN: External services (if needed)
   ```

2. **Service Binding:**
   - Bind services to specific interfaces
   - Prevent management access from untrusted networks
   - Use VPN for remote management

---

## 📊 Network Performance Tuning

### TCP/IP Stack Optimization

**Navigate to**: System → Tunables

1. **Network Buffer Tuning:**
   ```
   Recommended Network Tunables:
   ├── net.core.rmem_max = 16777216
   ├── net.core.wmem_max = 16777216
   ├── net.ipv4.tcp_rmem = 4096 16384 16777216
   └── net.ipv4.tcp_wmem = 4096 16384 16777216
   ```

2. **High-Performance Settings:**
   ```bash
   # For high-throughput environments
   sysctl net.core.netdev_max_backlog=5000
   sysctl net.ipv4.tcp_window_scaling=1
   sysctl net.ipv4.tcp_timestamps=1
   ```

### Network Monitoring Setup

1. **Interface Statistics:**
   ```bash
   # Monitor network throughput
   netstat -i 1
   
   # Monitor network connections
   ss -tuln
   
   # Check interface errors
   cat /proc/net/dev
   ```

2. **Performance Baselines:**
   ```bash
   # Baseline network performance
   iperf3 -c target-host -P 4 -t 60
   
   # Test different packet sizes
   iperf3 -c target-host -l 64K -P 1 -t 30
   ```

---

## 🔧 Service-Specific Network Configuration

### SMB/CIFS Network Optimization

**Navigate to**: Services → SMB

1. **SMB Network Settings:**
   - **Bind IP Addresses**: Select specific interfaces
   - **NetBIOS Name**: Keep unique and descriptive
   - **Workgroup**: Match your network workgroup

2. **SMB Performance Tuning:**
   ```
   SMB Optimization:
   ├── Enable: SMB3 multichannel (if multiple NICs)
   ├── Socket Options: SO_KEEPALIVE SO_RCVBUF=65536 SO_SNDBUF=65536
   ├── Min/Max Protocol: SMB2/SMB3
   └── Server Multi-Channel: Enabled
   ```

### NFS Network Configuration

**Navigate to**: Services → NFS

1. **NFS Service Settings:**
   - **Bind IP Addresses**: Specify interfaces for NFS traffic
   - **Mountd Port**: Static port for firewall configuration
   - **RPC Lockd Port**: Static port configuration

2. **NFS Performance Settings:**
   - **Servers**: Match CPU core count for high load
   - **UDP**: Disabled (use TCP for reliability)

### iSCSI Network Configuration

**Navigate to**: Services → iSCSI

1. **iSCSI Portal Configuration:**
   - **IP Address**: Dedicated storage network IP
   - **Port**: 3260 (standard)
   - **Discovery Auth Method**: CHAP recommended

---

## 🔍 Network Troubleshooting Tools

### Network Diagnostic Commands

```bash
# Interface status and configuration
ip addr show
ip route show
ip link show

# Network connectivity testing
ping -c 4 8.8.8.8
traceroute google.com
telnet host port

# Network performance testing
iperf3 -s                    # Server mode
iperf3 -c target -P 4 -t 30  # Client test

# Network statistics
ss -tuln                     # Active connections
netstat -i                   # Interface statistics
netstat -r                   # Routing table

# DNS testing
nslookup hostname
dig @server hostname
host hostname
```

### Network Monitoring Scripts

Create monitoring scripts for ongoing health checks:

```bash
#!/bin/bash
# Network health check script

echo "Network Interface Status:"
ip link show | grep -E "(eth|lagg|vlan)"

echo -e "\nNetwork Connectivity Test:"
ping -c 2 -W 2 8.8.8.8 > /dev/null && echo "Internet: OK" || echo "Internet: FAIL"
ping -c 2 -W 2 192.168.1.1 > /dev/null && echo "Gateway: OK" || echo "Gateway: FAIL"

echo -e "\nDNS Resolution Test:"
nslookup google.com > /dev/null && echo "DNS: OK" || echo "DNS: FAIL"

echo -e "\nInterface Statistics:"
cat /proc/net/dev | grep -E "(eth|lagg|vlan)" | awk '{print $1 $2 $10}'
```

---

## 📋 Network Configuration Checklist

### Basic Network Configuration:
- [ ] **Static IP configured** and accessible
- [ ] **DNS resolution** working correctly
- [ ] **Gateway connectivity** confirmed
- [ ] **Interface speeds** optimal (1Gbps+ where available)
- [ ] **MTU settings** appropriate for network infrastructure

### Advanced Network Features:
- [ ] **LAGG configured** (if multiple interfaces available)
- [ ] **VLANs implemented** (if network segmentation required)
- [ ] **Jumbo frames** tested (if high-performance network)
- [ ] **Static routes** configured (if complex topology)
- [ ] **Host name resolution** working

### Security Configuration:
- [ ] **SSH hardened** (key-only authentication, non-standard port)
- [ ] **Service binding** configured for appropriate interfaces
- [ ] **Management access** restricted to appropriate networks
- [ ] **Firewall rules** planned and documented
- [ ] **Network monitoring** tools configured

### Performance Optimization:
- [ ] **Network tunables** optimized for workload
- [ ] **Service-specific** network settings configured
- [ ] **Performance baselines** established
- [ ] **Monitoring tools** in place
- [ ] **Backup network paths** tested (if available)

---

## 🚀 Next Steps

With networking configured, you're ready to:

**[Security Hardening](security-hardening.md)** - Implement comprehensive security measures, VPN access, and access controls

---

## 🔧 Troubleshooting Network Configuration

### Common Network Issues:

**Problem**: Cannot access TrueNAS after network changes
- **Solution**: Use console access to revert changes, check IP configuration

**Problem**: Poor network performance
- **Solution**: Check MTU settings, verify switch configuration, test with iperf

**Problem**: LAGG not working correctly
- **Solution**: Verify switch LACP configuration, check cable connections

**Problem**: VLAN traffic not routing
- **Solution**: Verify VLAN configuration on switch, check IP addressing

**Problem**: DNS resolution failures
- **Solution**: Test different DNS servers, check network connectivity

### Network Recovery Procedures:

**Reset Network Configuration:**
```bash
# From TrueNAS console
1. Select "Configure Network Interfaces"
2. Reset to DHCP for recovery
3. Reconfigure from web interface
```

**Emergency Network Access:**
```bash
# If locked out, use console
ifconfig eth0 192.168.1.200/24
route add default gw 192.168.1.1
```

---
*Part of the [Complete TrueNAS Setup Guide](../README.md)*
#!/bin/bash
# TrueNAS Home Deployment Validation Script
# This script validates that the deployment was successful and all components are working

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TRUENAS_HOST=${TRUENAS_HOST:-"192.168.1.100"}
POOL_NAME=${POOL_NAME:-"tank"}
TEST_USER=${TEST_USER:-"john"}

# Logging
LOG_FILE="/tmp/truenas-validation-$(date +%Y%m%d-%H%M%S).log"
exec 1> >(tee -a "$LOG_FILE")
exec 2> >(tee -a "$LOG_FILE" >&2)

echo -e "${BLUE}=== TrueNAS Home Deployment Validation ===${NC}"
echo "Started: $(date)"
echo "Target: $TRUENAS_HOST"
echo "Log: $LOG_FILE"
echo

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Test helper functions
test_start() {
    echo -e "${BLUE}Testing: $1${NC}"
    ((TESTS_TOTAL++))
}

test_pass() {
    echo -e "${GREEN}✓ PASS: $1${NC}"
    ((TESTS_PASSED++))
}

test_fail() {
    echo -e "${RED}✗ FAIL: $1${NC}"
    ((TESTS_FAILED++))
}

test_warn() {
    echo -e "${YELLOW}⚠ WARN: $1${NC}"
}

# SSH connection test
test_ssh() {
    test_start "SSH connectivity and authentication"
    
    if ssh -o ConnectTimeout=10 -o BatchMode=yes "$TEST_USER@$TRUENAS_HOST" "echo 'SSH OK'" >/dev/null 2>&1; then
        test_pass "SSH connection successful"
        
        # Test sudo access for admin user
        if ssh -o ConnectTimeout=10 "$TEST_USER@$TRUENAS_HOST" "sudo -n id" >/dev/null 2>&1; then
            test_pass "Sudo access working"
        else
            test_fail "Sudo access not working"
        fi
    else
        test_fail "SSH connection failed"
        return 1
    fi
}

# System health check
test_system_health() {
    test_start "System health and resources"
    
    # Check system load
    LOAD=$(ssh "$TEST_USER@$TRUENAS_HOST" "uptime | awk '{print \$(NF-2)}' | sed 's/,//'")
    if (( $(echo "$LOAD < 2.0" | bc -l) )); then
        test_pass "System load acceptable ($LOAD)"
    else
        test_warn "System load high ($LOAD)"
    fi
    
    # Check memory usage
    MEM_USAGE=$(ssh "$TEST_USER@$TRUENAS_HOST" "free | grep Mem | awk '{print int(\$3/\$2 * 100)}'")
    if [ "$MEM_USAGE" -lt 80 ]; then
        test_pass "Memory usage acceptable ($MEM_USAGE%)"
    else
        test_warn "Memory usage high ($MEM_USAGE%)"
    fi
    
    # Check disk space
    ROOT_USAGE=$(ssh "$TEST_USER@$TRUENAS_HOST" "df / | tail -1 | awk '{print \$5}' | sed 's/%//'")
    if [ "$ROOT_USAGE" -lt 80 ]; then
        test_pass "Root filesystem usage acceptable ($ROOT_USAGE%)"
    else
        test_warn "Root filesystem usage high ($ROOT_USAGE%)"
    fi
}

# ZFS pool validation
test_zfs_pool() {
    test_start "ZFS pool health and configuration"
    
    # Check pool exists and is online
    if ssh "$TEST_USER@$TRUENAS_HOST" "sudo zpool status $POOL_NAME" >/dev/null 2>&1; then
        POOL_STATE=$(ssh "$TEST_USER@$TRUENAS_HOST" "sudo zpool status $POOL_NAME | grep 'state:' | awk '{print \$2}'")
        if [ "$POOL_STATE" = "ONLINE" ]; then
            test_pass "Pool $POOL_NAME is ONLINE"
        else
            test_fail "Pool $POOL_NAME state is $POOL_STATE (expected ONLINE)"
        fi
        
        # Check for any pool errors
        POOL_ERRORS=$(ssh "$TEST_USER@$TRUENAS_HOST" "sudo zpool status $POOL_NAME | grep -E '(errors:|FAULTED|DEGRADED|UNAVAIL)' | wc -l")
        if [ "$POOL_ERRORS" -eq 0 ]; then
            test_pass "No pool errors detected"
        else
            test_fail "Pool errors detected"
        fi
        
        # Check pool capacity
        POOL_CAPACITY=$(ssh "$TEST_USER@$TRUENAS_HOST" "sudo zpool list -H -o capacity $POOL_NAME | sed 's/%//'")
        if [ "$POOL_CAPACITY" -lt 80 ]; then
            test_pass "Pool capacity acceptable ($POOL_CAPACITY%)"
        else
            test_warn "Pool capacity high ($POOL_CAPACITY%)"
        fi
    else
        test_fail "Pool $POOL_NAME not found"
        return 1
    fi
}

# Dataset validation
test_datasets() {
    test_start "Dataset structure and properties"
    
    # Check required datasets exist
    REQUIRED_DATASETS=(
        "$POOL_NAME/home"
        "$POOL_NAME/home/john"
        "$POOL_NAME/home/susan"
        "$POOL_NAME/shared"
        "$POOL_NAME/shared/media"
        "$POOL_NAME/shared/documents"
        "$POOL_NAME/apps"
    )
    
    for dataset in "${REQUIRED_DATASETS[@]}"; do
        if ssh "$TEST_USER@$TRUENAS_HOST" "sudo zfs list $dataset" >/dev/null 2>&1; then
            test_pass "Dataset $dataset exists"
            
            # Check compression is enabled
            COMPRESSION=$(ssh "$TEST_USER@$TRUENAS_HOST" "sudo zfs get -H -o value compression $dataset")
            if [ "$COMPRESSION" != "off" ]; then
                test_pass "Dataset $dataset has compression enabled ($COMPRESSION)"
            else
                test_warn "Dataset $dataset has compression disabled"
            fi
        else
            test_fail "Dataset $dataset missing"
        fi
    done
}

# Share validation
test_shares() {
    test_start "SMB and NFS shares"
    
    # Test SMB service is running
    if ssh "$TEST_USER@$TRUENAS_HOST" "sudo systemctl is-active smbd" >/dev/null 2>&1; then
        test_pass "SMB service is running"
        
        # Test SMB configuration
        if ssh "$TEST_USER@$TRUENAS_HOST" "sudo testparm -s" >/dev/null 2>&1; then
            test_pass "SMB configuration is valid"
        else
            test_fail "SMB configuration has errors"
        fi
    else
        test_fail "SMB service is not running"
    fi
    
    # Test NFS service is running
    if ssh "$TEST_USER@$TRUENAS_HOST" "sudo systemctl is-active nfs-server" >/dev/null 2>&1; then
        test_pass "NFS service is running"
        
        # Test NFS exports
        if ssh "$TEST_USER@$TRUENAS_HOST" "sudo exportfs" | grep -q "/mnt/$POOL_NAME"; then
            test_pass "NFS exports configured"
        else
            test_fail "No NFS exports found"
        fi
    else
        test_fail "NFS service is not running"
    fi
}

# Network connectivity tests
test_network() {
    test_start "Network connectivity and services"
    
    # Test ping connectivity
    if ping -c 3 -W 5 "$TRUENAS_HOST" >/dev/null 2>&1; then
        test_pass "Host is reachable via ping"
    else
        test_fail "Host is not reachable via ping"
    fi
    
    # Test web UI accessibility
    if curl -k -s --connect-timeout 10 "https://$TRUENAS_HOST/" | grep -q "TrueNAS\|FreeNAS"; then
        test_pass "Web UI is accessible"
    else
        test_warn "Web UI may not be accessible (could be expected if not configured)"
    fi
    
    # Test SMB port
    if nc -z -v -w5 "$TRUENAS_HOST" 445 2>/dev/null; then
        test_pass "SMB port (445) is accessible"
    else
        test_fail "SMB port (445) is not accessible"
    fi
    
    # Test NFS port
    if nc -z -v -w5 "$TRUENAS_HOST" 2049 2>/dev/null; then
        test_pass "NFS port (2049) is accessible"
    else
        test_fail "NFS port (2049) is not accessible"
    fi
}

# Security validation
test_security() {
    test_start "Security configuration"
    
    # Check firewall status
    if ssh "$TEST_USER@$TRUENAS_HOST" "sudo ufw status" | grep -q "Status: active"; then
        test_pass "UFW firewall is active"
    else
        test_warn "UFW firewall is not active"
    fi
    
    # Check SSH configuration
    SSH_ROOT=$(ssh "$TEST_USER@$TRUENAS_HOST" "sudo grep '^PermitRootLogin' /etc/ssh/sshd_config | awk '{print \$2}'")
    if [ "$SSH_ROOT" = "no" ]; then
        test_pass "Root SSH login disabled"
    else
        test_warn "Root SSH login not disabled ($SSH_ROOT)"
    fi
    
    SSH_PASS=$(ssh "$TEST_USER@$TRUENAS_HOST" "sudo grep '^PasswordAuthentication' /etc/ssh/sshd_config | awk '{print \$2}'")
    if [ "$SSH_PASS" = "no" ]; then
        test_pass "SSH password authentication disabled"
    else
        test_warn "SSH password authentication not disabled ($SSH_PASS)"
    fi
}

# Monitoring validation
test_monitoring() {
    test_start "Monitoring and maintenance"
    
    # Check cron jobs are configured
    CRON_JOBS=$(ssh "$TEST_USER@$TRUENAS_HOST" "sudo crontab -l 2>/dev/null | wc -l")
    if [ "$CRON_JOBS" -gt 0 ]; then
        test_pass "Cron jobs configured ($CRON_JOBS jobs)"
    else
        test_warn "No cron jobs found"
    fi
    
    # Check SMART monitoring
    SMART_ENABLED=0
    for drive in sda sdb sdc sdd; do
        if ssh "$TEST_USER@$TRUENAS_HOST" "sudo smartctl -i /dev/$drive" >/dev/null 2>&1; then
            ((SMART_ENABLED++))
        fi
    done
    
    if [ "$SMART_ENABLED" -gt 0 ]; then
        test_pass "SMART monitoring available ($SMART_ENABLED drives)"
    else
        test_warn "SMART monitoring not available"
    fi
}

# User and permissions validation
test_users() {
    test_start "User accounts and permissions"
    
    # Check required users exist
    REQUIRED_USERS=("john" "susan" "alice" "bob")
    for user in "${REQUIRED_USERS[@]}"; do
        if ssh "$TEST_USER@$TRUENAS_HOST" "id $user" >/dev/null 2>&1; then
            test_pass "User $user exists"
            
            # Check home directory
            if ssh "$TEST_USER@$TRUENAS_HOST" "test -d /mnt/$POOL_NAME/home/$user"; then
                test_pass "Home directory for $user exists"
            else
                test_fail "Home directory for $user missing"
            fi
        else
            test_fail "User $user missing"
        fi
    done
    
    # Check required groups exist
    REQUIRED_GROUPS=("storage-admins" "family" "apps")
    for group in "${REQUIRED_GROUPS[@]}"; do
        if ssh "$TEST_USER@$TRUENAS_HOST" "getent group $group" >/dev/null 2>&1; then
            test_pass "Group $group exists"
        else
            test_fail "Group $group missing"
        fi
    done
}

# Performance test
test_performance() {
    test_start "Basic performance validation"
    
    # Test disk I/O performance (basic)
    echo "Testing disk write performance..."
    WRITE_SPEED=$(ssh "$TEST_USER@$TRUENAS_HOST" "sudo dd if=/dev/zero of=/mnt/$POOL_NAME/test_file bs=1M count=100 2>&1 | grep -o '[0-9.]\+ MB/s' | tail -1")
    
    if [ -n "$WRITE_SPEED" ]; then
        test_pass "Disk write performance: $WRITE_SPEED"
        # Clean up test file
        ssh "$TEST_USER@$TRUENAS_HOST" "sudo rm -f /mnt/$POOL_NAME/test_file"
    else
        test_warn "Could not measure disk performance"
    fi
    
    # Test network throughput to TrueNAS (basic)
    echo "Testing network connectivity speed..."
    PING_TIME=$(ping -c 5 "$TRUENAS_HOST" 2>/dev/null | tail -1 | awk -F '/' '{print $5}' | cut -d ' ' -f 1)
    if [ -n "$PING_TIME" ]; then
        if (( $(echo "$PING_TIME < 10.0" | bc -l) 2>/dev/null )); then
            test_pass "Network latency acceptable (${PING_TIME}ms)"
        else
            test_warn "Network latency high (${PING_TIME}ms)"
        fi
    fi
}

# Main execution
main() {
    echo -e "${BLUE}Starting validation tests...${NC}"
    echo
    
    # Run all tests
    test_ssh || { echo -e "${RED}Cannot continue without SSH access${NC}"; exit 1; }
    test_system_health
    test_zfs_pool
    test_datasets
    test_shares
    test_network
    test_security
    test_monitoring
    test_users
    test_performance
    
    echo
    echo -e "${BLUE}=== Validation Summary ===${NC}"
    echo "Total tests: $TESTS_TOTAL"
    echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
    echo "Log file: $LOG_FILE"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo
        echo -e "${GREEN}🎉 All tests passed! Your TrueNAS deployment is ready for production.${NC}"
        echo
        echo -e "${BLUE}Next steps:${NC}"
        echo "1. Configure backup destinations (cloud, external drives)"
        echo "2. Set up email alerts for monitoring"
        echo "3. Test backup and restore procedures"
        echo "4. Install and configure applications (Nextcloud, Plex, etc.)"
        echo "5. Set up VPN for remote access"
        echo "6. Configure user training and documentation"
        
        return 0
    else
        echo
        echo -e "${RED}❌ Some tests failed. Please review and fix issues before production use.${NC}"
        echo
        echo -e "${BLUE}Common fixes:${NC}"
        echo "- Ensure all services are started: sudo systemctl start smbd nmbd nfs-server"
        echo "- Check firewall rules: sudo ufw status"
        echo "- Verify disk names in pool configuration"
        echo "- Check network connectivity and DNS resolution"
        
        return 1
    fi
}

# Check dependencies
check_dependencies() {
    local missing_deps=()
    
    for cmd in ssh ping curl nc bc; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo -e "${RED}Missing required dependencies: ${missing_deps[*]}${NC}"
        echo "Please install missing commands and try again."
        exit 1
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--host)
            TRUENAS_HOST="$2"
            shift 2
            ;;
        -u|--user)
            TEST_USER="$2"
            shift 2
            ;;
        -p|--pool)
            POOL_NAME="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -h, --host HOST    TrueNAS hostname or IP (default: 192.168.1.100)"
            echo "  -u, --user USER    SSH user for testing (default: john)"
            echo "  -p, --pool POOL    Pool name to test (default: tank)"
            echo "  --help             Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Run the validation
check_dependencies
main
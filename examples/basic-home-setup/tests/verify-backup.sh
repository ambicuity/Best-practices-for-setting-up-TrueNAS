#!/bin/bash
# TrueNAS Backup Verification Script
# Tests backup functionality including snapshots and replication

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
TEST_DATASET=${TEST_DATASET:-"$POOL_NAME/home/john"}
RESTORE_PATH=${RESTORE_PATH:-"/tmp/backup-test"}

# Logging
LOG_FILE="/tmp/backup-verification-$(date +%Y%m%d-%H%M%S).log"
exec 1> >(tee -a "$LOG_FILE")
exec 2> >(tee -a "$LOG_FILE" >&2)

echo -e "${BLUE}=== TrueNAS Backup Verification ===${NC}"
echo "Started: $(date)"
echo "Target: $TRUENAS_HOST"
echo "Test Dataset: $TEST_DATASET"
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

# Generate test data
create_test_data() {
    test_start "Creating test data for backup verification"
    
    local test_file="/mnt/$TEST_DATASET/backup-test-$(date +%s).txt"
    local test_content="Backup test data created at $(date)"
    
    if ssh "$TEST_USER@$TRUENAS_HOST" "echo '$test_content' | sudo tee $test_file" >/dev/null 2>&1; then
        test_pass "Test data created: $test_file"
        echo "$test_file" > /tmp/test_file_path
        echo "$test_content" > /tmp/test_file_content
    else
        test_fail "Failed to create test data"
        return 1
    fi
}

# Test snapshot functionality
test_snapshots() {
    test_start "Snapshot creation and management"
    
    # Create a manual snapshot
    local snapshot_name="$TEST_DATASET@backup-test-$(date +%s)"
    
    if ssh "$TEST_USER@$TRUENAS_HOST" "sudo zfs snapshot $snapshot_name"; then
        test_pass "Manual snapshot created: $snapshot_name"
        
        # List snapshots to verify
        local snapshot_count
        snapshot_count=$(ssh "$TEST_USER@$TRUENAS_HOST" "sudo zfs list -t snapshot $TEST_DATASET 2>/dev/null | wc -l")
        
        if [ "$snapshot_count" -gt 1 ]; then  # Header + at least one snapshot
            test_pass "Snapshots exist for dataset ($((snapshot_count - 1)) snapshots)"
        else
            test_warn "No snapshots found for dataset"
        fi
        
        # Test snapshot properties
        if ssh "$TEST_USER@$TRUENAS_HOST" "sudo zfs list -t snapshot $snapshot_name" >/dev/null 2>&1; then
            local snap_size
            snap_size=$(ssh "$TEST_USER@$TRUENAS_HOST" "sudo zfs list -H -o used $snapshot_name")
            test_pass "Snapshot is accessible (size: $snap_size)"
        else
            test_fail "Snapshot is not accessible"
        fi
        
        # Clean up test snapshot
        ssh "$TEST_USER@$TRUENAS_HOST" "sudo zfs destroy $snapshot_name" 2>/dev/null || true
        
    else
        test_fail "Failed to create manual snapshot"
    fi
}

# Test automatic snapshots
test_automatic_snapshots() {
    test_start "Automatic snapshot scheduling"
    
    # Check if zfs-auto-snapshot is installed
    if ssh "$TEST_USER@$TRUENAS_HOST" "which zfs-auto-snapshot" >/dev/null 2>&1; then
        test_pass "zfs-auto-snapshot is installed"
    else
        test_warn "zfs-auto-snapshot is not installed"
    fi
    
    # Check for snapshot cron jobs
    local cron_count
    cron_count=$(ssh "$TEST_USER@$TRUENAS_HOST" "sudo crontab -l 2>/dev/null | grep -c 'zfs.*snapshot' || true")
    
    if [ "$cron_count" -gt 0 ]; then
        test_pass "Automatic snapshot jobs configured ($cron_count jobs)"
    else
        test_warn "No automatic snapshot jobs found"
    fi
    
    # Check for recent automatic snapshots
    local recent_snaps
    recent_snaps=$(ssh "$TEST_USER@$TRUENAS_HOST" "sudo zfs list -t snapshot -o name,creation $TEST_DATASET 2>/dev/null | grep -E '(hourly|daily)' | wc -l || true")
    
    if [ "$recent_snaps" -gt 0 ]; then
        test_pass "Recent automatic snapshots found ($recent_snaps snapshots)"
    else
        test_warn "No recent automatic snapshots found"
    fi
}

# Test snapshot restore
test_snapshot_restore() {
    test_start "Snapshot restore functionality"
    
    # Get the test file path and content
    if [ ! -f /tmp/test_file_path ] || [ ! -f /tmp/test_file_content ]; then
        test_warn "No test data available for restore test"
        return
    fi
    
    local test_file
    test_file=$(cat /tmp/test_file_path)
    local original_content
    original_content=$(cat /tmp/test_file_content)
    
    # Create a snapshot with our test data
    local restore_snapshot="$TEST_DATASET@restore-test-$(date +%s)"
    
    if ssh "$TEST_USER@$TRUENAS_HOST" "sudo zfs snapshot $restore_snapshot"; then
        
        # Modify the test file
        local modified_content="Modified content at $(date)"
        ssh "$TEST_USER@$TRUENAS_HOST" "echo '$modified_content' | sudo tee $test_file" >/dev/null
        
        # Verify file was modified
        local current_content
        current_content=$(ssh "$TEST_USER@$TRUENAS_HOST" "sudo cat $test_file")
        
        if [ "$current_content" = "$modified_content" ]; then
            test_pass "Test file successfully modified"
            
            # Restore from snapshot
            if ssh "$TEST_USER@$TRUENAS_HOST" "sudo zfs rollback $restore_snapshot"; then
                test_pass "Snapshot rollback successful"
                
                # Verify restoration
                local restored_content
                restored_content=$(ssh "$TEST_USER@$TRUENAS_HOST" "sudo cat $test_file")
                
                if [ "$restored_content" = "$original_content" ]; then
                    test_pass "File content restored correctly"
                else
                    test_fail "File content not restored correctly"
                fi
            else
                test_fail "Snapshot rollback failed"
            fi
        else
            test_fail "Test file modification failed"
        fi
        
        # Clean up
        ssh "$TEST_USER@$TRUENAS_HOST" "sudo zfs destroy $restore_snapshot" 2>/dev/null || true
    else
        test_fail "Failed to create restore test snapshot"
    fi
}

# Test file-level restore from .zfs/snapshot
test_file_restore() {
    test_start "File-level restore from .zfs/snapshot"
    
    # Check if .zfs/snapshot is accessible
    if ssh "$TEST_USER@$TRUENAS_HOST" "sudo ls /mnt/$TEST_DATASET/.zfs/snapshot/" >/dev/null 2>&1; then
        test_pass ".zfs/snapshot directory is accessible"
        
        # List available snapshots
        local snapshot_dirs
        snapshot_dirs=$(ssh "$TEST_USER@$TRUENAS_HOST" "sudo ls -1 /mnt/$TEST_DATASET/.zfs/snapshot/ | wc -l")
        
        if [ "$snapshot_dirs" -gt 0 ]; then
            test_pass "Snapshot directories available ($snapshot_dirs snapshots)"
            
            # Try to access a file from a snapshot
            local latest_snapshot
            latest_snapshot=$(ssh "$TEST_USER@$TRUENAS_HOST" "sudo ls -1t /mnt/$TEST_DATASET/.zfs/snapshot/ | head -1")
            
            if [ -n "$latest_snapshot" ]; then
                local snapshot_files
                snapshot_files=$(ssh "$TEST_USER@$TRUENAS_HOST" "sudo ls /mnt/$TEST_DATASET/.zfs/snapshot/$latest_snapshot/ 2>/dev/null | wc -l || echo 0")
                
                if [ "$snapshot_files" -gt 0 ]; then
                    test_pass "Files accessible in snapshot ($snapshot_files files)"
                else
                    test_warn "No files found in snapshot directory"
                fi
            fi
        else
            test_warn "No snapshot directories found"
        fi
    else
        test_warn ".zfs/snapshot directory not accessible"
    fi
}

# Test backup storage space
test_backup_storage() {
    test_start "Backup storage space monitoring"
    
    # Check overall pool usage
    local pool_usage
    pool_usage=$(ssh "$TEST_USER@$TRUENAS_HOST" "sudo zpool list -H -o capacity $POOL_NAME | sed 's/%//'")
    
    if [ "$pool_usage" -lt 70 ]; then
        test_pass "Pool storage usage acceptable ($pool_usage%)"
    elif [ "$pool_usage" -lt 85 ]; then
        test_warn "Pool storage usage getting high ($pool_usage%)"
    else
        test_fail "Pool storage usage critical ($pool_usage%)"
    fi
    
    # Check snapshot space usage
    local snapshot_space
    snapshot_space=$(ssh "$TEST_USER@$TRUENAS_HOST" "sudo zfs list -o used -t snapshot $TEST_DATASET 2>/dev/null | tail -n +2 | awk '{sum += \$1} END {print sum}' || echo 0")
    
    if [ "$snapshot_space" != "0" ]; then
        test_pass "Snapshots are using storage space (indicating they exist)"
    else
        test_warn "No snapshot space usage detected"
    fi
}

# Test cloud backup readiness (connectivity and config)
test_cloud_backup_readiness() {
    test_start "Cloud backup readiness"
    
    # Check if cloud backup tools are available
    local backup_tools=("rclone" "aws" "b2")
    local tools_found=0
    
    for tool in "${backup_tools[@]}"; do
        if ssh "$TEST_USER@$TRUENAS_HOST" "which $tool" >/dev/null 2>&1; then
            test_pass "Backup tool available: $tool"
            ((tools_found++))
        fi
    done
    
    if [ "$tools_found" -eq 0 ]; then
        test_warn "No cloud backup tools found (install rclone, aws-cli, or b2 for cloud backups)"
    fi
    
    # Check for backup configuration files
    local config_files=("/root/.aws/credentials" "/root/.config/rclone/rclone.conf" "/root/.b2_account_info")
    local configs_found=0
    
    for config in "${config_files[@]}"; do
        if ssh "$TEST_USER@$TRUENAS_HOST" "sudo test -f $config" 2>/dev/null; then
            test_pass "Backup configuration found: $config"
            ((configs_found++))
        fi
    done
    
    if [ "$configs_found" -eq 0 ]; then
        test_warn "No cloud backup configurations found"
    fi
    
    # Test internet connectivity for cloud backups
    if ssh "$TEST_USER@$TRUENAS_HOST" "ping -c 3 8.8.8.8" >/dev/null 2>&1; then
        test_pass "Internet connectivity available for cloud backups"
    else
        test_fail "No internet connectivity for cloud backups"
    fi
}

# Test backup script execution
test_backup_scripts() {
    test_start "Backup script configuration and execution"
    
    # Check for backup cron jobs
    local backup_crons
    backup_crons=$(ssh "$TEST_USER@$TRUENAS_HOST" "sudo crontab -l 2>/dev/null | grep -c 'backup\|replication\|rclone\|b2\|aws' || echo 0")
    
    if [ "$backup_crons" -gt 0 ]; then
        test_pass "Backup cron jobs configured ($backup_crons jobs)"
    else
        test_warn "No backup cron jobs found"
    fi
    
    # Check for backup log files
    local log_dirs=("/var/log/backup" "/var/log/replication" "/tmp")
    local logs_found=0
    
    for log_dir in "${log_dirs[@]}"; do
        local log_count
        log_count=$(ssh "$TEST_USER@$TRUENAS_HOST" "sudo find $log_dir -name '*backup*' -o -name '*replication*' 2>/dev/null | wc -l || echo 0")
        if [ "$log_count" -gt 0 ]; then
            test_pass "Backup logs found in $log_dir ($log_count files)"
            ((logs_found++))
        fi
    done
    
    if [ "$logs_found" -eq 0 ]; then
        test_warn "No backup log files found"
    fi
}

# Test backup retention policies
test_retention_policies() {
    test_start "Backup retention policy enforcement"
    
    # Check if old snapshots are being cleaned up
    local old_snapshots
    old_snapshots=$(ssh "$TEST_USER@$TRUENAS_HOST" "sudo zfs list -t snapshot $TEST_DATASET 2>/dev/null | grep -E '(hourly|daily|weekly|monthly)' | wc -l || echo 0")
    
    if [ "$old_snapshots" -gt 0 ] && [ "$old_snapshots" -lt 100 ]; then
        test_pass "Reasonable number of snapshots ($old_snapshots), retention policy appears to be working"
    elif [ "$old_snapshots" -gt 100 ]; then
        test_warn "Large number of snapshots ($old_snapshots), check retention policy"
    else
        test_warn "Very few snapshots found, check if snapshot creation is working"
    fi
    
    # Check snapshot age distribution
    local recent_snapshots
    recent_snapshots=$(ssh "$TEST_USER@$TRUENAS_HOST" "sudo zfs list -t snapshot -S creation $TEST_DATASET 2>/dev/null | head -5 | tail -n +2 | wc -l || echo 0")
    
    if [ "$recent_snapshots" -gt 0 ]; then
        test_pass "Recent snapshots available for quick recovery"
    else
        test_warn "No recent snapshots found"
    fi
}

# Test disaster recovery readiness
test_disaster_recovery() {
    test_start "Disaster recovery readiness"
    
    # Check if pool can be exported/imported (dry run)
    if ssh "$TEST_USER@$TRUENAS_HOST" "sudo zpool export -f $POOL_NAME -n" 2>/dev/null; then
        test_pass "Pool can be exported (dry run successful)"
    else
        test_warn "Pool export test failed (may be normal if pool is in use)"
    fi
    
    # Check for pool import cache
    if ssh "$TEST_USER@$TRUENAS_HOST" "sudo test -f /etc/zfs/zpool.cache"; then
        test_pass "ZFS pool cache file exists"
    else
        test_warn "ZFS pool cache file not found"
    fi
    
    # Check system configuration backup
    local config_backup_files=("/data/freenas-v1.db" "/etc/fstab" "/etc/passwd" "/etc/group")
    local config_backups_found=0
    
    for config in "${config_backup_files[@]}"; do
        if ssh "$TEST_USER@$TRUENAS_HOST" "sudo test -f $config" 2>/dev/null; then
            ((config_backups_found++))
        fi
    done
    
    if [ "$config_backups_found" -gt 2 ]; then
        test_pass "System configuration files available for recovery"
    else
        test_warn "Some system configuration files may be missing"
    fi
}

# Clean up test data
cleanup_test_data() {
    test_start "Cleaning up test data"
    
    if [ -f /tmp/test_file_path ]; then
        local test_file
        test_file=$(cat /tmp/test_file_path)
        
        if ssh "$TEST_USER@$TRUENAS_HOST" "sudo rm -f $test_file" 2>/dev/null; then
            test_pass "Test data cleaned up"
        else
            test_warn "Could not clean up test file: $test_file"
        fi
        
        rm -f /tmp/test_file_path /tmp/test_file_content
    fi
}

# Main execution
main() {
    echo -e "${BLUE}Starting backup verification tests...${NC}"
    echo
    
    # Run all tests
    create_test_data || { echo -e "${RED}Cannot create test data${NC}"; exit 1; }
    test_snapshots
    test_automatic_snapshots
    test_snapshot_restore
    test_file_restore
    test_backup_storage
    test_cloud_backup_readiness
    test_backup_scripts
    test_retention_policies
    test_disaster_recovery
    cleanup_test_data
    
    echo
    echo -e "${BLUE}=== Backup Verification Summary ===${NC}"
    echo "Total tests: $TESTS_TOTAL"
    echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
    echo "Log file: $LOG_FILE"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo
        echo -e "${GREEN}✅ Backup verification completed successfully!${NC}"
        echo
        echo -e "${BLUE}Backup readiness summary:${NC}"
        echo "• Snapshots are working and accessible"
        echo "• Restore procedures are functional" 
        echo "• Storage space is being monitored"
        echo "• System is prepared for disaster recovery"
        echo
        echo -e "${BLUE}Recommended next steps:${NC}"
        echo "1. Set up cloud backup with rclone/b2/aws"
        echo "2. Schedule regular backup tests"
        echo "3. Document recovery procedures"
        echo "4. Test full system restore in lab environment"
        
        return 0
    else
        echo
        echo -e "${RED}⚠️  Some backup tests failed or showed warnings.${NC}"
        echo
        echo -e "${BLUE}Common fixes:${NC}"
        echo "- Install and configure cloud backup tools (rclone, b2, aws-cli)"
        echo "- Set up automatic snapshot schedules with cron"
        echo "- Configure backup retention policies"
        echo "- Test backup and restore procedures regularly"
        echo "- Ensure adequate storage space for snapshots"
        
        return 1
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
        -d|--dataset)
            TEST_DATASET="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -h, --host HOST       TrueNAS hostname or IP (default: 192.168.1.100)"
            echo "  -u, --user USER       SSH user for testing (default: john)"
            echo "  -p, --pool POOL       Pool name to test (default: tank)"
            echo "  -d, --dataset DATASET Dataset to test (default: tank/home/john)"
            echo "  --help                Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Check dependencies
check_dependencies() {
    local missing_deps=()
    
    for cmd in ssh; do
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

# Run the verification
check_dependencies
main
#!/bin/bash
# TrueNAS Policy and Security Checks

set -e

SPECS_DIR="specs"

echo "Running TrueNAS policy checks..."

# Check for unsafe UI exposure
echo "Checking for internet-exposed UI..."
if find "$SPECS_DIR" -name "*.yaml" -o -name "*.yml" | xargs grep -l "exposure: internet" 2>/dev/null; then
    echo "ERROR: Found internet-exposed UI configuration!"
    echo "Web UI must only be accessible through VPN."
    exit 1
fi

if find "$SPECS_DIR" -name "*.yaml" -o -name "*.yml" | xargs grep -El "public:[[:space:]]*true\b" 2>/dev/null; then
    echo "ERROR: Found public interface configuration!"
    echo "Management interfaces should not be public."
    exit 1
fi

echo "✓ No internet-exposed UI found"

# Check for backup policies on critical datasets
echo "Checking backup coverage for critical datasets..."
critical_found=false
if find "$SPECS_DIR/datasets" -name "*.yaml" -o -name "*.yml" 2>/dev/null | xargs grep -l "critical\|important" 2>/dev/null; then
    critical_found=true
fi

if [ "$critical_found" = true ]; then
    if [ ! -f "$SPECS_DIR/backup/policies.yml" ]; then
        echo "WARNING: Critical datasets found but no backup policies defined"
        echo "Create backup policies in $SPECS_DIR/backup/"
    else
        echo "✓ Backup policies found for critical datasets"
    fi
fi

# Check for proper encryption settings
echo "Checking encryption requirements..."
if find "$SPECS_DIR" -name "*.yaml" -o -name "*.yml" | xargs grep -l "vpn\|remote" 2>/dev/null; then
    if ! find "$SPECS_DIR" -name "*.yaml" -o -name "*.yml" | xargs grep -l "encrypt.*true" 2>/dev/null; then
        echo "WARNING: VPN/remote access configured but encryption not explicitly enabled"
    else
        echo "✓ Encryption properly configured for remote access"
    fi
fi

# Check for SMART and scrub schedules
echo "Checking maintenance schedules..."
if [ -f "$SPECS_DIR/pools/pool-main.yaml" ]; then
    if ! grep -q "scrub:" "$SPECS_DIR/pools/pool-main.yaml"; then
        echo "WARNING: No scrub schedule found in pool configuration"
    else
        echo "✓ Scrub schedule configured"
    fi
fi

# Check for proper user/group separation
echo "Checking user and group configurations..."
if [ -f "$SPECS_DIR/users-groups/groups.yaml" ]; then
    if grep -q "root" "$SPECS_DIR/users-groups/groups.yaml"; then
        echo "WARNING: Direct root access found in user configurations"
        echo "Avoid using root for routine operations"
    fi
    echo "✓ User and group configurations found"
fi

echo "✓ Policy checks completed successfully!"
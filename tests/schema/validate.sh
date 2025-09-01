#!/bin/bash
# TrueNAS Specification Schema Validation

set -e

SPECS_DIR="specs"
SCHEMA_DIR="tests/schema"

echo "Validating TrueNAS specifications..."

# Check if specs directory exists
if [ ! -d "$SPECS_DIR" ]; then
    echo "Specs directory not found: $SPECS_DIR"
    exit 1
fi

# Basic YAML syntax validation
echo "Checking YAML syntax..."
find "$SPECS_DIR" -name "*.yaml" -o -name "*.yml" | while read -r file; do
    echo "  Validating: $file"
    python3 -c "import yaml; yaml.safe_load(open('$file'))"
done

# Validate pool specifications
echo "Validating pool specifications..."
find "$SPECS_DIR/pools" -name "*.yaml" 2>/dev/null | while read -r file; do
    echo "  Checking pool config: $file"
    python3 -c "
import yaml
config = yaml.safe_load(open('$file'))
assert 'pool' in config, 'Pool name required'
assert 'vdevs' in config, 'VDEVs configuration required'
assert 'scrub' in config, 'Scrub schedule required'
print('  ✓ Pool configuration valid')
" || { echo "  ✗ Invalid pool configuration in $file"; exit 1; }
done

# Validate dataset specifications
echo "Validating dataset specifications..."
find "$SPECS_DIR/datasets" -name "*.yaml" 2>/dev/null | while read -r file; do
    echo "  Checking dataset config: $file"
    python3 -c "
import yaml
config = yaml.safe_load(open('$file'))
assert 'dataset' in config, 'Dataset name required'
assert 'properties' in config, 'Dataset properties required'
print('  ✓ Dataset configuration valid')
" || { echo "  ✗ Invalid dataset configuration in $file"; exit 1; }
done

# Validate backup policies
echo "Validating backup policies..."
find "$SPECS_DIR/backup" -name "*.yml" -o -name "*.yaml" 2>/dev/null | while read -r file; do
    echo "  Checking backup config: $file"
    python3 -c "
import yaml
config = yaml.safe_load(open('$file'))
assert 'snapshots' in config, 'Snapshot policies required'
assert 'replication' in config or 'offsite-backup' in config, 'Offsite backup required'
print('  ✓ Backup policy valid')
" || { echo "  ✗ Invalid backup policy in $file"; exit 1; }
done

echo "✓ All specifications validated successfully!"
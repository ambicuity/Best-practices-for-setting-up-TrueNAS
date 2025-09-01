#!/usr/bin/env python3
import sys
import yaml

if len(sys.argv) < 3 or '--policies' not in sys.argv:
    print("Usage: python backup_check.py --policies <backup_policies_file>")
    sys.exit(1)

policies_file = sys.argv[sys.argv.index('--policies') + 1]

try:
    with open(policies_file, 'r') as f:
        pol = yaml.safe_load(f)
    
    # Check for required backup components
    assert pol.get('snapshots'), 'Missing snapshot policy'
    assert len(pol.get('snapshots', [])) > 0, 'No snapshot schedules defined'
    
    # Check for off-site backup/replication
    replication = pol.get('replication', [])
    offsite_backup = pol.get('offsite-backup', [])
    
    if not replication and not offsite_backup:
        print("WARNING: No off-site backup or replication configured")
    
    print('✓ Backup policy validation passed')
    sys.exit(0)
    
except FileNotFoundError:
    print(f"ERROR: Backup policy file not found: {policies_file}")
    sys.exit(1)
except Exception as e:
    print(f"ERROR: Backup policy validation failed: {e}")
    sys.exit(1)
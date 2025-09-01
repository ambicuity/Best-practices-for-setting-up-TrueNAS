#!/usr/bin/env python3
import sys, yaml, pathlib

if '--root' not in sys.argv:
    print("Usage: python validate.py --root <specs_directory>")
    sys.exit(1)

root = pathlib.Path(sys.argv[sys.argv.index('--root') + 1])
errors = 0

print(f"Validating YAML files in {root}...")

for p in root.rglob('*.y*ml'):
    try:
        data = yaml.safe_load(p.read_text())
        print(f"✓ {p}")
    except Exception as e:
        errors += 1
        print(f"✗ Schema error in {p}: {e}")

if errors:
    print(f"\n{errors} files failed validation")
    sys.exit(errors)
else:
    print(f"\n✓ All YAML files are valid")
    sys.exit(0)
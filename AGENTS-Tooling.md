# AGENTS-Tooling.md — Multi‑Agent System wired to Makefiles, GitHub Actions, and Ansible Roles

This companion to **AGENTS.md** focuses on concrete tooling so agents can produce deterministic, reproducible outcomes. Drop this in your repo root.

---

## 1) Makefile (single‑entry automation)

Create a top‑level `Makefile` with durable, idempotent targets. Agents call only these targets; humans do the same.

```make
SHELL := /bin/bash
.DEFAULT_GOAL := help

# —— Versions ——
PY ?= python3
ANSIBLE ?= ansible-playbook
MOLECULE ?= molecule

# —— Paths ——
SPECS := specs
ANS := ansible
TESTS := tests
DOCS := docs

.PHONY: help
help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}'

# —— Bootstrap ——
.PHONY: bootstrap
bootstrap: ## Install dev tooling locally
	$(PY) -m pip install --upgrade pip
	pip install -r requirements-dev.txt

.PHONY: env
env: ## Print versions
	@echo "Python: $$($(PY) -V)" && ansible --version

# —— Lint & Validate ——
.PHONY: lint
lint: ## Lint YAML, Ansible, Markdown
	yamllint .
	ansible-lint $(ANS)
	markdownlint "$(DOCS)/**/*.md" || true

.PHONY: schema
schema: ## Validate specs with JSON/YAML schema
	$(PY) $(TESTS)/schema/validate.py --root $(SPECS)

.PHONY: check
check: lint schema ## Lint + schema checks

# —— Tests ——
.PHONY: unit
unit: ## Run unit tests (if any)
	pytest -q

.PHONY: molecule
molecule: ## Run Molecule scenarios for roles
	$(MOLECULE) test

.PHONY: test
test: check unit molecule ## Full local test suite

# —— Dry‑runs & Provisioning ——
.PHONY: dryrun
dryrun: ## Ansible syntax & dry run
	$(ANSIBLE) --syntax-check $(ANS)/provision.yml
	$(ANSIBLE) $(ANS)/provision.yml -i $(ANS)/inventory --check

.PHONY: provision
provision: ## Apply provisioning to inventory (CAUTION)
	$(ANSIBLE) $(ANS)/provision.yml -i $(ANS)/inventory

.PHONY: backup-plan
backup-plan: ## Validate backup policies
	$(PY) $(TESTS)/policy/backup_check.py --policies $(SPECS)/backup/policies.yaml

.PHONY: docs
docs: ## Build/publish docs (optional)
	docusaurus build || true

.PHONY: all
all: test dryrun ## Everything except live provisioning
```

**Conventions**

* Always run `make check` before opening a PR; CI runs `make all`.
* Keep all validations inside `tests/` and referenced by `make` targets.

---

## 2) GitHub Actions (CI/CD blueprints)

Place workflows in `.github/workflows/`.

### 2.1 `ci.yml` — Lint, schema, unit, Molecule, dry‑run

```yaml
name: CI
on:
  pull_request:
    branches: [ main ]
    paths:
      - 'specs/**'
      - 'ansible/**'
      - 'tests/**'
      - 'docs/**'
      - 'Makefile'
  push:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: Cache pip
        uses: actions/cache@v4
        with:
          path: ~/.cache/pip
          key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements*.txt') }}

      - name: Install deps
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements-dev.txt

      - name: Make check
        run: make check

      - name: Unit tests
        run: make unit

      - name: Molecule
        run: make molecule

      - name: Dry run
        run: make dryrun

      - name: Backup policy guard
        run: make backup-plan
```

### 2.2 `release.yml` — Tag + changelog + docs

```yaml
name: Release
on:
  workflow_dispatch:
    inputs:
      version:
        description: 'SemVer (e.g., 1.2.0)'
        required: true

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      - name: Install deps
        run: |
          pip install -r requirements-dev.txt
          pip install git-changelog
      - name: Generate changelog
        run: git-changelog -o CHANGELOG.md
      - name: Commit & tag
        run: |
          git config user.name "release-bot"
          git config user.email "release-bot@users.noreply.github.com"
          git add CHANGELOG.md
          git commit -m "chore(release): update changelog"
          git tag v${{ inputs.version }}
          git push --follow-tags
      - name: Build docs (optional)
        run: make docs
```

### 2.3 Required status checks

* `Make check`
* `Unit tests`
* `Molecule`
* `Dry run`
* `Backup policy guard`

---

## 3) Ansible Roles (production layout)

Repo tree (simplified):

```
ansible/
  inventory               # inventory or dynamic inventory plugin
  provision.yml           # entry playbook
  roles/
    truenas_storage/
      defaults/main.yml
      vars/main.yml
      tasks/main.yml
      handlers/main.yml
      templates/
      files/
      meta/main.yml
      molecule/
        default/molecule.yml
        default/verify.yml
    truenas_network/
      ...
    truenas_backup/
      ...
    truenas_monitoring/
      ...
```

### 3.1 Example: `truenas_storage` role

**defaults/main.yml**

```yaml
pool_name: tank
ashift: 12
vdevs: []           # list of { type: raidz2|mirror, disks: [da0,da1,...] }
spares: []
datasets: []        # list of { name: tank/apps, properties: {compression: zstd, atime: off} }
scrub_schedule: monthly
```

**tasks/main.yml**

```yaml
- name: Create pool
  community.general.zpool:
    name: "{{ pool_name }}"
    state: present
  when: vdevs | length > 0

- name: Configure vdevs (sketch)
  debug:
    msg: "Would configure vdevs: {{ vdevs }}"

- name: Create datasets
  community.general.zfs:
    name: "{{ item.name }}"
    state: present
    extra_zfs_properties: "{{ item.properties | default({}) }}"
  loop: "{{ datasets }}"

- name: Schedule scrub (via cron)
  cron:
    name: "zfs scrub {{ pool_name }}"
    special_time: monthly
    job: "/sbin/zpool scrub {{ pool_name }}"
  when: scrub_schedule == 'monthly'
```

**molecule/default/molecule.yml**

```yaml
platforms:
  - name: instance
    image: geerlingguy/docker-ubuntu2204-ansible:latest
provisioner:
  name: ansible
  playbooks:
    converge: converge.yml
verifier:
  name: ansible
```

**molecule/default/converge.yml**

```yaml
- hosts: all
  roles:
    - role: truenas_storage
      vars:
        pool_name: tank
        datasets:
          - { name: tank/apps, properties: { compression: zstd, atime: off } }
```

**molecule/default/verify.yml**

```yaml
- hosts: all
  gather_facts: no
  tasks:
    - name: Verify dataset placeholder
      debug:
        msg: "Datasets configured"
```

### 3.2 `truenas_network` role (sketch)

**defaults/main.yml**

```yaml
vlans: []     # [{id: 10, name: storage}]
ui:
  exposure: vpn-only
  https: true
  hsts: true
vpn:
  type: wireguard
  peers: []
```

**tasks/main.yml**

```yaml
- name: Assert UI not Internet-exposed
  assert:
    that:
      - ui.exposure == 'vpn-only'
    fail_msg: "Web UI must never be Internet-facing"

- name: Configure WireGuard (placeholder)
  debug:
    msg: "WireGuard peers: {{ vpn.peers }}"
```

### 3.3 `truenas_backup` role (policies)

**defaults/main.yml**

```yaml
snapshots:
  - { dataset: tank/apps, schedule: hourly, keep: 48 }
  - { dataset: tank/apps, schedule: daily,  keep: 30 }
  - { dataset: tank,      schedule: weekly, keep: 8 }
replication:
  - { from: tank/apps, to: b2://my-bucket/apps, schedule: daily, encrypt: true }
```

**tasks/main.yml**

```yaml
- name: Validate 3-2-1 presence for critical datasets
  assert:
    that: snapshots | length > 0
    fail_msg: "Snapshot policy required"

- name: Configure replication (placeholder)
  debug:
    msg: "Replicate: {{ item.from }} -> {{ item.to }}"
  loop: "{{ replication }}"
```

### 3.4 `truenas_monitoring` role (health)

**defaults/main.yml**

```yaml
smart:
  short: daily
  long: weekly
alerts:
  route: email   # or slack/webhook
```

**tasks/main.yml**

```yaml
- name: Schedule SMART tests (placeholder)
  debug:
    msg: "SMART: short={{ smart.short }}, long={{ smart.long }}"

- name: Configure alert route (placeholder)
  debug:
    msg: "Alert route: {{ alerts.route }}"
```

---

## 4) Tests & Policy Guards

### 4.1 Schema validation script `tests/schema/validate.py`

```python
#!/usr/bin/env python3
import sys, yaml, pathlib
root = pathlib.Path(sys.argv[sys.argv.index('--root')+1])
errors = 0
for p in root.rglob('*.y*ml'):
    try:
        yaml.safe_load(p.read_text())
    except Exception as e:
        errors += 1
        print(f"Schema error in {p}: {e}")
sys.exit(errors)
```

### 4.2 Backup guard `tests/policy/backup_check.py`

```python
#!/usr/bin/env python3
import sys, yaml
pol = yaml.safe_load(open(sys.argv[-1]))
assert pol.get('snapshots'), 'Missing snapshot policy'
print('Backup policy OK')
```

---

## 5) Agent→Tooling Contract

* **Agents never call raw commands**; they invoke `make` targets only.
* **Storage/Network/Backup agents** modify only role defaults/vars and specs; QA adjusts tests.
* **QA/Compliance agent** may add Molecule scenarios but cannot relax failing asserts.
* **Release/Docs agent** triggers `release.yml` and updates CHANGELOG/Docs.

---

## 6) Prompts (tooling flavored)

**QA & Compliance (CI enforcer)**

> Run `make all`. Fail PR if any job fails. Enforce Internet‑exposed UI prohibition via `truenas_network` assert.

**Storage Engineer**

> Edit `roles/truenas_storage/defaults/main.yml` and specs. Keep uniform vdevs. Provide PR with rationale.

**Backup & DR**

> Ensure `tests/policy/backup_check.py` passes for any dataset with `critical: true` (if used). Add replication entries.

**Release/Docs**

> On approval, run the release workflow with a semantic version and update operator docs.

---

## 7) Minimum dependency set

Add to `requirements-dev.txt`:

```
ansible>=9
ansible-lint
molecule
molecule-plugins[docker]
yamllint
pytest
markdownlint-cli
PyYAML
```

---

## 8) Quickstart

1. `make bootstrap && make env`
2. Edit role defaults to match your hardware/policies.
3. `make check && make molecule && make dryrun`
4. Open a PR; CI will run the same steps.
5. Merge and (optionally) run `make provision` to apply.

---

**Result:** a consistent, tool‑driven repo where agents and humans share the same golden path for building, testing, and deploying TrueNAS infrastructure.

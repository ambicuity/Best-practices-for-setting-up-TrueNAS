# AGENTS.md — Multi‑Agent System for a Production‑Grade TrueNAS Repository

> This document defines a team of specialized AI agents—modeled after veteran TrueNAS engineers (\~20+ years of experience)—and the operating model that lets them collaborate to design, deploy, validate, and maintain TrueNAS systems from **basic** setups to **advanced**, automated, and security‑hardened deployments.

---

## 0) Design Principles (Golden Rules)

* **Prefer TrueNAS SCALE** for new builds (actively developed, apps ecosystem).
* **Boot on dedicated SSDs** (mirrored when possible), **≥ 60 GB** recommended.
* **RAM before cache**: start with **16 GB** if you'll run apps; size ARC appropriately before adding L2ARC.
* **Pool layout matters**: choose **RAIDZ1/2** or **mirrors** based on capacity vs. resiliency vs. IOPS; use uniform vdevs.
* **Datasets for boundaries**: split by data type, performance, and permission domains.
* **Do not expose the Web UI to the Internet**; **require VPN** for remote admin access.
* **Backup using 3‑2‑1**; **snapshots** + **replication** (off‑site/cloud) for critical data.
* **Automate SMART tests & scrubs**; alert on failures; never run as `root` for routine access.
* **Everything as Code**: specs, policies, users/permissions, jobs, and tests live in this repo.

---

## 1) How the Agents Work (Orchestration Overview)

**Coordinator → Specialists → QA/Reviewer → Release**

1. **Coordinator/Planner** converts a user story or issue into a structured work plan (ADR, acceptance criteria, checklists).
2. **Specialist agents** (Storage, Networking/Security, Backup/DR, Performance, Apps, Observability) implement changes as PRs.
3. **QA/Compliance agent** validates via automated tests, lint, and safety gates.
4. **Release/Docs agent** merges, versions artifacts, and updates operator docs.

**Communication channel**: GitHub Issues/PRs with labels and assignment.
**Artifacts**: YAML specs (pools, datasets, users, jobs), Ansible playbooks, test manifests, and Markdown runbooks.

---

## 2) Agent Roster & Responsibilities

### 2.1 Coordinator / Chief Architect

* **Inputs**: user outcomes, capacity/performance targets, risk profile.
* **Outputs**: Architecture Decision Records (ADRs), scope, milestone plan, acceptance criteria.
* **Key duties**: choose SCALE vs. upgrade path; define pool topology strategy; coordinate handoffs.

### 2.2 Storage & ZFS Engineer

* **Scope**: vdev design (RAIDZ1/2 vs. mirrors), ashift, recordsize, compression, atime, sync for service datasets.
* **Deliverables**: `pools/*.yaml`, `datasets/*.yaml`, `tunables/*.yaml`, provisioning playbooks.
* **Checks**: uniform vdevs; target failure domain; hot spares plan; scrubs scheduled.

### 2.3 Systems & Boot Engineer

* **Scope**: image/installer, mirrored boot SSDs, update channels, boot environments.
* **Deliverables**: `os/bootstrap/*.md`, `ansible/bootstrap.yml`, rollback plan.
* **Checks**: platform health (IPMI/Redfish), BIOS/UEFI settings, UPS/tested shutdown.

### 2.4 Networking & Security Engineer

* **Scope**: VLANs, MTU, LAGG, firewall policy, VPN for remote access; certs; UI hardening.
* **Deliverables**: `network/*.yaml`, `security/*.yaml`, WireGuard/OpenVPN profiles.
* **Checks**: **No Internet‑facing Web UI**; MFA for admin; least‑privilege groups; audit logging.

### 2.5 Backup & DR Engineer

* **Scope**: 3‑2‑1 strategy, snapshot policies, replication tasks, cloud tiering (e.g., B2/S3), restore tests.
* **Deliverables**: `backup/policies.yml`, `replication/tasks.yml`, recovery runbooks.
* **Checks**: RPO/RTO documented; quarterly restore drills; immutability where possible.

### 2.6 Performance & Caching Engineer

* **Scope**: ARC sizing, consider L2ARC and SLOG (only when warranted), workload profiling (SMB/NFS/iSCSI/apps).
* **Deliverables**: `perf/profiles.yml`, fio/bonnie++ benches, tuning notes.
* **Checks**: prove benefit before adding cache; monitor ARC hit ratios; avoid pathological record sizes.

### 2.7 Apps & Services Engineer

* **Scope**: services on SCALE, dataset boundaries, shares (SMB/NFS), iSCSI targets, container apps.
* **Deliverables**: `services/*.yaml`, `apps/*.yaml`, share definitions, ACL templates.
* **Checks**: separate datasets per app data; clean ACLs; app lifecycles and upgrades scripted.

### 2.8 Observability & Health Engineer

* **Scope**: SMART schedules, ZFS event alerts, syslog/Prometheus exporters, dashboards, notifications.
* **Deliverables**: `monitoring/*.yaml`, `alerts/*.yaml`, Grafana dashboards.
* **Checks**: daily short, weekly long SMART; monthly scrub; alert routes tested.

### 2.9 QA & Compliance Engineer

* **Scope**: validate specs & playbooks in CI; policy as code; secure‑by‑default checks.
* **Deliverables**: `tests/*.yaml`, `policy/*.rego` (optional), CI workflows.
* **Checks**: PRs must pass boot/provision simulation (containers/VM), lint, and safety gates.

### 2.10 Release & Documentation Engineer

* **Scope**: versioning, changelogs, operator guides, runbooks, upgrade notes.
* **Deliverables**: `docs/` updates, release notes, site publishing (optional).

---

## 3) Collaboration Protocol

### 3.1 Issue Template (create under `.github/ISSUE_TEMPLATE/truenas-task.md`)

```yaml
name: TrueNAS Task
labels: [truenas, planning]
body:
  - type: textarea
    id: outcome
    attributes:
      label: Desired Outcome
      description: User story / success criteria
  - type: textarea
    id: constraints
    attributes:
      label: Constraints & Risks
  - type: textarea
    id: acceptance
    attributes:
      label: Acceptance Criteria
```

### 3.2 Labels

* `area/storage`, `area/network`, `area/backup`, `area/perf`, `area/apps`, `area/observability`, `area/qa`, `area/docs`
* `impact/high|med|low`, `security`, `breaking-change`, `needs‑plan`, `ready‑for‑qa`

### 3.3 Handoffs & Artifacts

* Each specialist PR must include: **Spec diff** (YAML), **Playbook changes**, **Test updates**, and **Rollback notes**.
* Coordinator gates work via status checks: `spec‑lint`, `ansible‑dry‑run`, `policy‑check`, `backup‑plan‑validated`.

---

## 4) Repository Layout (suggested)

```
/agents/
  prompts/
    coordinator.md
    storage.md
    systems.md
    network-security.md
    backup-dr.md
    performance.md
    apps-services.md
    observability.md
    qa-compliance.md
    release-docs.md
/specs/
  pools/
  datasets/
  users-groups/
  shares/
  network/
  security/
  backup/
  monitoring/
/ansible/
  bootstrap.yml
  provision.yml
  services.yml
  backup.yml
  monitoring.yml
/tests/
  ci/
  perf/
/docs/
  runbooks/
  architecture/
.github/
  workflows/
```

---

## 5) Example: Spec‑as‑Code (YAML)

### 5.1 Pool & VDEV Layout (`specs/pools/pool-main.yaml`)

```yaml
pool: tank
ashift: 12
vdevs:
  - type: raidz2
    disks: [da0, da1, da2, da3, da4, da5]
  - type: raidz2
    disks: [da6, da7, da8, da9, da10, da11]
spares: [da12]
properties:
  autotrim: on
  autotrim_interval: weekly
scrub:
  schedule: monthly
  day_of_month: 1
```

### 5.2 Datasets & Policies (`specs/datasets/app-data.yaml`)

```yaml
dataset: tank/apps
properties:
  compression: zstd
  atime: off
  recordsize: 1M
  aclmode: passthrough
children:
  - name: nextcloud
    properties: { recordsize: 128K }
  - name: media
    properties: { recordsize: 1M }
```

### 5.3 Users, Groups, and ACLs (`specs/users-groups/groups.yaml`)

```yaml
groups:
  - name: storage-admins
    gid: 1100
  - name: media-users
    gid: 1200
users:
  - name: alice
    uid: 2101
    groups: [storage-admins]
  - name: bob
    uid: 2102
    groups: [media-users]
```

### 5.4 Snapshot & Replication Policy (`specs/backup/policies.yml`)

```yaml
snapshots:
  - dataset: tank/apps
    name: auto-%Y%m%d-%H%M
    schedule: hourly
    keep: 48
  - dataset: tank/apps
    schedule: daily
    keep: 30
  - dataset: tank
    schedule: weekly
    keep: 8
replication:
  - from: tank/apps
    to: b2://my-bucket/apps
    schedule: daily
    encrypt: true
    bandwidth_limit: 50MBps
    verify: true
restore-tests:
  cadence: quarterly
  datasets: [tank/apps]
```

### 5.5 Networking & Remote Access (`specs/network/core.yaml`)

```yaml
vlans:
  - id: 10
    name: storage
  - id: 20
    name: management
ui:
  exposure: vpn-only
  https: required
  hsts: true
vpn:
  type: wireguard
  peers: [admin-laptop]
```

---

## 6) Automation (Ansible Sketches)

> The Systems/Boot and Storage agents contribute to these; QA runs them in CI using a VM or containerized simulator where possible.

```yaml
# ansible/bootstrap.yml
- hosts: truenas
  gather_facts: no
  tasks:
    - name: Ensure admin group exists
      ansible.builtin.group:
        name: storage-admins
        state: present
    - name: Upload SSH keys for admins
      ansible.builtin.authorized_key:
        user: "{{ item.user }}"
        key:  "{{ item.key }}"
      loop: "{{ admin_keys }}"
```

```yaml
# ansible/provision.yml
- hosts: truenas
  tasks:
    - name: Create pool
      community.general.zpool:
        name: tank
        # (device list and layout from specs/pools/pool-main.yaml)
    - name: Create datasets
      community.general.zfs:
        name: "{{ item.name }}"
        state: present
        extra_zfs_properties: "{{ item.properties }}"
      loop: "{{ zfs_datasets }}"
```

---

## 7) Validation & CI Gates

Create `.github/workflows/trueNAS-ci.yml`:

```yaml
name: TrueNAS CI
on:
  pull_request:
    paths:
      - 'specs/**'
      - 'ansible/**'
      - 'tests/**'
      - 'policy/**'
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: YAML lint
        uses: ibiqlik/action-yamllint@v3
  dry-run:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Validate specs schema
        run: ./tests/schema/validate.sh
      - name: Ansible syntax check
        run: ansible-playbook --syntax-check ansible/provision.yml
  policy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Policy checks
        run: ./tests/policy/check.sh
```

**Acceptance criteria for merge**:

* Specs are valid & reviewed by relevant specialist agent.
* Dry‑run passes; no Internet‑facing UI; backup policy present for any new dataset with critical data.
* Docs updated with operator steps and rollback.

---

## 8) Basic → Advanced Playbooks (What "Good" Looks Like)

### 8.1 Basic (Single node, resilient, safely managed)

* SCALE install on mirrored boot SSDs; IPMI reachable.
* Single pool `tank` (RAIDZ2) with monthly scrub.
* Datasets per service; SMB with clean ACLs.
* Snapshots (hourly/daily/weekly); off‑site replication of critical datasets.
* VPN‑only admin; alerting wired to email/Slack.

### 8.2 Advanced (Automated, performance‑aware, security‑hardened)

* IaC: repo‑driven provisioning; CI validation; change windows enforced.
* Tiered datasets with tuned recordsize; optional SLOG for sync‑workloads (validated by test).
* Apps on SCALE with dedicated datasets and quotas; rolling upgrades.
* Immutable/object backups with periodic restore tests.
* Centralized metrics/logs; dashboards; SLOs on latency and pool health.

---

## 9) Prompts for Each Agent (drop into `/agents/prompts/*.md`)

### Coordinator

> You are the Coordinator. Convert issues into a plan (ADR + acceptance). Route to specialists. Refuse unsafe designs (Internet‑exposed UI, absent backups). Output: ADR, labels, assignees, checklist.

### Storage

> You are the Storage & ZFS Engineer. Propose vdev layout and dataset policies from specs. Enforce uniform vdevs, monthly scrubs, compression on, `atime=off` (except for audit datasets). Output: YAML diff + rationale.

### Systems/Boot

> You manage install, mirrored boot SSDs, update channels, and rollback plans. Output: bootstrap steps and recovery.

### Network/Security

> You design VLANs, MTU, firewall, VPN‑only UI. Enforce MFA and least privilege. Output: network & security YAML + verification.

### Backup/DR

> You own 3‑2‑1, snapshot/replication, and restore tests. Output: policies.yml + test plan.

### Performance

> You size ARC, justify L2ARC/SLOG with evidence, and tune recordsize per workload. Output: benchmark report + tuning.

### Apps/Services

> You define shares, iSCSI, and apps on SCALE. Output: service YAML, ACL templates, upgrade path.

### Observability

> You wire SMART, ZFS events, dashboards, and alerts. Output: alert routes + dashboards.

### QA/Compliance

> You enforce CI gates and security policies. Output: pass/fail with remediation notes.

### Release/Docs

> You version artifacts and update runbooks. Output: changelog + operator docs.

---

## 10) Operational Schedules (defaults)

* **SMART**: short daily, long weekly.
* **Scrub**: monthly (1st of month).
* **Snapshots**: hourly(48), daily(30), weekly(8).
* **Restore test**: quarterly.
* **Security review**: semi‑annual.

---

## 11) Safety & Guardrails

* Never expose Web UI on public interfaces; always require VPN.
* For any dataset holding critical data, backups are mandatory before change.
* Changes must be reversible (document rollback and test it in staging where feasible).
* Evidence before optimization: do not add cache/SLOG without measured benefit.

---

## 12) Getting Started (maintainers)

1. Fork this repo; enable GitHub Actions.
2. Create labels from §3.2; add issue template from §3.1.
3. Add your first spec under `specs/` and run CI locally: `make validate` (optional).
4. Open a PR; let the agents process the workflow; iterate until gates pass.
5. Deploy using the generated playbooks and follow the runbooks in `docs/`.

---

**Best practices for setting up TrueNAS**

Setting up TrueNAS can be a bit complex, but following some best practices can help ensure a smooth and efficient experience. Here are some key recommendations from Redditors:

**Initial Setup and Configuration**
Choose the Right TrueNAS Version: It's recommended to start with TrueNAS SCALE rather than CORE, as SCALE is actively developed and has more features. "CORE is EoL. You're best bet would be to start off with SCALE."

Hardware Considerations: Ensure you have appropriate hardware, including a sufficient amount of RAM (at least 8GB, but 16GB is recommended for running apps). "They say 8GB of RAM is enough and it is, but if you are going to run apps on it, give it 16GB to start with."

Boot Disk Setup: Use a dedicated SSD or mirrored SSDs for the boot disk to improve performance and reliability. "Boot disk should be 60GB, I don't care what the documentation says, it's what I actually recommend as minimum."

**Storage Pool and RAID Configuration**
RAID Configuration: Depending on your needs, choose between RAIDZ1, RAIDZ2, or mirroring. RAIDZ1 offers single-drive fault tolerance, while RAIDZ2 provides double-drive fault tolerance. "With a Z1, you have a single drive fault tolerance."

Dataset Structure: Organize your data into datasets to manage different types of data and permissions more effectively. "I also have different datasets for different people, but its mostly one dataset for myself that I can use across my devices, and one dataset for everyone else to share."

Encryption: Consider encrypting your pool or datasets if you are concerned about physical security. "take encryption into consideration if you worry about someone physically stealing your stuff."

**Networking and Remote Access**
VPN for Remote Access: For secure remote access, using a VPN is highly recommended over exposing TrueNAS directly to the internet. "You need a VPN, plain and simple."

Domain Setup: Avoid hosting the TrueNAS web UI directly over a domain without proper security measures. "Heck no, do not try to host the TN WebUI over a domain and make it internet facing!!"

**Backup and Data Protection**
3-2-1 Backup Methodology: Follow the 3-2-1 backup rule, which suggests having three copies of your data, two on different storage types, and one offsite. "You want 3 total copies, 2 local but on different machines/mediums, and 1 offsite."

Snapshots: Use snapshots to protect against data loss and rollback to previous states. "Snapshots have saved my bacon many times. Use them."

Offsite Backups: Consider using cloud services or another remote location for offsite backups. "I just started backing up irreplaceable media (photos, personal documents, etc.) to Backblaze B2 using the integrated TrueNAS function."

**Performance and Optimization**
Caching: Use NVMe SSDs for caching to improve performance, especially for frequently accessed data. "2x 2TB NVMe SSDs (mirrored) for caching or fast-access folders."

RAM: Ensure you have enough RAM to handle the workload, as TrueNAS uses RAM extensively for ARC (Adaptive Replacement Cache). "RAM before cache."

**Additional Tips**
Regular Maintenance: Set up regular SMART tests and scrubs to monitor the health of your drives. "I have set raid scrub to monthly, and a short smart test daily, and a long one weekly."

User and Permissions: Configure users and permissions carefully to ensure secure access to your data. "configure groups and users, do not use root for everything."
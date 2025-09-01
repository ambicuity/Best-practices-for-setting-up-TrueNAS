# TrueNAS Multi-Agent Architecture

## Overview
This document describes the architecture and design decisions for the TrueNAS multi-agent system framework.

## Architecture Decision Records (ADRs)

### ADR-001: Multi-Agent System Design
**Status**: Accepted  
**Date**: 2024-01-01

**Context**: TrueNAS deployments require expertise across multiple domains (storage, networking, security, backup, performance). Managing this complexity through traditional documentation is error-prone and doesn't scale.

**Decision**: Implement a multi-agent system where each agent specializes in one domain and communicates through structured specifications (YAML) and workflows (GitHub Issues/PRs).

**Consequences**:
- Positive: Domain expertise separated, knowledge captured in prompts, reproducible deployments
- Negative: Initial complexity, requires coordination between agents

### ADR-002: Specification-as-Code Approach  
**Status**: Accepted  
**Date**: 2024-01-01

**Context**: TrueNAS configurations are complex and changes need to be tracked, reviewed, and versioned.

**Decision**: Use YAML specifications to define all aspects of TrueNAS deployment (pools, datasets, users, network, security, backup).

**Consequences**:
- Positive: Version controlled, reviewable, automated validation
- Negative: Learning curve for YAML syntax

### ADR-003: Security-First Design
**Status**: Accepted  
**Date**: 2024-01-01

**Context**: TrueNAS systems often contain critical data and are attractive targets for attacks.

**Decision**: Enforce security-first design with mandatory VPN for admin access, no internet-exposed UI, and backup requirements for critical data.

**Consequences**:
- Positive: Secure by default, reduced attack surface
- Negative: More complex remote access setup

### ADR-004: TrueNAS SCALE Preference
**Status**: Accepted  
**Date**: 2024-01-01

**Context**: TrueNAS CORE is reaching end-of-life while SCALE is actively developed with modern container ecosystem support.

**Decision**: Prefer TrueNAS SCALE for all new deployments unless specific CORE requirements exist.

**Consequences**:
- Positive: Modern features, active development, container support
- Negative: Migration required for existing CORE systems

## System Components

### Agent Types
1. **Coordinator**: Orchestrates work and makes architectural decisions
2. **Storage Engineer**: ZFS pools, datasets, and performance tuning  
3. **Systems Engineer**: Boot configuration, OS maintenance
4. **Network/Security Engineer**: VLANs, VPN, firewall, certificates
5. **Backup/DR Engineer**: 3-2-1 backup strategy, replication
6. **Performance Engineer**: Caching, workload optimization
7. **Apps/Services Engineer**: Application deployment, shares
8. **Observability Engineer**: Monitoring, alerting, dashboards
9. **QA/Compliance**: Validation, policy enforcement
10. **Release/Docs**: Documentation, versioning

### Communication Flow
```
User Story → Coordinator → Specialist Agents → QA → Release
     ↓            ↓              ↓           ↓       ↓
GitHub Issue → ADR/Tasks → Spec Changes → Tests → Docs
```

### Repository Structure
- `/agents/prompts/` - Agent instructions and capabilities
- `/specs/` - YAML specifications for all components
- `/ansible/` - Automation playbooks for deployment
- `/tests/` - Validation and policy checks
- `/docs/` - Runbooks and architecture documentation

## Quality Assurance

### Validation Gates
1. **YAML Lint**: Syntax and formatting validation
2. **Schema Validation**: Ensure specifications meet requirements
3. **Policy Checks**: Security and safety validations
4. **Ansible Dry-run**: Test playbook syntax and logic
5. **Integration Tests**: End-to-end deployment validation

### Safety Guardrails
- Internet-exposed UI configurations blocked
- Backup policies required for critical datasets
- Rollback procedures documented and tested
- Evidence required for performance optimizations

## Deployment Patterns

### Basic Deployment
- Single node with RAIDZ2 storage
- VPN-only admin access
- Automated snapshots and replication
- Basic monitoring and alerting

### Advanced Deployment  
- High-availability configurations
- Performance-tuned workloads
- Advanced security policies
- Comprehensive monitoring and SLOs
- Automated testing and validation
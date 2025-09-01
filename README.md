# Best Practices for Setting Up TrueNAS

This repository provides a comprehensive framework for setting up, configuring, and maintaining TrueNAS systems using a multi-agent approach modeled after veteran TrueNAS engineers.

## 🚀 Quick Start

### For New Users - Complete Examples  
1. **Choose Your Scenario**: Start with [examples/](examples/) for complete deployment examples
   - **Home/Small Office**: [Basic Home Setup](examples/basic-home-setup/) - Complete 4-drive RAIDZ1 system
   - **Enterprise**: [Advanced Enterprise](examples/advanced-enterprise/) - High-availability configuration  
2. **Follow the Workflow**: Use [examples/workflows/](examples/workflows/) for step-by-step guidance
3. **Deploy**: Run the provided Ansible playbooks for automated deployment
4. **Validate**: Use included test scripts to verify your deployment

### For Advanced Users - Framework Components
1. **Review the Framework**: Start with [AGENTS.md](AGENTS.md) to understand the multi-agent system
2. **Customize Specifications**: Edit YAML files in `specs/` to match your requirements  
3. **Bootstrap a System**: Follow [docs/runbooks/bootstrap.md](docs/runbooks/bootstrap.md) for new installations
4. **Validate Configuration**: Run `./tests/schema/validate.sh` to check your specifications
5. **Deploy**: Use Ansible playbooks in `ansible/` for automated deployment

## 📁 Repository Structure

- [`AGENTS.md`](AGENTS.md) - Complete multi-agent system documentation
- [`examples/`](examples/) - **Complete deployment examples from setup to production**
  - [`basic-home-setup/`](examples/basic-home-setup/) - Home/small office deployment with full automation
  - [`workflows/`](examples/workflows/) - Step-by-step deployment workflows  
  - [`troubleshooting/`](examples/troubleshooting/) - Common issues and solutions
- `specs/` - YAML specifications for all TrueNAS components
- `ansible/` - Automation playbooks for deployment
- `tests/` - Validation scripts and policy checks
- `docs/` - Runbooks and architecture documentation
- `agents/prompts/` - Individual agent instructions

## 🛡️ Security-First Design

- **No Internet-Exposed Web UI** - Admin access through VPN only
- **3-2-1 Backup Strategy** - Comprehensive data protection
- **Policy Enforcement** - Automated security checks in CI
- **Least Privilege** - Proper user and group separation

## 🔧 Key Features

- **Infrastructure as Code** - All configurations version controlled
- **Automated Validation** - CI/CD pipelines with safety gates
- **Expert Knowledge** - Best practices from 20+ years of experience
- **Production Ready** - From basic setups to advanced enterprise deployments

## 📊 Specifications

The framework includes example specifications for:
- Storage pools and datasets
- User and group management
- Network configuration and VLANs
- Backup and replication policies
- Monitoring and alerting
- Shares and iSCSI targets

**🎯 Complete Examples Available:**
- **[Basic Home Setup](examples/basic-home-setup/)**: Production-ready 4-drive RAIDZ1 system for families
  - Hardware requirements and build guide
  - Complete Ansible automation
  - Comprehensive backup strategy (3-2-1 methodology)
  - Security hardening and VPN-ready configuration  
  - Monitoring and maintenance procedures
  - Validation and testing scripts
- **[Deployment Workflows](examples/workflows/)**: Step-by-step guides using the multi-agent framework

## 🤖 Multi-Agent System

Ten specialized agents handle different aspects:
1. **Coordinator** - Orchestrates work and architectural decisions
2. **Storage Engineer** - ZFS pools and performance tuning
3. **Systems Engineer** - Boot configuration and OS maintenance
4. **Network/Security Engineer** - VPN, firewall, and certificates
5. **Backup/DR Engineer** - Disaster recovery and data protection
6. **Performance Engineer** - Caching and workload optimization
7. **Apps/Services Engineer** - Application deployment
8. **Observability Engineer** - Monitoring and alerting
9. **QA/Compliance** - Validation and policy enforcement
10. **Release/Docs** - Documentation and versioning

## 🧪 Testing

Run validation tests:
```bash
# Validate YAML specifications
./tests/schema/validate.sh

# Run security and policy checks
./tests/policy/check.sh

# Full CI validation
./.github/workflows/truenas-ci.yml
```

## 📚 Best Practices Summary

- **Prefer TrueNAS SCALE** for new builds
- **Boot on mirrored SSDs** (≥60GB recommended)
- **RAM before cache** - Start with 16GB for apps
- **Use uniform VDEVs** in pools
- **Separate datasets** by data type and permissions
- **Automate maintenance** - SMART tests and scrubs
- **Never run as root** for routine operations

## 🚨 Getting Help

1. Check the [runbooks](docs/runbooks/) for operational procedures
2. Review [architecture documentation](docs/architecture/) for design decisions
3. Validate your configuration with the included tests
4. Open an issue using the TrueNAS task template

## 📄 License

See [LICENSE](LICENSE) file for details.
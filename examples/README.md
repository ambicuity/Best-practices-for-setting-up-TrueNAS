# TrueNAS Deployment Examples

This directory contains complete, production-ready examples that demonstrate how to use this framework from initial setup to production deployment.

## 📁 Directory Structure

```
examples/
├── basic-home-setup/           # Home/small office deployment
├── advanced-enterprise/        # Enterprise production deployment
├── workflows/                  # Step-by-step deployment workflows
├── integrations/              # Component integration examples
└── troubleshooting/           # Common issues and solutions
```

## 🎯 Deployment Scenarios

### 🏠 Basic Home Setup (`basic-home-setup/`)
**Target**: Home users, small offices, basic NAS requirements
- Single TrueNAS SCALE system
- Simple storage pool with redundancy
- Basic file sharing (SMB/NFS)
- Essential backup strategy
- VPN-secured remote access

### 🏢 Advanced Enterprise (`advanced-enterprise/`)
**Target**: Business environments, high availability requirements
- High-availability configuration
- Performance-optimized storage
- Advanced security hardening
- Comprehensive monitoring
- Automated backup/DR
- Multi-tier storage strategy

### 🔄 Workflows (`workflows/`)
**Target**: Step-by-step deployment guides
- Pre-deployment planning
- Installation and bootstrap
- Configuration and validation
- Production deployment
- Maintenance procedures

## 🚀 Quick Start

1. **Choose your scenario**: Review the deployment scenarios above
2. **Follow the workflow**: Start with `workflows/` for step-by-step guidance
3. **Customize specs**: Adapt the example configurations to your environment
4. **Deploy**: Use the provided Ansible playbooks
5. **Validate**: Run the included tests and checks

## 🔗 Integration with Framework

All examples are designed to work with the multi-agent framework defined in [`AGENTS.md`](../AGENTS.md):

- **Specs**: YAML configurations for all components
- **Automation**: Ansible playbooks for deployment
- **Validation**: Tests and policy checks
- **Documentation**: Runbooks and troubleshooting guides

## 📊 What Each Example Includes

Each deployment example provides:

- **Complete specifications**: All required YAML configs
- **Deployment playbooks**: Ready-to-run Ansible automation
- **Validation scripts**: Tests to verify deployment
- **Documentation**: Setup guides and operational runbooks
- **Rollback procedures**: Recovery and troubleshooting steps

## 🔧 Prerequisites

Before using these examples:

- [ ] TrueNAS SCALE installed on appropriate hardware
- [ ] Network connectivity configured
- [ ] Ansible control machine available
- [ ] Required storage devices available
- [ ] Administrative access configured

## 💡 Tips for Success

- **Start simple**: Use the basic example first, then progress to advanced
- **Validate early**: Run tests at each stage of deployment
- **Document changes**: Track any customizations you make
- **Test backups**: Verify your backup strategy works before going to production
- **Monitor regularly**: Set up proper alerting and monitoring

## 🆘 Getting Help

- Check the `troubleshooting/` directory for common issues
- Review the validation scripts if deployment fails
- Consult the main framework documentation in [`AGENTS.md`](../AGENTS.md)
- Use the issue template for reporting problems
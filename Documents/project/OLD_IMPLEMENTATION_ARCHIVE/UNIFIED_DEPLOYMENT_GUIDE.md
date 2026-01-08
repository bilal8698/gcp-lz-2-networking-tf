# Carrier Infrastructure Unified Deployment Script
## Complete Integration for Carrier Meeting

**Date:** January 6, 2026  
**Version:** 1.0  
**Status:** Ready for Carrier Presentation

---

## 📋 Executive Summary

This integrated deployment solution combines all networking infrastructure and Palo Alto firewall components into a single, automated deployment workflow for the Carrier project.

### What's Been Integrated

✅ **Networking Infrastructure**
- Network Connectivity Center (NCC) Hub & Spokes (M1P, M1NP, M3P, M3NP, Transit)
- Shared VPCs across 6 regions (US-EAST-1, US-CENTRAL-1, EU-WEST-1, EU-EAST-1, AP-WEST-1, AP-EAST-1)
- Cloud Routers & HA-VPN configurations
- Network Address Translation (NAT)
- Private Service Connect & Network Service Integration (NSI)
- Automated subnet vending with project metadata

✅ **Palo Alto VM-Series Firewalls**
- 6 firewalls (3 active/active pairs) across 3 regions
- Automated GCS bootstrap buckets with complete configuration
- External & Internal Load Balancers
- Panorama/StrataCom integration ready
- Security policies and health checks

✅ **Compliance & Governance**
- Mandatory Carrier tags (cost_center, owner, application, leanix_app_id)
- Security scanning and validation
- Terraform linting and formatting checks
- Carrier Terraform Scaffold compliance

---

## 🚀 Quick Start

### For Windows (PowerShell)
```powershell
# Run with menu
.\deploy-carrier-infrastructure.ps1

# Or run specific mode
.\deploy-carrier-infrastructure.ps1 -Mode Full        # Full deployment
.\deploy-carrier-infrastructure.ps1 -Mode Networking  # Networking only
.\deploy-carrier-infrastructure.ps1 -Mode Bootstrap   # Palo Alto only
.\deploy-carrier-infrastructure.ps1 -Mode Validate    # Validation only
.\deploy-carrier-infrastructure.ps1 -Mode Verify      # Verification only
```

### For Linux/Mac (Bash)
```bash
# Make executable
chmod +x deploy-carrier-infrastructure.sh

# Run
./deploy-carrier-infrastructure.sh
```

---

## 📁 File Structure

```
project/
│
├── deploy-carrier-infrastructure.sh      # Unified deployment script (Bash)
├── deploy-carrier-infrastructure.ps1     # Unified deployment script (PowerShell)
├── UNIFIED_DEPLOYMENT_GUIDE.md          # This file
│
├── gcp-lz-2-networking-tf/              # Networking Infrastructure
│   ├── main.tf                          # Main configuration
│   ├── network-vpc.tf                   # VPC definitions
│   ├── network-ncc.tf                   # NCC Hub & Spokes
│   ├── network-cloud-routers.tf         # Cloud Router configs
│   ├── network-ha-vpn.tf                # HA-VPN tunnels
│   ├── network-subnets-*.tf             # Infrastructure & vending subnets
│   ├── network-nat.tf                   # Cloud NAT
│   ├── network-nsi.tf                   # Network Service Integration
│   ├── variables.tf                     # Input variables
│   ├── outputs.tf                       # Output values
│   └── data/                            # YAML configurations
│       ├── shared-vpc-config.yaml
│       ├── ncc-config.yaml
│       ├── network-projects.yaml
│       └── network-subnets.yaml
│
└── gcp-palo-alto-bootstrap/             # Palo Alto Firewalls
    ├── terraform/                       # Terraform configuration
    │   ├── main.tf
    │   ├── firewalls.tf                 # VM-Series instances
    │   ├── load-balancers.tf            # External & Internal LBs
    │   ├── variables.tf
    │   └── outputs.tf
    └── bootstrap-files/                 # Bootstrap configurations
        ├── region1-fw01/
        ├── region1-fw02/
        ├── region2-fw01/
        ├── region2-fw02/
        ├── region3-fw01/
        └── region3-fw02/
```

---

## 🔧 Deployment Options

### Option 1: Full Deployment
**Duration:** ~30-45 minutes  
**What it does:**
1. Validates all networking configurations
2. Validates all Palo Alto bootstrap configurations
3. Checks mandatory Carrier tags
4. Runs security compliance checks
5. Deploys networking infrastructure (NCC, VPCs, Routers)
6. Deploys Palo Alto firewalls and load balancers
7. Verifies all resources in GCP

**Use case:** Complete infrastructure deployment from scratch

### Option 2: Networking Only
**Duration:** ~20-30 minutes  
**What it does:**
1. Validates networking configurations
2. Checks mandatory tags
3. Deploys VPCs, NCC Hub & Spokes, Cloud Routers, HA-VPN
4. Verifies networking resources

**Use case:** Deploy network foundation first, add security later

### Option 3: Palo Alto Bootstrap Only
**Duration:** ~15-20 minutes  
**What it does:**
1. Validates bootstrap configurations
2. Checks all init-cfg.txt files
3. Deploys VM-Series firewalls
4. Creates GCS bootstrap buckets
5. Deploys load balancers
6. Verifies firewall resources

**Use case:** Network already exists, add security layer

### Option 4: Validation & Security Checks Only
**Duration:** ~5 minutes  
**What it does:**
1. Validates Terraform syntax
2. Checks YAML configurations
3. Verifies mandatory tags
4. Scans for sensitive data
5. Checks .gitignore configuration

**Use case:** Pre-deployment validation before carrier meeting

### Option 5: Post-Deployment Verification
**Duration:** ~2 minutes  
**What it does:**
1. Counts VPCs
2. Counts Cloud Routers
3. Counts VM instances (firewalls)
4. Counts Load Balancers
5. Lists GCS buckets

**Use case:** After deployment, verify all resources exist

---

## 📊 What Gets Deployed

### Networking Infrastructure

| Component | Quantity | Description |
|-----------|----------|-------------|
| **NCC Hub** | 1 | Global NCC hub for transitivity |
| **NCC Spokes** | 4 | M1P, M1NP, M3P, M3NP |
| **Transit Spoke** | 1 | Connects to SD-WAN via Router Appliances |
| **Shared VPCs** | 4 | M1P, M1NP, M3P, M3NP host projects |
| **Subnets** | 24 | 6 regions × 4 VPCs |
| **Cloud Routers** | Variable | Per region, per VPC |
| **HA-VPN Tunnels** | Variable | Per interconnect requirement |
| **Cloud NAT** | Variable | Per region, per VPC |

### Palo Alto Security

| Component | Quantity | Description |
|-----------|----------|-------------|
| **VM-Series Firewalls** | 6 | 2 per region (active/active HA) |
| **Regions** | 3 | us-central1, us-east1, us-west1 |
| **External Load Balancers** | 3 | 1 per region |
| **Internal Load Balancers** | 3 | 1 per region |
| **GCS Bootstrap Buckets** | 3 | 1 per region (shared by HA pair) |
| **Service Accounts** | 1 | For firewall instances |

---

## 🎯 Architecture Overview

### Network Flow

```
Internet
    │
    ├──► External Load Balancer (per region)
    │        │
    │        ├──► Palo Alto FW-01 ◄──HA2/HA3──► Palo Alto FW-02
    │        │           │                              │
    │        └───────────┴──────────────────────────────┘
    │                    │
    │        Internal Load Balancer (per region)
    │                    │
    └──► NCC Hub ◄──────┤
             │           │
             ├──► M1P Spoke ──► Workloads (Internal, No Internet)
             ├──► M1NP Spoke ──► Workloads (Internal, No Internet)
             ├──► M3P Spoke ──► Workloads (DMZ, One-way)
             ├──► M3NP Spoke ──► Workloads (DMZ, One-way)
             └──► Transit Spoke ──► SD-WAN / Router Appliances
```

### Traffic Inspection Logic

✅ **No Inspection Required:**
- M1P → M1P (same model)
- M1NP → M1NP (same model)
- M3P → M3P (same model)
- M3NP → M3NP (same model)

🔍 **Inspection Required (via Palo Alto):**
- M1P ↔ M1NP (cross-environment)
- M1P ↔ M3P (cross-model)
- M1P ↔ M3NP (cross-model)
- M1NP ↔ M3P (cross-model)
- M1NP ↔ M3NP (cross-model)
- M3P ↔ M3NP (cross-environment)
- Any traffic to/from Internet

---

## 🔐 Security & Compliance

### Mandatory Carrier Tags

All resources include:
```hcl
labels = {
  cost_center    = "your-cost-center"
  owner          = "your-email@carrier.com"
  application    = "carrier-network-security"
  leanix_app_id  = "your-leanix-id"
}
```

### Security Checks Performed

✅ Format validation (terraform fmt)  
✅ Syntax validation (terraform validate)  
✅ YAML configuration validation  
✅ Sensitive data scanning  
✅ .gitignore verification  
✅ Tag compliance checking  
✅ Bootstrap file completeness  

---

## 📝 Pre-Deployment Checklist

### Before Running the Script

- [ ] GCP project created and selected
- [ ] GCP authentication configured (`gcloud auth login`)
- [ ] Terraform installed (version ≥ 1.0)
- [ ] Git installed
- [ ] gcloud CLI installed

### Networking Configuration

- [ ] Update `data/shared-vpc-config.yaml` with project IDs
- [ ] Update `data/ncc-config.yaml` with hub and spoke details
- [ ] Update `data/network-projects.yaml` with project information
- [ ] Update `data/network-subnets.yaml` with subnet CIDRs
- [ ] Configure `terraform.tfvars` (or use defaults)

### Palo Alto Configuration

- [ ] Update `terraform/terraform.tfvars` with project details
- [ ] Update all 6 `init-cfg.txt` files with:
  - License auth codes
  - VM auth keys
  - Panorama IP (if using)
- [ ] Download content updates from Palo Alto support:
  - [ ] Anti-virus updates
  - [ ] Threat prevention content
  - [ ] WildFire updates
  - [ ] PAN-OS software
  - [ ] VM-Series plugin
- [ ] Place downloaded files in appropriate `bootstrap-files/` directories

---

## 🎬 Deployment Flow

```
┌─────────────────────────────────────────────────────────┐
│ 1. Prerequisites Check                                  │
│    - Verify tools (terraform, gcloud, git)             │
│    - Check GCP authentication                           │
│    - Verify versions                                    │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│ 2. Configuration Validation                             │
│    - YAML files                                         │
│    - Terraform syntax                                   │
│    - Mandatory tags                                     │
│    - Bootstrap files                                    │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│ 3. Security Checks                                      │
│    - Sensitive data scanning                            │
│    - .gitignore verification                            │
│    - Compliance validation                              │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│ 4. Terraform Init & Plan                                │
│    - Initialize providers                               │
│    - Create execution plan                              │
│    - Review changes                                     │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│ 5. User Confirmation                                    │
│    - Review plan output                                 │
│    - Confirm deployment (yes/no)                        │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│ 6. Terraform Apply                                      │
│    - Deploy networking (NCC, VPCs, Routers)            │
│    - Deploy Palo Alto (Firewalls, LBs)                 │
│    - Create GCS buckets                                 │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│ 7. Post-Deployment Verification                         │
│    - Count resources                                    │
│    - Verify connectivity                                │
│    - Check firewall status                              │
└─────────────────────────────────────────────────────────┘
```

---

## 📜 Logs & Outputs

### Log Files
All deployment logs are saved to:
```
deployment-logs/deployment_YYYY-MM-DD_HH-MM-SS.log
```

### Terraform Outputs

**Networking Outputs:**
```hcl
- NCC Hub ID
- Spoke IDs (M1P, M1NP, M3P, M3NP, Transit)
- VPC IDs
- Subnet IDs
- Cloud Router IDs
- NAT Gateway IDs
```

**Palo Alto Outputs:**
```hcl
- Firewall instance IDs
- Firewall management IPs
- External LB IPs
- Internal LB IPs
- Bootstrap bucket URLs
- Service account email
```

---

## 🚨 Troubleshooting

### Common Issues

**Issue:** Terraform init fails
```
Solution: Check GCP authentication and project selection
$ gcloud auth login
$ gcloud config set project YOUR_PROJECT_ID
```

**Issue:** Validation fails for YAML files
```
Solution: Check YAML syntax using online validator
Ensure no tabs, only spaces for indentation
```

**Issue:** Missing mandatory tags
```
Solution: Add tags to variables.tf or locals.tf
Ensure all resources inherit tag labels
```

**Issue:** Palo Alto bootstrap files incomplete
```
Solution: Check all init-cfg.txt files for REPLACE_WITH placeholders
Download missing content from Palo Alto support portal
```

**Issue:** Terraform plan shows unexpected changes
```
Solution: Review the plan output carefully
Check if resources already exist in GCP
Verify state file is up to date
```

---

## 📞 Support & Resources

### Documentation
- [Networking README](gcp-lz-2-networking-tf/README.md)
- [Networking Technical Docs](gcp-lz-2-networking-tf/TECHNICAL_DOCUMENTATION.md)
- [Palo Alto README](gcp-palo-alto-bootstrap/README.md)
- [Palo Alto Quick Reference](gcp-palo-alto-bootstrap/QUICK_REFERENCE.md)

### Carrier Requirements
- [Carrier Requirements](Carrier requirement & Solution Approach.txt)
- [Overall Project Info](Overall Information  Carrier Projec.txt)

### External Resources
- [Terraform Documentation](https://www.terraform.io/docs)
- [GCP Networking](https://cloud.google.com/vpc/docs)
- [NCC Documentation](https://cloud.google.com/network-connectivity/docs/network-connectivity-center)
- [Palo Alto VM-Series](https://docs.paloaltonetworks.com/vm-series)

---

## ✅ Carrier Meeting Checklist

### Before the Meeting

- [ ] Run validation checks (`Mode 4`)
- [ ] Review all configuration files
- [ ] Ensure all mandatory tags are present
- [ ] Verify bootstrap files are complete
- [ ] Prepare demo environment (optional)
- [ ] Review deployment logs
- [ ] Test rollback procedures

### During the Meeting

- [ ] Explain unified deployment approach
- [ ] Demonstrate validation checks
- [ ] Show architecture diagrams
- [ ] Explain traffic flow and inspection logic
- [ ] Discuss mandatory tag compliance
- [ ] Review security scanning results
- [ ] Walk through deployment options
- [ ] Show estimated deployment times
- [ ] Discuss monitoring and logging

### After the Meeting

- [ ] Address any feedback
- [ ] Update configurations as needed
- [ ] Schedule deployment window
- [ ] Plan post-deployment validation
- [ ] Set up monitoring and alerts

---

## 🎯 Key Differentiators for Carrier

### ✅ Fully Integrated Solution
Single script handles networking + security instead of separate deployments

### ✅ Compliance Built-In
Mandatory Carrier tags enforced across all resources

### ✅ Automated Validation
Pre-deployment checks ensure configuration correctness

### ✅ Security Scanning
Automatic detection of sensitive data and security issues

### ✅ Flexible Deployment
Choose full, partial, or validation-only modes

### ✅ Comprehensive Logging
All actions logged with timestamps for audit trail

### ✅ Cross-Platform Support
Bash (Linux/Mac) and PowerShell (Windows) versions

### ✅ Production-Ready
Error handling, rollback support, and confirmation prompts

---

## 📈 Next Steps

1. **Immediate:**
   - Review this guide with the team
   - Run validation checks
   - Prepare for Carrier meeting

2. **Pre-Deployment:**
   - Finalize configuration values
   - Complete Palo Alto bootstrap files
   - Test in non-production environment

3. **Deployment:**
   - Execute unified deployment script
   - Monitor deployment progress
   - Verify all resources

4. **Post-Deployment:**
   - Configure Panorama integration
   - Set up monitoring and alerts
   - Enable logging pipelines
   - Test traffic flows
   - Document as-built architecture

---

## 🔄 Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-06 | Initial unified deployment script |

---

## 👥 Contributors

- Infrastructure Team
- Security Team
- Networking Team

---

**Document Status:** ✅ Ready for Carrier Meeting  
**Last Updated:** January 6, 2026  
**Next Review:** After Carrier Meeting

# Carrier GCP Landing Zone - Networking Stage

This repository implements the **Stage 2: Networking** of Carrier's GCP Landing Zone using Google Cloud Foundation Fabric (CFF) modules and YAML-driven network configuration factories.

## Overview

The networking stage establishes the core network infrastructure foundation for Carrier's GCP environment, featuring:

- **Network Project Factory**: YAML-driven provisioning of network-specific projects
- **Shared VPC Architecture**: Four shared VPCs for Model 1 and Model 3 environments
- **Network Connectivity Center (NCC)**: Global mesh topology for transitivity
- **Automated Subnet Vending**: YAML-driven subnet provisioning with IPAM integration
- **Network Security Integration (NSI)**: Framework for Palo Alto in-band inspection
- **Service Account Automation**: IaC automation accounts with proper role segregation

## Network Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                  Global NCC Hub (Mesh Topology)                   │
│                     hub-global-ncc-hub                            │
│                    (8 Spokes Connected)                           │
└───┬─────┬─────┬─────┬──────┬──────┬──────┬──────┬───────────────┘
    │     │     │     │      │      │      │      │
 ┌──▼──┐┌─▼──┐┌─▼──┐┌─▼───┐┌─▼────┐┌▼────┐┌▼────┐┌▼──────┐
 │ M1P ││M1NP││M3P ││M3NP ││  RA  ││ FW  ││ FW  ││Shared │
 │ VPC ││VPC ││VPC ││ VPC ││Appl. ││Data ││Mgmt ││ Svcs  │
 │Spoke││Spk ││Spk ││Spoke││Spoke ││VPC  ││ VPC ││  VPC  │
 └─────┘└────┘└────┘└─────┘└──────┘└─────┘└─────┘└───────┘
                              │
                         ┌────▼──────┐
                         │    NSI    │ (In-band Inspection)
                         │ Palo Alto │
                         │ Firewalls │
                         └───────────┘
```

## Projects Created

Total of **5 Projects**:

| Project | Name | Purpose |
|---------|------|---------|
| **M1P Host** | `prj-prd-gcp-xxxxx-host-m1p` | Model 1 Production Shared VPC Host |
| **M1NP Host** | `prj-prd-gcp-xxxxx-host-m1np` | Model 1 Non-Production Shared VPC Host |
| **M3P Host** | `prj-prd-gcp-xxxxx-host-m3p` | Model 3 Production Shared VPC Host |
| **M3NP Host** | `prj-prd-gcp-xxxxx-host-m3np` | Model 3 Non-Production Shared VPC Host |
| **Networking** | `prj-prd-gcp-40036-mgmt-nethub` | NCC Hub + Platform VPCs (Transit, Security, Shared Services) |

## Shared VPCs

| VPC | Model | Environment | Description |
|-----|-------|-------------|-------------|
| `global-host-M1P-vpc` | Model 1 | Production | Internal/Private workloads |
| `global-host-M1NP-vpc` | Model 1 | Non-Prod | Internal/Private workloads |
| `global-host-M3P-vpc` | Model 3 | Production | DMZ/Public workloads |
| `global-host-M3NP-vpc` | Model 3 | Non-Prod | DMZ/Public workloads |

### Additional VPCs

- `global-transit-vpc` - SD-WAN and DNS services
- `global-security-vpc-data` - Palo Alto data plane
- `global-security-vpc-mgmt` - Palo Alto management
- `global-shared-svcs-vpc` - PSC endpoints

## Regions

- **AMER**: `us-east4`, `us-central1`
- **EMEA**: `europe-west3`, `europe-west1`
- **APAC**: `asia-southeast1`, `asia-east2`

## 🚀 Quick Start

### Prerequisites

1. **Previous stages completed**:
   - Stage 0: Bootstrap (`gcp-lz-0-bootstrap-tf`)
   - Stage 1: Resource Manager (`landing-zone-tf-main`)

2. **Required outputs** in `output_files/`:
   - `0-bootstrap-outputs.json`
   - `0-global-outputs.json`
   - `1-resman-outputs.json`

3. **GitHub Secrets configured**:
   - `WIF_PROVIDER` - Workload Identity Provider
   - `SERVICE_ACCOUNT` - Service account for Terraform
   - `OUTPUTS_BUCKET` - GCS bucket for stage outputs

### Local Development

```bash
# Clone repository
git clone <repo-url>
cd gcp-lz-2-networking-tf

# Download dependencies from previous stages
gcloud storage cp gs://<outputs-bucket>/outputs/0-bootstrap-outputs.json ./output_files/
gcloud storage cp gs://<outputs-bucket>/outputs/0-global-outputs.json ./output_files/
gcloud storage cp gs://<outputs-bucket>/outputs/1-resman-outputs.json ./output_files/

# Initialize Terraform
terraform init

# Review plan
terraform plan

# Apply (with approval)
terraform apply
```

## 📝 Configuration

### Network Projects Configuration

Edit `data/network-projects.yaml` to modify network project settings:

```yaml
network_projects:
  nethub:
    business_segment: "mgmt"
    team: "network-team"
    folder: "networking"
    deletion_policy: "PREVENT"
    services: [...]
    envs:
      prd:
        ad_group_number: "40036"
        shared_vpc_host: true
```

### Subnet Vending

Request new subnets via `data/network-subnets.yaml`:

```yaml
subnets:
  - region: "us-east4"
    model: "m1p"
    business_unit: "whq"
    application: "agtspace"
    size: "S"                    # S=/26, M=/25, L=/24
    cidr_block: "10.150.1.0/26"  # From Blue Cat IPAM
    cost_center: "109985"
    owner: "ai-platform_carrier_com"
    leanix_app_id: "app-05022"
```

**T-Shirt Sizing**:
- **Small (S)**: /26 = 64 IPs (default)
- **Medium (M)**: /25 = 128 IPs
- **Large (L)**: /24 = 256 IPs

## 🔐 Service Accounts

Each network project gets two service accounts:

- **`{project}-iac`**: Owner role for `terraform apply` operations
- **`{project}-iacr`**: Viewer role for `terraform plan` operations

## 🔄 Subnet Vending Workflow

1. **Request CIDR**: Contact network team or use APIGEE to get allocation from Blue Cat
2. **Create Branch**: `git checkout -b feature/add-subnet-{app}-{region}`
3. **Update YAML**: Add subnet configuration to `data/network-subnets.yaml`
4. **Commit & Push**: `git commit` and `git push`
5. **Create PR**: GitHub Actions runs `terraform plan`
6. **Review**: Check plan output for correctness
7. **Merge**: Subnet created automatically
8. **IPAM Updated**: Blue Cat records the allocation

## 🏗️ Infrastructure Resources

### Created by This Stage

✅ **Network Projects** (4 projects)
✅ **Service Accounts** (8 SAs: 4 owner + 4 viewer)
✅ **Shared VPCs** (4 VPCs for Models)
✅ **Transit & Security VPCs** (4 VPCs)
✅ **NCC Hub** (1 global hub)
✅ **NCC VPC Spokes** (8 spokes)
✅ **Subnet Vending Framework** (YAML-driven)

### To Be Added (Phase 2)

⏳ **Infrastructure Subnets** (PSC, ALB proxy, NAT)
⏳ **Cloud Routers** (per region)
⏳ **Cloud NAT** (per model per region)
⏳ **Router Appliances** (Cisco SD-WAN)
⏳ **Palo Alto Firewalls** (VM-Series MIGs)
⏳ **NSI Configuration** (In-band inspection)
⏳ **Blue Cat DNS** (VM deployment)

## 📊 Outputs

The stage produces `2-networking-outputs.json` with:

- Network project IDs and service accounts
- Shared VPC IDs and metadata
- NCC Hub and Spoke IDs
- Vended subnet information
- Region configuration

Outputs are stored in:
- **Local**: `output_files/2-networking-outputs.json` (if `outputs_location` set)
- **GCS**: `gs://<automation-bucket>/outputs/2-networking-outputs.json`

## 🔧 Development

### Running Tests

```bash
# Full test suite
make test

# Individual tests
make test-terraform    # Terraform validation
make test-security     # Security scans
make test-docs         # Documentation

# Format code
make format

# Security scanning
make security
```

### Pre-commit Hooks

```bash
# Install hooks
pre-commit install

# Run manually
pre-commit run --all-files
```

## 📚 Mandatory Tags

All resources must include:

- `cost_center` - For chargeback allocation
- `owner` - Responsible team/individual
- `application` - Application name
- `leanix_app_id` - Architecture inventory ID

## 🔗 Related Repositories

- [gcp-lz-0-bootstrap-tf](../gcp-lz-0-bootstrap-tf) - Stage 0: Bootstrap
- [landing-zone-tf-main](../landing-zone-tf-main) - Stage 1: Resource Manager
- [gcp-lz-3-security-tf](../gcp-lz-3-security-tf) - Stage 3: Security
- [gcp-lz-4-services-tf](../gcp-lz-4-services-tf) - Stage 4: Services

## 📖 Documentation

- [Technical Design Document (TDD)](docs/TDD.md)
- [Low-Level Design (LLD)](docs/LLD.md)
- [Subnet Vending Guide](docs/SUBNET_VENDING.md)
- [NCC Configuration](docs/NCC.md)
- [NSI Setup](docs/NSI.md)

## 🤝 Contributing

1. Create feature branch
2. Make changes
3. Run tests: `make test`
4. Create pull request
5. Wait for CI/CD checks
6. Merge after approval

## 📜 License

Copyright 2024 Google LLC

Licensed under the Apache License, Version 2.0

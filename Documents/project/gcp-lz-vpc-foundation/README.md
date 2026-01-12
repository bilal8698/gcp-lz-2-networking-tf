# GCP Landing Zone - VPC Foundation Module

Terraform module for creating the foundational VPC infrastructure per Carrier LLD v1.0.

## Overview

This module creates 8 VPCs across 6 regions with complete networking infrastructure:

### Model VPCs (Shared Services Project)
- **global-host-m1p-vpc** - Model 1 Production (6 subnets, /16 reserved pools)
- **global-host-m1np-vpc** - Model 1 Non-Production (6 subnets, /16 reserved pools)
- **global-host-m3p-vpc** - Model 3 Production (6 subnets, /16 or /17 reserved pools)
- **global-host-m3np-vpc** - Model 3 Non-Production (6 subnets, /16 or /17 reserved pools)

### Infrastructure VPCs
- **global-transit-vpc** (network-transit project) - SD-WAN, BlueCat DNS, Cloud Routers
- **global-security-vpc-data** (network-security project) - Palo Alto data plane
- **global-security-vpc-mgmt** (network-security project) - Palo Alto management plane
- **global-shared-svcs-vpc** (shared-host-pvpc project) - PSC endpoints

## Architecture

```
Carrier GCP Network Foundation
├── Model VPCs (shared-services)
│   ├── M1P  - 6 regions x /16 reserved pools
│   ├── M1NP - 6 regions x /16 reserved pools
│   ├── M3P  - 6 regions x /16 or /17 reserved pools
│   └── M3NP - 6 regions x /16 or /17 reserved pools
│
├── Infrastructure VPCs
│   ├── Transit (network-transit)
│   │   ├── 6 subnets (10.154.0-5.0/24)
│   │   ├── Cloud Routers (ASN 16550)
│   │   └── Cloud NAT
│   │
│   ├── Security Data (network-security)
│   │   └── 6 subnets (10.154.8-13.0/24)
│   │
│   ├── Security Mgmt (network-security)
│   │   ├── 6 subnets (10.154.16-21.0/24)
│   │   └── Cloud NAT
│   │
│   └── Shared Services (shared-host-pvpc)
│       ├── 6 subnets (10.154.32-37.0/24)
│       └── Cloud NAT
│
└── Regions: us-east4, us-central1, europe-west1, 
             europe-west3, asia-east2, asia-southeast1
```

## Features

- ✅ **8 VPCs** across 6 regions (48 subnets total)
- ✅ **Cloud Routers** in all regions (ASN 16550 for Transit)
- ✅ **Cloud NAT** for internet connectivity
- ✅ **Service Accounts** with Viewer IAM bindings (one per project)
- ✅ **YAML-driven configuration** following Vijay's pattern
- ✅ **Flow logs** enabled on all subnets
- ✅ **Global routing** mode for all VPCs
- ✅ **Reserved pool allocation** for Model VPCs (BlueCat IPAM integration)

## Prerequisites

1. **GCP Projects** must exist:
   - `shared-services`
   - `network-transit`
   - `network-security`
   - `shared-host-pvpc`

2. **IAM Permissions**:
   - `compute.networks.create`
   - `compute.subnetworks.create`
   - `compute.routers.create`

3. **Terraform**:
   - Version >= 1.5.0
   - Google Provider ~> 5.0

## Usage

### Basic Deployment

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### Custom Configuration

Edit YAML files in `data/` directory:

```yaml
# data/model-vpcs-config.yaml
model_vpcs:
  m1p:
    vpc_name: global-host-m1p-vpc
    project_id: shared-services
    subnets:
      - name: useast4-m1p-reserved-pool
        region: us-east4
        ip_cidr_range: 10.150.0.0/16
```

## Configuration Files

| File | Purpose |
|------|---------|
| `data/model-vpcs-config.yaml` | M1P, M1NP, M3P, M3NP VPC configurations |
| `data/infrastructure-vpcs-config.yaml` | Transit, Security, Shared Services configurations |
| `data/service-accounts-config.yaml` | Service accounts with IAM role bindings |
| `terraform/main.tf` | Main orchestration |
| `terraform/locals.tf` | YAML processing and data structures |
| `terraform/variables.tf` | Input variables |
| `terraform/outputs.tf` | Output values |

## Modules

### VPC Module (`modules/vpc/`)
Creates VPC with subnets and flow logs.

### Cloud Router Module (`modules/cloud-router/`)
Creates Cloud Routers for BGP and Cloud NAT.

### Cloud NAT Module (`modules/cloud-nat/`)
Creates Cloud NAT for internet connectivity.

### Service Account Module (`modules/service-account/`)
Creates service accounts for IAM management.

### IAM Binding Module (`modules/iam-binding/`)
Grants IAM roles to service accounts.

## Outputs

```hcl
# VPC Outputs
vpc_ids                 # Map of VPC keys to IDs
vpc_self_links          # Map of VPC keys to self-links
vpc_names               # Map of VPC keys to names

# Subnet Outputs
subnet_ids              # Map of VPC keys to subnet IDs
subnet_self_links       # Map of VPC keys to subnet self-links
subnet_regions          # Map of VPC keys to subnet regions

# Cloud Router Outputs
cloud_router_ids        # Map of router keys to IDs
cloud_router_names      # Map of router keys to names

# Cloud NAT Outputs
cloud_nat_ids           # Map of NAT keys to IDs
cloud_nat_names         # Map of NAT keys to names

# Service Account Outputs
service_account_emails  # Map of SA keys to emails
service_account_ids     # Map of SA keys to IDs

# Summary
resource_summary        # Summary of all resources created
vpc_details_for_ncc     # Formatted for NCC Hub-Spoke module
```

## Integration with Other Modules

### NCC Hub-Spoke Module
```hcl
module "vpc_foundation" {
  source = "./gcp-lz-vpc-foundation/terraform"
}

module "ncc_hub_spoke" {
  source = "./gcp-lz-ncc-hub-spoke/terraform"
  
  # Use VPC Foundation outputs
  vpc_details = module.vpc_foundation.vpc_details_for_ncc
}
```

## Deployment Phases

### Phase 1: Foundation VPCs (This Module)
1. Create all 8 VPCs
2. Create subnets in all regions
3. Deploy Cloud Routers
4. Configure Cloud NAT

### Phase 2: NCC Hub-Spoke
1. Create NCC Hub
2. Attach VPC spokes
3. Attach Router Appliance spoke

### Phase 3: Security (NSI)
1. Deploy Palo Alto firewalls
2. Configure ILB
3. Implement NSI policies

## CIDR Allocation

### Model VPCs (Reserved Pools)
Subnets are vended dynamically by BlueCat IPAM from these pools:

| VPC | US-East4 | US-Central1 | EU-West1 | EU-West3 | Asia-East2 | Asia-SE1 |
|-----|----------|-------------|----------|----------|------------|----------|
| M1P | 10.150/16 | 10.100/16 | 10.177/16 | 10.173/16 | 10.115/16 | 10.109/16 |
| M1NP | 10.151/16 | 10.101/16 | 10.178/16 | 10.174/16 | 10.116/16 | 10.110/16 |
| M3P | 10.152/16 | 10.102/16 | 10.179.0/17 | 10.175.0/17 | 10.117.0/17 | 10.111.0/17 |
| M3NP | 10.153/16 | 10.103/16 | 10.179.128/17 | 10.175.128/17 | 10.117.128/17 | 10.111.0/17 |

### Infrastructure VPCs (/24 Subnets)
| VPC | US-East4 | US-Central1 | EU-West1 | EU-West3 | Asia-East2 | Asia-SE1 |
|-----|----------|-------------|----------|----------|------------|----------|
| Transit | 10.154.0/24 | 10.154.1/24 | 10.154.2/24 | 10.154.3/24 | 10.154.4/24 | 10.154.5/24 |
| Security Data | 10.154.8/24 | 10.154.9/24 | 10.154.10/24 | 10.154.11/24 | 10.154.12/24 | 10.154.13/24 |
| Security Mgmt | 10.154.16/24 | 10.154.17/24 | 10.154.18/24 | 10.154.19/24 | 10.154.20/24 | 10.154.21/24 |
| Shared Svcs | 10.154.32/24 | 10.154.33/24 | 10.154.34/24 | 10.154.35/24 | 10.154.36/24 | 10.154.37/24 |

## Naming Conventions

Per Carrier LLD v1.0:

- **VPCs**: `global-{type}-vpc` or `global-host-{model}-vpc`
- **Subnets**: `{region}-{model|type}-{purpose}-subnet` or `{region}-{model}-reserved-pool`
- **Cloud Routers**: `{region}-cr1` (e.g., `useast4-cr1`)
- **Cloud NAT**: `{region}-{model|type}-cnat1` (e.g., `useast4-m1p-cnat1`)

## Troubleshooting

### Issue: Terraform state conflicts
```bash
terraform state list
terraform import google_compute_network.vpc projects/{project}/global/networks/{vpc-name}
```

### Issue: Project not found
Verify project IDs in YAML files match existing projects.

### Issue: Quota exceeded
Request quota increase for:
- VPC networks
- Subnetworks
- Cloud Routers
- Cloud NAT

## Next Steps

After deploying VPCs:

1. **Deploy NCC Hub-Spoke** (`gcp-lz-ncc-hub-spoke/`)
2. **Deploy Palo Alto Firewalls** (`gcp-palo-alto-bootstrap/`)
3. **Configure NSI Policies**
4. **Deploy BlueCat DNS**
5. **Configure Shared VPC Host/Service Projects**

## Support

- LLD Reference: Carrier LLD v1.0
- Cloud Foundation Fabric: v45.0.0
- Module Pattern: Vijay's YAML-driven approach

## License

Carrier Confidential

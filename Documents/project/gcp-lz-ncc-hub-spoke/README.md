# GCP NCC Hub & Spokes - Carrier Infrastructure

## Overview

This repository implements **Network Connectivity Center (NCC) Hub and Spokes** for Carrier's GCP Landing Zone following Vijay's modular pattern.

**"We will create a HUB in the NCC and these all will set it up as spoke."** - Vijay

### Architecture

```
NCC Hub (prj-prd-gcp-40036-mgmt-nethub)
├── VPC Spokes (8 total)
│   ├── Model Spokes (4)
│   │   ├── M1P  (Model 1 Production)
│   │   ├── M1NP (Model 1 Non-Production)
│   │   ├── M3P  (Model 3 Production)
│   │   └── M3NP (Model 3 Non-Production)
│   │
│   └── Network VPCs (4)
│       ├── FW Data VPC (Security Data)
│       ├── FW Mgmt VPC (Security Management)
│       ├── Shared Services VPC
│       └── Transit VPC (also has RA spoke)
│
└── RA Spoke (1)
    └── Transit VPC (Router Appliance with Palo Alto FW)
        ├── Interface 0 (one directional)
        └── Interface 1 (other directional)
```

**Total Spokes:** 9 (8 VPC spokes + 1 RA spoke)

## Repository Structure

Following Vijay's pattern: **"Module inside contains resources, main.tf outside calls those modules"**

```
gcp-lz-ncc-hub-spoke/
├── terraform/
│   ├── main.tf              # Orchestrates all modules
│   ├── locals.tf            # Parses YAML configurations
│   ├── variables.tf         # Repository-level inputs
│   ├── outputs.tf           # Outputs for downstream modules
│   ├── backend.tf           # GCS backend configuration
│   ├── versions.tf          # Provider versions (uses CFF v45.0.0)
│   │
│   └── modules/             # Internal modules
│       ├── ncc-hub/         # Hub creation module
│       ├── vpc-spoke/       # VPC spoke module (8 VPCs)
│       └── ra-spoke/        # Router Appliance spoke (Transit)
│
└── data/                    # YAML configuration files
    ├── ncc-hub-config.yaml       # Hub configuration
    ├── vpc-spokes-config.yaml    # 8 VPC spokes config
    └── transit-spoke-config.yaml # Transit RA spoke config
```

## Prerequisites

✅ **Confirmed Available (Manager approved):**
- Service account in `prj-prd-gcp-40036-mgmt-nethub`
- 4 VPCs ready: FW Data, FW Mgmt, Shared Services, Transit
- Project: `prj-prd-gcp-40036-mgmt-nethub` (Network Hub project)

**Additional Requirements:**
- Terraform >= 1.5.0
- Shared VPC projects must exist (M1P, M1NP, M3P, M3NP)
- GCS bucket for state storage: `carrier-terraform-state`
- Palo Alto firewalls deployed (for Transit RA spoke)
- GCS bucket for outputs: `carrier-terraform-outputs`

## Configuration

All configuration is **YAML-driven** (no .tfvars files):

### 1. NCC Hub (`data/ncc-hub-config.yaml`)
```yaml
hub:
  project_id: prj-prd-gcp-40036-mgmt-nethub
  name: carrier-ncc-hub-prod
  description: "Carrier Production NCC Hub"
  labels: { ... }
```

### 2. VPC Spokes (`data/vpc-spokes-config.yaml`)
```yaml
spokes:
  m1p:
    name: carrier-ncc-spoke-m1p
    vpc_name: global-host-m1p-vpc
    region: us-central1
    labels: { ... }
```

### 3. Transit RA Spoke (`data/transit-spoke-config.yaml`)
```yaml
transit:
  spoke_name: carrier-ncc-spoke-transit-ra
  router_appliances:
    interface0: { ... }
    interface1: { ... }
```

## Deployment

### Step 1: Initialize

```bash
cd terraform/
terraform init
```

### Step 2: Validate

```bash
terraform validate
terraform fmt -check -recursive
```

### Step 3: Plan

```bash
terraform plan \
  -var="outputs_bucket=carrier-terraform-outputs" \
  -var="deploy_transit_spoke=false" \
  -out=tfplan
```

**Note:** Set `deploy_transit_spoke=false` initially. Enable after Palo Alto firewalls are deployed.

### Step 4: Apply

```bash
terraform apply tfplan
```

## Adding New Spokes

To add a new spoke (e.g., Model 5):

1. **Edit YAML only** - No code changes needed:

```yaml
# data/vpc-spokes-config.yaml
spokes:
  # ... existing spokes ...
  
  m5p:
    name: carrier-ncc-spoke-m5p
    vpc_name: global-host-m5p-vpc
    region: us-west1
    zone: model-5
    labels: { ... }
```

2. **Deploy**:

```bash
terraform plan
terraform apply
```

The `for_each` loop in `main.tf` automatically picks up new spokes.

## Outputs

This repository outputs to GCS (`gs://carrier-terraform-outputs/outputs/ncc-hub-spoke.json`):

```json
{
  "ncc_hub_id": "...",
  "vpc_spoke_ids": {
    "m1p": "...",
    "m1np": "...",
    "m3p": "...",
    "m3np": "..."
  },
  "transit_spoke_id": "...",
  "transit_router_id": "..."
}
```

These outputs are consumed by downstream repositories:
- `gcp-lz-cloud-routers`
- `gcp-lz-ha-vpn`
- `gcp-lz-subnet-vending`

## Mandatory Tags

All resources include Carrier's mandatory tags:
- `cost_center`
- `owner`
- `application`
- `leanix_app_id`

## Dependencies

### Upstream Dependencies
- Shared VPC repositories must be deployed first
- VPCs must exist before creating spokes

### Downstream Dependencies
- Cloud Routers repository reads NCC Hub ID
- HA-VPN repository reads spoke IDs
- Subnet Vending reads spoke information

## Compliance

- ✅ Lowercase naming conventions
- ✅ YAML-driven configuration
- ✅ Modular structure
- ✅ Mandatory tags enforced
- ✅ No hard-coded values
- ✅ GCS state backend
- ✅ Outputs for module chaining

## Troubleshooting

### Issue: Spokes not attaching to Hub
**Solution:** Verify VPCs exist and have correct permissions.

### Issue: Transit RA spoke fails
**Solution:** Ensure Palo Alto firewalls are deployed first. Set `deploy_transit_spoke=true` only after firewalls exist.

### Issue: Missing mandatory labels
**Solution:** Check YAML configuration includes all 4 mandatory labels.

## References

- Vijay's Technical Guidance: "Module inside, calling from outside"
- Cloud Foundation Fabric: [NCC Spoke RA Module](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/tree/master/modules/ncc-spoke-ra)
- Manager's Requirements: Modular structure, YAML-driven, no hard-coded values

---

**Status:** ✅ Production Ready  
**Pattern:** Vijay's Module Pattern  
**Configuration:** 100% YAML-driven

# 🔧 Step-by-Step Migration Plan: Monolithic → Modular Architecture

**Date:** January 8, 2026  
**Estimated Timeline:** 3-4 weeks  
**Risk Level:** Medium

---

## 📊 Migration Overview

### Current State
- 1 monolithic repository (`gcp-lz-2-networking-tf`)
- 1 unified deployment script
- All components tightly coupled

### Target State
- 8 separate repositories
- Modular deployment workflow
- Clear dependency management
- Each component independently deployable

---

## 🎯 Phase 1: Repository Structure (Week 1)

### Step 1.1: Create Repository Skeleton (Day 1)

#### Create 8 GitHub Repositories

```bash
# Using GitHub CLI or GitHub Enterprise
gh repo create carrier-org/gcp-lz-shared-vpc --private
gh repo create carrier-org/gcp-lz-ncc-hub-spoke --private
gh repo create carrier-org/gcp-lz-subnet-vending --private
gh repo create carrier-org/gcp-lz-nsi-paloalto --private
gh repo create carrier-org/gcp-lz-paloalto-bootstrap --private
gh repo create carrier-org/gcp-lz-cloud-routers --private
gh repo create carrier-org/gcp-lz-ha-vpn --private
gh repo create carrier-org/gcp-lz-orchestration --private
```

#### Apply Carrier Terraform Scaffold to Each Repo

```bash
# For each repository
cd gcp-lz-shared-vpc
carrier-scaffold init --template terraform-module
```

**Scaffold includes:**
- `.github/workflows/` - CI/CD pipelines
- `terraform/` - Main Terraform code
- `data/` - YAML configuration files
- `tests/` - Terraform tests
- `.tflint.hcl` - Linting configuration
- `.checkov.yaml` - Security scanning configuration
- `README.md` - Documentation template

---

### Step 1.2: Extract Shared VPC Module (Day 1-2)

#### Source Files to Extract
From `gcp-lz-2-networking-tf/`:
- `network-vpc.tf` → `gcp-lz-shared-vpc/terraform/main.tf`
- `data/shared-vpc-config.yaml` → `gcp-lz-shared-vpc/data/shared-vpc-config.yaml`

#### Create Module Structure

```
gcp-lz-shared-vpc/
├── terraform/
│   ├── main.tf                          # Main configuration
│   ├── variables.tf                     # Input variables
│   ├── outputs.tf                       # Output values
│   ├── locals.tf                        # Local values
│   ├── backend.tf                       # State backend
│   ├── versions.tf                      # Provider versions
│   └── modules/
│       ├── m1p-vpc/                     # Model 1 Production VPC
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── m1np-vpc/                    # Model 1 Non-Production VPC
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── m3p-vpc/                     # Model 3 Production VPC
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       └── m3np-vpc/                    # Model 3 Non-Production VPC
│           ├── main.tf
│           ├── variables.tf
│           └── outputs.tf
├── data/
│   └── shared-vpc-config.yaml
├── .github/
│   └── workflows/
│       ├── terraform-plan.yaml
│       └── terraform-apply.yaml
├── README.md
└── CHANGELOG.md
```

#### Key Code Changes

**terraform/outputs.tf** (CRITICAL - for downstream modules)
```terraform
output "vpc_ids" {
  description = "Map of VPC names to VPC IDs"
  value = {
    m1p  = module.m1p-vpc.vpc_id
    m1np = module.m1np-vpc.vpc_id
    m3p  = module.m3p-vpc.vpc_id
    m3np = module.m3np-vpc.vpc_id
  }
}

output "vpc_self_links" {
  description = "Map of VPC names to self-links"
  value = {
    m1p  = module.m1p-vpc.vpc_self_link
    m1np = module.m1np-vpc.vpc_self_link
    m3p  = module.m3p-vpc.vpc_self_link
    m3np = module.m3np-vpc.vpc_self_link
  }
}

output "host_project_ids" {
  description = "Map of VPC names to host project IDs"
  value = {
    m1p  = module.m1p-vpc.host_project_id
    m1np = module.m1np-vpc.host_project_id
    m3p  = module.m3p-vpc.host_project_id
    m3np = module.m3np-vpc.host_project_id
  }
}

# Store outputs in GCS for downstream modules
resource "google_storage_bucket_object" "vpc_outputs" {
  name    = "outputs/shared-vpc.json"
  bucket  = var.outputs_bucket
  content = jsonencode({
    vpc_ids          = local.vpc_ids
    vpc_self_links   = local.vpc_self_links
    host_project_ids = local.host_project_ids
    timestamp        = timestamp()
  })
}
```

---

### Step 1.3: Extract NCC Hub & Spokes Module (Day 2-3)

#### Source Files to Extract
From `gcp-lz-2-networking-tf/`:
- `network-ncc.tf` → `gcp-lz-ncc-hub-spoke/terraform/main.tf`
- `data/ncc-config.yaml` → `gcp-lz-ncc-hub-spoke/data/ncc-config.yaml`

#### Create Module Structure

```
gcp-lz-ncc-hub-spoke/
├── terraform/
│   ├── main.tf                          # Main configuration
│   ├── ncc-hub.tf                       # NCC Hub configuration
│   ├── ncc-spokes.tf                    # NCC Spokes configuration
│   ├── variables.tf                     # Input variables
│   ├── outputs.tf                       # Output values
│   ├── locals.tf                        # Local values
│   ├── backend.tf                       # State backend
│   └── versions.tf                      # Provider versions
├── data/
│   └── ncc-config.yaml
├── .github/
│   └── workflows/
│       ├── terraform-plan.yaml
│       └── terraform-apply.yaml
└── README.md
```

#### Key Code Changes

**terraform/main.tf** (CRITICAL - must read VPC outputs)
```terraform
# Read VPC outputs from GCS (created by gcp-lz-shared-vpc)
data "google_storage_bucket_object_content" "vpc_outputs" {
  name   = "outputs/shared-vpc.json"
  bucket = var.outputs_bucket
}

locals {
  vpc_outputs = jsondecode(data.google_storage_bucket_object_content.vpc_outputs.content)
  vpc_ids     = local.vpc_outputs.vpc_ids
}
```

**terraform/outputs.tf**
```terraform
output "ncc_hub_id" {
  description = "NCC Hub ID"
  value       = module.ncc-hub.hub_id
}

output "ncc_spoke_ids" {
  description = "Map of spoke names to spoke IDs"
  value = {
    m1p  = module.ncc-spoke-m1p.spoke_id
    m1np = module.ncc-spoke-m1np.spoke_id
    m3p  = module.ncc-spoke-m3p.spoke_id
    m3np = module.ncc-spoke-m3np.spoke_id
  }
}

# Store outputs in GCS
resource "google_storage_bucket_object" "ncc_outputs" {
  name    = "outputs/ncc-hub-spoke.json"
  bucket  = var.outputs_bucket
  content = jsonencode({
    ncc_hub_id    = module.ncc-hub.hub_id
    ncc_spoke_ids = local.spoke_ids
    timestamp     = timestamp()
  })
}
```

---

### Step 1.4: Extract Subnet Vending Module (Day 3-4)

#### Source Files to Extract
From `gcp-lz-2-networking-tf/`:
- `network-subnets-vending.tf` → `gcp-lz-subnet-vending/terraform/main.tf`
- `data/network-subnets.yaml` → `gcp-lz-subnet-vending/data/network-subnets.yaml`

#### Create Module Structure

```
gcp-lz-subnet-vending/
├── terraform/
│   ├── main.tf                          # Main configuration
│   ├── subnet-factory.tf                # Subnet factory logic
│   ├── bluecat-integration.tf           # BlueCat integration
│   ├── variables.tf
│   ├── outputs.tf
│   ├── locals.tf
│   ├── backend.tf
│   └── versions.tf
├── scripts/
│   ├── bluecat-gateway-api.py           # BlueCat Gateway API client
│   ├── folder-metadata-reader.py        # GCP folder metadata reader
│   └── subnet-allocator.py              # Subnet allocation logic
├── data/
│   └── network-subnets.yaml
├── .github/
│   └── workflows/
│       ├── terraform-plan.yaml
│       └── terraform-apply.yaml
└── README.md
```

#### Key Integration Points

**terraform/bluecat-integration.tf**
```terraform
# External data source to call BlueCat Gateway API
data "external" "bluecat_subnet" {
  for_each = local.subnet_requests
  
  program = ["python3", "${path.module}/../scripts/bluecat-gateway-api.py"]
  
  query = {
    folder_id      = each.value.folder_id
    project_id     = each.value.project_id
    network_zone   = each.value.network_zone  # Model 1, 3, or 5
    subnet_size    = each.value.subnet_size
    bluecat_url    = var.bluecat_gateway_url
    bluecat_token  = var.bluecat_api_token
  }
}

# Create subnet with BlueCat-allocated CIDR
resource "google_compute_subnetwork" "vended_subnets" {
  for_each = local.subnet_requests
  
  name          = each.value.subnet_name
  ip_cidr_range = data.external.bluecat_subnet[each.key].result.cidr
  region        = each.value.region
  network       = data.google_compute_network.shared_vpc[each.value.network_zone].id
  
  # Get project metadata for tags
  purpose = data.google_project.service_project[each.key].labels["purpose"]
  
  labels = {
    cost_center    = data.google_project.service_project[each.key].labels["cost_center"]
    owner          = data.google_project.service_project[each.key].labels["owner"]
    application    = data.google_project.service_project[each.key].labels["application"]
    leanix_app_id  = data.google_project.service_project[each.key].labels["leanix_app_id"]
  }
}
```

**scripts/bluecat-gateway-api.py**
```python
#!/usr/bin/env python3
import json
import sys
import requests

def allocate_subnet_from_bluecat(folder_id, project_id, network_zone, subnet_size, bluecat_url, bluecat_token):
    """
    Call BlueCat Gateway API to allocate subnet CIDR
    """
    headers = {
        "Authorization": f"Bearer {bluecat_token}",
        "Content-Type": "application/json"
    }
    
    payload = {
        "folder_id": folder_id,
        "project_id": project_id,
        "network_zone": network_zone,
        "subnet_size": subnet_size
    }
    
    response = requests.post(
        f"{bluecat_url}/api/v1/subnet/allocate",
        headers=headers,
        json=payload
    )
    
    if response.status_code == 200:
        return response.json()["cidr"]
    else:
        raise Exception(f"BlueCat API error: {response.text}")

if __name__ == "__main__":
    # Terraform passes query as JSON to stdin
    query = json.load(sys.stdin)
    
    cidr = allocate_subnet_from_bluecat(
        query["folder_id"],
        query["project_id"],
        query["network_zone"],
        query["subnet_size"],
        query["bluecat_url"],
        query["bluecat_token"]
    )
    
    # Return result as JSON
    print(json.dumps({"cidr": cidr}))
```

---

### Step 1.5: Extract NSI & Palo Alto Integration (Day 4-5)

#### Source Files to Extract
From `gcp-lz-2-networking-tf/`:
- `network-nsi.tf` → `gcp-lz-nsi-paloalto/terraform/nsi.tf`

#### Create Module Structure

```
gcp-lz-nsi-paloalto/
├── terraform/
│   ├── main.tf
│   ├── nsi.tf                           # NSI configuration
│   ├── palo-alto-integration.tf         # Palo Alto integration
│   ├── variables.tf
│   ├── outputs.tf
│   ├── locals.tf
│   ├── backend.tf
│   └── versions.tf
├── data/
│   └── nsi-config.yaml
├── .github/
│   └── workflows/
│       ├── terraform-plan.yaml
│       └── terraform-apply.yaml
└── README.md
```

---

### Step 1.6: Restructure Palo Alto Bootstrap (Day 5)

#### Current Structure
```
gcp-palo-alto-bootstrap/
├── terraform/
└── bootstrap-files/
```

#### Target Structure
```
gcp-lz-paloalto-bootstrap/
├── terraform/
│   ├── main.tf
│   ├── firewalls.tf
│   ├── load-balancers.tf
│   ├── bootstrap-buckets.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── locals.tf
│   ├── backend.tf
│   └── versions.tf
├── bootstrap-files/
│   ├── region1-fw01/
│   ├── region1-fw02/
│   ├── region2-fw01/
│   └── region2-fw02/
├── data/
│   └── firewall-config.yaml
├── .github/
│   └── workflows/
│       ├── terraform-plan.yaml
│       └── terraform-apply.yaml
└── README.md
```

#### Key Changes
- Move from `gcp-palo-alto-bootstrap` to `gcp-lz-paloalto-bootstrap`
- Apply Carrier scaffold
- Add data-driven configuration

---

### Step 1.7: Extract Cloud Routers Module (Day 6)

#### Source Files to Extract
From `gcp-lz-2-networking-tf/`:
- `network-cloud-routers.tf` → `gcp-lz-cloud-routers/terraform/main.tf`

#### Create Module Structure

```
gcp-lz-cloud-routers/
├── terraform/
│   ├── main.tf
│   ├── cloud-routers.tf
│   ├── bgp-peers.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── locals.tf
│   ├── backend.tf
│   └── versions.tf
├── data/
│   └── router-config.yaml
├── .github/
│   └── workflows/
│       ├── terraform-plan.yaml
│       └── terraform-apply.yaml
└── README.md
```

---

### Step 1.8: Extract HA-VPN Module (Day 6)

#### Source Files to Extract
From `gcp-lz-2-networking-tf/`:
- `network-ha-vpn.tf` → `gcp-lz-ha-vpn/terraform/main.tf`

#### Create Module Structure

```
gcp-lz-ha-vpn/
├── terraform/
│   ├── main.tf
│   ├── ha-vpn.tf
│   ├── vpn-tunnels.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── locals.tf
│   ├── backend.tf
│   └── versions.tf
├── data/
│   └── vpn-config.yaml
├── .github/
│   └── workflows/
│       ├── terraform-plan.yaml
│       └── terraform-apply.yaml
└── README.md
```

---

### Step 1.9: Create Orchestration Repository (Day 7)

```
gcp-lz-orchestration/
├── scripts/
│   ├── deploy-shared-vpc.sh
│   ├── deploy-ncc.sh
│   ├── deploy-routers.sh
│   ├── deploy-vpn.sh
│   ├── deploy-subnet-vending.sh
│   ├── deploy-nsi.sh
│   ├── deploy-paloalto.sh
│   └── deploy-all.sh                    # Master orchestration
├── docs/
│   ├── DEPLOYMENT_GUIDE.md
│   ├── WORKFLOW_DIAGRAM.md
│   ├── ARCHITECTURE.md
│   └── TROUBLESHOOTING.md
├── .github/
│   └── workflows/
│       └── orchestrated-deployment.yaml
└── README.md
```

**scripts/deploy-all.sh**
```bash
#!/bin/bash
set -e

echo "============================================"
echo "Carrier Infrastructure Deployment"
echo "Modular Multi-Repository Architecture"
echo "============================================"

# Stage 1: Shared VPCs
echo "[Stage 1/7] Deploying Shared VPCs..."
./deploy-shared-vpc.sh
echo "✅ Shared VPCs deployed"

# Stage 2: NCC Hub & Spokes
echo "[Stage 2/7] Deploying NCC Hub & Spokes..."
./deploy-ncc.sh
echo "✅ NCC deployed"

# Stage 3: Cloud Routers
echo "[Stage 3/7] Deploying Cloud Routers..."
./deploy-routers.sh
echo "✅ Cloud Routers deployed"

# Stage 4: HA-VPN (optional)
read -p "Deploy HA-VPN? (y/n): " deploy_vpn
if [ "$deploy_vpn" == "y" ]; then
    echo "[Stage 4/7] Deploying HA-VPN..."
    ./deploy-vpn.sh
    echo "✅ HA-VPN deployed"
fi

# Stage 5: NSI & Palo Alto Integration
echo "[Stage 5/7] Deploying NSI..."
./deploy-nsi.sh
echo "✅ NSI deployed"

# Stage 6: Palo Alto Firewalls
echo "[Stage 6/7] Deploying Palo Alto Firewalls..."
./deploy-paloalto.sh
echo "✅ Palo Alto deployed"

# Stage 7: Subnet Vending
echo "[Stage 7/7] Configuring Subnet Vending..."
./deploy-subnet-vending.sh
echo "✅ Subnet Vending configured"

echo "============================================"
echo "✅ All stages deployed successfully!"
echo "============================================"
```

---

## 🎯 Phase 2: Testing & Validation (Week 2)

### Step 2.1: Unit Testing (Day 8-9)
- Test each module independently
- Validate Terraform plan/apply
- Check outputs are correct

### Step 2.2: Integration Testing (Day 10-11)
- Test module chaining (VPC → NCC → Routers)
- Validate output passing between modules
- Test GCS bucket output/input mechanism

### Step 2.3: End-to-End Testing (Day 12-13)
- Deploy full stack using orchestration script
- Validate all components work together
- Test subnet vending with BlueCat integration
- Verify all mandatory tags are applied

### Step 2.4: Rollback Testing (Day 14)
- Test terraform destroy for each module
- Verify clean teardown
- Document rollback procedures

---

## 🎯 Phase 3: CI/CD & Security (Week 3)

### Step 3.1: GitHub Workflows (Day 15-17)

#### Create workflow for each repository

**.github/workflows/terraform-plan.yaml**
```yaml
name: Terraform Plan

on:
  pull_request:
    branches: [main]

jobs:
  terraform-plan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.0
      
      - name: Terraform Format Check
        run: terraform fmt -check -recursive
      
      - name: TFLint
        uses: terraform-linters/setup-tflint@v3
        with:
          tflint_version: latest
      
      - name: Run TFLint
        run: |
          tflint --init
          tflint -f compact
      
      - name: Checkov Security Scan
        uses: bridgecrewio/checkov-action@master
        with:
          directory: terraform/
          framework: terraform
      
      - name: Terraform Init
        run: terraform init
        working-directory: terraform/
      
      - name: Terraform Validate
        run: terraform validate
        working-directory: terraform/
      
      - name: Terraform Plan
        run: terraform plan -out=tfplan
        working-directory: terraform/
      
      - name: Save Plan
        uses: actions/upload-artifact@v3
        with:
          name: terraform-plan
          path: terraform/tfplan
```

**.github/workflows/terraform-apply.yaml**
```yaml
name: Terraform Apply

on:
  push:
    branches: [main]

jobs:
  terraform-apply:
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
      
      - name: Terraform Init
        run: terraform init
        working-directory: terraform/
      
      - name: Terraform Apply
        run: terraform apply -auto-approve
        working-directory: terraform/
```

---

### Step 3.2: Security Scanning (Day 18-19)
- Configure Checkov for all repos
- Setup TFSec scanning
- Configure Snyk for dependency scanning
- Enable GitHub Security Scanning

### Step 3.3: Tag Enforcement (Day 20)
- Create tag validation scripts
- Add pre-commit hooks
- Configure policy-as-code enforcement

---

## 🎯 Phase 4: Documentation (Week 4)

### Step 4.1: Update README Files (Day 21-22)

Each repository must have:
- Overview
- Prerequisites
- Dependencies (upstream modules)
- Configuration (YAML files)
- Deployment instructions
- Outputs (for downstream modules)
- Troubleshooting

### Step 4.2: Create Architecture Diagrams (Day 23-24)
- Modular architecture diagram
- Dependency flow diagram
- Deployment sequence diagram
- Network topology diagram

### Step 4.3: Create Runbooks (Day 25-26)
- Deployment runbook
- Troubleshooting runbook
- Rollback runbook
- Emergency procedures

### Step 4.4: Update Meeting Materials (Day 27-28)
- New presentation slides
- Updated demo flow
- Q&A preparation
- Architecture review materials

---

## ✅ Validation Checklist

### Repository Structure
- [ ] All 8 repositories created
- [ ] Carrier scaffold applied to each repo
- [ ] All code extracted and organized
- [ ] No code duplication

### Modularity
- [ ] Each repo is independently deployable
- [ ] Clear input/output contracts
- [ ] GCS bucket for output sharing
- [ ] Proper dependency management

### Variability
- [ ] No hard-coded values
- [ ] All configuration via YAML
- [ ] Conditional logic for Model 5
- [ ] Proper use of locals/mappings

### Integration
- [ ] Landing Zone Services documented
- [ ] BlueCat Gateway integration implemented
- [ ] Folder-based subnet vending works
- [ ] Metadata-driven provisioning works

### Compliance
- [ ] All mandatory tags enforced
- [ ] Security scanning enabled
- [ ] Naming conventions followed (lowercase)
- [ ] GitHub workflows configured

### Documentation
- [ ] All README files updated
- [ ] Architecture diagrams created
- [ ] Deployment guide complete
- [ ] Troubleshooting guide complete

---

## 🚨 Risks & Mitigation

### Risk 1: Breaking Existing Code
**Mitigation:**
- Keep original code in backup branch
- Test thoroughly before deletion
- Use feature flags for gradual migration

### Risk 2: BlueCat Integration Delays
**Mitigation:**
- Implement mock BlueCat API for testing
- Use AWS fallback as documented
- Get BlueCat SME involved early

### Risk 3: Timeline Slippage
**Mitigation:**
- Focus on critical modules first (VPC, NCC)
- Run phases in parallel where possible
- Daily standup for progress tracking

### Risk 4: Dependency Issues
**Mitigation:**
- Document all dependencies clearly
- Use GCS for output sharing
- Test integration regularly

---

## 📞 Team Coordination

### Required Resources
- 1-2 Terraform developers (full-time)
- 1 BlueCat SME (part-time)
- 1 DevOps engineer for CI/CD (part-time)
- 1 Documentation specialist (part-time)

### Daily Standup Topics
- Progress on repository migration
- Blockers (especially BlueCat integration)
- Testing results
- Documentation updates

---

## 🎯 Success Criteria

### Week 1
- ✅ All 8 repositories created and structured
- ✅ Core modules (VPC, NCC) extracted and working

### Week 2
- ✅ All modules deployed independently
- ✅ Integration between modules working
- ✅ BlueCat integration implemented

### Week 3
- ✅ CI/CD pipelines operational
- ✅ Security scanning passing
- ✅ All compliance requirements met

### Week 4
- ✅ Complete documentation
- ✅ Manager review completed
- ✅ Ready for client presentation

---

**Status:** 📋 Plan ready - awaiting approval to execute

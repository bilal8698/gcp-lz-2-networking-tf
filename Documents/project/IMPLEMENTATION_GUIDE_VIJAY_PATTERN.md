# 🔧 Implementation Guide - Vijay's Module Pattern

**Date:** January 8, 2026  
**Based on:** Vijay's technical guidance  
**Purpose:** Exact implementation patterns for modular structure

---

## 🎯 Vijay's Core Pattern

### The Golden Rule
> "I had created the Module (inside the module) there are resources, locals whatever we are putting inside. Now, from outside we are calling those modules using main.tf or variables.tf or outputs.tf"

```
┌─────────────────────────────────────────┐
│  Repository Root                        │
│  ├── main.tf          ← Calls modules  │
│  ├── variables.tf                       │
│  ├── outputs.tf                         │
│  ├── data/            ← YAML configs    │
│  │   └── *.yaml                         │
│  └── modules/         ← Internal logic  │
│      └── [module]/                      │
│          ├── main.tf     (resources)    │
│          ├── variables.tf               │
│          └── outputs.tf                 │
└─────────────────────────────────────────┘
```

---

## 📦 Example 1: NCC Hub & Spokes Repository

### Complete Directory Structure

```
gcp-lz-ncc-hub-spoke/
│
├── terraform/
│   ├── main.tf                          # Orchestrates all modules
│   ├── variables.tf                     # Repository-level inputs
│   ├── outputs.tf                       # Downstream module outputs
│   ├── locals.tf                        # Parse YAML files
│   ├── backend.tf                       # GCS backend config
│   ├── versions.tf                      # Provider versions
│   │
│   └── modules/                         # Internal modules
│       │
│       ├── ncc-hub/                     # NCC Hub module
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       │
│       ├── vpc-spoke/                   # VPC Spoke module (M1P, M1NP, M3P, M3NP)
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       │
│       └── ra-spoke/                    # Router Appliance Spoke (Transit)
│           ├── main.tf
│           ├── variables.tf
│           └── outputs.tf
│
├── data/                                # YAML configuration files
│   ├── ncc-hub-config.yaml
│   ├── vpc-spokes-config.yaml
│   └── transit-spoke-config.yaml
│
├── .github/
│   └── workflows/
│       ├── terraform-plan.yaml
│       └── terraform-apply.yaml
│
└── README.md
```

---

## 📄 Implementation: NCC Hub Module

### File: `terraform/modules/ncc-hub/main.tf`

```terraform
# NCC Hub Module - Contains resources and logic
# This is the "inside the module" part Vijay mentioned

resource "google_network_connectivity_hub" "hub" {
  project     = var.project_id
  name        = var.hub_name
  description = var.description
  
  labels = merge(
    var.labels,
    {
      managed_by = "terraform"
      component  = "ncc-hub"
    }
  )
}

# Optional: Hub routing configuration
resource "google_network_connectivity_hub_route" "default" {
  count = var.enable_default_route ? 1 : 0
  
  hub_id      = google_network_connectivity_hub.hub.id
  name        = "${var.hub_name}-default-route"
  destination = "0.0.0.0/0"
  next_hop    = var.next_hop_id
}
```

### File: `terraform/modules/ncc-hub/variables.tf`

```terraform
variable "project_id" {
  description = "Project ID where NCC Hub will be created"
  type        = string
}

variable "hub_name" {
  description = "Name of the NCC Hub"
  type        = string
}

variable "description" {
  description = "Description of the NCC Hub"
  type        = string
  default     = "NCC Hub for Carrier Infrastructure"
}

variable "labels" {
  description = "Labels to apply to the NCC Hub"
  type        = map(string)
  default     = {}
}

variable "enable_default_route" {
  description = "Enable default route in hub"
  type        = bool
  default     = false
}

variable "next_hop_id" {
  description = "Next hop for default route"
  type        = string
  default     = null
}
```

### File: `terraform/modules/ncc-hub/outputs.tf`

```terraform
output "hub_id" {
  description = "ID of the NCC Hub"
  value       = google_network_connectivity_hub.hub.id
}

output "hub_name" {
  description = "Name of the NCC Hub"
  value       = google_network_connectivity_hub.hub.name
}

output "hub_self_link" {
  description = "Self-link of the NCC Hub"
  value       = google_network_connectivity_hub.hub.self_link
}

output "hub_state" {
  description = "State of the NCC Hub"
  value       = google_network_connectivity_hub.hub.state
}
```

---

## 📄 Implementation: VPC Spoke Module

### File: `terraform/modules/vpc-spoke/main.tf`

```terraform
# VPC Spoke Module - For M1P, M1NP, M3P, M3NP
# Uses Cloud Foundation Fabric module

module "ncc_vpc_spoke" {
  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc-spoke?ref=v45.0.0"
  
  hub     = var.hub_id
  name    = var.spoke_name
  project = var.project_id
  
  vpc_config = {
    network_name = var.vpc_self_link
    region       = var.region
  }
  
  spoke_type = "VPC_SPOKE"
  
  labels = merge(
    var.labels,
    {
      spoke_type = "vpc"
      zone       = var.zone  # model-1, model-3, etc.
    }
  )
}

# Data source to read VPC details
data "google_compute_network" "vpc" {
  name    = var.vpc_name
  project = var.project_id
}
```

### File: `terraform/modules/vpc-spoke/variables.tf`

```terraform
variable "hub_id" {
  description = "NCC Hub ID to attach spoke to"
  type        = string
}

variable "spoke_name" {
  description = "Name of the NCC spoke"
  type        = string
}

variable "project_id" {
  description = "Project ID where spoke will be created"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_self_link" {
  description = "Self-link of the VPC"
  type        = string
}

variable "region" {
  description = "Region for the spoke"
  type        = string
}

variable "zone" {
  description = "Zone designation (model-1, model-3, etc.)"
  type        = string
}

variable "labels" {
  description = "Labels to apply"
  type        = map(string)
  default     = {}
}
```

### File: `terraform/modules/vpc-spoke/outputs.tf`

```terraform
output "spoke_id" {
  description = "ID of the NCC spoke"
  value       = module.ncc_vpc_spoke.spoke_id
}

output "spoke_name" {
  description = "Name of the NCC spoke"
  value       = var.spoke_name
}

output "spoke_uri" {
  description = "URI of the NCC spoke"
  value       = module.ncc_vpc_spoke.spoke_uri
}
```

---

## 📄 Implementation: RA Spoke Module

### File: `terraform/modules/ra-spoke/main.tf`

```terraform
# Router Appliance Spoke Module - For Transit VPC
# Uses Cloud Foundation Fabric RA module

module "ncc_ra_spoke" {
  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/ncc-spoke-ra?ref=v45.0.0"
  
  hub     = var.hub_id
  name    = var.spoke_name
  project = var.project_id
  region  = var.region
  
  # Router configuration
  router_config = {
    name    = var.router_name
    network = var.vpc_self_link
    asn     = var.router_asn
  }
  
  # Router Appliance instances
  router_appliances = var.router_appliances
  
  labels = merge(
    var.labels,
    {
      spoke_type = "router-appliance"
      zone       = "transit"
    }
  )
}
```

### File: `terraform/modules/ra-spoke/variables.tf`

```terraform
variable "hub_id" {
  description = "NCC Hub ID to attach spoke to"
  type        = string
}

variable "spoke_name" {
  description = "Name of the RA spoke"
  type        = string
}

variable "project_id" {
  description = "Project ID where spoke will be created"
  type        = string
}

variable "region" {
  description = "Region for the spoke"
  type        = string
}

variable "router_name" {
  description = "Name of the Cloud Router"
  type        = string
}

variable "vpc_self_link" {
  description = "Self-link of the VPC"
  type        = string
}

variable "router_asn" {
  description = "ASN for the Cloud Router"
  type        = number
}

variable "router_appliances" {
  description = "Router appliance configurations (interface 0 and 1)"
  type = map(object({
    internal_ip  = string
    external_ip  = string
    redundancy   = string
  }))
}

variable "labels" {
  description = "Labels to apply"
  type        = map(string)
  default     = {}
}
```

### File: `terraform/modules/ra-spoke/outputs.tf`

```terraform
output "spoke_id" {
  description = "ID of the RA spoke"
  value       = module.ncc_ra_spoke.spoke_id
}

output "spoke_name" {
  description = "Name of the RA spoke"
  value       = var.spoke_name
}

output "router_id" {
  description = "ID of the Cloud Router"
  value       = module.ncc_ra_spoke.router_id
}
```

---

## 📄 Main Orchestration File

### File: `terraform/main.tf`

```terraform
# Main orchestration file - "calling those modules from outside"
# This is what Vijay meant by "from outside we are calling those modules"

# Create NCC Hub
module "ncc_hub" {
  source = "./modules/ncc-hub"
  
  project_id  = local.ncc_hub_config.project_id
  hub_name    = local.ncc_hub_config.hub_name
  description = local.ncc_hub_config.description
  
  labels = {
    cost_center   = local.ncc_hub_config.labels.cost_center
    owner         = local.ncc_hub_config.labels.owner
    application   = local.ncc_hub_config.labels.application
    leanix_app_id = local.ncc_hub_config.labels.leanix_app_id
  }
}

# Create VPC Spokes for Model 1 and Model 3
module "vpc_spokes" {
  source   = "./modules/vpc-spoke"
  for_each = local.vpc_spokes_config
  
  hub_id        = module.ncc_hub.hub_id
  spoke_name    = each.value.spoke_name
  project_id    = each.value.project_id
  vpc_name      = each.value.vpc_name
  vpc_self_link = each.value.vpc_self_link
  region        = each.value.region
  zone          = each.value.zone
  
  labels = each.value.labels
  
  depends_on = [module.ncc_hub]
}

# Create Router Appliance Spoke for Transit VPC
module "transit_ra_spoke" {
  source = "./modules/ra-spoke"
  
  hub_id         = module.ncc_hub.hub_id
  spoke_name     = local.transit_spoke_config.spoke_name
  project_id     = local.transit_spoke_config.project_id
  region         = local.transit_spoke_config.region
  router_name    = local.transit_spoke_config.router_name
  vpc_self_link  = local.transit_spoke_config.vpc_self_link
  router_asn     = local.transit_spoke_config.router_asn
  
  router_appliances = local.transit_spoke_config.router_appliances
  
  labels = local.transit_spoke_config.labels
  
  depends_on = [module.ncc_hub]
}
```

---

## 📄 Locals File (YAML Parser)

### File: `terraform/locals.tf`

```terraform
# Parse YAML configuration files
# This is the "Data" part that Vijay mentioned

locals {
  # Parse NCC Hub configuration
  ncc_hub_config_raw = yamldecode(file("${path.module}/../data/ncc-hub-config.yaml"))
  ncc_hub_config = {
    project_id  = local.ncc_hub_config_raw.hub.project_id
    hub_name    = local.ncc_hub_config_raw.hub.name
    description = local.ncc_hub_config_raw.hub.description
    labels      = local.ncc_hub_config_raw.hub.labels
  }
  
  # Parse VPC Spokes configuration
  vpc_spokes_config_raw = yamldecode(file("${path.module}/../data/vpc-spokes-config.yaml"))
  vpc_spokes_config = {
    for key, spoke in local.vpc_spokes_config_raw.spokes : key => {
      spoke_name    = spoke.name
      project_id    = spoke.project_id
      vpc_name      = spoke.vpc_name
      vpc_self_link = spoke.vpc_self_link
      region        = spoke.region
      zone          = spoke.zone
      labels        = spoke.labels
    }
  }
  
  # Parse Transit RA Spoke configuration
  transit_spoke_config_raw = yamldecode(file("${path.module}/../data/transit-spoke-config.yaml"))
  transit_spoke_config = {
    spoke_name        = local.transit_spoke_config_raw.transit.spoke_name
    project_id        = local.transit_spoke_config_raw.transit.project_id
    region            = local.transit_spoke_config_raw.transit.region
    router_name       = local.transit_spoke_config_raw.transit.router_name
    vpc_self_link     = local.transit_spoke_config_raw.transit.vpc_self_link
    router_asn        = local.transit_spoke_config_raw.transit.router_asn
    router_appliances = local.transit_spoke_config_raw.transit.router_appliances
    labels            = local.transit_spoke_config_raw.transit.labels
  }
}
```

---

## 📄 YAML Configuration Files

### File: `data/ncc-hub-config.yaml`

```yaml
# NCC Hub Configuration
# "whatever they do in the yaml files that would be the input"

hub:
  project_id: prj-prd-gcp-40036-mgmt-nethub
  name: carrier-ncc-hub-prod
  description: "Carrier Production NCC Hub for multi-region connectivity"
  
  labels:
    cost_center: "network-infrastructure"
    owner: "network-team"
    application: "ncc-hub"
    leanix_app_id: "app-ncc-001"
    environment: "production"
    zone: "global"
```

### File: `data/vpc-spokes-config.yaml`

```yaml
# VPC Spokes Configuration for M1P, M1NP, M3P, M3NP

spokes:
  m1p:
    name: carrier-ncc-spoke-m1p
    project_id: prj-prd-gcp-40036-m1p-host
    vpc_name: global-host-m1p-vpc
    vpc_self_link: projects/prj-prd-gcp-40036-m1p-host/global/networks/global-host-m1p-vpc
    region: us-central1
    zone: model-1
    
    labels:
      cost_center: "model1-production"
      owner: "platform-team"
      application: "shared-vpc-m1p"
      leanix_app_id: "app-m1p-001"
      environment: "production"
      zone: "model-1"
  
  m1np:
    name: carrier-ncc-spoke-m1np
    project_id: prj-prd-gcp-40036-m1np-host
    vpc_name: global-host-m1np-vpc
    vpc_self_link: projects/prj-prd-gcp-40036-m1np-host/global/networks/global-host-m1np-vpc
    region: us-central1
    zone: model-1
    
    labels:
      cost_center: "model1-nonprod"
      owner: "platform-team"
      application: "shared-vpc-m1np"
      leanix_app_id: "app-m1np-001"
      environment: "non-production"
      zone: "model-1"
  
  m3p:
    name: carrier-ncc-spoke-m3p
    project_id: prj-prd-gcp-40036-m3p-host
    vpc_name: global-host-m3p-vpc
    vpc_self_link: projects/prj-prd-gcp-40036-m3p-host/global/networks/global-host-m3p-vpc
    region: us-east1
    zone: model-3
    
    labels:
      cost_center: "model3-production"
      owner: "security-team"
      application: "shared-vpc-m3p"
      leanix_app_id: "app-m3p-001"
      environment: "production"
      zone: "model-3"
  
  m3np:
    name: carrier-ncc-spoke-m3np
    project_id: prj-prd-gcp-40036-m3np-host
    vpc_name: global-host-m3np-vpc
    vpc_self_link: projects/prj-prd-gcp-40036-m3np-host/global/networks/global-host-m3np-vpc
    region: us-east1
    zone: model-3
    
    labels:
      cost_center: "model3-nonprod"
      owner: "security-team"
      application: "shared-vpc-m3np"
      leanix_app_id: "app-m3np-001"
      environment: "non-production"
      zone: "model-3"
```

### File: `data/transit-spoke-config.yaml`

```yaml
# Transit Router Appliance Spoke Configuration

transit:
  spoke_name: carrier-ncc-spoke-transit-ra
  project_id: prj-prd-gcp-40036-mgmt-nethub
  region: us-central1
  router_name: carrier-transit-router
  vpc_self_link: projects/prj-prd-gcp-40036-mgmt-nethub/global/networks/transit-vpc
  router_asn: 64512
  
  # Router Appliance instances - Interface 0 and Interface 1
  router_appliances:
    interface0:
      internal_ip: 10.1.1.10
      external_ip: null  # Private only
      redundancy: active
    
    interface1:
      internal_ip: 10.1.1.11
      external_ip: null  # Private only
      redundancy: standby
  
  labels:
    cost_center: "network-infrastructure"
    owner: "network-team"
    application: "transit-vpc"
    leanix_app_id: "app-transit-001"
    environment: "production"
    zone: "transit"
```

---

## 📄 Outputs File (For Downstream Modules)

### File: `terraform/outputs.tf`

```terraform
# Outputs for downstream modules
# These will be stored in GCS for other repos to consume

output "ncc_hub_id" {
  description = "NCC Hub ID for downstream modules"
  value       = module.ncc_hub.hub_id
}

output "ncc_hub_name" {
  description = "NCC Hub name"
  value       = module.ncc_hub.hub_name
}

output "vpc_spoke_ids" {
  description = "Map of VPC spoke names to their IDs"
  value = {
    for key, spoke in module.vpc_spokes : key => spoke.spoke_id
  }
}

output "vpc_spoke_uris" {
  description = "Map of VPC spoke names to their URIs"
  value = {
    for key, spoke in module.vpc_spokes : key => spoke.spoke_uri
  }
}

output "transit_spoke_id" {
  description = "Transit RA spoke ID"
  value       = module.transit_ra_spoke.spoke_id
}

output "transit_router_id" {
  description = "Transit Cloud Router ID"
  value       = module.transit_ra_spoke.router_id
}

# Store outputs in GCS for downstream modules
resource "google_storage_bucket_object" "ncc_outputs" {
  name    = "outputs/ncc-hub-spoke.json"
  bucket  = var.outputs_bucket
  content = jsonencode({
    ncc_hub_id       = module.ncc_hub.hub_id
    ncc_hub_name     = module.ncc_hub.hub_name
    vpc_spoke_ids    = { for key, spoke in module.vpc_spokes : key => spoke.spoke_id }
    vpc_spoke_uris   = { for key, spoke in module.vpc_spokes : key => spoke.spoke_uri }
    transit_spoke_id = module.transit_ra_spoke.spoke_id
    transit_router_id = module.transit_ra_spoke.router_id
    timestamp        = timestamp()
  })
}
```

---

## 🚀 Deployment Workflow

### Step 1: Initialize Terraform

```bash
cd terraform/
terraform init
```

### Step 2: Validate Configuration

```bash
terraform validate
terraform fmt -check -recursive
```

### Step 3: Plan

```bash
terraform plan -out=tfplan
```

### Step 4: Review YAML Changes

```bash
# Any configuration change happens in YAML files
# No code changes needed!

vim ../data/vpc-spokes-config.yaml
```

### Step 5: Apply

```bash
terraform apply tfplan
```

---

## 🔄 How to Add New Spoke

### Without Code Changes (YAML Only)

**File: `data/vpc-spokes-config.yaml`**

```yaml
spokes:
  # ... existing spokes ...
  
  # Add new spoke for Model 5
  m5p:
    name: carrier-ncc-spoke-m5p
    project_id: prj-prd-gcp-40036-m5p-host
    vpc_name: global-host-m5p-vpc
    vpc_self_link: projects/prj-prd-gcp-40036-m5p-host/global/networks/global-host-m5p-vpc
    region: us-west1
    zone: model-5
    
    labels:
      cost_center: "model5-production"
      owner: "platform-team"
      application: "shared-vpc-m5p"
      leanix_app_id: "app-m5p-001"
      environment: "production"
      zone: "model-5"
```

**That's it!** The `for_each` in main.tf automatically picks up the new spoke.

```bash
terraform plan  # Will show new spoke being added
terraform apply
```

---

## ✅ Benefits of This Pattern

### 1. **Modularity**
- Each module is self-contained
- Reusable across projects
- Easy to test independently

### 2. **Variablization**
- All configuration in YAML
- No hard-coded values
- Easy to update without code changes

### 3. **Maintainability**
- Small focused modules (50-100 lines each)
- Clear separation of concerns
- Easy to debug

### 4. **Scalability**
- Add new spokes by editing YAML
- No code duplication
- Consistent patterns

### 5. **Compliance**
- Mandatory tags enforced via YAML
- Naming conventions in YAML
- Easy to audit

---

## 🎯 Pattern Summary

```
┌──────────────────────────────────────────┐
│ YAML Files (data/)                       │
│ ↓ Input: Configuration                   │
├──────────────────────────────────────────┤
│ Locals (locals.tf)                       │
│ ↓ Parse: YAML → Terraform objects       │
├──────────────────────────────────────────┤
│ Main (main.tf)                           │
│ ↓ Orchestrate: Call modules with config │
├──────────────────────────────────────────┤
│ Modules (modules/)                       │
│ ↓ Execute: Create resources             │
├──────────────────────────────────────────┤
│ Outputs (outputs.tf)                     │
│ ↓ Export: Data for downstream modules   │
├──────────────────────────────────────────┤
│ GCS Bucket                               │
│ ↓ Store: Outputs as JSON                │
└──────────────────────────────────────────┘
```

---

## 📚 Next Steps

Apply this **exact pattern** to all 8 repositories:

1. ✅ **gcp-lz-ncc-hub-spoke** (shown above)
2. **gcp-lz-shared-vpc** (similar pattern)
3. **gcp-lz-subnet-vending** (similar pattern)
4. **gcp-lz-cloud-routers** (similar pattern)
5. **gcp-lz-ha-vpn** (similar pattern)
6. **gcp-lz-nsi-paloalto** (similar pattern)
7. **gcp-lz-paloalto-bootstrap** (similar pattern)
8. **gcp-lz-orchestration** (scripts only)

---

**Status:** ✅ Implementation pattern defined and ready to use

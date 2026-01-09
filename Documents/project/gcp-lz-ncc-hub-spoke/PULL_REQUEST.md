# Pull Request - NCC Hub & Spokes Implementation

**Date:** January 9, 2026  
**Repository:** gcp-lz-ncc-hub-spoke  
**Based on:** Carrier GCP Low Level Design Document v1.0

---

## 📋 PR Summary

Implementation of Network Connectivity Center (NCC) Hub and Spokes following Carrier LLD specifications with proper naming conventions for projects, VPCs, subnets, and network resources.

---

## 🎯 Changes Implemented

### 1. **NCC Hub Configuration**
- ✅ Project: `global-ncc-hub` (per LLD)
- ✅ Hub Name: `global-carrier-hub` (per LLD)
- ✅ Topology: Mesh (global transitivity enabled)
- ✅ Location: Global

### 2. **VPC Spokes (8 Total)**

#### Model Spokes (4)
| Spoke | VPC Name | Project | Region | Status |
|-------|----------|---------|--------|--------|
| spoke-m1p | global-host-m1p-vpc | shared-services | us-east4 | ✅ |
| spoke-m1np | global-host-m1np-vpc | shared-services | us-east4 | ✅ |
| spoke-m3p | global-host-m3p-vpc | shared-services | us-east4 | ✅ |
| spoke-m3np | global-host-m3np-vpc | shared-services | us-east4 | ✅ |

#### Network VPCs (4)
| Spoke | VPC Name | Project | Region | Status |
|-------|----------|---------|--------|--------|
| spoke-security-data | global-security-vpc-data | network-security | us-east4 | ✅ |
| spoke-security-mgmt | global-security-vpc-mgmt | network-security | us-east4 | ✅ |
| spoke-shared-services | global-shared-svcs-vpc | shared-host-pvpc | us-east4 | ✅ |
| spoke-transit | global-transit-vpc | network-transit | us-east4 | ✅ |

### 3. **Router Appliance Spoke (1)**
- ✅ Spoke Name: `spoke-transit-ra`
- ✅ Project: `network-transit`
- ✅ VPC: `global-transit-vpc`
- ✅ Cloud Router: `useast4-cr1` (per LLD naming: region-cr1)
- ✅ Router ASN: 16550 (standard GCP ASN per LLD)
- ✅ SD-WAN RAs: Cisco Catalyst 8000V (sdwan-ra-01/02)
- ✅ Peer ASN: 65001 (private ASN for SD-WAN)

---

## 📐 Naming Standards (Per LLD & Manager Requirements)

### **Projects**
```yaml
global-ncc-hub          # NCC Hub
shared-services         # Shared Host project for all 4 model VPCs
network-transit         # Transit VPC with SD-WAN RAs & BlueCat
network-security        # Security VPCs (data & mgmt) with Palo Alto
shared-host-pvpc        # PSC endpoints
```

### **VPCs**
```yaml
# Model VPCs (in shared-services project)
global-host-m1p-vpc
global-host-m1np-vpc
global-host-m3p-vpc
global-host-m3np-vpc

# Network VPCs
global-security-vpc-data      # Palo Alto data plane (network-security)
global-security-vpc-mgmt      # Palo Alto management (network-security)
global-transit-vpc            # SD-WAN & BlueCat (network-transit)
global-shared-svcs-vpc        # Shared services (shared-host-pvpc)
```

### **Subnets** (Per LLD Document)

#### Application Subnets (Dynamic - Subnet Vending)
```bash
# Pattern: region-model-BU-APP-subnet1
# Variables: region, model (m1p/m1np/m3p/m3np), BU (Business Unit), APP (Application)

# Examples:
useast4-m1p-finance-erp-subnet1
uscentral1-m1np-hr-portal-subnet1
europewest3-m3p-sales-crm-subnet1
asiasoutheast1-m3np-it-tools-subnet1
```

#### Infrastructure Subnets (Per LLD Table)
```bash
# Security Data Subnets
useast4-security-data-subnet      # 10.154.8.0/24
uscentral1-security-data-subnet   # 10.154.9.0/24
europewest1-security-data-subnet  # 10.154.10.0/24
europewest3-security-data-subnet  # 10.154.11.0/24
asiaeast2-security-data-subnet    # 10.154.12.0/24
asiasoutheast1-security-data-subnet # 10.154.13.0/24

# Security Management Subnets
useast4-security-mgmt-subnet      # 10.154.16.0/24
uscentral1-security-mgmt-subnet   # 10.154.17.0/24
# ... (pattern continues for all 6 regions)

# Transit Subnets
useast4-transit-subnet            # 10.154.0.0/24
uscentral1-transit-subnet         # 10.154.1.0/24
# ... (pattern continues for all 6 regions)

# Shared Services Subnets
useast4-shared-svcs-subnet        # 10.154.32.0/24
uscentral1-shared-svcs-subnet     # 10.154.33.0/24
# ... (pattern continues for all 6 regions)

# PSC & ALB Subnets (Per Manager Requirements)
useast4-shared-psc-subnet
useast4-shared-alb-subnet
# ... (pattern for all regions)
```

### **Cloud Routers**
```bash
# Pattern: region-cr1
useast4-cr1
uscentral1-cr1
europewest3-cr1
europewest1-cr1
asiaeast2-cr1
asiasoutheast1-cr1
```

### **Cloud NAT**
```bash
# Pattern: region-model-cnat1
useast4-m1p-cnat1
uscentral1-m1np-cnat1
europewest3-m3p-cnat1
# ... etc
```

---

## 🌍 Regional Deployment (6 Regions per LLD)

```yaml
Regions:
  - us-east4         # Primary US East
  - us-central1      # Primary US Central
  - europe-west3     # Europe Frankfurt
  - europe-west1     # Europe Belgium
  - asia-east2       # Asia Hong Kong
  - asia-southeast1  # Asia Singapore
```

All VPC spokes and infrastructure will be deployed across these 6 regions.

---

## 📊 IP Addressing (Per LLD)

### Model VPC Subnets (Reserved Pools - /16 blocks)

| VPC | Region | CIDR Block | Purpose |
|-----|--------|------------|---------|
| **M1P** | us-east4 | 10.150.0.0/16 | Reserved Pool (BlueCat assigns /24, /25, /26) |
| | us-central1 | 10.100.0.0/16 | Reserved Pool |
| | europe-west3 | 10.173.0.0/16 | Reserved Pool |
| | europe-west1 | 10.177.0.0/16 | Reserved Pool |
| | asia-southeast1 | 10.109.0.0/16 | Reserved Pool |
| | asia-east2 | 10.115.0.0/16 | Reserved Pool |
| **M1NP** | us-east4 | 10.151.0.0/16 | Reserved Pool |
| | us-central1 | 10.101.0.0/16 | Reserved Pool |
| | europe-west3 | 10.174.0.0/16 | Reserved Pool |
| | europe-west1 | 10.178.0.0/16 | Reserved Pool |
| | asia-southeast1 | 10.110.0.0/16 | Reserved Pool |
| | asia-east2 | 10.116.0.0/16 | Reserved Pool |
| **M3P** | us-east4 | 10.152.0.0/16 | Reserved Pool |
| | us-central1 | 10.102.0.0/16 | Reserved Pool |
| | europe-west3 | 10.175.0.0/17 | Reserved Pool |
| | europe-west1 | 10.179.0.0/17 | Reserved Pool |
| | asia-southeast1 | 10.111.0.0/17 | Reserved Pool |
| | asia-east2 | 10.117.0.0/17 | Reserved Pool |
| **M3NP** | us-east4 | 10.153.0.0/16 | Reserved Pool |
| | us-central1 | 10.103.0.0/16 | Reserved Pool |
| | europe-west3 | 10.175.128.0/17 | Reserved Pool |
| | europe-west1 | 10.179.128.0/17 | Reserved Pool |
| | asia-southeast1 | 10.111.128.0/17 | Reserved Pool |
| | asia-east2 | 10.117.128.0/17 | Reserved Pool |

### Infrastructure Subnets (/24 blocks per LLD Table)

| VPC | US-East4 | US-Central1 | EU-West1 | EU-West3 | AP-East2 | AP-SE1 |
|-----|----------|-------------|----------|----------|----------|--------|
| global-transit-vpc | 10.154.0.0/24 | 10.154.1.0/24 | 10.154.2.0/24 | 10.154.3.0/24 | 10.154.4.0/24 | 10.154.5.0/24 |
| global-security-vpc-data | 10.154.8.0/24 | 10.154.9.0/24 | 10.154.10.0/24 | 10.154.11.0/24 | 10.154.12.0/24 | 10.154.13.0/24 |
| global-security-vpc-mgmt | 10.154.16.0/24 | 10.154.17.0/24 | 10.154.18.0/24 | 10.154.19.0/24 | 10.154.20.0/24 | 10.154.21.0/24 |
| global-shared-svcs-vpc | 10.154.32.0/24 | 10.154.33.0/24 | 10.154.34.0/24 | 10.154.35.0/24 | 10.154.36.0/24 | 10.154.37.0/24 |

---

## 🔧 BGP Configuration (Per LLD)

```yaml
Cloud Router:
  Name: useast4-cr1 (region-cr1 pattern)
  ASN: 16550 (standard GCP ASN)
  Region: us-east4
  
SD-WAN Router Appliances:
  Type: Cisco Catalyst 8000V
  Instances:
    - sdwan-ra-01 (zone: us-east4-a)
    - sdwan-ra-02 (zone: us-east4-b) # HA
  ASN: 65001 (private ASN - example, confirm with network team)
  
BGP Peering:
  Interface 0: Primary path (priority 100)
  Interface 1: Secondary path (priority 110)
```

---

## 📂 Files Changed

### YAML Configuration Files
- ✅ [data/ncc-hub-config.yaml](data/ncc-hub-config.yaml)
  - Updated project: `global-ncc-hub`
  - Updated hub name: `global-carrier-hub`
  - Enabled global routing for mesh topology

- ✅ [data/vpc-spokes-config.yaml](data/vpc-spokes-config.yaml)
  - Updated all 8 VPC spokes with LLD naming
  - Changed projects: `shared-services`, `network-security`, `shared-host-pvpc`, `network-transit`
  - Updated VPC names: `global-host-{model}-vpc`, `global-security-vpc-{data|mgmt}`, `global-transit-vpc`, `global-shared-svcs-vpc`
  - Changed primary region to `us-east4` (per LLD)

- ✅ [data/transit-spoke-config.yaml](data/transit-spoke-config.yaml)
  - Updated project: `network-transit`
  - Updated VPC: `global-transit-vpc`
  - Changed router name: `useast4-cr1` (per LLD pattern: region-cr1)
  - Updated ASN: 16550 (standard GCP ASN per LLD)
  - Changed RAs from Palo Alto to SD-WAN appliances (Cisco Catalyst 8000V)
  - Updated subnet: 10.154.0.0/24 (per LLD table)

### Documentation (No code changes needed)
All existing documentation references the YAML-driven approach, so no updates required for:
- terraform/main.tf (reads from YAML)
- terraform/locals.tf (parses YAML)
- terraform/outputs.tf (dynamic based on YAML)

---

## ✅ Pre-Deployment Checklist

### Infrastructure Prerequisites
- [ ] All 5 projects created: `global-ncc-hub`, `shared-services`, `network-transit`, `network-security`, `shared-host-pvpc`
- [ ] All 8 VPCs created with proper names
- [ ] Subnets created per LLD table (infrastructure subnets)
- [ ] SD-WAN appliances deployed in `network-transit` project
- [ ] Service accounts configured with proper IAM roles

### Configuration Review
- [x] Project names match LLD specification
- [x] VPC names follow `global-*-vpc` pattern
- [x] Cloud Router follows `region-cr1` pattern
- [x] ASN 16550 configured for Cloud Router
- [x] SD-WAN RA references updated (sdwan-ra-01/02)
- [x] IP addressing matches LLD table
- [x] All 6 regions specified in configuration
- [x] Labels include all mandatory Carrier tags

### Terraform Validation
- [ ] `terraform fmt` executed
- [ ] `terraform validate` passes
- [ ] `terraform plan` reviewed (no unexpected changes)
- [ ] State backend configured (GCS bucket)
- [ ] Variables file created (`terraform.tfvars`)

---

## 🚀 Deployment Plan

### Phase 1: Hub + VPC Spokes (No SD-WAN dependency)
```bash
# Set deploy_transit_spoke = false
terraform apply -var="deploy_transit_spoke=false"

# Expected resources:
# - 1 NCC Hub (global-carrier-hub)
# - 8 VPC Spokes (all models + network VPCs)
```

### Phase 2: Transit RA Spoke (After SD-WAN deployment)
```bash
# Prerequisites:
# - SD-WAN appliances deployed and running
# - Update transit-spoke-config.yaml with actual VM URIs and IPs

# Set deploy_transit_spoke = true
terraform apply -var="deploy_transit_spoke=true"

# Expected resources:
# - 1 Cloud Router (useast4-cr1)
# - 1 RA Spoke (spoke-transit-ra)
# - 2 BGP Peers (interface0, interface1)
```

---

## 🔍 Testing & Verification

### Verify NCC Hub
```bash
gcloud network-connectivity hubs describe global-carrier-hub \
  --project=global-ncc-hub
```

### Verify All Spokes
```bash
gcloud network-connectivity spokes list \
  --hub=global-carrier-hub \
  --project=global-ncc-hub
```

### Verify Cloud Router & BGP
```bash
gcloud compute routers describe useast4-cr1 \
  --region=us-east4 \
  --project=network-transit

gcloud compute routers get-status useast4-cr1 \
  --region=us-east4 \
  --project=network-transit
```

### Verify Mesh Connectivity
```bash
# Test connectivity between spokes (after NSI policies applied)
# M1P → M3P
# M1P → Transit
# All spokes → Shared Services
```

---

## 📋 Integration Points

### Downstream Modules
This NCC Hub-Spoke deployment provides outputs for:

1. **gcp-lz-subnet-vending**
   - VPC IDs for subnet creation
   - Project IDs for each model
   - Subnet naming patterns

2. **gcp-lz-cloud-routers**
   - Cloud Router IDs
   - BGP ASN information
   - Regional distribution

3. **gcp-lz-nsi-paloalto**
   - VPC spoke IDs for NSI policy attachment
   - Security VPC information

4. **gcp-lz-ha-vpn**
   - Cloud Router self-links
   - Transit VPC details

### BlueCat Integration
- DNS forwarding from all VPCs to BlueCat in `global-shared-svcs-vpc`
- IPAM integration via BlueCat Gateway (deployed in GCP)
- Subnet vending automation via Terraform + Apigee

---

## 🎯 Acceptance Criteria

- [x] All project names match LLD specification
- [x] All VPC names follow LLD naming standards
- [x] Subnet naming patterns match manager requirements
- [x] Cloud Router follows `region-cr1` pattern
- [x] All 6 regions configured
- [x] IP addressing matches LLD table
- [x] BGP configuration uses LLD ASN (16550)
- [x] SD-WAN appliances referenced (not Palo Alto)
- [x] All mandatory labels applied
- [x] YAML-driven configuration (no hardcoded values)
- [x] Modular structure maintained

---

## 📝 Notes

### Key Changes from Initial Design
1. **Project Names:** Changed from `prj-prd-gcp-40036-*` to LLD standard (`global-ncc-hub`, `shared-services`, etc.)
2. **VPC Names:** Standardized to `global-*-vpc` pattern per LLD
3. **Router Appliances:** Changed from Palo Alto to SD-WAN (Cisco Catalyst 8000V) per LLD
4. **Cloud Router Naming:** Updated to `region-cr1` pattern
5. **ASN:** Changed from 64512 to 16550 (standard GCP ASN per LLD)
6. **Primary Region:** Changed from us-central1 to us-east4 per LLD
7. **Spoke Names:** Simplified to `spoke-{name}` pattern per LLD table

### Manager Guidance Applied
✅ Host projects: `shared-services` (not individual m1p/m1np/m3p/m3np projects)  
✅ VPC naming: `global-host-Model-vpc` pattern  
✅ Subnet pattern: `region-model-BU-APP-subnet1`  
✅ Router naming: `region-cr1` (e.g., useast4-cr1)  
✅ NAT naming: `region-model-cnat1` (e.g., useast4-m1p-cnat1)  
✅ Refer to LLD for all infrastructure details  

---

## 👥 Reviewers

- [ ] Network Architecture Team
- [ ] Security Team
- [ ] Platform Engineering Team
- [ ] Vijay (Cloud Architect)

---

## 🔗 References

- Carrier GCP Low Level Design v1.0 (December 16, 2025)
- Vijay's Implementation Pattern (YAML-driven, modular)
- Manager Requirements (naming standards)
- Cloud Foundation Fabric v45.0.0

---

**Status:** ✅ Ready for Review  
**Next Steps:** Review, approve, and deploy Phase 1 (Hub + VPC Spokes)

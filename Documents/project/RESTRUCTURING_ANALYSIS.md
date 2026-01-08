# 🔄 Carrier Project Restructuring Analysis

**Date:** January 8, 2026  
**Status:** 🚨 CRITICAL - Immediate Action Required  
**Priority:** HIGH

---

## 🎯 Problem Statement

### Manager's Feedback (Critical Issues)

Based on the Project Manager's email, the current implementation does **NOT** align with client/Carrier expectations:

> **"The final solution must avoid monolithic repositories. Components such as Shared VPCs, NSI/Palo Alto, subnet vending, and bootstrap should be separated into dedicated modules and repositories."**

### Current Structure ❌ (INCORRECT)

```
project/
│
├── deploy-carrier-infrastructure.ps1      # ❌ Monolithic unified script
├── deploy-carrier-infrastructure.sh       # ❌ Monolithic unified script
│
├── gcp-lz-2-networking-tf/               # ❌ MONOLITHIC - All in one repo
│   ├── network-vpc.tf                    # Shared VPCs
│   ├── network-ncc.tf                    # NCC Hub & Spokes
│   ├── network-subnets-vending.tf        # Subnet Vending
│   ├── network-nsi.tf                    # NSI
│   ├── network-cloud-routers.tf          # Routers
│   ├── network-ha-vpn.tf                 # HA-VPN
│   └── network-nat.tf                    # NAT
│
└── gcp-palo-alto-bootstrap/              # ❌ Separate but needs modularization
    ├── terraform/
    └── bootstrap-files/
```

**Problems:**
1. ❌ **Single monolithic repository** with all networking components
2. ❌ **Unified deployment script** that deploys everything together
3. ❌ **No separation** between Shared VPCs, NSI, Subnet Vending, Bootstrap
4. ❌ **Tight coupling** - Cannot deploy components independently
5. ❌ **Not following** Carrier's multi-repo architecture requirement

---

## ✅ Expected Structure (CORRECT)

### Multi-Repository Architecture

```
Carrier GCP Landing Zone Infrastructure
│
├── 1️⃣ gcp-lz-shared-vpc/                   # REPO #1: Shared VPC Management
│   ├── terraform/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── modules/
│   │       ├── m1p-vpc/
│   │       ├── m1np-vpc/
│   │       ├── m3p-vpc/
│   │       └── m3np-vpc/
│   ├── data/
│   │   └── shared-vpc-config.yaml
│   ├── README.md
│   └── .github/workflows/
│
├── 2️⃣ gcp-lz-ncc-hub-spoke/                # REPO #2: NCC Hub & Spokes
│   ├── terraform/
│   │   ├── main.tf
│   │   ├── ncc-hub.tf
│   │   ├── ncc-spokes.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── data/
│   │   └── ncc-config.yaml
│   ├── README.md
│   └── .github/workflows/
│
├── 3️⃣ gcp-lz-subnet-vending/               # REPO #3: Automated Subnet Vending
│   ├── terraform/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── modules/
│   │       └── subnet-factory/
│   ├── data/
│   │   └── network-subnets.yaml
│   ├── scripts/
│   │   └── bluecat-integration.py
│   ├── README.md
│   └── .github/workflows/
│
├── 4️⃣ gcp-lz-nsi-paloalto/                 # REPO #4: NSI & Palo Alto Integration
│   ├── terraform/
│   │   ├── main.tf
│   │   ├── nsi.tf
│   │   ├── palo-alto-integration.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── README.md
│   └── .github/workflows/
│
├── 5️⃣ gcp-lz-paloalto-bootstrap/           # REPO #5: Palo Alto Bootstrap
│   ├── terraform/
│   │   ├── main.tf
│   │   ├── firewalls.tf
│   │   ├── load-balancers.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── bootstrap-files/
│   │   ├── region1-fw01/
│   │   ├── region1-fw02/
│   │   ├── region2-fw01/
│   │   └── region2-fw02/
│   ├── README.md
│   └── .github/workflows/
│
├── 6️⃣ gcp-lz-cloud-routers/                # REPO #6: Cloud Routers & BGP
│   ├── terraform/
│   │   ├── main.tf
│   │   ├── cloud-routers.tf
│   │   ├── bgp-peers.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── README.md
│   └── .github/workflows/
│
├── 7️⃣ gcp-lz-ha-vpn/                       # REPO #7: HA-VPN Configuration
│   ├── terraform/
│   │   ├── main.tf
│   │   ├── ha-vpn.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── README.md
│   └── .github/workflows/
│
└── 8️⃣ gcp-lz-orchestration/                # REPO #8: Orchestration & CI/CD
    ├── scripts/
    │   ├── deploy-shared-vpc.sh
    │   ├── deploy-ncc.sh
    │   ├── deploy-subnet-vending.sh
    │   └── deploy-all.sh              # Orchestration script
    ├── docs/
    │   ├── DEPLOYMENT_GUIDE.md
    │   └── WORKFLOW_DIAGRAM.md
    ├── README.md
    └── .github/workflows/
```

---

## 🔄 Deployment Workflow Changes

### Current Workflow ❌ (INCORRECT)

```
User runs:
  → deploy-carrier-infrastructure.ps1
    └─→ Deploys EVERYTHING in one shot
        ├── Networking (VPCs, NCC, Routers, VPN, NAT, NSI)
        └── Security (Palo Alto Firewalls)
```

**Problem:** Monolithic, no flexibility, not modular

---

### Expected Workflow ✅ (CORRECT)

```
STAGE 0: Landing Zone Foundation (Pre-requisite)
  → Resman creates projects via Landing Zone Services module
  
STAGE 1: Shared VPC Setup
  ├─→ Deploy gcp-lz-shared-vpc
  └─→ Output: VPC IDs, Host Project IDs

STAGE 2: NCC Hub & Spokes
  ├─→ Deploy gcp-lz-ncc-hub-spoke
  │   └─→ Input: VPC IDs from Stage 1
  └─→ Output: NCC Hub ID, Spoke IDs

STAGE 3: Cloud Routers & BGP
  ├─→ Deploy gcp-lz-cloud-routers
  │   └─→ Input: VPC IDs, NCC Hub ID
  └─→ Output: Router IDs, BGP session info

STAGE 4: HA-VPN (if needed)
  ├─→ Deploy gcp-lz-ha-vpn
  │   └─→ Input: Router IDs
  └─→ Output: VPN Gateway IDs

STAGE 5: NSI & Palo Alto Integration
  ├─→ Deploy gcp-lz-nsi-paloalto
  │   └─→ Input: VPC IDs, NCC Hub ID
  └─→ Output: NSI Endpoint IDs

STAGE 6: Palo Alto Bootstrap
  ├─→ Deploy gcp-lz-paloalto-bootstrap
  │   └─→ Input: VPC IDs, Subnet IDs
  └─→ Output: Firewall Instance IDs

STAGE 7: Subnet Vending (Ongoing)
  ├─→ Triggered by project creation
  │   └─→ Input: Project metadata, Folder path, BlueCat API
  └─→ Output: Dynamically created subnets
```

---

## 📋 Key Requirements from Manager

### 1. **Modularity** (CRITICAL)
- ✅ Separate repositories for each component
- ✅ Each repo must use Carrier Terraform Scaffold
- ✅ Independent versioning and deployment
- ✅ Clear input/output contracts between modules

### 2. **Variability** (CRITICAL)
- ✅ NO hard-coded values (ports, ASNs, CIDRs, etc.)
- ✅ All configuration via YAML files in `data/` directory
- ✅ Use locals and mappings for conditional logic
- ✅ Support for Model 5 (disconnected networks)

### 3. **Landing Zone Integration** (CRITICAL)
- ✅ Projects created by **Landing Zone Services module** (Resman)
- ✅ Network vending **triggered AFTER** project creation
- ✅ README must document this flow clearly
- ✅ No project creation in network code

### 4. **Subnet Vending & BlueCat** (CRITICAL)
- ✅ Folder-based logic for subnet allocation
- ✅ BlueCat Gateway integration (likely in Model 3)
- ✅ Metadata-driven subnet provisioning
- ✅ AWS fallback option
- ✅ Requires BlueCat automation SME

### 5. **Naming & Security** (CRITICAL)
- ✅ ALL lowercase naming conventions
- ✅ Consistent zoning (Model 1, 3, 5)
- ✅ Applied across shared VPCs, transit, management networks

### 6. **Outputs & Reusability** (CRITICAL)
- ✅ Cloud router outputs for downstream modules
- ✅ GCS state outputs
- ✅ NCC spoke outputs
- ✅ Enable module chaining

---

## 🚨 Critical Changes Required

### Immediate Actions

1. **STOP using unified deployment script**
   - ❌ Delete `deploy-carrier-infrastructure.ps1`
   - ❌ Delete `deploy-carrier-infrastructure.sh`
   - ❌ These violate the modular architecture requirement

2. **BREAK DOWN monolithic repository**
   - Split `gcp-lz-2-networking-tf` into 5+ separate repositories
   - Create separate repos for each component listed above

3. **CREATE module structure**
   - Each repository must follow module pattern
   - Clear separation of resources, variables, outputs
   - Data-driven configuration via YAML

4. **UPDATE documentation**
   - README must show Landing Zone → Network flow
   - Document dependency order
   - Show input/output contracts

5. **IMPLEMENT BlueCat integration**
   - Subnet vending must integrate with BlueCat Gateway
   - Folder-based logic
   - Metadata-driven provisioning

---

## 📝 Action Items (Priority Order)

### Phase 1: Immediate (This Week)
- [ ] Create separate Git repositories for each component
- [ ] Split monolithic code into modular repositories
- [ ] Update all YAML configurations
- [ ] Remove hard-coded values
- [ ] Create output contracts between modules
- [ ] Update README files with correct workflow

### Phase 2: Integration (Next Week)
- [ ] Implement Landing Zone Services integration
- [ ] Create BlueCat Gateway integration scripts
- [ ] Setup folder-based subnet vending logic
- [ ] Test module chaining with outputs
- [ ] Validate end-to-end workflow

### Phase 3: Compliance (Week 3)
- [ ] Apply Carrier Terraform Scaffold to all repos
- [ ] Setup GitHub Enterprise CI/CD pipelines
- [ ] Implement mandatory tag enforcement
- [ ] Security scanning integration
- [ ] PR review workflows

### Phase 4: Documentation (Week 4)
- [ ] Update all README files
- [ ] Create architecture diagrams for new structure
- [ ] Document deployment workflows
- [ ] Create runbooks for each module
- [ ] Update meeting materials

---

## 💡 Key Insights

### What We Did Wrong
1. Created a **unified monolithic solution** thinking it would be easier
2. Combined all components into **one repository**
3. Built **single deployment script** instead of modular approach
4. Focused on **quick integration** instead of proper architecture

### What Client Actually Wants
1. **Separate repositories** for each component (5-8 repos)
2. **Modular deployment** with clear dependencies
3. **Flexible workflow** that can deploy components independently
4. **Production-grade** architecture with proper separation of concerns

### Why This Matters
- **Separation of concerns**: Different teams can work on different repos
- **Independent versioning**: Each component can be updated separately
- **Better testing**: Test and deploy each module independently
- **Compliance**: Easier to apply governance and security controls
- **Scalability**: Can add new components without affecting existing ones

---

## 🎯 Next Steps

1. **Review this document** with the manager
2. **Get approval** for the restructuring plan
3. **Create GitHub repositories** (8 repos as outlined above)
4. **Start migration** following the priority order
5. **Update all documentation** to reflect new structure

---

## 📞 Questions for Manager

1. Should we create all 8 repositories immediately or phase them?
2. What's the priority order for repository creation?
3. Do we have access to BlueCat Gateway for integration?
4. Who is the BlueCat automation SME we need to coordinate with?
5. What's the timeline for this restructuring?
6. Should we keep the current code as backup/reference?

---

**Status:** 🚨 Awaiting manager approval to proceed with restructuring

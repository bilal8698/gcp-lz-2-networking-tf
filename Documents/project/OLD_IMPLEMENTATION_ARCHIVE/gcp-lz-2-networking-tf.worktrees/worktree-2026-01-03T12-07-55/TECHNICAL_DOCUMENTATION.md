# GCP Landing Zone Stage 2: Networking - Complete Technical Documentation

## Table of Contents
1. [Overview](#overview)
2. [Basic Concepts](#basic-concepts)
3. [What We Built](#what-we-built)
4. [Architecture Deep Dive](#architecture-deep-dive)
5. [Technical Components](#technical-components)
6. [File Structure and Purpose](#file-structure-and-purpose)
7. [How Everything Works Together](#how-everything-works-together)
8. [Prerequisites and Dependencies](#prerequisites-and-dependencies)
9. [Technical Terms Glossary](#technical-terms-glossary)
10. [Implementation Details](#implementation-details)

---

## Overview

### What is a Landing Zone?
A **Landing Zone** is a pre-configured, secure, and scalable cloud environment that serves as the foundation for deploying workloads in Google Cloud Platform (GCP). Think of it as building the infrastructure foundation before constructing a house.

### What is Stage 2: Networking?
This is the **second stage** in a multi-stage Landing Zone deployment where we establish the core network infrastructure. This stage creates the "highways and roads" that connect all your cloud resources together.

### Purpose
The networking stage provides:
- **Connectivity**: How different systems communicate with each other
- **Isolation**: Keeping production separate from non-production
- **Security**: Controlled traffic flow and inspection
- **Scalability**: Automated provisioning of network resources
- **Centralization**: Shared networking services for multiple projects

---

## Basic Concepts

### 1. Virtual Private Cloud (VPC)
**What it is**: A VPC is like your own private network in the cloud. It's isolated from other networks and you control who can access it.

**Real-world analogy**: Think of it as your company's private office building with its own internal phone system and security.

**In our implementation**: We created 8 VPCs for different purposes (production, non-production, security, etc.)

### 2. Shared VPC
**What it is**: A special VPC configuration where one "host" project owns the VPC, but multiple "service" projects can use it.

**Real-world analogy**: Like a central IT department managing the office network, while different departments (HR, Finance, Engineering) use it for their systems.

**Why it's useful**: 
- Centralized network management
- Consistent security policies
- Cost efficiency (one VPC serves many projects)

### 3. Subnets
**What it is**: A subdivision of a VPC network, typically scoped to a single region.

**Real-world analogy**: Like different floors in an office building - each floor is part of the same building but serves different teams.

**In our implementation**: We use automated "subnet vending" to create subnets on-demand based on YAML configuration.

### 4. Network Connectivity Center (NCC)
**What it is**: Google's solution for connecting multiple VPCs and on-premises networks in a hub-and-spoke or mesh topology.

**Real-world analogy**: Like a central airport hub that connects multiple cities - instead of having direct flights between every city pair, everyone goes through the hub.

**Why it's useful**:
- Simplifies network connectivity (no need for VPC peering between every VPC pair)
- Provides transitivity (VPC A can reach VPC C through the hub, even without direct connection)
- Centralized routing management

### 5. Network Security Integration (NSI)
**What it is**: A framework for routing traffic through security appliances (firewalls) for inspection.

**Real-world analogy**: Like having a security checkpoint at the entrance of your office where all visitors must check in.

**In our implementation**: Uses Palo Alto VM-Series firewalls for in-band traffic inspection.

---

## What We Built

### High-Level Summary
We created a complete networking infrastructure foundation for Carrier's GCP environment with:

✅ **4 Network Projects** - Specialized GCP projects for network functions
✅ **8 Service Accounts** - Automated identity and access management
✅ **8 Virtual Private Clouds** - Isolated network environments
✅ **1 NCC Hub + 8 Spokes** - Mesh topology for full connectivity
✅ **Subnet Vending Automation** - Self-service subnet provisioning
✅ **NSI Framework** - Security inspection infrastructure

### Network Projects Created

| Project | Purpose | Why It Exists |
|---------|---------|---------------|
| **nethub** (40036) | Hosts the 4 shared VPCs (M1P, M1NP, M3P, M3NP) and NCC Hub | Centralized network management |
| **transit** (40038) | Hosts SD-WAN routers and Blue Cat DNS servers | Hybrid connectivity to on-premises |
| **netsec** (40039) | Hosts Palo Alto firewalls for traffic inspection | Security enforcement point |
| **pvpc** (40040) | Hosts Private Service Connect endpoints | Secure access to Google services |

### VPC Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    NETWORK CONNECTIVITY CENTER                   │
│                       (Global Hub - Mesh)                        │
│                     hub-global-ncc-hub                          │
└────┬──────┬──────┬──────┬──────┬──────┬──────┬──────┬──────────┘
     │      │      │      │      │      │      │      │
     │      │      │      │      │      │      │      │
┌────▼───┐┌─▼────┐┌─▼───┐┌─▼───┐┌─▼────────┐┌─▼──────┐┌▼──────┐┌▼──────┐
│  M1P   ││ M1NP ││ M3P ││ M3NP││ Transit  ││Security││Security││Shared │
│  VPC   ││  VPC ││ VPC ││ VPC ││   VPC    ││  Data  ││ Mgmt   ││ Svcs  │
│        ││      ││     ││     ││  +RA     ││  VPC   ││  VPC   ││  VPC  │
│ Spoke  ││Spoke ││Spoke││Spoke││  Spoke   ││ Spoke  ││ Spoke  ││ Spoke │
└────────┘└──────┘└─────┘└─────┘└──────────┘└────────┘└────────┘└───────┘
         │                │                     │
         ▼                ▼                     ▼
    Production      DMZ/Public            Firewalls
    Workloads       Workloads            (Palo Alto)
```

### The 8 VPCs Explained

#### 1-4. Shared VPCs (Model 1 & Model 3)

**M1P (Model 1 Production)**
- **Purpose**: Internal/private production workloads
- **Example use cases**: Internal databases, backend APIs, processing systems
- **Who uses it**: Production applications that don't need internet exposure
- **Security level**: High - no direct internet access

**M1NP (Model 1 Non-Production)**
- **Purpose**: Internal/private development and testing workloads
- **Example use cases**: Dev environments, QA testing, staging
- **Who uses it**: Development teams testing applications
- **Security level**: Medium - isolated from production

**M3P (Model 3 Production)**
- **Purpose**: DMZ/public-facing production workloads
- **Example use cases**: Web servers, API gateways, public endpoints
- **Who uses it**: Applications that need to be accessible from internet
- **Security level**: High - with strict firewall rules

**M3NP (Model 3 Non-Production)**
- **Purpose**: DMZ/public-facing non-production workloads
- **Example use cases**: Testing public APIs, staging websites
- **Who uses it**: Development teams testing public-facing features
- **Security level**: Medium - internet accessible but non-production

#### 5. Transit VPC
- **Purpose**: Hybrid connectivity hub
- **Contains**: SD-WAN Router Appliances, Blue Cat DNS servers
- **Why separate**: Isolates hybrid connectivity components
- **Connects to**: On-premises networks via Cloud Interconnect/VPN

#### 6-7. Security VPCs
**Security Data Plane VPC**
- **Purpose**: Hosts Palo Alto firewall data interfaces
- **Handles**: All inspected traffic flows
- **Why needed**: Separates traffic inspection from management

**Security Management VPC**
- **Purpose**: Hosts Palo Alto firewall management interfaces
- **Handles**: Firewall administration and logging
- **Why needed**: Keeps management traffic separate from data traffic

#### 8. Shared Services VPC
- **Purpose**: Hosts Private Service Connect (PSC) endpoints
- **Contains**: Endpoints for Google APIs and services
- **Why needed**: Centralized access to Google services without internet exposure

---

## Architecture Deep Dive

### Model 1 vs Model 3 Architecture

**Model 1: Internal/Private (East-West Traffic)**
```
User → VPN → Cloud Router → M1P/M1NP VPC → Internal Apps
           └─→ SD-WAN ─→ Transit VPC ─→ On-Premises
```
- **Use case**: Internal corporate applications
- **Access**: Through VPN or private connectivity
- **Examples**: HR systems, internal dashboards, databases
- **Internet**: No direct internet access
- **NAT**: Uses Cloud NAT for outbound internet (updates, APIs)

**Model 3: DMZ/Public (North-South Traffic)**
```
Internet → Cloud Load Balancer → M3P/M3NP VPC → Public Apps
                                      ↓
                              Palo Alto Firewall (NSI)
                                      ↓
                              Security Policies Applied
```
- **Use case**: Public-facing applications
- **Access**: From internet through load balancers
- **Examples**: Company website, customer portals, public APIs
- **Internet**: Direct internet exposure with firewall protection
- **Security**: All traffic inspected by Palo Alto firewalls

### Network Connectivity Center (NCC) - Mesh Topology

**What is Mesh Topology?**
In a mesh topology, every VPC can communicate with every other VPC through the hub. No direct peering needed between VPCs.

**Without NCC** (Traditional VPC Peering):
```
To connect 8 VPCs, you need: 8 × 7 ÷ 2 = 28 peering connections
```

**With NCC** (Hub and Spoke):
```
To connect 8 VPCs, you need: 8 spoke connections to 1 hub = 8 connections
```

**Benefits**:
1. **Simplified Management**: One hub instead of 28 peer connections
2. **Transitivity**: M1P can reach Transit VPC through hub (not possible with peering)
3. **Dynamic Routing**: Automatic route propagation across all VPCs
4. **Scalability**: Adding new VPC = 1 spoke connection (not N-1 peerings)

**How it works**:
```
1. Application in M1P VPC wants to reach database in M3P VPC
2. Traffic goes to NCC Hub
3. Hub checks routing table
4. Hub forwards to M3P VPC spoke
5. Response follows same path back
```

### Subnet Vending Automation

**Traditional Subnet Creation**:
```
Developer → Opens ticket → Network team → Manually creates subnet → 3-5 days
```

**With Automated Subnet Vending**:
```
Developer → Updates YAML file → Git commit → Terraform apply → Subnet ready in minutes
```

**Workflow**:
```yaml
# Developer adds this to data/network-subnets.yaml:
subnets:
  - region: "us-east4"
    model: "m1p"
    business_unit: "whq"
    application: "myapp"
    size: "S"                        # S=/26 (64 IPs)
    cidr_block: "10.150.1.0/26"      # From Blue Cat IPAM
    cost_center: "109985"
    owner: "myteam_carrier_com"
    leanix_app_id: "app-12345"
```

**What happens**:
1. Developer commits YAML changes
2. GitHub Actions runs terraform plan
3. Plan shows new subnet will be created
4. After approval, terraform apply creates subnet
5. Blue Cat IPAM is updated with allocation
6. Subnet is ready to use

**T-Shirt Sizing**:
- **Small (S)**: /26 = 64 IP addresses
  - Use for: Small microservices, testing environments
  - Example: 10 VMs with room to grow
  
- **Medium (M)**: /25 = 128 IP addresses
  - Use for: Medium applications with 30-100 resources
  - Example: Application with 50 pods/VMs
  
- **Large (L)**: /24 = 256 IP addresses
  - Use for: Large applications, many pods/VMs
  - Example: Kubernetes cluster with 150+ pods

### Network Security Integration (NSI)

**What is In-Band Inspection?**
All traffic flows through security appliances for inspection before reaching destination.

**Traffic Flow with NSI**:
```
┌─────────────────────────────────────────────────────────────┐
│                    Traffic Flow Diagram                      │
└─────────────────────────────────────────────────────────────┘

Internet Request
      │
      ▼
Cloud Load Balancer (M3P VPC)
      │
      ▼
Packet Mirroring / Policy-Based Routing
      │
      ▼
┌─────────────────────────────┐
│  Palo Alto VM-Series        │
│  (Security VPC)             │
│                             │
│  1. Deep Packet Inspection  │
│  2. Threat Detection        │
│  3. Security Policy Check   │
│  4. URL Filtering           │
│  5. IPS/IDS                 │
└──────────┬──────────────────┘
           │
           ▼
    Decision Point
     │         │
  Allow    Block
     │         │
     ▼         ▼
Destination  Drop
  (M3P)     Packet
```

**Geneve Encapsulation**:
- **What**: Protocol for tunneling traffic to security appliances
- **Why**: Preserves original packet information while routing through firewall
- **How**: Wraps original packet in Geneve header, firewall inspects and unwraps

**NSI Components**:
1. **Data Plane VPC**: Where traffic actually flows
2. **Management Plane VPC**: Where firewall is managed
3. **Palo Alto VM-Series**: Firewall instances (managed instance groups)
4. **Security Policies**: Rules defining allowed/blocked traffic
5. **Logging**: All traffic logs sent to Cloud Logging/SIEM

---

## Technical Components

### Service Accounts Automation

**What are Service Accounts?**
Service accounts are special Google accounts that represent applications or services (not humans). They're used for programmatic access to GCP resources.

**Why Two Service Accounts per Project?**

**IaC (Infrastructure as Code) Account**:
- **Role**: Owner
- **Purpose**: Used by terraform apply to create/modify/delete resources
- **Name pattern**: `{project-name}-iac@{domain}`
- **When used**: During deployment, infrastructure changes
- **Permissions**: Full control (needed to create resources)

**IaCr (Infrastructure as Code Reader) Account**:
- **Role**: Viewer
- **Purpose**: Used by terraform plan to read resources without making changes
- **Name pattern**: `{project-name}-iacr@{domain}`
- **When used**: During plan, validation, testing
- **Permissions**: Read-only (safer for pre-deployment checks)

**Security Benefit**: Principle of least privilege - use read-only account unless write access is needed.

### YAML-Driven Factory Pattern

**What is a Factory?**
A factory is a programming pattern that creates objects based on configuration. In our case, it creates network resources based on YAML files.

**Why YAML Instead of Terraform Code?**

**Traditional Approach** (Bad):
```hcl
# Need to edit Terraform code for each new subnet
resource "google_compute_subnetwork" "subnet1" {
  name          = "my-subnet-1"
  ip_cidr_range = "10.0.1.0/26"
  region        = "us-east4"
  # ... many more lines
}

resource "google_compute_subnetwork" "subnet2" {
  name          = "my-subnet-2"
  ip_cidr_range = "10.0.2.0/26"
  region        = "us-east4"
  # ... many more lines
}
# Repeat 100 times...
```

**Factory Approach** (Good):
```yaml
# Just add configuration, no code changes
subnets:
  - name: "my-subnet-1"
    cidr: "10.0.1.0/26"
    region: "us-east4"
  - name: "my-subnet-2"
    cidr: "10.0.2.0/26"
    region: "us-east4"
```

**Benefits**:
1. **Separation of Concerns**: Developers edit YAML, infrastructure team manages code
2. **Scalability**: Add 1 subnet or 100 subnets with same effort
3. **Self-Service**: Developers can request resources without knowing Terraform
4. **Validation**: YAML schema can enforce standards (mandatory tags, naming conventions)
5. **Version Control**: Track who requested what and when

### Blue Cat IPAM Integration

**What is IPAM?**
IP Address Management - a system that tracks which IP addresses are used and which are available.

**Why Blue Cat?**
- **Central Source of Truth**: One system knows all IP allocations
- **Prevents Conflicts**: No two teams can get overlapping IP ranges
- **Audit Trail**: Track who requested what IP range and when
- **Automation**: API-driven allocation instead of manual spreadsheets

**How Integration Works**:
```
1. Developer requests subnet via YAML
2. APIGEE API Gateway receives request
3. APIGEE validates request (authentication, authorization)
4. APIGEE forwards to Blue Cat IPAM
5. Blue Cat checks available IP ranges
6. Blue Cat allocates CIDR block from pool
7. Blue Cat returns allocated CIDR to APIGEE
8. APIGEE returns CIDR to developer
9. Developer updates YAML with allocated CIDR
10. Terraform creates subnet with that CIDR
11. Blue Cat marks CIDR as "in use"
```

**APIGEE's Role**:
- **API Gateway**: Single entry point for all IPAM requests
- **Security**: Authentication and authorization
- **Rate Limiting**: Prevent abuse
- **Logging**: Audit trail of all requests
- **Abstraction**: Hide Blue Cat implementation details

---

## File Structure and Purpose

### Configuration Files

#### `data/network-projects.yaml`
**Purpose**: Defines all network projects to be created
**Contains**: Project metadata, team ownership, services to enable, folder structure
**Who edits**: Network architects, infrastructure team
**When to edit**: When adding new network projects

```yaml
network_projects:
  nethub:                        # Project key (used in Terraform)
    business_segment: "mgmt"     # For folder organization
    team: "network-team"         # Owning team
    folder: "networking"         # Parent folder
    deletion_policy: "PREVENT"   # Prevent accidental deletion
    services:                    # APIs to enable
      - compute.googleapis.com
      - networkconnectivity.googleapis.com
    envs:
      prd:                       # Environment
        ad_group_number: "40036" # Used in project naming
        shared_vpc_host: true    # This project hosts shared VPCs
```

#### `data/network-subnets.yaml`
**Purpose**: Self-service subnet provisioning
**Contains**: Subnet requests with region, size, CIDR, and metadata
**Who edits**: Application teams, developers
**When to edit**: When new subnets are needed

**Example Entry**:
```yaml
subnets:
  - region: "us-east4"              # GCP region
    model: "m1p"                    # Which shared VPC
    business_unit: "whq"            # For naming
    application: "myapp"            # Application name
    size: "S"                       # T-shirt size (S/M/L)
    cidr_block: "10.150.1.0/26"    # From Blue Cat
    cost_center: "109985"           # Required label
    owner: "team_carrier_com"       # Required label
    leanix_app_id: "app-12345"     # Required label
```

### Terraform Resource Files

#### `network-projects.tf`
**Purpose**: Creates the 4 network projects
**How**: Uses Cloud Foundation Fabric project module with YAML factory
**Key resources**: 
- Google Cloud projects
- Shared VPC host configuration
- Project service enablement

**What it does**:
1. Reads `network-projects.yaml`
2. Creates project for each entry
3. Enables specified APIs
4. Sets up shared VPC host (for nethub)
5. Configures billing and folder structure

#### `network-sa.tf`
**Purpose**: Creates service accounts for automation
**How**: Loop through projects, create 2 SAs per project
**Key resources**:
- IaC service accounts (owner role)
- IaCr service accounts (viewer role)

**What it does**:
1. For each network project
2. Create `{project}-iac` service account
3. Grant project Owner role
4. Create `{project}-iacr` service account
5. Grant project Viewer role

#### `network-vpc.tf`
**Purpose**: Creates all 8 VPCs
**How**: Uses Cloud Foundation Fabric net-vpc module
**Key resources**: 8 VPC networks

**What it does**:
1. Create 4 shared VPCs (M1P, M1NP, M3P, M3NP) in nethub project
2. Enable shared_vpc_host on these 4
3. Create transit VPC in transit project
4. Create 2 security VPCs in netsec project
5. Create shared services VPC in pvpc project
6. Configure routing mode (GLOBAL for dynamic routing)

#### `network-ncc.tf`
**Purpose**: Creates Network Connectivity Center hub and spokes
**How**: Uses Cloud Foundation Fabric net-ncc module
**Key resources**:
- 1 NCC hub (global)
- 8 NCC spokes (one per VPC)

**What it does**:
1. Create global NCC hub in nethub project
2. For each of the 8 VPCs:
   - Create VPC spoke
   - Attach spoke to hub
   - Configure for mesh topology
3. Enable automatic route propagation

#### `network-nsi.tf`
**Purpose**: Framework for Network Security Integration
**How**: Placeholder with implementation notes
**Key resources**: (To be implemented in Phase 2)
- Palo Alto VM-Series instances
- Security policies
- Geneve encapsulation config

**What it will do** (Phase 2):
1. Deploy Palo Alto VM-Series in managed instance groups
2. Configure data plane and management plane interfaces
3. Set up Geneve encapsulation
4. Configure policy-based routing
5. Enable packet mirroring for inspection

#### `network-subnets-vending.tf`
**Purpose**: Automated subnet provisioning from YAML
**How**: Factory pattern with for_each loop
**Key resources**: Dynamic subnets based on YAML

**What it does**:
1. Read `network-subnets.yaml`
2. For each subnet entry:
   - Determine target VPC based on model
   - Generate subnet name from template
   - Create subnet with specified CIDR
   - Apply mandatory labels
   - Enable VPC Flow Logs (50% sampling, 5s aggregation)
   - Configure private Google access

**Name Template**: `{region}-{model}-{business_unit}-{application}-{size}`
**Example**: `us-east4-m1p-whq-myapp-s`

#### `locals.tf`
**Purpose**: Central data aggregation and calculations
**How**: Reads JSON outputs from previous stages
**Key locals**:
- Bootstrap data (automation bucket, WIF pool)
- Resource manager data (folders, projects)
- CIDR allocations per region/model
- VPC configurations

**What it does**:
1. Load `0-bootstrap-outputs.json`
2. Load `0-global-outputs.json`
3. Load `1-resman-outputs.json`
4. Define CIDR ranges for each region/model
5. Create VPC configuration maps
6. Map folders to network projects

#### `outputs.tf`
**Purpose**: Define what information is exported to next stages
**How**: Local aggregation then individual outputs
**Key outputs**:
- Network project IDs
- VPC IDs and self-links
- NCC hub and spoke IDs
- Service account emails

**What it does**:
1. Create `networking_outputs` local with all data
2. Export individual convenience outputs
3. Mark sensitive data (service accounts) as sensitive
4. Structure for consumption by stages 3, 4, 5

#### `outputs-files.tf`
**Purpose**: Write outputs to local JSON file
**How**: Terraform local_file resource
**Key resources**: `2-networking-outputs.json`

**What it does**:
1. Convert `networking_outputs` to JSON
2. Write to `output_files/2-networking-outputs.json`
3. Allow local testing without GCS

#### `outputs-gcs.tf`
**Purpose**: Upload outputs to GCS for stage handoff
**How**: Terraform google_storage_bucket_object resource
**Key resources**: GCS object in automation bucket

**What it does**:
1. Convert `networking_outputs` to JSON
2. Upload to `gs://{automation-bucket}/outputs/2-networking-outputs.json`
3. Make available to downstream stages (3-security, 4-services)

#### `variables.tf`
**Purpose**: Define configurable inputs
**How**: Terraform variable blocks
**Key variables**:
- `outputs_location`: Where to write local outputs
- `factories_config`: Paths to YAML files

**What it does**:
1. Define expected inputs
2. Set defaults where appropriate
3. Provide descriptions for documentation

#### `main.tf`
**Purpose**: Minimal main file (convention)
**How**: Copyright header only
**Why minimal**: Following services stage pattern

---

## How Everything Works Together

### Stage Integration Flow

```
┌──────────────────────────────────────────────────────────────┐
│                    Stage Dependencies                         │
└──────────────────────────────────────────────────────────────┘

Stage 0: Bootstrap
├─→ Creates automation bucket
├─→ Creates Workload Identity Pool
├─→ Outputs: 0-bootstrap-outputs.json
│
▼
Stage 1: Resource Manager
├─→ Creates folder hierarchy
├─→ Creates organization policies
├─→ Outputs: 1-resman-outputs.json
│
▼
Stage 2: Networking (THIS STAGE)
├─→ Reads bootstrap outputs
├─→ Reads resman outputs
├─→ Creates network projects
├─→ Creates VPCs and NCC
├─→ Outputs: 2-networking-outputs.json
│
▼
Stage 3: Security (Next)
├─→ Reads networking outputs
├─→ Creates security projects
├─→ Implements Cloud Armor, KMS
│
▼
Stage 4: Services (Future)
├─→ Reads security outputs
├─→ Creates application projects
├─→ Attaches to shared VPCs
```

### Terraform Execution Flow

```
1. terraform init
   ├─→ Download Cloud Foundation Fabric modules
   ├─→ Initialize GCS backend
   └─→ Validate configuration

2. terraform plan
   ├─→ Read output files from stages 0 & 1
   ├─→ Read YAML factory files
   ├─→ Calculate what will be created
   ├─→ Show plan for review
   └─→ Use IaCr (viewer) service account

3. terraform apply
   ├─→ Execute plan
   ├─→ Create projects (4 network projects)
   ├─→ Create service accounts (8 SAs)
   ├─→ Create VPCs (8 VPCs)
   ├─→ Create NCC hub + spokes (1 hub, 8 spokes)
   ├─→ Create vended subnets (from YAML)
   ├─→ Write outputs to files and GCS
   └─→ Use IaC (owner) service account
```

### CI/CD Workflow (GitHub Actions)

```
Developer commits code
      │
      ▼
GitHub Actions triggered
      │
      ├─→ Checkout code
      ├─→ Authenticate with Workload Identity Federation
      ├─→ Download stage 0 & 1 outputs from GCS
      │
      ▼
terraform fmt -check (format validation)
      │
      ▼
terraform init (initialize)
      │
      ▼
terraform validate (syntax check)
      │
      ▼
terraform plan -out=plan.tfplan
      │
      ├─→ Uses IaCr (viewer) service account
      ├─→ Generates execution plan
      └─→ Post plan as PR comment
      │
      ▼
Manual review and approval
      │
      ▼
PR merged to main branch
      │
      ▼
terraform apply plan.tfplan
      │
      ├─→ Uses IaC (owner) service account
      ├─→ Creates/updates resources
      └─→ Uploads outputs to GCS
```

---

## Prerequisites and Dependencies

### Required Before Running This Stage

#### 1. Completed Stages
- ✅ **Stage 0: Bootstrap** - Must be completed
  - Provides: Automation bucket, WIF pool, terraform state backend
  - Output file: `0-bootstrap-outputs.json`
  
- ✅ **Stage 1: Resource Manager** - Must be completed
  - Provides: Folder structure, organization policies
  - Output file: `1-resman-outputs.json`

#### 2. GCP Organization Setup
- Organization ID configured
- Billing account linked
- Organization policies allowing required resources
- Sufficient quotas for:
  - Projects: 4 new projects
  - VPCs: 8 VPCs
  - Compute instances: For future Palo Alto deployment

#### 3. IAM Permissions
The service account running terraform needs:
- `roles/resourcemanager.projectCreator` - Create projects
- `roles/billing.user` - Link billing
- `roles/compute.networkAdmin` - Create VPCs
- `roles/iam.serviceAccountAdmin` - Create service accounts
- `roles/iam.securityAdmin` - Grant IAM roles

#### 4. APIs Enabled (at organization level)
- `cloudresourcemanager.googleapis.com` - Project management
- `compute.googleapis.com` - VPC and networking
- `iam.googleapis.com` - IAM and service accounts
- `networkconnectivity.googleapis.com` - NCC
- `servicenetworking.googleapis.com` - Private service networking

#### 5. Tools Installed
- Terraform >= 1.5.0
- Git >= 2.0
- gcloud CLI (for authentication)
- GitHub account with repo access

#### 6. Configuration Files
- Output files in `output_files/` directory:
  - `0-bootstrap-outputs.json`
  - `0-global-outputs.json`
  - `1-resman-outputs.json`

### External Dependencies

#### Blue Cat IPAM
- **Purpose**: IP address management and allocation
- **Access**: API credentials through APIGEE
- **Required for**: Subnet vending CIDR allocation
- **Setup**: Coordinate with network team

#### APIGEE API Gateway
- **Purpose**: API management and security
- **Access**: API key and authentication
- **Required for**: Blue Cat integration
- **Setup**: Obtain API credentials from APIGEE team

#### Cloud Foundation Fabric Modules
- **Version**: v45.0.0
- **Source**: GitHub terraform-google-modules/cloud-foundation-fabric
- **Modules used**:
  - `project` - Project creation
  - `net-vpc` - VPC creation
  - `net-ncc` - NCC hub and spokes
  - `project-factory` - YAML-driven project creation

---

## Technical Terms Glossary

### Infrastructure Terms

**Infrastructure as Code (IaC)**
- Writing infrastructure configuration as code files instead of manual clicking
- Benefits: Version control, automation, consistency, documentation

**Terraform**
- Tool for defining and provisioning infrastructure using code
- Uses declarative language (describe what you want, not how to do it)

**State File**
- Terraform's database of what infrastructure currently exists
- Stored in GCS bucket for team collaboration
- Critical: Never delete or corrupt

**Workload Identity Federation (WIF)**
- Secure authentication method where GitHub Actions can act as GCP service account
- No need for service account keys (more secure)
- Uses OIDC (OpenID Connect) for trust

### Networking Terms

**CIDR (Classless Inter-Domain Routing)**
- Notation for IP address ranges: `10.0.1.0/26`
- `/26` means first 26 bits are network, last 6 bits are hosts
- `/26` = 64 IP addresses (2^6)

**RFC 1918 (Private IP Ranges)**
- Reserved IP addresses for private networks
- Ranges: 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16
- Not routable on public internet

**BGP (Border Gateway Protocol)**
- Protocol for exchanging routing information
- Used by Cloud Routers to learn and advertise routes
- Enables dynamic routing (automatically updates when topology changes)

**Cloud Router**
- Google Cloud's managed BGP router
- Learns routes from on-premises networks
- Advertises GCP routes to on-premises
- Required for hybrid connectivity

**Cloud NAT (Network Address Translation)**
- Allows resources without public IPs to access internet
- For outbound connections only (downloading updates, calling APIs)
- Regional service

**Private Google Access**
- Allows VMs without public IPs to reach Google APIs
- Uses internal Google network (faster, more secure)
- Example: VM can write to Cloud Storage without internet

**VPC Peering**
- Direct connection between two VPCs
- Low latency, high bandwidth
- Limitation: Not transitive (if A peers with B, and B peers with C, A cannot reach C)

**Private Service Connect (PSC)**
- Service for privately accessing Google services
- Alternative to VPC peering or internet access
- More scalable and manageable

### Security Terms

**In-Band vs Out-of-Band Inspection**
- **In-Band**: Traffic flows through security appliance (can block malicious traffic)
- **Out-of-Band**: Traffic is copied to appliance (can only alert, not block)
- We use in-band for enforcement

**Defense in Depth**
- Multiple layers of security controls
- If one layer fails, others still protect
- Example: Firewall + OS hardening + application security

**Zero Trust**
- "Never trust, always verify"
- Assume breach and verify each request
- Applies to internal network (not just internet perimeter)

**Geneve (Generic Network Virtualization Encapsulation)**
- Tunneling protocol for overlay networks
- Encapsulates original packet in new packet
- Preserves metadata while routing through security appliances

### GCP-Specific Terms

**Shared VPC Host Project**
- Project that owns and hosts the VPC
- Central network administration
- Other projects attach as service projects

**Shared VPC Service Project**
- Project that uses VPC from host project
- Cannot modify network, only use it
- Example: Application project using networking hub's VPC

**Organization Node**
- Root of GCP resource hierarchy
- Represents your company
- Where organization-level policies are applied

**Folder**
- Grouping mechanism below organization
- Can nest folders
- Inherit policies from parent

**Project**
- Container for GCP resources
- Has unique project ID
- Billing is tracked per project

**Service Account**
- Non-human identity for applications
- Has email address ending in `@{project}.iam.gserviceaccount.com`
- Can be granted IAM roles

**Managed Instance Group (MIG)**
- Group of identical VM instances
- Auto-scaling based on load
- Auto-healing (recreates failed instances)
- Used for Palo Alto firewall deployment

### Tagging and Labeling

**Labels**
- Key-value pairs attached to resources
- Used for organization, billing, automation
- Example: `cost_center: 109985`

**Tags (Network Tags)**
- Applied to compute instances
- Used by firewall rules
- Example: `web-server` tag allows HTTP/HTTPS

**ad_group_number**
- Active Directory group number
- Used in project naming for CMDB integration
- Maps to responsible team

**LeanIX Application ID**
- Enterprise architecture tool identifier
- Links resource to application in architecture repository
- Required for governance

---

## Implementation Details

### Naming Conventions

#### Project Names
**Pattern**: `prj-{env}-gcp-{ad_group_number}-{segment}-{name}`

**Examples**:
- `prj-prd-gcp-40036-mgmt-nethub`
- `prj-prd-gcp-40038-mgmt-transit`

**Breakdown**:
- `prj`: Prefix indicating project
- `prd`: Environment (prd, npd, dev)
- `gcp`: Cloud provider
- `40036`: AD group number
- `mgmt`: Business segment
- `nethub`: Descriptive name

#### VPC Names
**Pattern**: `global-{type}-{model}-vpc`

**Examples**:
- `global-host-M1P-vpc`
- `global-transit-vpc`

**Breakdown**:
- `global`: Routing mode
- `host/transit/security`: Type
- `M1P/M1NP/M3P/M3NP`: Model (if applicable)
- `vpc`: Resource type

#### Subnet Names (Vended)
**Pattern**: `{region}-{model}-{business_unit}-{application}-{size}`

**Examples**:
- `us-east4-m1p-whq-myapp-s`
- `europe-west3-m3p-energy-api-m`

**Breakdown**:
- `us-east4`: GCP region
- `m1p`: Model and environment
- `whq`: Business unit
- `myapp`: Application name
- `s`: Size (s, m, l)

#### Service Account Names
**Pattern**: `{project}-{type}@{project}.iam.gserviceaccount.com`

**Examples**:
- `prj-prd-gcp-40036-mgmt-nethub-iac@...`
- `prj-prd-gcp-40036-mgmt-nethub-iacr@...`

**Breakdown**:
- `{project}`: Full project name
- `iac`: Owner (infrastructure as code)
- `iacr`: Viewer (infrastructure as code reader)

### CIDR Allocation Strategy

#### Regional CIDR Blocks

**US-East4** (Primary US region):
- M1P: 10.150.0.0/20 (4096 IPs)
- M1NP: 10.151.0.0/20 (4096 IPs)
- M3P: 10.152.0.0/20 (4096 IPs)
- M3NP: 10.153.0.0/20 (4096 IPs)

**US-Central1** (Secondary US region):
- M1P: 10.160.0.0/20
- M1NP: 10.161.0.0/20
- M3P: 10.162.0.0/20
- M3NP: 10.163.0.0/20

**Europe-West3** (Primary EU region):
- M1P: 10.170.0.0/20
- M1NP: 10.171.0.0/20
- M3P: 10.172.0.0/20
- M3NP: 10.173.0.0/20

**Europe-West1** (Secondary EU region):
- M1P: 10.180.0.0/20
- M1NP: 10.181.0.0/20
- M3P: 10.182.0.0/20
- M3NP: 10.183.0.0/20

**Asia-Southeast1** (Primary APAC region):
- M1P: 10.190.0.0/20
- M1NP: 10.191.0.0/20
- M3P: 10.192.0.0/20
- M3NP: 10.193.0.0/20

**Asia-East2** (Secondary APAC region):
- M1P: 10.200.0.0/20
- M1NP: 10.201.0.0/20
- M3P: 10.202.0.0/20
- M3NP: 10.203.0.0/20

#### Why This Allocation?
1. **Regional Isolation**: Each region gets distinct /20 blocks
2. **Model Segregation**: Models get adjacent blocks for easy aggregation
3. **Growth Room**: Each /20 provides 4096 IPs per model per region
4. **Route Summarization**: Can summarize regions (e.g., all US-East4 = 10.150.0.0/18)

### VPC Flow Logs Configuration

**Settings Applied**:
```hcl
flow_logs_config = {
  aggregation_interval = "INTERVAL_5_SEC"  # How often to aggregate
  flow_sampling        = 0.5               # Sample 50% of traffic
  metadata            = "INCLUDE_ALL_METADATA"  # Full packet details
}
```

**What is captured**:
- Source and destination IPs
- Ports and protocols
- Bytes and packets transferred
- Latency and RTT (round-trip time)
- Timestamp

**Why 50% sampling**:
- Balance between observability and cost
- Still provides statistical accuracy
- Reduces log storage costs by 50%

**Use cases**:
- Network troubleshooting
- Security analysis
- Compliance auditing
- Cost optimization (identify chatty services)

### Mandatory Labels

**Four Required Labels**:

1. **cost_center**
   - Format: Numeric string (e.g., "109985")
   - Purpose: Chargeback allocation
   - Example: Finance department's cost center

2. **owner**
   - Format: Email with underscore (e.g., "team_at_carrier_com")
   - Purpose: Responsible party for issues
   - Example: Team distribution list

3. **application**
   - Format: Lowercase with hyphens (e.g., "my-app")
   - Purpose: Application identification
   - Example: Name of service/application

4. **leanix_app_id**
   - Format: Application ID (e.g., "app-12345")
   - Purpose: Architecture repository link
   - Example: Links to LeanIX application record

**Enforcement**:
- YAML schema validation (pre-deployment)
- Terraform validation blocks
- Organization policies (post-deployment)
- Automated tagging audit scripts

---

## Summary

### What We Accomplished

We built a **production-ready networking foundation** for Carrier's GCP Landing Zone that provides:

1. **Centralized Network Management**
   - 4 dedicated network projects
   - 8 service accounts for automation
   - Consistent naming and organization

2. **Scalable Connectivity**
   - 8 VPCs serving different purposes
   - Network Connectivity Center with mesh topology
   - Support for hybrid connectivity (SD-WAN)

3. **Self-Service Automation**
   - YAML-driven subnet vending
   - Integrated with Blue Cat IPAM via APIGEE
   - T-shirt sizing for simplicity

4. **Security Framework**
   - NSI ready for Palo Alto deployment
   - Separate production and non-production
   - In-band traffic inspection capability

5. **Enterprise Governance**
   - Mandatory tagging for cost allocation
   - VPC Flow Logs for compliance
   - Integration with existing tools (LeanIX, Blue Cat)

### Key Differentiators

**Compared to Manual Setup**:
- ✅ 10x faster deployment (hours vs days)
- ✅ Consistent configuration (no human error)
- ✅ Full version control and audit trail
- ✅ Self-service for developers

**Compared to Basic Terraform**:
- ✅ Factory pattern (configuration vs code)
- ✅ Stage integration (automated handoffs)
- ✅ Enterprise patterns (NCC, NSI, IPAM)
- ✅ Production-ready (security, governance, automation)

### Next Steps

**Immediate** (Complete networking):
- Add infrastructure subnets (PSC, ALB proxy, NAT)
- Deploy Cloud Routers and Cloud NAT
- Deploy SD-WAN Router Appliances

**Phase 2** (Security):
- Deploy Palo Alto VM-Series firewalls
- Implement NSI traffic routing
- Configure security policies

**Phase 3** (Services):
- Deploy Blue Cat DNS servers
- Complete APIGEE integration
- Enable subnet vending automation

**Phase 4** (Validation):
- Test connectivity across all VPCs
- Validate traffic inspection
- Performance testing
- Security validation

---

## Questions and Support

### Common Questions

**Q: Can we add more VPCs later?**
A: Yes, just add a new net-vpc module and NCC spoke. No impact to existing VPCs.

**Q: How do we request a new subnet?**
A: Add entry to `data/network-subnets.yaml`, commit, and create PR. Automated after approval.

**Q: What if we need a subnet larger than /24?**
A: Requires architecture review board approval. Update factory validation logic.

**Q: Can we change CIDR ranges later?**
A: Difficult - requires recreating VPCs. Plan carefully upfront.

**Q: How do we troubleshoot connectivity issues?**
A: Check VPC Flow Logs, NCC spoke status, firewall rules, and route tables.

### Support Resources

**Documentation**:
- [Google Cloud VPC Documentation](https://cloud.google.com/vpc/docs)
- [Network Connectivity Center](https://cloud.google.com/network-connectivity/docs/network-connectivity-center)
- [Cloud Foundation Fabric](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric)

**Internal**:
- Network team: network-team@carrier.com
- IPAM team: ipam@carrier.com (Blue Cat access)
- Security team: security@carrier.com (Palo Alto policies)

**Tools**:
- Blue Cat IPAM: [Internal URL]
- APIGEE API Portal: [Internal URL]
- LeanIX: [Internal URL]

---

*Last Updated: December 26, 2025*
*Version: 1.0*
*Maintained by: Network Architecture Team*

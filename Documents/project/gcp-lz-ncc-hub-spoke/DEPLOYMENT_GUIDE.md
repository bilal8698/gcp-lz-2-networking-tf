# NCC Hub-Spoke Deployment Guide

## Deployment Overview

Following **Vijay's pattern**: YAML-driven, modular Terraform deployment

### Deployment Phases

```
Phase 1: NCC Hub + 8 VPC Spokes (No Palo Alto dependency)
Phase 2: Transit RA Spoke (After Palo Alto deployment)
```

---

## Phase 1: Deploy NCC Hub and VPC Spokes

### Step 1: Configure YAML Files

All configuration is in the `data/` directory:

#### 1. Hub Configuration (`ncc-hub-config.yaml`)
```yaml
hub:
  project_id: prj-prd-gcp-40036-mgmt-nethub
  name: carrier-ncc-hub-prod
  description: "Carrier Production NCC Hub"
  enable_global_routing: false
```

#### 2. VPC Spokes Configuration (`vpc-spokes-config.yaml`)

Configure all 8 VPC spokes:
- **Model Spokes:** M1P, M1NP, M3P, M3NP
- **Network VPCs:** FW Data, FW Mgmt, Shared Services, Transit

**Example configuration:**
```yaml
spokes:
  m1p:
    name: carrier-ncc-spoke-m1p
    project_id: prj-prd-gcp-40036-m1p-host
    vpc_name: global-host-m1p-vpc
    region: us-central1
    zone: model-1
```

### Step 2: Set Variables

Create `terraform.tfvars`:
```hcl
# Required variables
outputs_bucket = "carrier-terraform-outputs"
project_id     = "prj-prd-gcp-40036-mgmt-nethub"
region         = "us-central1"

# Phase 1: Deploy VPC spokes only (no Transit RA)
deploy_transit_spoke = false
```

### Step 3: Deploy Phase 1

```bash
cd terraform/

# Initialize Terraform
terraform init

# Review the plan (should show 9 resources: 1 hub + 8 VPC spokes)
terraform plan

# Apply Phase 1
terraform apply
```

**Expected Resources:**
- 1 NCC Hub
- 8 VPC Spokes (M1P, M1NP, M3P, M3NP, FW Data, FW Mgmt, Shared Services, Transit)

---

## Phase 2: Deploy Transit RA Spoke (After Palo Alto)

### Prerequisites
✅ Palo Alto firewalls deployed via `gcp-palo-alto-bootstrap`
✅ Firewall VMs accessible in Transit VPC

### Step 1: Update Transit Configuration

Edit `data/transit-spoke-config.yaml`:

```yaml
transit:
  spoke_name: carrier-ncc-spoke-transit-ra
  router_name: carrier-transit-router
  router_asn: 64512
  
  # Update with actual Palo Alto VM URIs
  router_appliances:
    interface0:
      vm_uri: "projects/prj-prd-gcp-40036-mgmt-nethub/zones/us-central1-a/instances/carrier-palo-region1-fw01"
      ip_address: "10.1.10.10"
      peer_ip: "10.1.10.1"
      peer_asn: 65001
      route_priority: 100
    
    interface1:
      vm_uri: "projects/prj-prd-gcp-40036-mgmt-nethub/zones/us-central1-b/instances/carrier-palo-region1-fw02"
      ip_address: "10.1.10.11"
      peer_ip: "10.1.10.2"
      peer_asn: 65002
      route_priority: 110
```

### Step 2: Enable Transit RA Spoke

Update `terraform.tfvars`:
```hcl
# Enable Transit Router Appliance spoke
deploy_transit_spoke = true
```

### Step 3: Deploy Phase 2

```bash
# Review the plan (should show Transit RA spoke resources)
terraform plan

# Apply Phase 2
terraform apply
```

**Expected Additional Resources:**
- 1 Cloud Router (carrier-transit-router)
- 1 NCC RA Spoke (carrier-ncc-spoke-transit-ra)
- 2 BGP Peers (interface0, interface1)

---

## Verification

### Verify NCC Hub
```bash
gcloud network-connectivity hubs describe carrier-ncc-hub-prod \
  --project=prj-prd-gcp-40036-mgmt-nethub
```

### Verify VPC Spokes
```bash
gcloud network-connectivity spokes list \
  --hub=carrier-ncc-hub-prod \
  --project=prj-prd-gcp-40036-mgmt-nethub
```

### Verify Transit Router & BGP Peers
```bash
# Check Cloud Router
gcloud compute routers describe carrier-transit-router \
  --region=us-central1 \
  --project=prj-prd-gcp-40036-mgmt-nethub

# Check BGP sessions
gcloud compute routers get-status carrier-transit-router \
  --region=us-central1 \
  --project=prj-prd-gcp-40036-mgmt-nethub
```

---

## Outputs

All outputs are stored in GCS: `gs://carrier-terraform-outputs/outputs/ncc-hub-spoke.json`

### Key Outputs for Downstream Modules

- **ncc_hub_id** - Hub ID for other modules
- **vpc_spoke_ids** - Map of spoke IDs (all 8 VPC spokes)
- **transit_router_id** - For HA-VPN integration
- **transit_router_self_link** - For HA-VPN configuration
- **transit_bgp_peers** - BGP peer details for Palo Alto

---

## Troubleshooting

### Issue: Spoke Creation Fails
**Solution:** Ensure VPCs exist in the specified projects

### Issue: Transit RA Spoke Fails
**Solution:** Verify Palo Alto VMs are running and reachable

### Issue: BGP Peers Not Established
**Solution:** Check Palo Alto BGP configuration matches peer IPs/ASNs

---

## Vijay's Key Points

> "The NCC would be in the network project (prj-prd-gcp-40036-mgmt-nethub) this project will create a HUB and those three VPC's are FW Data VPC, FW Mgmt VPC, Shared Services VPC and Transit also."

> "We will create a HUB in the NCC and these all will set it up as spoke."

> "Interface 0 is one directional and the interface 1 is another directional and peering also we have."

> "Everything should be variabalized. As instead of tfvar files we are going with the Data and putting it as the yaml files."

---

## Next Steps

1. ✅ Deploy NCC Hub and VPC Spokes (Phase 1)
2. ⏳ Deploy Palo Alto firewalls (`gcp-palo-alto-bootstrap`)
3. ⏳ Deploy Transit RA Spoke (Phase 2)
4. ⏳ Configure HA-VPN (`gcp-lz-ha-vpn`)
5. ⏳ Deploy Cloud Routers (`gcp-lz-cloud-routers`)

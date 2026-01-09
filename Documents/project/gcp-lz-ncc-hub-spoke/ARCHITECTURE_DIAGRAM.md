# NCC Hub-Spoke Architecture Diagram

## Complete Network Topology

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                                                                 │
│                        GCP Landing Zone - Carrier                               │
│                     Network Connectivity Center (NCC)                           │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘


                    ╔═══════════════════════════════════════╗
                    ║    carrier-ncc-hub-prod (HUB)        ║
                    ║  prj-prd-gcp-40036-mgmt-nethub       ║
                    ║         (Global Routing)              ║
                    ╚═══════════════════════════════════════╝
                                    │
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        │                           │                           │
        │                           │                           │
        ▼                           ▼                           ▼
┌───────────────────┐   ┌───────────────────────┐   ┌──────────────────┐
│   VPC SPOKES (8)  │   │    RA SPOKE (1)       │   │  FUTURE SPOKES   │
│                   │   │                       │   │                  │
│  Model 1 & 3      │   │  Transit VPC          │   │  • Model 5       │
│  Network VPCs     │   │  with Palo Alto       │   │  • On-Premises   │
└───────────────────┘   └───────────────────────┘   └──────────────────┘
        │                           │
        │                           │
        └───────────────────────────┘
                    │
                    │
        ┌───────────┴───────────┐
        │                       │
        ▼                       ▼
┌──────────────────┐  ┌─────────────────────┐
│  MODEL SPOKES    │  │  NETWORK VPC SPOKES │
│                  │  │                     │
│  Region: us-     │  │  Region: us-        │
│  central1/east1  │  │  central1           │
└──────────────────┘  └─────────────────────┘
```

---

## Detailed Spoke Architecture

### 1. Model 1 Spokes (us-central1)

```
┌────────────────────────────────────────────────────────────┐
│                    Model 1 - Zone                          │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  ┌─────────────────────┐      ┌─────────────────────┐    │
│  │   M1P (Production)  │      │  M1NP (Non-Prod)    │    │
│  │                     │      │                     │    │
│  │  VPC: global-host-  │      │  VPC: global-host-  │    │
│  │       m1p-vpc       │      │       m1np-vpc      │    │
│  │                     │      │                     │    │
│  │  Project:           │      │  Project:           │    │
│  │  prj-...-m1p-host   │      │  prj-...-m1np-host  │    │
│  │                     │      │                     │    │
│  │  Region:            │      │  Region:            │    │
│  │  us-central1        │      │  us-central1        │    │
│  └─────────────────────┘      └─────────────────────┘    │
│            │                            │                 │
│            └────────────┬───────────────┘                 │
│                         │                                 │
│                         ▼                                 │
│              [ NCC Hub - M1 Spokes ]                      │
└────────────────────────────────────────────────────────────┘
```

### 2. Model 3 Spokes (us-east1)

```
┌────────────────────────────────────────────────────────────┐
│                    Model 3 - Zone                          │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  ┌─────────────────────┐      ┌─────────────────────┐    │
│  │   M3P (Production)  │      │  M3NP (Non-Prod)    │    │
│  │                     │      │                     │    │
│  │  VPC: global-host-  │      │  VPC: global-host-  │    │
│  │       m3p-vpc       │      │       m3np-vpc      │    │
│  │                     │      │                     │    │
│  │  Project:           │      │  Project:           │    │
│  │  prj-...-m3p-host   │      │  prj-...-m3np-host  │    │
│  │                     │      │                     │    │
│  │  Region:            │      │  Region:            │    │
│  │  us-east1           │      │  us-east1           │    │
│  └─────────────────────┘      └─────────────────────┘    │
│            │                            │                 │
│            └────────────┬───────────────┘                 │
│                         │                                 │
│                         ▼                                 │
│              [ NCC Hub - M3 Spokes ]                      │
└────────────────────────────────────────────────────────────┘
```

### 3. Network VPCs (prj-prd-gcp-40036-mgmt-nethub)

```
┌─────────────────────────────────────────────────────────────────────┐
│            Network Hub Project - Security & Services                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────────────┐      │
│  │  FW Data VPC │  │  FW Mgmt VPC │  │  Shared Services    │      │
│  │              │  │              │  │  VPC                │      │
│  │  Security    │  │  Security    │  │                     │      │
│  │  Data Plane  │  │  Mgmt Plane  │  │  Common Services    │      │
│  │              │  │              │  │  (DNS, Logging)     │      │
│  │  Zone:       │  │  Zone:       │  │                     │      │
│  │  security    │  │  security    │  │  Zone: shared-svc   │      │
│  └──────────────┘  └──────────────┘  └─────────────────────┘      │
│         │                  │                      │                │
│         └──────────────────┼──────────────────────┘                │
│                            │                                       │
│                            ▼                                       │
│                  [ NCC Hub - Network VPCs ]                        │
└─────────────────────────────────────────────────────────────────────┘
```

### 4. Transit VPC with Router Appliance

```
┌─────────────────────────────────────────────────────────────────────┐
│                   Transit VPC - Router Appliance                    │
│                   prj-prd-gcp-40036-mgmt-nethub                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌────────────────────────────────────────────────────────┐        │
│  │              Transit VPC (VPC Spoke)                    │        │
│  │              - Regular NCC VPC spoke                    │        │
│  │              - Connectivity to all other spokes         │        │
│  └────────────────────────────────────────────────────────┘        │
│                              │                                      │
│                              ▼                                      │
│  ┌────────────────────────────────────────────────────────┐        │
│  │         Transit VPC (Router Appliance Spoke)           │        │
│  │                                                         │        │
│  │  ┌─────────────────────────────────────────────────┐   │        │
│  │  │     Cloud Router (carrier-transit-router)       │   │        │
│  │  │     ASN: 64512                                  │   │        │
│  │  │                                                 │   │        │
│  │  │  BGP Advertisement:                             │   │        │
│  │  │  - ALL_SUBNETS                                  │   │        │
│  │  │  - 10.0.0.0/8                                   │   │        │
│  │  │  - 172.16.0.0/12                                │   │        │
│  │  │  - 192.168.0.0/16                               │   │        │
│  │  └─────────────────────────────────────────────────┘   │        │
│  │                │                    │                   │        │
│  │      Interface 0                Interface 1             │        │
│  │      (Outbound)                 (Inbound)               │        │
│  │                │                    │                   │        │
│  │                ▼                    ▼                   │        │
│  │  ┌──────────────────┐    ┌──────────────────┐          │        │
│  │  │ Palo Alto FW01   │    │ Palo Alto FW02   │          │        │
│  │  │                  │    │                  │          │        │
│  │  │ Zone: us-c1-a    │    │ Zone: us-c1-b    │          │        │
│  │  │ IP: 10.1.10.10   │    │ IP: 10.1.10.11   │          │        │
│  │  │ Peer: 10.1.10.1  │    │ Peer: 10.1.10.2  │          │        │
│  │  │ ASN: 65001       │    │ ASN: 65002       │          │        │
│  │  │ Priority: 100    │    │ Priority: 110    │          │        │
│  │  └──────────────────┘    └──────────────────┘          │        │
│  │         (Primary)              (Secondary HA)           │        │
│  └─────────────────────────────────────────────────────────┘        │
│                              │                                      │
│                              ▼                                      │
│                    [ NCC Hub - RA Spoke ]                           │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Network Flow Diagram

```
┌──────────────┐                                    ┌──────────────┐
│   M1P VPC    │──────┐                    ┌────────│   M3P VPC    │
└──────────────┘      │                    │        └──────────────┘
                      │                    │
┌──────────────┐      │                    │        ┌──────────────┐
│  M1NP VPC    │──────┤                    ├────────│  M3NP VPC    │
└──────────────┘      │                    │        └──────────────┘
                      │                    │
┌──────────────┐      │                    │        ┌──────────────┐
│ FW Data VPC  │──────┤                    ├────────│ Shared Svc   │
└──────────────┘      │                    │        │ VPC          │
                      │                    │        └──────────────┘
┌──────────────┐      │    ┌──────────┐   │
│ FW Mgmt VPC  │──────┼────│ NCC HUB  │───┤
└──────────────┘      │    └──────────┘   │
                      │         │          │
┌──────────────┐      │         │          │
│ Transit VPC  │──────┘         │          └────────┐
│ (VPC Spoke)  │                │                   │
└──────────────┘                │                   │
        │                       │                   │
        │                       │                   │
        ▼                       ▼                   ▼
┌──────────────────────────────────────────────────────────┐
│         Transit VPC - Router Appliance Spoke             │
│                                                          │
│    Palo Alto FW01 (ASN 65001) ←→ Cloud Router ←→        │
│    Palo Alto FW02 (ASN 65002) ←→ (ASN 64512)            │
│                                                          │
│                 BGP Routing + HA Failover                │
└──────────────────────────────────────────────────────────┘
                            │
                            │
                            ▼
                   ┌─────────────────┐
                   │   On-Premises   │
                   │   (via HA-VPN)  │
                   │   Future        │
                   └─────────────────┘
```

---

## BGP Peering Details

```
┌─────────────────────────────────────────────────────────────────┐
│                    BGP Peering Architecture                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Cloud Router (carrier-transit-router)                          │
│  └─ ASN: 64512                                                  │
│     Region: us-central1                                         │
│     VPC: transit-vpc                                            │
│                                                                 │
│  BGP Peers:                                                     │
│                                                                 │
│  ┌───────────────────────────────────────────────────────┐     │
│  │  Interface 0 (Primary Path - Outbound Direction)     │     │
│  ├───────────────────────────────────────────────────────┤     │
│  │  Peer Name:     interface0                           │     │
│  │  Router App:    carrier-palo-region1-fw01            │     │
│  │  Zone:          us-central1-a                        │     │
│  │  Local IP:      10.1.10.10                           │     │
│  │  Peer IP:       10.1.10.1                            │     │
│  │  Peer ASN:      65001                                │     │
│  │  Priority:      100 (Higher priority = Primary)      │     │
│  └───────────────────────────────────────────────────────┘     │
│                                                                 │
│  ┌───────────────────────────────────────────────────────┐     │
│  │  Interface 1 (Secondary Path - Inbound Direction)    │     │
│  ├───────────────────────────────────────────────────────┤     │
│  │  Peer Name:     interface1                           │     │
│  │  Router App:    carrier-palo-region1-fw02            │     │
│  │  Zone:          us-central1-b                        │     │
│  │  Local IP:      10.1.10.11                           │     │
│  │  Peer IP:       10.1.10.2                            │     │
│  │  Peer ASN:      65002                                │     │
│  │  Priority:      110 (Lower priority = Backup)        │     │
│  └───────────────────────────────────────────────────────┘     │
│                                                                 │
│  Advertised Routes:                                             │
│  • ALL_SUBNETS (all VPC subnets)                               │
│  • 10.0.0.0/8 (Private range)                                  │
│  • 172.16.0.0/12 (Private range)                               │
│  • 192.168.0.0/16 (Private range)                              │
└─────────────────────────────────────────────────────────────────┘
```

---

## Deployment Sequence

```
Step 1: Deploy NCC Hub
───────────────────────────────────────────
    │
    │  Resource: google_network_connectivity_hub
    │  Name: carrier-ncc-hub-prod
    │  Project: prj-prd-gcp-40036-mgmt-nethub
    │
    ▼
Step 2: Deploy 8 VPC Spokes
───────────────────────────────────────────
    │
    │  for_each: 8 spokes in vpc-spokes-config.yaml
    │  - m1p, m1np, m3p, m3np
    │  - fw-data, fw-mgmt, shared-services, transit
    │
    ▼
Step 3: Deploy Palo Alto Firewalls
───────────────────────────────────────────
    │  (Separate repo: gcp-palo-alto-bootstrap)
    │
    │  Deploy: carrier-palo-region1-fw01
    │  Deploy: carrier-palo-region1-fw02
    │
    ▼
Step 4: Deploy Transit RA Spoke
───────────────────────────────────────────
    │
    │  count: var.deploy_transit_spoke = true
    │  Resources:
    │  - Cloud Router
    │  - NCC RA Spoke
    │  - 2 BGP Peers
    │
    ▼
Step 5: Verify BGP Sessions
───────────────────────────────────────────
    │
    │  Check: BGP peer status = ESTABLISHED
    │  Verify: Routes advertised/received
    │
    ▼
Step 6: Test Connectivity
───────────────────────────────────────────
    │
    │  Test: M1P → M3P (via NCC Hub)
    │  Test: M1P → Transit → Palo Alto
    │  Test: All spokes interconnectivity
    │
    ▼
Complete ✓
```

---

## Project & Region Distribution

```
┌────────────────────────────────────────────────────────────────┐
│                      PROJECT LAYOUT                            │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  prj-prd-gcp-40036-mgmt-nethub (NETWORK HUB)                  │
│  ├─ NCC Hub (global)                                          │
│  ├─ FW Data VPC (us-central1)                                 │
│  ├─ FW Mgmt VPC (us-central1)                                 │
│  ├─ Shared Services VPC (us-central1)                         │
│  ├─ Transit VPC (us-central1)                                 │
│  │  ├─ VPC Spoke                                              │
│  │  └─ RA Spoke with Cloud Router                            │
│  ├─ Palo Alto FW01 (us-central1-a)                            │
│  └─ Palo Alto FW02 (us-central1-b)                            │
│                                                                │
│  prj-prd-gcp-40036-m1p-host (MODEL 1 PROD)                    │
│  └─ M1P VPC (us-central1)                                     │
│                                                                │
│  prj-prd-gcp-40036-m1np-host (MODEL 1 NON-PROD)               │
│  └─ M1NP VPC (us-central1)                                    │
│                                                                │
│  prj-prd-gcp-40036-m3p-host (MODEL 3 PROD)                    │
│  └─ M3P VPC (us-east1)                                        │
│                                                                │
│  prj-prd-gcp-40036-m3np-host (MODEL 3 NON-PROD)               │
│  └─ M3NP VPC (us-east1)                                       │
│                                                                │
└────────────────────────────────────────────────────────────────┘

REGIONAL DISTRIBUTION:
  us-central1:  6 VPCs (M1P, M1NP, FW Data, FW Mgmt, Shared, Transit)
  us-east1:     2 VPCs (M3P, M3NP)
```

---

## Labels & Tagging

All resources are tagged with mandatory Carrier labels:

```yaml
Standard Labels:
  cost_center:     <department>
  owner:           <team-name>
  application:     <app-name>
  leanix_app_id:   <app-id>
  environment:     production | non-production
  zone:            model-1 | model-3 | security | transit | shared-services
  managed_by:      terraform
```

---

## Summary Statistics

| Metric | Count |
|--------|-------|
| **Total Projects** | 5 |
| **Total VPCs** | 8 |
| **Total Spokes** | 9 (8 VPC + 1 RA) |
| **Cloud Routers** | 1 |
| **BGP Peers** | 2 |
| **Palo Alto Firewalls** | 2 |
| **Regions** | 2 (us-central1, us-east1) |
| **Zones** | 5 (model-1, model-3, security, transit, shared-services) |

---

**Last Updated:** January 9, 2026  
**Based on:** Vijay's architecture guidance and manager approval

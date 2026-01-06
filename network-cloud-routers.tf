# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

###############################################################################
# Cloud Routers for SD-WAN Router Appliance (RA) BGP Peering
# 
# Purpose: Creates Cloud Routers in the Networking project for BGP peering
#          with SD-WAN Router Appliances (Cisco Catalyst 8000V).
#          Communication happens through BGP protocol (ASN 16550 <-> 65001).
#
# Architecture:
#   - Cloud Routers deployed in Networking project (ncchub_project)
#   - One Cloud Router per region for HA and scaling
#   - BGP peering with SD-WAN RA for hybrid connectivity
#   - Integrated with NCC Hub for mesh transitivity
#
# Source: Carrier GCP LLD v1.1 (Section 2.1 - Routing & BGP Parameters)
# Reference: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-cloudrouter?ref=v45.0.0
###############################################################################

# Cloud Router configuration for each region
# Used for BGP peering with SD-WAN Router Appliances
module "cloud_router_ra" {
  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-cloudrouter?ref=v45.0.0"

  for_each = local.regions

  project_id = local.ncchub_project
  region     = each.value.location
  name       = "${each.key}-cr-ra"
  
  # Reference to Transit VPC network where RA instances are deployed
  # Note: Transit VPC network creation handled in network-vpc.tf
  network = "global-transit-vpc"

  # BGP Configuration
  bgp = {
    asn                = 16550  # GCP Standard ASN for Cloud Router
    advertise_mode     = "CUSTOM"
    advertised_groups  = ["ALL_SUBNETS"]
    
    # Advertise routes from all Shared VPCs (M1P, M1NP, M3P, M3NP)
    # This enables on-premises access to GCP workloads via SD-WAN
    advertised_ip_ranges = {
      m1p_range  = try(local.cidr_allocations[each.key].m1p, null)
      m1np_range = try(local.cidr_allocations[each.key].m1np, null)
      m3p_range  = try(local.cidr_allocations[each.key].m3p, null)
      m3np_range = try(local.cidr_allocations[each.key].m3np, null)
    }
  }

  # BGP Peers - SD-WAN Router Appliances
  # Format: peer_name => peer_configuration
  # Note: Uncomment and configure when RA instances are deployed
  # peers = {
  #   sdwan-ra-01 = {
  #     peer_asn        = 65001  # SD-WAN ASN (example - confirm with network team)
  #     peer_ip_address = var.ra_appliance_ip_01  # RA instance IP in transit subnet
  #     advertised_route_priority = 100
  #   }
  #   sdwan-ra-02 = {
  #     peer_asn        = 65001
  #     peer_ip_address = var.ra_appliance_ip_02  # HA RA instance
  #     advertised_route_priority = 100
  #   }
  # }
}

# Output Cloud Router details for NCC spoke attachment
output "cloud_routers" {
  description = "Cloud Router IDs for SD-WAN RA BGP peering and NCC spoke attachment"
  value = {
    for region, router in module.cloud_router_ra : region => {
      id         = router.router.id
      name       = router.router.name
      self_link  = router.router.self_link
      region     = router.router.region
      bgp_asn    = 16550
    }
  }
}

# Output for NCC Router Appliance Spoke configuration
output "ncc_ra_spoke_config" {
  description = "Configuration data for NCC Router Appliance spoke attachment"
  value = {
    for region, router in module.cloud_router_ra : region => {
      cloud_router_id = router.router.id
      region          = region
      # RA instance details to be populated when deployed
      # instances = [
      #   {
      #     virtual_machine = var.ra_vm_instance_01
      #     ip_address      = var.ra_appliance_ip_01
      #   },
      #   {
      #     virtual_machine = var.ra_vm_instance_02
      #     ip_address      = var.ra_appliance_ip_02
      #   }
      # ]
    }
  }
}

###############################################################################
# Variables for Cloud Router Configuration
# Uncomment when configuring BGP peers with SD-WAN RA
###############################################################################

# variable "bgp_asn_gcp" {
#   description = "GCP Cloud Router ASN"
#   type        = number
#   default     = 16550
# }
# 
# variable "bgp_asn_sdwan" {
#   description = "SD-WAN Router Appliance ASN (confirm with network team)"
#   type        = number
#   default     = 65001
# }
# 
# variable "ra_appliance_ip_01" {
#   description = "Primary SD-WAN RA instance IP address in transit subnet"
#   type        = string
# }
# 
# variable "ra_appliance_ip_02" {
#   description = "Secondary SD-WAN RA instance IP address for HA"
#   type        = string
# }
# 
# variable "ra_vm_instance_01" {
#   description = "Primary SD-WAN RA VM instance self-link"
#   type        = string
# }
# 
# variable "ra_vm_instance_02" {
#   description = "Secondary SD-WAN RA VM instance self-link for HA"
#   type        = string
# }

###############################################################################
# Notes:
# 1. Cloud Routers are created in the Networking project (ncchub_project)
# 2. BGP peers configuration commented out - enable when RA instances deployed
# 3. Cloud Routers will be attached to NCC Hub as Router Appliance spokes
# 4. Enables hybrid connectivity between GCP and on-premises via SD-WAN
# 5. Advertises all Shared VPC ranges to on-premises networks
###############################################################################

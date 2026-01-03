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

# HA VPN Gateway for Remote Access (RA)
# Provides secure VPN connectivity for remote users and sites

locals {
  # HA VPN Gateways per region
  ha_vpn_gateways = {
    for region_key, region in local.regions : region_key => {
      name        = "vpn-gw-${region_key}-transit"
      region      = region.location
      description = "HA VPN Gateway for Remote Access in ${region_key}"
    }
  }
}

# Create HA VPN Gateways in Transit VPC
resource "google_compute_ha_vpn_gateway" "transit_vpn_gateways" {
  for_each = local.ha_vpn_gateways

  project     = local.transit_project
  name        = each.value.name
  region      = each.value.region
  network     = module.vpc_transit.id
  description = each.value.description

  depends_on = [
    module.vpc_transit,
    google_compute_subnetwork.infrastructure_subnets
  ]
}

# VPN Tunnels will be configured separately based on on-premises requirements
# This creates the gateway infrastructure; tunnel configuration requires:
# - Peer VPN gateway details
# - Shared secrets (stored in Secret Manager)
# - BGP configuration for dynamic routing

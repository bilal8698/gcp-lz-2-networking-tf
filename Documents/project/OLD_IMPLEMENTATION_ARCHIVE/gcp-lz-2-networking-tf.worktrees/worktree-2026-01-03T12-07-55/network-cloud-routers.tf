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

# Cloud Routers for Hybrid Connectivity
# Deployed in Transit VPC for BGP with Router Appliances (SD-WAN)

locals {
  # Cloud Router configurations per region
  cloud_routers = {
    for region_key, region in local.regions : region_key => {
      name        = "cr-${region_key}-transit"
      region      = region.location
      description = "Cloud Router for SD-WAN connectivity in ${region_key}"
      asn         = 64512 + index(keys(local.regions), region_key)
    }
  }
}

# Create Cloud Routers in Transit VPC for each region
resource "google_compute_router" "transit_routers" {
  for_each = local.cloud_routers

  project     = local.transit_project
  name        = each.value.name
  region      = each.value.region
  network     = module.vpc_transit.id
  description = each.value.description

  bgp {
    asn               = each.value.asn
    advertise_mode    = "CUSTOM"
    
    # Advertise all subnets
    advertised_groups = ["ALL_SUBNETS"]
    
    # Advertise custom routes for NCC connectivity
    advertised_ip_ranges {
      range       = "10.0.0.0/8"
      description = "Carrier internal network range"
    }
  }

  depends_on = [
    module.vpc_transit,
    google_compute_subnetwork.infrastructure_subnets
  ]
}

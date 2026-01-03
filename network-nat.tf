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

# Cloud NAT Configuration
# Provides outbound internet connectivity for VMs without external IPs
# Deployed per model per region for isolation

locals {
  # Generate Cloud NAT configurations for all model VPCs in all regions
  cloud_nat_configs = flatten([
    for region_key, region in local.regions : [
      for model_key, vpc_config in local.shared_vpcs : {
        key         = "${region_key}-${model_key}-nat"
        name        = "nat-${region_key}-${model_key}"
        region      = region.location
        model       = model_key
        project_id  = vpc_config.project_id
        vpc_id      = local.vpc_modules[model_key].id
        router_name = "cr-${region_key}-${model_key}"
        description = "Cloud NAT for ${model_key} in ${region_key}"
      }
    ]
  ])

  cloud_nat_map = { for nat in local.cloud_nat_configs : nat.key => nat }
}

# Create Cloud Routers for each model VPC in each region
resource "google_compute_router" "model_routers" {
  for_each = local.cloud_nat_map

  project     = each.value.project_id
  name        = each.value.router_name
  region      = each.value.region
  network     = each.value.vpc_id
  description = "Cloud Router for NAT in ${each.value.model} - ${each.value.region}"

  bgp {
    asn = 65000 + index(keys(local.cloud_nat_map), each.key)
  }

  depends_on = [
    module.vpc_m1p,
    module.vpc_m1np,
    module.vpc_m3p,
    module.vpc_m3np,
    google_compute_subnetwork.infrastructure_subnets
  ]
}

# Create Cloud NAT gateways
resource "google_compute_router_nat" "model_nat_gateways" {
  for_each = local.cloud_nat_map

  project = each.value.project_id
  name    = each.value.name
  region  = each.value.region
  router  = google_compute_router.model_routers[each.key].name

  # NAT for all subnets in the VPC
  nat_ip_allocate_option = "AUTO_ONLY"

  # Source subnetwork configuration
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  # Logging configuration per TDD requirements
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }

  # TCP timeouts
  tcp_established_idle_timeout_sec = 1200
  tcp_transitory_idle_timeout_sec  = 30

  # UDP timeout
  udp_idle_timeout_sec = 30

  # Minimum ports per VM
  min_ports_per_vm = 64

  # Enable dynamic port allocation
  enable_dynamic_port_allocation = true

  depends_on = [
    google_compute_router.model_routers
  ]
}

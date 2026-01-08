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

# Infrastructure Subnets for all VPCs across 6 regions
# Creates subnets in each region for: M1P, M1NP, M3P, M3NP, Transit, Security, Shared Services

locals {
  # Generate infrastructure subnets for all regions and models
  model_subnets = flatten([
    for region_key, region in local.regions : [
      for model_key, vpc_config in local.shared_vpcs : {
        key          = "${region_key}-${model_key}-subnet"
        name         = "${region_key}-${model_key}-subnet"
        region       = region.location
        model        = model_key
        vpc_id       = local.vpc_modules[model_key].id
        project_id   = vpc_config.project_id
        cidr_range   = local.cidr_allocations[region_key][model_key]
        description  = "Infrastructure subnet for ${model_key} in ${region_key}"
      }
    ]
  ])

  # Transit VPC subnets per region
  transit_subnets = [
    for region_key, region in local.regions : {
      key          = "${region_key}-transit-subnet"
      name         = "${region_key}-transit-subnet"
      region       = region.location
      vpc_id       = module.vpc_transit.id
      project_id   = local.transit_project
      cidr_range   = local.infra_subnet_cidrs[region_key].transit
      description  = "Transit subnet for SD-WAN and DNS in ${region_key}"
    }
  ]

  # Security Data Plane subnets per region
  security_data_subnets = [
    for region_key, region in local.regions : {
      key          = "${region_key}-sec-data-subnet"
      name         = "${region_key}-sec-data-subnet"
      region       = region.location
      vpc_id       = module.vpc_security_data.id
      project_id   = local.netsec_project
      cidr_range   = local.infra_subnet_cidrs[region_key].sec_data
      description  = "Security data plane subnet for Palo Alto in ${region_key}"
    }
  ]

  # Security Management Plane subnets per region
  security_mgmt_subnets = [
    for region_key, region in local.regions : {
      key          = "${region_key}-sec-mgmt-subnet"
      name         = "${region_key}-sec-mgmt-subnet"
      region       = region.location
      vpc_id       = module.vpc_security_mgmt.id
      project_id   = local.netsec_project
      cidr_range   = local.infra_subnet_cidrs[region_key].sec_mgmt
      description  = "Security management subnet for Palo Alto in ${region_key}"
    }
  ]

  # Shared Services subnets per region
  shared_svcs_subnets = [
    for region_key, region in local.regions : {
      key          = "${region_key}-shared-svcs-subnet"
      name         = "${region_key}-shared-svcs-subnet"
      region       = region.location
      vpc_id       = module.vpc_shared_svcs.id
      project_id   = local.pvpc_project
      cidr_range   = local.infra_subnet_cidrs[region_key].shared_svcs
      description  = "Shared services subnet for PSC in ${region_key}"
    }
  ]

  # Combine all infrastructure subnets
  all_infra_subnets = concat(
    local.model_subnets,
    local.transit_subnets,
    local.security_data_subnets,
    local.security_mgmt_subnets,
    local.shared_svcs_subnets
  )

  # Convert to map for resource creation
  infra_subnets_map = { for subnet in local.all_infra_subnets : subnet.key => subnet }
}

# Create all infrastructure subnets
resource "google_compute_subnetwork" "infrastructure_subnets" {
  for_each = local.infra_subnets_map

  project       = each.value.project_id
  name          = each.value.name
  region        = each.value.region
  network       = each.value.vpc_id
  ip_cidr_range = each.value.cidr_range
  description   = each.value.description

  # Private Google Access enabled by default
  private_ip_google_access = true

  # VPC Flow Logs enabled per TDD requirements
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }

  depends_on = [
    module.vpc_m1p,
    module.vpc_m1np,
    module.vpc_m3p,
    module.vpc_m3np,
    module.vpc_transit,
    module.vpc_security_data,
    module.vpc_security_mgmt,
    module.vpc_shared_svcs
  ]
}

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

# Network Connectivity Center (NCC) Hub and Spokes Configuration
# Using Cloud Foundation Fabric net-ncc module
# Configuration driven by data/ncc-config.yaml

# NCC Hub - Global Mesh Topology
module "ncc_hub" {
  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-ncc?ref=v45.0.0"

  project_id = local.ncchub_project
  name       = local.ncc_config_raw.ncc_hub.name
  description = local.ncc_config_raw.ncc_hub.description

  depends_on = [module.network_projects]
}

# NCC VPC Spokes - Model VPCs (YAML-driven)
# Loop through vpc_spokes from ncc-config.yaml

locals {
  # Parse VPC spokes from YAML
  vpc_spokes_config = {
    for spoke in local.ncc_config_raw.vpc_spokes : spoke.vpc_key => spoke
  }
}

# Model 1 Production Spoke
module "ncc_spoke_m1p" {
  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-ncc-spoke?ref=v45.0.0"

  project_id = local.network_projects[local.vpc_spokes_config["m1p"].project_key].name
  hub        = module.ncc_hub.id
  name       = local.vpc_spokes_config["m1p"].name
  description = local.vpc_spokes_config["m1p"].description

  vpc_config = {
    network_id = module.vpc_m1p.id
    excluded_export_ranges = local.vpc_spokes_config["m1p"].excluded_export_ranges
  }

  depends_on = [module.ncc_hub, module.vpc_m1p]
}

# Model 1 Non-Production Spoke
module "ncc_spoke_m1np" {
  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-ncc-spoke?ref=v45.0.0"

  project_id = local.network_projects[local.vpc_spokes_config["m1np"].project_key].name
  hub        = module.ncc_hub.id
  name       = local.vpc_spokes_config["m1np"].name
  description = local.vpc_spokes_config["m1np"].description

  vpc_config = {
    network_id = module.vpc_m1np.id
    excluded_export_ranges = local.vpc_spokes_config["m1np"].excluded_export_ranges
  }

  depends_on = [module.ncc_hub, module.vpc_m1np]
}

# Model 3 Production Spoke
module "ncc_spoke_m3p" {
  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-ncc-spoke?ref=v45.0.0"

  project_id = local.network_projects[local.vpc_spokes_config["m3p"].project_key].name
  hub        = module.ncc_hub.id
  name       = local.vpc_spokes_config["m3p"].name
  description = local.vpc_spokes_config["m3p"].description

  vpc_config = {
    network_id = module.vpc_m3p.id
    excluded_export_ranges = local.vpc_spokes_config["m3p"].excluded_export_ranges
  }

  depends_on = [module.ncc_hub, module.vpc_m3p]
}

# Model 3 Non-Production Spoke
module "ncc_spoke_m3np" {
  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-ncc-spoke?ref=v45.0.0"

  project_id = local.network_projects[local.vpc_spokes_config["m3np"].project_key].name
  hub        = module.ncc_hub.id
  name       = local.vpc_spokes_config["m3np"].name
  description = local.vpc_spokes_config["m3np"].description

  vpc_config = {
    network_id = module.vpc_m3np.id
    excluded_export_ranges = local.vpc_spokes_config["m3np"].excluded_export_ranges
  }

  depends_on = [module.ncc_hub, module.vpc_m3np]
}

# Router Appliance Spoke (Cisco SD-WAN with Cloud Router)
# This spoke connects Router Appliances to the NCC Hub for hybrid connectivity
# Architecture: Router Appliance -> Cloud Router -> SD-WAN
# Configuration driven by data/ncc-config.yaml

module "ncc_spoke_router_appliance" {
  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-ncc-spoke-ra?ref=v45.0.0"

  project_id = local.network_projects[local.ncc_config_raw.router_appliance_spoke.project_key].name
  hub        = module.ncc_hub.id
  name       = local.ncc_config_raw.router_appliance_spoke.name
  description = local.ncc_config_raw.router_appliance_spoke.description

  # Router Appliances will be configured separately in network-router-appliances.tf
  # This module creates the spoke registration in NCC
  # Region-specific RA instances will be added via router_appliances parameter
  
  region = local.ncc_config_raw.router_appliance_spoke.region
  
  # Router appliances will be added after Cisco VM deployment
  # Example structure (to be populated):
  # router_appliances = {
  #   "us-central1-ra1" = {
  #     internal_ip = "10.xxx.x.x"
  #     vm_self_link = "projects/.../zones/.../instances/..."
  #   }
  # }

  depends_on = [module.ncc_hub, module.vpc_transit]
}

# Note: Security VPCs (Data & Management) and Shared Services VPC are NOT spokes.
# Note: Router Appliance VM instances (Cisco SD-WAN) will be deployed separately
# Note: Cloud Routers for BGP peering will be created in network-cloud-routers.tf

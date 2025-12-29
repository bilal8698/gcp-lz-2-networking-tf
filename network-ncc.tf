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

# NCC Hub - Global Mesh Topology
module "ncc_hub" {
  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-ncc?ref=v45.0.0"

  project_id = local.nethub_project
  name       = "hub-global-ncc-hub"
  description = "Global NCC Hub for Carrier network with Mesh topology"

  depends_on = [module.network_projects]
}

# NCC VPC Spokes - Only Model and Transit VPCs

# Model 1 Production Spoke
module "ncc_spoke_m1p" {
  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-ncc-spoke?ref=v45.0.0"

  project_id = local.nethub_project
  hub        = module.ncc_hub.id
  name       = "spoke-m1p"
  description = "NCC Spoke for Model 1 Production VPC"

  vpc_config = {
    network_id = module.vpc_m1p.id
    excluded_export_ranges = [] # Add GKE Pod ranges here if needed
  }

  depends_on = [module.ncc_hub, module.vpc_m1p]
}

# Model 1 Non-Production Spoke
module "ncc_spoke_m1np" {
  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-ncc-spoke?ref=v45.0.0"

  project_id = local.nethub_project
  hub        = module.ncc_hub.id
  name       = "spoke-m1np"
  description = "NCC Spoke for Model 1 Non-Production VPC"

  vpc_config = {
    network_id = module.vpc_m1np.id
    excluded_export_ranges = []
  }

  depends_on = [module.ncc_hub, module.vpc_m1np]
}

# Model 3 Production Spoke
module "ncc_spoke_m3p" {
  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-ncc-spoke?ref=v45.0.0"

  project_id = local.nethub_project
  hub        = module.ncc_hub.id
  name       = "spoke-m3p"
  description = "NCC Spoke for Model 3 Production VPC"

  vpc_config = {
    network_id = module.vpc_m3p.id
    excluded_export_ranges = []
  }

  depends_on = [module.ncc_hub, module.vpc_m3p]
}

# Model 3 Non-Production Spoke
module "ncc_spoke_m3np" {
  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-ncc-spoke?ref=v45.0.0"

  project_id = local.nethub_project
  hub        = module.ncc_hub.id
  name       = "spoke-m3np"
  description = "NCC Spoke for Model 3 Non-Production VPC"

  vpc_config = {
    network_id = module.vpc_m3np.id
    excluded_export_ranges = []
  }

  depends_on = [module.ncc_hub, module.vpc_m3np]
}

# Transit VPC Spoke
module "ncc_spoke_transit" {
  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-ncc-spoke?ref=v45.0.0"

  project_id = local.transit_project
  hub        = module.ncc_hub.id
  name       = "spoke-transit"
  description = "NCC Spoke for Transit VPC (SD-WAN, Blue Cat DNS)"

  vpc_config = {
    network_id = module.vpc_transit.id
    excluded_export_ranges = []
  }

  depends_on = [module.ncc_hub, module.vpc_transit]
}

# Note: Security VPCs (Data & Management) and Shared Services VPC are NOT spokes.
# Note: Router Appliance Spokes (for SD-WAN) will be added after Cisco deployment
# These will be created in a separate file: network-router-appliances.tf

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

  project_id = local.ncchub_project
  name       = "hub-global-ncc-hub"
  description = "Global NCC Hub for Carrier network with Mesh topology"

  depends_on = [module.network_projects]
}

# NCC VPC Spokes - Only Model and Transit VPCs

# Model 1 Production Spoke
module "ncc_spoke_m1p" {
  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-ncc-spoke?ref=v45.0.0"

  project_id = local.m1p_host_project
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

  project_id = local.m1np_host_project
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

  project_id = local.m3p_host_project
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

  project_id = local.m3np_host_project
  hub        = module.ncc_hub.id
  name       = "spoke-m3np"
  description = "NCC Spoke for Model 3 Non-Production VPC"

  vpc_config = {
    network_id = module.vpc_m3np.id
    excluded_export_ranges = []
  }

  depends_on = [module.ncc_hub, module.vpc_m3np]
}

# Router Appliance Spoke (Cisco SD-WAN with Cloud Router)
# This spoke connects Router Appliances to the NCC Hub for hybrid connectivity
# Architecture: Router Appliance -> Cloud Router -> SD-WAN
# The Transit VPC is part of the Router Appliance infrastructure, not a separate spoke

module "ncc_spoke_router_appliance" {
  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-ncc-spoke-ra?ref=v45.0.0"

  project_id = local.transit_project
  hub        = module.ncc_hub.id
  name       = "spoke-router-appliance"
  description = "NCC Spoke for Router Appliances (Cisco SD-WAN) with Cloud Router"

  # Router Appliances will be configured separately in network-router-appliances.tf
  # This module creates the spoke registration in NCC
  # Region-specific RA instances will be added via router_appliances parameter
  
  region = "us-central1" # Primary region for global spoke
  
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

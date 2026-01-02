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

# Shared VPCs for Model 1 and Model 3 Environments
# Using Cloud Foundation Fabric net-vpc module

# Model 1 Production VPC (Internal/Private)
module "vpc_m1p" {
  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc?ref=v45.0.0"

  project_id = local.m1p_host_project
  name       = local.shared_vpcs.m1p.name
  description = local.shared_vpcs.m1p.description

  # Auto-create subnets disabled - we'll create them explicitly
  auto_create_subnetworks = false

  # Shared VPC host configuration
  shared_vpc_host = true

  # VPC-level configurations
  mtu                    = 1460
  enable_ula_internal_ipv6 = false

  # DNS configuration
  dns_policy = {
    inbound  = false
    logging  = true
    outbound = null
  }

  depends_on = [module.network_projects]
}

# Model 1 Non-Production VPC (Internal/Private)
module "vpc_m1np" {
  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc?ref=v45.0.0"

  project_id = local.m1np_host_project
  name       = local.shared_vpcs.m1np.name
  description = local.shared_vpcs.m1np.description

  auto_create_subnetworks = false
  shared_vpc_host = true
  mtu = 1460
  enable_ula_internal_ipv6 = false

  dns_policy = {
    inbound  = false
    logging  = true
    outbound = null
  }

  depends_on = [module.network_projects]
}

# Model 3 Production VPC (DMZ/Public)
module "vpc_m3p" {
  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc?ref=v45.0.0"

  project_id = local.m3p_host_project
  name       = local.shared_vpcs.m3p.name
  description = local.shared_vpcs.m3p.description

  auto_create_subnetworks = false
  shared_vpc_host = true
  mtu = 1460
  enable_ula_internal_ipv6 = false

  dns_policy = {
    inbound  = false
    logging  = true
    outbound = null
  }

  depends_on = [module.network_projects]
}

# Model 3 Non-Production VPC (DMZ/Public)
module "vpc_m3np" {
  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc?ref=v45.0.0"

  project_id = local.m3np_host_project
  name       = local.shared_vpcs.m3np.name
  description = local.shared_vpcs.m3np.description

  auto_create_subnetworks = false
  shared_vpc_host = true
  mtu = 1460
  enable_ula_internal_ipv6 = false

  dns_policy = {
    inbound  = false
    logging  = true
    outbound = null
  }

  depends_on = [module.network_projects]
}

# Transit VPC (for SD-WAN Router Appliances and Blue Cat DNS)
module "vpc_transit" {
  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc?ref=v45.0.0"

  project_id = local.transit_project
  name       = local.transit_vpc.name
  description = local.transit_vpc.description

  auto_create_subnetworks = false
  mtu = 1460
  enable_ula_internal_ipv6 = false

  dns_policy = {
    inbound  = false
    logging  = true
    outbound = null
  }

  depends_on = [module.network_projects]
}

# Security VPC - Data Plane (for Palo Alto VM-Series)
module "vpc_security_data" {
  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc?ref=v45.0.0"

  project_id = local.netsec_project
  name       = local.security_vpcs.data.name
  description = local.security_vpcs.data.description

  auto_create_subnetworks = false
  mtu = 1460
  enable_ula_internal_ipv6 = false

  depends_on = [module.network_projects]
}

# Security VPC - Management Plane (for Palo Alto Management)
module "vpc_security_mgmt" {
  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc?ref=v45.0.0"

  project_id = local.netsec_project
  name       = local.security_vpcs.mgmt.name
  description = local.security_vpcs.mgmt.description

  auto_create_subnetworks = false
  mtu = 1460
  enable_ula_internal_ipv6 = false

  depends_on = [module.network_projects]
}

# Shared Services VPC (for PSC Endpoints)
module "vpc_shared_svcs" {
  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc?ref=v45.0.0"

  project_id = local.pvpc_project
  name       = local.shared_svcs_vpc.name
  description = local.shared_svcs_vpc.description

  auto_create_subnetworks = false
  mtu = 1460
  enable_ula_internal_ipv6 = false

  dns_policy = {
    inbound  = false
    logging  = true
    outbound = null
  }

  depends_on = [module.network_projects]
}

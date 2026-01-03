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

# Networking stage outputs

locals {
  # Networking-specific outputs for stage handoff and downstream consumption
  networking_outputs = {
    # Network projects information
    network_projects = {
      for k, v in local.network_projects : k => {
        project_id     = try(module.network_projects[k].project_id, "")
        project_number = try(module.network_projects[k].number, "")
        name           = k
        folder_id      = v.parent_folder_id
        service_accounts = {
          iac  = try(module.network_iac_service_accounts[k].email, "")
          iacr = try(module.network_iac_service_accounts_r[k].email, "")
        }
      }
    }

    # Shared VPCs information
    shared_vpcs = {
      m1p = {
        id             = module.vpc_m1p.id
        name           = module.vpc_m1p.name
        project_id     = local.m1p_host_project
        self_link      = module.vpc_m1p.self_link
      }
      m1np = {
        id             = module.vpc_m1np.id
        name           = module.vpc_m1np.name
        project_id     = local.m1np_host_project
        self_link      = module.vpc_m1np.self_link
      }
      m3p = {
        id             = module.vpc_m3p.id
        name           = module.vpc_m3p.name
        project_id     = local.m3p_host_project
        self_link      = module.vpc_m3p.self_link
      }
      m3np = {
        id             = module.vpc_m3np.id
        name           = module.vpc_m3np.name
        project_id     = local.m3np_host_project
        self_link      = module.vpc_m3np.self_link
      }
    }

    # Transit and Security VPCs
    transit_vpc = {
      id         = module.vpc_transit.id
      name       = module.vpc_transit.name
      project_id = local.transit_project
      self_link  = module.vpc_transit.self_link
    }

    security_vpcs = {
      data = {
        id         = module.vpc_security_data.id
        name       = module.vpc_security_data.name
        project_id = local.netsec_project
        self_link  = module.vpc_security_data.self_link
      }
      mgmt = {
        id         = module.vpc_security_mgmt.id
        name       = module.vpc_security_mgmt.name
        project_id = local.netsec_project
        self_link  = module.vpc_security_mgmt.self_link
      }
    }

    shared_svcs_vpc = {
      id         = module.vpc_shared_svcs.id
      name       = module.vpc_shared_svcs.name
      project_id = local.pvpc_project
      self_link  = module.vpc_shared_svcs.self_link
    }

    # NCC Hub and Spokes
    ncc_hub = {
      id   = module.ncc_hub.id
      name = module.ncc_hub.name
      spokes = {
        m1p                 = module.ncc_spoke_m1p.id
        m1np                = module.ncc_spoke_m1np.id
        m3p                 = module.ncc_spoke_m3p.id
        m3np                = module.ncc_spoke_m3np.id
        router_appliance    = module.ncc_spoke_router_appliance.id
      }
    }

    # Vended subnets
    vended_subnets = {
      for k, v in google_compute_subnetwork.vended_subnets : k => {
        id            = v.id
        name          = v.name
        region        = v.region
        ip_cidr_range = v.ip_cidr_range
        vpc_id        = v.network
        project_id    = v.project
      }
    }

    # Infrastructure subnets
    infrastructure_subnets = {
      for k, v in google_compute_subnetwork.infrastructure_subnets : k => {
        id            = v.id
        name          = v.name
        region        = v.region
        ip_cidr_range = v.ip_cidr_range
        vpc_id        = v.network
        project_id    = v.project
      }
    }

    # Cloud Routers
    cloud_routers = {
      transit = {
        for k, v in google_compute_router.transit_routers : k => {
          id         = v.id
          name       = v.name
          region     = v.region
          self_link  = v.self_link
        }
      }
      model = {
        for k, v in google_compute_router.model_routers : k => {
          id         = v.id
          name       = v.name
          region     = v.region
          self_link  = v.self_link
        }
      }
    }

    # HA VPN Gateways
    ha_vpn_gateways = {
      for k, v in google_compute_ha_vpn_gateway.transit_vpn_gateways : k => {
        id        = v.id
        name      = v.name
        region    = v.region
        self_link = v.self_link
      }
    }

    # Cloud NAT Gateways
    cloud_nat_gateways = {
      for k, v in google_compute_router_nat.model_nat_gateways : k => {
        id     = v.id
        name   = v.name
        region = v.region
      }
    }

    # Interconnect VLAN Attachments
    interconnect_attachments = {
      for k, v in google_compute_interconnect_attachment.vlan_attachments : k => {
        id        = v.id
        name      = v.name
        region    = v.region
        self_link = v.self_link
      }
    }

    # Regions configuration
    regions = local.regions
  }
}

# Output the networking outputs object
output "networking_outputs" {
  description = "Networking stage outputs for downstream consumption"
  value       = local.networking_outputs
}

# Individual outputs for convenience
output "ncchub_project_id" {
  description = "NCC Hub project ID"
  value       = local.ncchub_project
}

output "model_host_projects" {
  description = "Model host project IDs"
  value = {
    m1p  = local.m1p_host_project
    m1np = local.m1np_host_project
    m3p  = local.m3p_host_project
    m3np = local.m3np_host_project
  }
}

output "shared_vpcs" {
  description = "Shared VPC information"
  value       = local.networking_outputs.shared_vpcs
}

output "ncc_hub_id" {
  description = "NCC Hub ID"
  value       = module.ncc_hub.id
}

output "network_service_accounts" {
  description = "Network project service accounts"
  value = {
    for k, v in local.network_projects : k => {
      iac  = try(module.network_iac_service_accounts[k].email, "")
      iacr = try(module.network_iac_service_accounts_r[k].email, "")
    }
  }
  sensitive = true
}

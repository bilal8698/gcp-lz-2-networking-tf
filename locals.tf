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

# Locals for networking stage - aggregates data from previous stages

locals {
  # Read outputs from previous stages
  bootstrap_outputs = jsondecode(file("./output_files/0-bootstrap-outputs.json"))
  global_outputs    = jsondecode(file("./output_files/0-global-outputs.json"))
  resman_outputs    = jsondecode(file("./output_files/1-resman-outputs.json"))

  # Extracted values for easy reference
  prefix = local.global_outputs.prefix

  # Folder reference from resman outputs
  networking_folder_id = local.resman_outputs.shared_service_folders.networking.id

  # Network project labels
  network_project_labels = {
    managed-by      = "terraform"
    stage           = "2-networking"
    repository      = "gcp-lz-2-networking-tf"
    terraform-stage = "networking"
  }

  # Core LZ project labels (inherited from global outputs)
  core_lz_project_labels   = local.global_outputs.core_project_labels
  core_lz_resources_labels = local.global_outputs.core_resource_labels

  # Network projects configuration from YAML
  network_projects_raw = try(
    yamldecode(file("${path.module}/${var.factories_config.network_projects}")),
    {}
  )

  # Generate all network projects from network-projects.yaml
  all_network_projects = flatten([
    for project_name, project_config in local.network_projects_raw.network_projects : [
      for env_name, env_config in try(project_config.envs, { "" = {} }) : {
        # Unique key for project identification
        key = env_name != "" ? "${project_name}-${env_name}" : project_name

        # Generated project name following Carrier naming convention
        name = "prj-${env_name}-gcp-${env_config.ad_group_number}-${project_config.business_segment}-${project_name}"

        # Project metadata
        project_name     = project_name
        environment      = env_name
        team             = project_config.team
        ad_group_number  = try(env_config.ad_group_number, null)
        business_segment = project_config.business_segment
        admin_principal  = try(env_config.admin_principal, project_config.admin_principal, null)
        shared_vpc_host  = try(env_config.shared_vpc_host, false)

        # GCP services to enable
        services = project_config.services

        # Resource labels
        labels = merge(
          try(project_config.labels, {}),
          {
            environment_type = env_name
          }
        )

        # Project deletion policy
        deletion_policy = try(project_config.deletion_policy, "PREVENT")

        # Parent folder
        parent_folder_id = local.networking_folder_id
      }
    ]
  ])

  # Convert network project list to map for easier terraform processing
  network_projects = { for proj in local.all_network_projects : proj.key => proj }

  # Key project references
  nethub_project       = local.network_projects["nethub-prd"].name
  transit_project      = local.network_projects["transit-prd"].name
  netsec_project       = local.network_projects["netsec-prd"].name
  pvpc_project         = local.network_projects["pvpc-prd"].name

  # Regions configuration (from TDD/LLD)
  regions = {
    "us-east4"         = { location = "us-east4", zone_a = "us-east4-a", zone_b = "us-east4-b" }
    "us-central1"      = { location = "us-central1", zone_a = "us-central1-a", zone_b = "us-central1-b" }
    "europe-west3"     = { location = "europe-west3", zone_a = "europe-west3-a", zone_b = "europe-west3-b" }
    "europe-west1"     = { location = "europe-west1", zone_a = "europe-west1-b", zone_b = "europe-west1-c" }
    "asia-southeast1"  = { location = "asia-southeast1", zone_a = "asia-southeast1-a", zone_b = "asia-southeast1-b" }
    "asia-east2"       = { location = "asia-east2", zone_a = "asia-east2-a", zone_b = "asia-east2-b" }
  }

  # VPC configurations
  shared_vpcs = {
    m1p = {
      name        = "global-host-M1P-vpc"
      description = "Shared VPC for Model 1 Production (Internal/Private)"
      project_id  = local.nethub_project
    }
    m1np = {
      name        = "global-host-M1NP-vpc"
      description = "Shared VPC for Model 1 Non-Production (Internal/Private)"
      project_id  = local.nethub_project
    }
    m3p = {
      name        = "global-host-M3P-vpc"
      description = "Shared VPC for Model 3 Production (DMZ/Public)"
      project_id  = local.nethub_project
    }
    m3np = {
      name        = "global-host-M3NP-vpc"
      description = "Shared VPC for Model 3 Non-Production (DMZ/Public)"
      project_id  = local.nethub_project
    }
  }

  # Transit VPC configuration
  transit_vpc = {
    name        = "global-transit-vpc"
    description = "Transit VPC for SD-WAN Router Appliances and Blue Cat DNS"
    project_id  = local.transit_project
  }

  # Security VPCs configuration
  security_vpcs = {
    data = {
      name        = "global-security-vpc-data"
      description = "Security VPC Data Plane for Palo Alto VM-Series"
      project_id  = local.netsec_project
    }
    mgmt = {
      name        = "global-security-vpc-mgmt"
      description = "Security VPC Management Plane for Palo Alto Management"
      project_id  = local.netsec_project
    }
  }

  # Shared services VPC configuration
  shared_svcs_vpc = {
    name        = "global-shared-svcs-vpc"
    description = "Shared Services VPC for PSC Endpoints"
    project_id  = local.pvpc_project
  }

  # CIDR allocations (from TDD Table 4.2.3a)
  cidr_allocations = {
    "us-east4" = {
      m1p  = "10.150.0.0/16"
      m1np = "10.151.0.0/16"
      m3p  = "10.152.0.0/16"
      m3np = "10.153.0.0/16"
    }
    "us-central1" = {
      m1p  = "10.100.0.0/16"
      m1np = "10.101.0.0/16"
      m3p  = "10.102.0.0/16"
      m3np = "10.103.0.0/16"
    }
    "europe-west3" = {
      m1p  = "10.172.0.0/16"
      m1np = "10.173.0.0/16"
      m3p  = "10.174.0.0/16"
      m3np = "10.175.0.0/16"
    }
    "europe-west1" = {
      m1p  = "10.176.0.0/16"
      m1np = "10.177.0.0/16"
      m3p  = "10.178.0.0/16"
      m3np = "10.179.0.0/16"
    }
    "asia-southeast1" = {
      m1p  = "10.184.0.0/16"
      m1np = "10.185.0.0/16"
      m3p  = "10.186.0.0/16"
      m3np = "10.187.0.0/16"
    }
    "asia-east2" = {
      m1p  = "10.188.0.0/16"
      m1np = "10.189.0.0/16"
      m3p  = "10.190.0.0/16"
      m3np = "10.191.0.0/16"
    }
  }

  # Infrastructure subnet CIDRs (from TDD/LLD)
  infra_subnet_cidrs = {
    "us-east4" = {
      transit     = "10.154.0.0/24"
      sec_data    = "10.154.8.0/24"
      sec_mgmt    = "10.154.16.0/24"
      shared_svcs = "10.154.32.0/24"
    }
    "us-central1" = {
      transit     = "10.154.1.0/24"
      sec_data    = "10.154.9.0/24"
      sec_mgmt    = "10.154.17.0/24"
      shared_svcs = "10.154.33.0/24"
    }
    "europe-west3" = {
      transit     = "10.154.3.0/24"
      sec_data    = "10.154.11.0/24"
      sec_mgmt    = "10.154.19.0/24"
      shared_svcs = "10.154.35.0/24"
    }
    "europe-west1" = {
      transit     = "10.154.2.0/24"
      sec_data    = "10.154.10.0/24"
      sec_mgmt    = "10.154.18.0/24"
      shared_svcs = "10.154.34.0/24"
    }
    "asia-southeast1" = {
      transit     = "10.154.5.0/24"
      sec_data    = "10.154.13.0/24"
      sec_mgmt    = "10.154.21.0/24"
      shared_svcs = "10.154.37.0/24"
    }
    "asia-east2" = {
      transit     = "10.154.4.0/24"
      sec_data    = "10.154.12.0/24"
      sec_mgmt    = "10.154.20.0/24"
      shared_svcs = "10.154.36.0/24"
    }
  }
}

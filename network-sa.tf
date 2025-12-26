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

# Network-level IaC service accounts factory

# IaC service account for each network project (owner access)
module "network_iac_service_accounts" {
  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/iam-service-account?ref=v45.0.0"

  for_each = local.network_projects

  # Create service account in the network project
  project_id   = module.network_projects[each.key].project_id
  name         = "${each.key}-iac"
  display_name = "Terraform IaC Service Account for ${each.key} network project"
  prefix       = local.prefix

  # Grant owner role on the project for full automation capabilities
  iam_project_roles = {
    (module.network_projects[each.key].project_id) = ["roles/owner"]
  }

  # Additional network-specific roles
  iam = {
    "roles/compute.networkAdmin" = []
    "roles/compute.securityAdmin" = []
  }
}

# Read-only service account for each network project (viewer access)
module "network_iac_service_accounts_r" {
  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/iam-service-account?ref=v45.0.0"

  for_each = local.network_projects

  # Create service account in the network project
  project_id   = module.network_projects[each.key].project_id
  name         = "${each.key}-iacr"
  display_name = "Terraform IaC Service Account for ${each.key} network project (read-only)"
  prefix       = local.prefix

  # Grant viewer role on the project for read-only operations (terraform plan)
  iam_project_roles = {
    (module.network_projects[each.key].project_id) = ["roles/viewer"]
  }
}

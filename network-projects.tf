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

# Network projects factory using Cloud Foundation Fabric project module
# Provisions network projects based on YAML configuration

module "network_projects" {
  source = "git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref=v45.0.0"

  for_each = local.network_projects

  # Project identification
  name = each.value.name

  # Folder placement
  parent = each.value.parent_folder_id

  # Billing configuration
  billing_account = local.global_outputs.billing_account.id

  # API services configuration
  services = try(each.value.services, [])

  # Project labels
  labels = merge(
    local.network_project_labels,
    try(each.value.labels, {})
  )

  # Deletion policy
  deletion_policy = each.value.deletion_policy

  # Shared VPC configuration
  shared_vpc_host_config = each.value.shared_vpc_host ? {
    enabled = true
  } : null
}

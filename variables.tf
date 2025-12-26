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

# Variables for networking stage

# Outputs location for local development
variable "outputs_location" {
  description = "Enable writing provider, tfvars and CI/CD workflow files to local filesystem."
  type        = string
  default     = null
}

# Factories configuration
variable "factories_config" {
  description = "Paths to data files and folders that enable factory functionality."
  type = object({
    network_projects = optional(string, "data/network-projects.yaml")
    subnet_vending   = optional(string, "data/network-subnets.yaml")
  })
  default = {
    network_projects = "data/network-projects.yaml"
    subnet_vending   = "data/network-subnets.yaml"
  }
}

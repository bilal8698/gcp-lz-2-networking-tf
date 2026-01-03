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

# Automated Subnet Vending with IPAM Integration
# YAML-driven factory for dynamic subnet creation

# Create data/network-subnets.yaml file for subnet vending configuration
locals {
  # Read subnet vending configuration from YAML
  subnet_vending_raw = try(
    yamldecode(file("${path.module}/${var.factories_config.subnet_vending}")),
    { subnets = [] }
  )

  # T-Shirt sizing for subnets (from TDD)
  subnet_sizes = {
    "S" = 26  # Small: /26 (64 IPs) - Default
    "M" = 25  # Medium: /25 (128 IPs)
    "L" = 24  # Large: /24 (256 IPs)
  }

  # Process vended subnets
  vended_subnets = {
    for subnet in try(local.subnet_vending_raw.subnets, []) : 
    "${subnet.region}-${subnet.model}-${subnet.business_unit}-${subnet.application}-subnet1" => {
      name               = "${subnet.region}-${subnet.model}-${subnet.business_unit}-${subnet.application}-subnet1"
      region             = subnet.region
      model              = subnet.model
      business_unit      = subnet.business_unit
      application        = subnet.application
      size               = try(subnet.size, "S")
      cidr_block         = subnet.cidr_block  # Allocated by Blue Cat via APIGEE
      vpc_key            = subnet.model        # m1p, m1np, m3p, m3np
      
      # VPC Flow Logs configuration (enabled by default per TDD)
      flow_logs_config = {
        aggregation_interval = try(subnet.flow_logs_aggregation_interval, "INTERVAL_5_SEC")
        flow_sampling        = try(subnet.flow_logs_sampling, 0.5)
        metadata            = "INCLUDE_ALL_METADATA"
      }

      # Private Google Access (enabled by default per TDD)
      private_ip_google_access = try(subnet.private_ip_google_access, true)

      # Mandatory labels
      labels = merge(
        {
          cost_center    = try(subnet.cost_center, "unknown")
          owner          = try(subnet.owner, "unknown")
          application    = subnet.application
          leanix_app_id  = try(subnet.leanix_app_id, "unknown")
          business_unit  = subnet.business_unit
          model          = subnet.model
          managed_by     = "terraform"
          vending_method = "automated"
        },
        try(subnet.additional_labels, {})
      )
    }
  }

  # Map VPC keys to module references
  vpc_modules = {
    "m1p"  = module.vpc_m1p
    "m1np" = module.vpc_m1np
    "m3p"  = module.vpc_m3p
    "m3np" = module.vpc_m3np
  }
}

# Create vended subnets using Cloud Foundation Fabric subnet module
resource "google_compute_subnetwork" "vended_subnets" {
  for_each = local.vended_subnets

  project       = local.shared_vpcs[each.value.vpc_key].project_id
  name          = each.value.name
  region        = each.value.region
  network       = local.vpc_modules[each.value.vpc_key].id
  ip_cidr_range = each.value.cidr_block

  # Private Google Access
  private_ip_google_access = each.value.private_ip_google_access

  # VPC Flow Logs
  log_config {
    aggregation_interval = each.value.flow_logs_config.aggregation_interval
    flow_sampling        = each.value.flow_logs_config.flow_sampling
    metadata             = each.value.flow_logs_config.metadata
  }

  depends_on = [
    module.vpc_m1p,
    module.vpc_m1np,
    module.vpc_m3p,
    module.vpc_m3np
  ]
}

# APIGEE Integration for IPAM Automation
# Note: This is a placeholder for APIGEE → Blue Cat integration
# The actual integration will use Terraform providers or Cloud Run functions

/*
# Example APIGEE Integration (to be implemented with Cloud Run)

module "apigee_bluecat_integration" {
  source = "./modules/apigee-bluecat"

  project_id = local.nethub_project
  
  apigee_config = {
    endpoint = var.apigee_endpoint
    api_key  = var.apigee_api_key  # Stored in Secret Manager
  }

  bluecat_config = {
    gateway_url = var.bluecat_gateway_url
    bam_url     = var.bluecat_bam_url  # In AWS
  }

  # Cloud Run function for automation
  cloud_run_config = {
    name     = "bluecat-ipam-automation"
    region   = "us-central1"
    vpc      = module.vpc_m1p.id
    vpc_connector = google_vpc_access_connector.bluecat_connector.id
  }
}
*/

# Subnet Vending Automation Notes:
#
# 1. Workflow:
#    a. User creates PR modifying data/network-subnets.yaml
#    b. GitHub Actions triggers terraform plan
#    c. Terraform calls APIGEE API (via provider or Cloud Run)
#    d. APIGEE forwards to Blue Cat Gateway
#    e. Blue Cat Gateway communicates with BAM in AWS
#    f. Blue Cat allocates IP from IPAM database
#    g. CIDR block returned to Terraform
#    h. On merge, terraform apply creates subnet with allocated CIDR
#    i. Blue Cat records subnet in IPAM
#
# 2. T-Shirt Sizing:
#    - Small (S): /26 = 64 IPs (default)
#    - Medium (M): /25 = 128 IPs
#    - Large (L): /24 = 256 IPs
#    - Exception: > /24 requires architecture review
#
# 3. Mandatory Tags (enforced):
#    - cost_center
#    - owner
#    - application
#    - leanix_app_id
#
# 4. VPC Flow Logs (enabled by default):
#    - Sampling: 50%
#    - Aggregation: 5 seconds
#    - Metadata: All fields (for latency analysis)
#
# 5. Private Google Access:
#    - Enabled on all subnets by default
#    - Allows VMs without external IPs to reach Google APIs

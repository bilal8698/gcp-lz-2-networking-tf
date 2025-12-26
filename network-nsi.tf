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

# Network Security Integration (NSI) Configuration
# In-band traffic inspection using Palo Alto VM-Series

# Note: This is a placeholder for NSI configuration
# The actual NSI implementation will be completed after:
# 1. Palo Alto VM-Series firewalls are deployed (in network-paloalto.tf)
# 2. Internal Load Balancers are configured
# 3. NSI policies are defined

# NSI Service Producer Configuration
# This will define the Security VPC as the service producer for NSI

/*
# Example NSI Configuration (to be implemented)

resource "google_network_security_firewall_endpoint" "paloalto_endpoints" {
  for_each = local.regions

  name     = "fw-endpoint-${each.key}"
  parent   = "projects/${local.netsec_project}/locations/${each.key}"
  project  = local.netsec_project

  billing_project_id = local.netsec_project

  # Reference to the ILB frontend
  firewall_endpoint_type = "NETWORK_FIREWALL_ENDPOINT"

  # Association with security VPC
  network = module.vpc_security_data.id

  depends_on = [
    module.vpc_security_data,
    module.paloalto_ilb  # To be created
  ]
}

# NSI Policy Configuration for Workload VPCs
resource "google_compute_network_firewall_policy" "nsi_policy_m1p" {
  project     = local.nethub_project
  name        = "nsi-policy-m1p"
  description = "NSI policy for Model 1 Production - redirect traffic to Palo Alto"

  # Rules for traffic interception
  rule {
    action      = "apply_security_profile_group"
    direction   = "EGRESS"
    priority    = 1000
    description = "Intercept egress traffic for inspection"

    match {
      dest_ip_ranges = ["0.0.0.0/0"]
    }

    target_secure_tags {
      name = "tagValues/${google_tags_tag_value.nsi_enabled.name}"
    }

    security_profile_group = google_network_security_security_profile_group.paloalto_profile.id
  }

  depends_on = [module.vpc_m1p]
}

# Associate NSI policy with VPC
resource "google_compute_network_firewall_policy_association" "m1p_nsi" {
  project           = local.nethub_project
  name              = "m1p-nsi-association"
  firewall_policy   = google_compute_network_firewall_policy.nsi_policy_m1p.name
  attachment_target = module.vpc_m1p.id
}
*/

# Placeholder outputs for NSI endpoints
output "nsi_endpoints_placeholder" {
  description = "NSI endpoints will be created after Palo Alto deployment"
  value = {
    status = "To be implemented after Palo Alto VM-Series deployment"
    next_steps = [
      "Deploy Palo Alto VM-Series firewalls",
      "Configure Internal Load Balancers",
      "Create NSI firewall endpoints",
      "Define NSI policies for each VPC",
      "Associate policies with VPCs"
    ]
  }
}

# NSI Configuration Notes:
# 
# 1. Traffic Flow with NSI:
#    VM → NSI intercepts at vNIC → Geneve encapsulation → Palo Alto ILB
#    → Palo Alto inspects → Return to VPC → Route via NCC → Destination
#
# 2. NSI Policy Requirements:
#    - Inter-model traffic: INSPECT (M1P → M1NP, M1P → M3P, etc.)
#    - Intra-model traffic: SELECTIVE (use Secure Tags for bypass)
#    - Hybrid traffic: INSPECT (All traffic to On-Prem)
#    - Internet traffic: INSPECT (All egress via Cloud NAT)
#
# 3. Fail-Open Design:
#    - If Palo Alto fleet is down, traffic fails open for availability
#    - This is a risk acceptance documented in TDD
#
# 4. Regional Deployment:
#    - NSI endpoints deployed per region
#    - Regional Managed Instance Groups for Palo Alto
#    - Regional ILB for traffic distribution

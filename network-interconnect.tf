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

# Cloud Interconnect VLAN Attachments
# Provides dedicated connectivity to SD-WAN Fabric (Underlay)
# Connections to On-Premises Data Centers, AWS, and Azure

# Note: This file creates the VLAN attachment configuration framework
# Actual Interconnect circuits must be ordered separately from Google Cloud

locals {
  # Primary regions for Interconnect attachments
  interconnect_regions = {
    "us-east4" = {
      region      = "us-east4"
      router_key  = "us-east4"
      description = "Primary AMER Interconnect"
    }
    "europe-west3" = {
      region      = "europe-west3"
      router_key  = "europe-west3"
      description = "Primary EMEA Interconnect"
    }
    "asia-southeast1" = {
      region      = "asia-southeast1"
      router_key  = "asia-southeast1"
      description = "Primary APAC Interconnect"
    }
  }
}

# VLAN Attachments for Dedicated Interconnect
# Configuration template - requires actual Interconnect provisioning
resource "google_compute_interconnect_attachment" "vlan_attachments" {
  for_each = local.interconnect_regions

  project     = local.transit_project
  name        = "vlan-attachment-${each.key}"
  region      = each.value.region
  router      = google_compute_router.transit_routers[each.value.router_key].id
  description = each.value.description

  type                     = "DEDICATED"
  edge_availability_domain = "AVAILABILITY_DOMAIN_1"

  # Bandwidth configuration - adjust based on actual circuit capacity
  bandwidth = "BPS_10G"

  # VLAN tag for 802.1Q - coordinate with network team
  vlan_tag8021q = 100 + index(keys(local.interconnect_regions), each.key)

  # Admin enabled by default
  admin_enabled = true

  # Encryption disabled for Interconnect (uses dedicated physical connection)
  encryption = "NONE"

  depends_on = [
    google_compute_router.transit_routers
  ]
}

# Note: Interconnect attachments require:
# 1. Physical Interconnect circuit ordered from Google Cloud
# 2. Cross-connect in colocation facility
# 3. BGP configuration on Cloud Router
# 4. Coordination with on-premises network team for VLAN and IP addressing

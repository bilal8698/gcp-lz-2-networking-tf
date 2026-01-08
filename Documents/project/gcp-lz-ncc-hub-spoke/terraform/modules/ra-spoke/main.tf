# Router Appliance Spoke Module
# For Transit VPC with Router Appliance instances
# Vijay's note: "Interface 0 is one directional and interface 1 is another directional"

# Data source to get VPC details
data "google_compute_network" "vpc" {
  name    = var.vpc_name
  project = var.vpc_project_id
}

# Create Cloud Router for RA spoke
resource "google_compute_router" "router" {
  name    = var.router_name
  project = var.project_id
  region  = var.region
  network = data.google_compute_network.vpc.id

  bgp {
    asn               = var.router_asn
    advertise_mode    = var.advertise_mode
    advertised_groups = var.advertised_groups

    dynamic "advertised_ip_ranges" {
      for_each = var.advertised_ip_ranges
      content {
        range       = advertised_ip_ranges.value.range
        description = advertised_ip_ranges.value.description
      }
    }
  }

  description = "Router for NCC RA spoke - ${var.zone}"
}

# Create Router Appliance Spoke
resource "google_network_connectivity_spoke" "ra_spoke" {
  project  = var.project_id
  name     = var.spoke_name
  location = var.region
  hub      = var.hub_id

  linked_router_appliance_instances {
    dynamic "instances" {
      for_each = var.router_appliances
      content {
        virtual_machine = instances.value.vm_uri
        ip_address      = instances.value.ip_address
      }
    }

    site_to_site_data_transfer = var.site_to_site_data_transfer
  }

  labels = merge(
    var.labels,
    {
      spoke_type = "router-appliance"
      zone       = var.zone
      managed_by = "terraform"
    }
  )

  description = "NCC Router Appliance spoke for ${var.zone}"
}

# BGP Peers for Router Appliances
resource "google_compute_router_peer" "ra_peers" {
  for_each = var.router_appliances

  name                      = "${var.router_name}-peer-${each.key}"
  project                   = var.project_id
  router                    = google_compute_router.router.name
  region                    = var.region
  peer_ip_address          = each.value.peer_ip
  peer_asn                 = each.value.peer_asn
  advertised_route_priority = each.value.route_priority
  interface                = each.key  # interface0 or interface1

  router_appliance_instance = each.value.vm_uri
}

# VPC Module - Creates VPC with subnets
# Per Carrier LLD v1.0

resource "google_compute_network" "vpc" {
  name                            = var.vpc_name
  project                         = var.project_id
  description                     = var.description
  routing_mode                    = var.routing_mode
  auto_create_subnetworks         = var.auto_create_subnetworks
  delete_default_routes_on_create = var.delete_default_routes_on_create
  enable_ula_internal_ipv6        = var.enable_ula_internal_ipv6

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

resource "google_compute_subnetwork" "subnets" {
  for_each = { for subnet in var.subnets : subnet.name => subnet }

  name                     = each.value.name
  project                  = var.project_id
  region                   = each.value.region
  network                  = google_compute_network.vpc.self_link
  ip_cidr_range            = each.value.ip_cidr_range
  description              = each.value.description
  private_ip_google_access = each.value.private_ip_google_access

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

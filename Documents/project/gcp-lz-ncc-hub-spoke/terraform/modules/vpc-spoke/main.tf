# VPC Spoke Module
# Creates NCC VPC spokes for M1P, M1NP, M3P, M3NP
# Following Vijay's pattern: Uses Cloud Foundation Fabric module

# Data source to get VPC details
data "google_compute_network" "vpc" {
  name    = var.vpc_name
  project = var.vpc_project_id
}

# Create NCC VPC Spoke using Cloud Foundation Fabric
resource "google_network_connectivity_spoke" "vpc_spoke" {
  project  = var.project_id
  name     = var.spoke_name
  location = var.region
  hub      = var.hub_id

  linked_vpc_network {
    uri                       = data.google_compute_network.vpc.self_link
    exclude_export_ranges     = var.exclude_export_ranges
    include_export_ranges     = var.include_export_ranges
  }

  labels = merge(
    var.labels,
    {
      spoke_type = "vpc"
      zone       = var.zone
      managed_by = "terraform"
    }
  )

  description = "NCC VPC spoke for ${var.zone} zone"
}

# Optional: Spoke activation policy
resource "google_network_connectivity_spoke_activation" "activation" {
  count = var.auto_activate ? 1 : 0

  spoke = google_network_connectivity_spoke.vpc_spoke.id
}

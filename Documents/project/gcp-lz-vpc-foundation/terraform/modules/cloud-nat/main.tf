# Cloud NAT Module - Creates Cloud NAT for internet connectivity
# Per Carrier LLD v1.0

resource "google_compute_router_nat" "nat" {
  name    = var.name
  project = var.project_id
  region  = var.region
  router  = var.router

  nat_ip_allocate_option             = var.nat_ip_allocate_option
  source_subnetwork_ip_ranges_to_nat = var.source_subnetwork_ip_ranges_to_nat

  min_ports_per_vm                    = var.min_ports_per_vm
  max_ports_per_vm                    = var.max_ports_per_vm
  enable_dynamic_port_allocation      = var.enable_dynamic_port_allocation
  enable_endpoint_independent_mapping = var.enable_endpoint_independent_mapping

  log_config {
    enable = var.enable_logging
    filter = var.log_filter
  }

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

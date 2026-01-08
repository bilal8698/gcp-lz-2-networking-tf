# NCC Hub Module
# Creates the central Network Connectivity Center Hub
# Following Vijay's pattern: "Inside the module - resources and locals"

resource "google_network_connectivity_hub" "hub" {
  project     = var.project_id
  name        = var.hub_name
  description = var.description

  labels = merge(
    var.labels,
    {
      managed_by = "terraform"
      component  = "ncc-hub"
      zone       = "global"
    }
  )
}

# Hub routing configuration
resource "google_network_connectivity_spoke" "hub_default_route" {
  count = var.enable_global_routing ? 1 : 0

  project  = var.project_id
  name     = "${var.hub_name}-global-routing"
  hub      = google_network_connectivity_hub.hub.id
  location = "global"

  labels = var.labels
}

# NCC Hub Module Outputs
# These outputs are used by the main.tf to pass to other modules

output "hub_id" {
  description = "ID of the NCC Hub (used by spoke modules)"
  value       = google_network_connectivity_hub.hub.id
}

output "hub_name" {
  description = "Name of the NCC Hub"
  value       = google_network_connectivity_hub.hub.name
}

output "hub_self_link" {
  description = "Self-link of the NCC Hub"
  value       = google_network_connectivity_hub.hub.self_link
}

output "hub_state" {
  description = "State of the NCC Hub"
  value       = google_network_connectivity_hub.hub.state
}

output "hub_uri" {
  description = "URI of the NCC Hub"
  value       = google_network_connectivity_hub.hub.uri
}

output "hub_unique_id" {
  description = "Unique ID of the NCC Hub"
  value       = google_network_connectivity_hub.hub.unique_id
}

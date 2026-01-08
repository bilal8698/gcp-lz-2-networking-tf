# VPC Spoke Module Outputs

output "spoke_id" {
  description = "ID of the NCC VPC spoke"
  value       = google_network_connectivity_spoke.vpc_spoke.id
}

output "spoke_name" {
  description = "Name of the NCC spoke"
  value       = google_network_connectivity_spoke.vpc_spoke.name
}

output "spoke_uri" {
  description = "URI of the NCC spoke"
  value       = google_network_connectivity_spoke.vpc_spoke.uri
}

output "spoke_state" {
  description = "State of the spoke"
  value       = google_network_connectivity_spoke.vpc_spoke.state
}

output "vpc_uri" {
  description = "URI of the connected VPC"
  value       = data.google_compute_network.vpc.self_link
}

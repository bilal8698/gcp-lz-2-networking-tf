# Router Appliance Spoke Module Outputs

output "spoke_id" {
  description = "ID of the RA spoke"
  value       = google_network_connectivity_spoke.ra_spoke.id
}

output "spoke_name" {
  description = "Name of the RA spoke"
  value       = google_network_connectivity_spoke.ra_spoke.name
}

output "spoke_uri" {
  description = "URI of the RA spoke"
  value       = google_network_connectivity_spoke.ra_spoke.uri
}

output "router_id" {
  description = "ID of the Cloud Router"
  value       = google_compute_router.router.id
}

output "router_name" {
  description = "Name of the Cloud Router"
  value       = google_compute_router.router.name
}

output "router_self_link" {
  description = "Self-link of the Cloud Router"
  value       = google_compute_router.router.self_link
}

output "bgp_peers" {
  description = "BGP peer information"
  value = {
    for key, peer in google_compute_router_peer.ra_peers :
    key => {
      name            = peer.name
      peer_ip_address = peer.peer_ip_address
      peer_asn        = peer.peer_asn
    }
  }
}

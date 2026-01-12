# Cloud Router Module Outputs

output "router_id" {
  description = "Cloud Router ID"
  value       = google_compute_router.router.id
}

output "router_name" {
  description = "Cloud Router name"
  value       = google_compute_router.router.name
}

output "router_self_link" {
  description = "Cloud Router self-link"
  value       = google_compute_router.router.self_link
}

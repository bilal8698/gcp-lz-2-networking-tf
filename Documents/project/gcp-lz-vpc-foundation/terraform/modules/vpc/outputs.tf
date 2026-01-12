# VPC Module Outputs

output "vpc_id" {
  description = "VPC ID"
  value       = google_compute_network.vpc.id
}

output "vpc_name" {
  description = "VPC name"
  value       = google_compute_network.vpc.name
}

output "vpc_self_link" {
  description = "VPC self-link"
  value       = google_compute_network.vpc.self_link
}

output "subnet_ids" {
  description = "Map of subnet names to IDs"
  value = {
    for key, subnet in google_compute_subnetwork.subnets : key => subnet.id
  }
}

output "subnet_self_links" {
  description = "Map of subnet names to self-links"
  value = {
    for key, subnet in google_compute_subnetwork.subnets : key => subnet.self_link
  }
}

output "subnet_regions" {
  description = "Map of subnet names to regions"
  value = {
    for key, subnet in google_compute_subnetwork.subnets : key => subnet.region
  }
}

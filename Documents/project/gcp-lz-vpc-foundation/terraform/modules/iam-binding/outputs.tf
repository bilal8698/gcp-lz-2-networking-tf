# IAM Binding Module Outputs

output "project_id" {
  description = "Project ID where IAM bindings were applied"
  value       = var.project_id
}

output "roles_granted" {
  description = "List of roles granted"
  value       = var.roles
}

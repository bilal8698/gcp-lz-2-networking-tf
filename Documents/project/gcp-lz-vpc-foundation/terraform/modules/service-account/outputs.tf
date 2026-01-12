# Service Account Module Outputs

output "service_account_email" {
  description = "Service account email"
  value       = google_service_account.service_account.email
}

output "service_account_id" {
  description = "Service account ID"
  value       = google_service_account.service_account.id
}

output "service_account_name" {
  description = "Service account name"
  value       = google_service_account.service_account.name
}

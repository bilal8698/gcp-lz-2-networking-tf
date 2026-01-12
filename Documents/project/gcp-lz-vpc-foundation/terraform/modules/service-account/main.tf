# Service Account Module - Creates service accounts
# Per Carrier LLD v1.0

resource "google_service_account" "service_account" {
  account_id   = var.account_id
  display_name = var.display_name
  description  = var.description
  project      = var.project_id
}

# IAM Binding Module - Grants IAM roles to service accounts
# Per Carrier LLD v1.0

resource "google_project_iam_member" "iam_binding" {
  for_each = toset(var.roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${var.service_account_email}"
}

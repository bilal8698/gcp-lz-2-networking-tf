# IAM Binding Module Variables

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "service_account_email" {
  description = "Service account email"
  type        = string
}

variable "roles" {
  description = "List of IAM roles to grant"
  type        = list(string)
}

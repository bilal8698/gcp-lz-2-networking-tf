# Backend Configuration
# GCS backend for Terraform state storage

terraform {
  backend "gcs" {
    bucket = "carrier-terraform-state"
    prefix = "ncc-hub-spoke"
  }
}

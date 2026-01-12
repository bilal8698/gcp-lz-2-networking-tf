# Terraform and provider version constraints
# Aligned with Cloud Foundation Fabric v45.0.0

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Reference: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/tree/v45.0.0

# Provider and Terraform Version Configuration
# Using cloud-foundation-fabric v45.0.0 as source - Vijay's requirement

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  # Configuration will come from environment variables or service account
  # Service account confirmed available by manager
}

provider "google-beta" {
  # Configuration will come from environment variables or service account
}

# Reference to Cloud Foundation Fabric modules
# Source: git::https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/net-ncc-spoke?ref=v45.0.0
# This comment documents the source for ncc-spoke-ra module mentioned by Vijay

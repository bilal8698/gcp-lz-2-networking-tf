# Backend Configuration for VPC Foundation Module
# Per Carrier LLD v1.0

# IMPORTANT: Update these values before deployment
# This file defines where Terraform state is stored

terraform {
  backend "gcs" {
    # GCS bucket for storing Terraform state
    # Replace with your actual state bucket
    bucket = "carrier-terraform-state-vpc-foundation"
    
    # State file prefix/path
    prefix = "vpc-foundation/terraform.tfstate"
    
    # Optional: Enable state locking
    # encryption_key = "projects/{project}/locations/{location}/keyRings/{keyring}/cryptoKeys/{key}"
  }
}

# Alternative: Local backend for testing (NOT recommended for production)
# terraform {
#   backend "local" {
#     path = "terraform.tfstate"
#   }
# }

# Note: Before running terraform init, create the GCS bucket:
# gsutil mb -p {project-id} -l us-central1 gs://carrier-terraform-state-vpc-foundation
# gsutil versioning set on gs://carrier-terraform-state-vpc-foundation

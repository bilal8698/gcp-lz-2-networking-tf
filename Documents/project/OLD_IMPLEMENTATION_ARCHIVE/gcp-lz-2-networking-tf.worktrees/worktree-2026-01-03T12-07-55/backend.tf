# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Terraform backend configuration for GCS state storage
# This stores the Terraform state file in a Google Cloud Storage bucket

terraform {
  backend "gcs" {
    # Bucket name should be set via backend config file or CLI
    # Example: terraform init -backend-config="bucket=carrier-tf-state-networking"
    # Example: terraform init -backend-config="prefix=networking/state"
    
    # bucket  = "carrier-tf-state-networking"  # To be specified during init
    # prefix  = "networking/terraform.tfstate"  # To be specified during init
    
    # These can be set via backend config or environment variables
    # impersonate_service_account = "terraform@project-id.iam.gserviceaccount.com"
  }

  required_version = ">= 1.7.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0, < 6.0.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 5.0.0, < 6.0.0"
    }
  }
}

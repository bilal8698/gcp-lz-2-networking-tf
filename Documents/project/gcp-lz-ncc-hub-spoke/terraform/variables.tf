# Repository-level Variables
# These are input variables for the entire repository

variable "outputs_bucket" {
  description = "GCS bucket name for storing outputs (for downstream modules)"
  type        = string
}

variable "deploy_transit_spoke" {
  description = "Deploy Transit Router Appliance spoke (set to false until Palo Alto is deployed)"
  type        = bool
  default     = false
}

variable "project_id" {
  description = "Default project ID (can be overridden in YAML)"
  type        = string
  default     = ""
}

variable "region" {
  description = "Default region (can be overridden in YAML)"
  type        = string
  default     = "us-central1"
}

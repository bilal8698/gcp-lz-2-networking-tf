# Input variables for VPC Foundation Module
# Per Carrier LLD v1.0

variable "model_vpcs_config_file" {
  description = "Path to the YAML file containing Model VPCs configuration (M1P, M1NP, M3P, M3NP)"
  type        = string
  default     = "../data/model-vpcs-config.yaml"
}

variable "infrastructure_vpcs_config_file" {
  description = "Path to the YAML file containing Infrastructure VPCs configuration (Transit, Security, Shared Services)"
  type        = string
  default     = "../data/infrastructure-vpcs-config.yaml"
}

variable "service_accounts_config_file" {
  description = "Path to the YAML file containing Service Accounts configuration"
  type        = string
  default     = "../data/service-accounts-config.yaml"
}

variable "labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
  default = {
    environment = "production"
    managed-by  = "terraform"
    module      = "vpc-foundation"
  }
}

variable "enable_cloud_nat" {
  description = "Enable Cloud NAT for VPCs (can be overridden per VPC in YAML)"
  type        = bool
  default     = true
}

variable "enable_cloud_routers" {
  description = "Enable Cloud Routers for VPCs (required for Cloud NAT and BGP)"
  type        = bool
  default     = true
}

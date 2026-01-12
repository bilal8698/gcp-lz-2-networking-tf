# VPC Module Variables

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "description" {
  description = "VPC description"
  type        = string
  default     = ""
}

variable "routing_mode" {
  description = "VPC routing mode (GLOBAL or REGIONAL)"
  type        = string
  default     = "GLOBAL"
}

variable "auto_create_subnetworks" {
  description = "Auto-create subnetworks"
  type        = bool
  default     = false
}

variable "delete_default_routes_on_create" {
  description = "Delete default routes on VPC creation"
  type        = bool
  default     = false
}

variable "enable_ula_internal_ipv6" {
  description = "Enable ULA internal IPv6"
  type        = bool
  default     = false
}

variable "subnets" {
  description = "List of subnets to create"
  type = list(object({
    name                     = string
    region                   = string
    ip_cidr_range            = string
    description              = string
    private_ip_google_access = bool
  }))
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}

# Router Appliance Spoke Module Variables
# For Transit VPC with Palo Alto or other router appliances

variable "hub_id" {
  description = "NCC Hub ID to attach spoke to"
  type        = string
}

variable "spoke_name" {
  description = "Name of the RA spoke"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.spoke_name))
    error_message = "Spoke name must be lowercase."
  }
}

variable "project_id" {
  description = "Project ID where spoke will be created"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_project_id" {
  description = "Project ID where VPC exists"
  type        = string
}

variable "region" {
  description = "Region for the spoke and router"
  type        = string
}

variable "router_name" {
  description = "Name of the Cloud Router"
  type        = string
}

variable "router_asn" {
  description = "ASN for the Cloud Router"
  type        = number
}

variable "zone" {
  description = "Zone designation (transit, management)"
  type        = string
  default     = "transit"
}

variable "router_appliances" {
  description = "Router appliance configurations (interface0, interface1)"
  type = map(object({
    vm_uri         = string
    ip_address     = string
    peer_ip        = string
    peer_asn       = number
    route_priority = number
  }))
}

variable "advertise_mode" {
  description = "BGP advertise mode (DEFAULT or CUSTOM)"
  type        = string
  default     = "CUSTOM"
}

variable "advertised_groups" {
  description = "BGP advertised groups"
  type        = list(string)
  default     = ["ALL_SUBNETS"]
}

variable "advertised_ip_ranges" {
  description = "Custom IP ranges to advertise"
  type = list(object({
    range       = string
    description = string
  }))
  default = []
}

variable "site_to_site_data_transfer" {
  description = "Enable site-to-site data transfer"
  type        = bool
  default     = true
}

variable "labels" {
  description = "Labels to apply"
  type        = map(string)
  default     = {}
}

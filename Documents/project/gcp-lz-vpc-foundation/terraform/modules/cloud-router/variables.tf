# Cloud Router Module Variables

variable "name" {
  description = "Cloud Router name"
  type        = string
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "network" {
  description = "VPC network self-link"
  type        = string
}

variable "asn" {
  description = "BGP ASN"
  type        = number
  default     = 16550
}

variable "advertise_mode" {
  description = "BGP advertise mode"
  type        = string
  default     = "CUSTOM"
}

variable "advertised_groups" {
  description = "BGP advertised groups"
  type        = list(string)
  default     = ["ALL_SUBNETS"]
}

variable "advertised_ip_ranges" {
  description = "BGP advertised IP ranges"
  type = list(object({
    range       = string
    description = string
  }))
  default = []
}

# VPC Spoke Module Variables
# For M1P, M1NP, M3P, M3NP spokes

variable "hub_id" {
  description = "NCC Hub ID to attach spoke to"
  type        = string
}

variable "spoke_name" {
  description = "Name of the NCC spoke"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.spoke_name))
    error_message = "Spoke name must be lowercase, start with letter."
  }
}

variable "project_id" {
  description = "Project ID where spoke will be created"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC to connect"
  type        = string
}

variable "vpc_project_id" {
  description = "Project ID where VPC exists"
  type        = string
}

variable "region" {
  description = "Region for the spoke"
  type        = string
}

variable "zone" {
  description = "Zone designation (model-1, model-3, model-5)"
  type        = string
}

variable "labels" {
  description = "Labels to apply (must include mandatory Carrier tags)"
  type        = map(string)
  default     = {}
}

variable "exclude_export_ranges" {
  description = "IP ranges to exclude from export"
  type        = list(string)
  default     = []
}

variable "include_export_ranges" {
  description = "IP ranges to include in export"
  type        = list(string)
  default     = []
}

variable "auto_activate" {
  description = "Automatically activate the spoke"
  type        = bool
  default     = true
}

# NCC Hub Module Variables
# All values come from YAML configuration

variable "project_id" {
  description = "Project ID where NCC Hub will be created (prj-prd-gcp-40036-mgmt-nethub)"
  type        = string
}

variable "hub_name" {
  description = "Name of the NCC Hub"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.hub_name))
    error_message = "Hub name must be lowercase, start with letter, contain only letters, numbers, and hyphens."
  }
}

variable "description" {
  description = "Description of the NCC Hub"
  type        = string
  default     = "Carrier Production NCC Hub for multi-region connectivity"
}

variable "labels" {
  description = "Labels to apply to the NCC Hub (mandatory: cost_center, owner, application, leanix_app_id)"
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      contains(keys(var.labels), "cost_center"),
      contains(keys(var.labels), "owner"),
      contains(keys(var.labels), "application"),
      contains(keys(var.labels), "leanix_app_id")
    ])
    error_message = "Labels must include: cost_center, owner, application, leanix_app_id."
  }
}

variable "enable_global_routing" {
  description = "Enable global routing configuration"
  type        = bool
  default     = false
}

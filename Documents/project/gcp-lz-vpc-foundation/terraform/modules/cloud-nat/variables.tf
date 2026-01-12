# Cloud NAT Module Variables

variable "name" {
  description = "Cloud NAT name"
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

variable "router" {
  description = "Cloud Router name"
  type        = string
}

variable "nat_ip_allocate_option" {
  description = "NAT IP allocation option"
  type        = string
  default     = "AUTO_ONLY"
}

variable "source_subnetwork_ip_ranges_to_nat" {
  description = "Source subnetwork IP ranges to NAT"
  type        = string
  default     = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

variable "min_ports_per_vm" {
  description = "Minimum ports per VM"
  type        = number
  default     = 64
}

variable "max_ports_per_vm" {
  description = "Maximum ports per VM"
  type        = number
  default     = 65536
}

variable "enable_dynamic_port_allocation" {
  description = "Enable dynamic port allocation"
  type        = bool
  default     = true
}

variable "enable_endpoint_independent_mapping" {
  description = "Enable endpoint independent mapping"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Enable Cloud NAT logging"
  type        = bool
  default     = true
}

variable "log_filter" {
  description = "Log filter (ERRORS_ONLY, TRANSLATIONS_ONLY, ALL)"
  type        = string
  default     = "ERRORS_ONLY"
}

# Locals - Parse YAML Configuration Files
# "Under Data it consists of yaml files so whatever they do in the yaml files that would be the input" - Vijay

locals {
  # Parse NCC Hub configuration
  ncc_hub_config_raw = yamldecode(file("${path.module}/../data/ncc-hub-config.yaml"))
  ncc_hub_config = {
    project_id            = local.ncc_hub_config_raw.hub.project_id
    hub_name              = local.ncc_hub_config_raw.hub.name
    description           = local.ncc_hub_config_raw.hub.description
    enable_global_routing = lookup(local.ncc_hub_config_raw.hub, "enable_global_routing", false)
    labels                = local.ncc_hub_config_raw.hub.labels
  }

  # Parse VPC Spokes configuration (M1P, M1NP, M3P, M3NP)
  vpc_spokes_config_raw = yamldecode(file("${path.module}/../data/vpc-spokes-config.yaml"))
  vpc_spokes_config = {
    for key, spoke in local.vpc_spokes_config_raw.spokes : key => {
      spoke_name            = spoke.name
      project_id            = spoke.project_id
      vpc_name              = spoke.vpc_name
      vpc_project_id        = spoke.vpc_project_id
      region                = spoke.region
      zone                  = spoke.zone
      labels                = spoke.labels
      exclude_export_ranges = lookup(spoke, "exclude_export_ranges", [])
      include_export_ranges = lookup(spoke, "include_export_ranges", [])
      auto_activate         = lookup(spoke, "auto_activate", true)
    }
  }

  # Parse Transit RA Spoke configuration
  transit_spoke_config_raw = var.deploy_transit_spoke ? yamldecode(file("${path.module}/../data/transit-spoke-config.yaml")) : null
  transit_spoke_config = var.deploy_transit_spoke ? {
    spoke_name           = local.transit_spoke_config_raw.transit.spoke_name
    project_id           = local.transit_spoke_config_raw.transit.project_id
    vpc_name             = local.transit_spoke_config_raw.transit.vpc_name
    vpc_project_id       = local.transit_spoke_config_raw.transit.vpc_project_id
    region               = local.transit_spoke_config_raw.transit.region
    router_name          = local.transit_spoke_config_raw.transit.router_name
    router_asn           = local.transit_spoke_config_raw.transit.router_asn
    zone                 = local.transit_spoke_config_raw.transit.zone
    router_appliances    = local.transit_spoke_config_raw.transit.router_appliances
    advertise_mode       = lookup(local.transit_spoke_config_raw.transit, "advertise_mode", "CUSTOM")
    advertised_groups    = lookup(local.transit_spoke_config_raw.transit, "advertised_groups", ["ALL_SUBNETS"])
    advertised_ip_ranges = lookup(local.transit_spoke_config_raw.transit, "advertised_ip_ranges", [])
    labels               = local.transit_spoke_config_raw.transit.labels
  } : null
}

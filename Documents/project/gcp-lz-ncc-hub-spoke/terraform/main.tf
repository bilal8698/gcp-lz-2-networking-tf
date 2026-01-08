# Main Orchestration File
# "From outside we are calling those modules" - Vijay's pattern
# This file orchestrates all NCC Hub and Spoke deployments

# Create NCC Hub
module "ncc_hub" {
  source = "./modules/ncc-hub"

  project_id           = local.ncc_hub_config.project_id
  hub_name             = local.ncc_hub_config.hub_name
  description          = local.ncc_hub_config.description
  enable_global_routing = local.ncc_hub_config.enable_global_routing
  labels               = local.ncc_hub_config.labels
}

# Create VPC Spokes for Model 1 and Model 3 (M1P, M1NP, M3P, M3NP)
module "vpc_spokes" {
  source   = "./modules/vpc-spoke"
  for_each = local.vpc_spokes_config

  hub_id                = module.ncc_hub.hub_id
  spoke_name            = each.value.spoke_name
  project_id            = each.value.project_id
  vpc_name              = each.value.vpc_name
  vpc_project_id        = each.value.vpc_project_id
  region                = each.value.region
  zone                  = each.value.zone
  labels                = each.value.labels
  exclude_export_ranges = lookup(each.value, "exclude_export_ranges", [])
  include_export_ranges = lookup(each.value, "include_export_ranges", [])
  auto_activate         = lookup(each.value, "auto_activate", true)

  depends_on = [module.ncc_hub]
}

# Create Router Appliance Spoke for Transit VPC
module "transit_ra_spoke" {
  source = "./modules/ra-spoke"
  count  = var.deploy_transit_spoke ? 1 : 0

  hub_id              = module.ncc_hub.hub_id
  spoke_name          = local.transit_spoke_config.spoke_name
  project_id          = local.transit_spoke_config.project_id
  vpc_name            = local.transit_spoke_config.vpc_name
  vpc_project_id      = local.transit_spoke_config.vpc_project_id
  region              = local.transit_spoke_config.region
  router_name         = local.transit_spoke_config.router_name
  router_asn          = local.transit_spoke_config.router_asn
  zone                = local.transit_spoke_config.zone
  router_appliances   = local.transit_spoke_config.router_appliances
  advertise_mode      = local.transit_spoke_config.advertise_mode
  advertised_groups   = local.transit_spoke_config.advertised_groups
  advertised_ip_ranges = local.transit_spoke_config.advertised_ip_ranges
  labels              = local.transit_spoke_config.labels

  depends_on = [module.ncc_hub]
}

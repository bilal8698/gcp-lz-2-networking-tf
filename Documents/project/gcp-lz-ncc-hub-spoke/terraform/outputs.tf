# Outputs - For Downstream Modules
# These outputs are stored in GCS for other repositories to consume
# "Cloud router outputs for downstream modules" - Manager requirement

# ==============================================================================
# NCC Hub Outputs
# ==============================================================================
output "ncc_hub_id" {
  description = "NCC Hub ID for downstream modules"
  value       = module.ncc_hub.hub_id
}

output "ncc_hub_name" {
  description = "NCC Hub name"
  value       = module.ncc_hub.hub_name
}

output "ncc_hub_uri" {
  description = "NCC Hub URI"
  value       = module.ncc_hub.hub_uri
}

# ==============================================================================
# VPC Spoke Outputs (8 spokes total)
# ==============================================================================
output "vpc_spoke_ids" {
  description = "Map of VPC spoke names to their IDs (M1P, M1NP, M3P, M3NP, FW Data, FW Mgmt, Shared Services, Transit)"
  value = {
    for key, spoke in module.vpc_spokes : key => spoke.spoke_id
  }
}

output "vpc_spoke_uris" {
  description = "Map of VPC spoke names to their URIs"
  value = {
    for key, spoke in module.vpc_spokes : key => spoke.spoke_uri
  }
}

output "vpc_spoke_regions" {
  description = "Map of VPC spoke names to their regions"
  value = {
    for key, spoke_config in local.vpc_spokes_config : key => spoke_config.region
  }
}

# ==============================================================================
# Transit RA Spoke Outputs
# ==============================================================================
output "transit_spoke_id" {
  description = "Transit RA spoke ID (if deployed)"
  value       = var.deploy_transit_spoke ? module.transit_ra_spoke[0].spoke_id : null
}

output "transit_spoke_uri" {
  description = "Transit RA spoke URI (if deployed)"
  value       = var.deploy_transit_spoke ? module.transit_ra_spoke[0].spoke_uri : null
}

output "transit_router_id" {
  description = "Transit Cloud Router ID (if deployed) - For downstream HA-VPN module"
  value       = var.deploy_transit_spoke ? module.transit_ra_spoke[0].router_id : null
}

output "transit_router_name" {
  description = "Transit Cloud Router name (if deployed)"
  value       = var.deploy_transit_spoke ? module.transit_ra_spoke[0].router_name : null
}

output "transit_router_self_link" {
  description = "Transit Cloud Router self-link (if deployed) - For downstream modules"
  value       = var.deploy_transit_spoke ? module.transit_ra_spoke[0].router_self_link : null
}

output "transit_router_asn" {
  description = "Transit Cloud Router ASN (if deployed)"
  value       = var.deploy_transit_spoke ? local.transit_spoke_config.router_asn : null
}

output "transit_bgp_peers" {
  description = "Transit BGP peer information for Palo Alto integration"
  value = var.deploy_transit_spoke ? {
    for key, appliance in local.transit_spoke_config.router_appliances : key => {
      interface_name  = key
      peer_ip        = appliance.peer_ip
      peer_asn       = appliance.peer_asn
      local_ip       = appliance.ip_address
      route_priority = appliance.route_priority
    }
  } : null
}

# ==============================================================================
# Summary Output
# ==============================================================================
output "deployment_summary" {
  description = "Summary of NCC deployment"
  value = {
    hub_name          = local.ncc_hub_config.hub_name
    total_vpc_spokes  = length(local.vpc_spokes_config)
    vpc_spoke_names   = keys(local.vpc_spokes_config)
    transit_deployed  = var.deploy_transit_spoke
    project_id        = local.ncc_hub_config.project_id
  }
}

# ==============================================================================
# Store outputs in GCS for downstream modules to consume
# ==============================================================================
resource "google_storage_bucket_object" "ncc_outputs" {
  name    = "outputs/ncc-hub-spoke.json"
  bucket  = var.outputs_bucket
  content = jsonencode({
    # Hub details
    ncc_hub_id   = module.ncc_hub.hub_id
    ncc_hub_name = module.ncc_hub.hub_name
    ncc_hub_uri  = module.ncc_hub.hub_uri
    
    # VPC spokes (8 total)
    vpc_spoke_ids     = { for key, spoke in module.vpc_spokes : key => spoke.spoke_id }
    vpc_spoke_uris    = { for key, spoke in module.vpc_spokes : key => spoke.spoke_uri }
    vpc_spoke_regions = { for key, config in local.vpc_spokes_config : key => config.region }
    
    # Transit RA spoke
    transit_spoke_id         = var.deploy_transit_spoke ? module.transit_ra_spoke[0].spoke_id : null
    transit_spoke_uri        = var.deploy_transit_spoke ? module.transit_ra_spoke[0].spoke_uri : null
    transit_router_id        = var.deploy_transit_spoke ? module.transit_ra_spoke[0].router_id : null
    transit_router_name      = var.deploy_transit_spoke ? module.transit_ra_spoke[0].router_name : null
    transit_router_self_link = var.deploy_transit_spoke ? module.transit_ra_spoke[0].router_self_link : null
    transit_router_asn       = var.deploy_transit_spoke ? local.transit_spoke_config.router_asn : null
    transit_bgp_peers        = var.deploy_transit_spoke ? local.transit_spoke_config.router_appliances : null
    
    # Metadata
    deployment_timestamp = timestamp()
    deployed_by          = "terraform"
    module_version       = "v1.0.0"
    total_spokes         = length(local.vpc_spokes_config) + (var.deploy_transit_spoke ? 1 : 0)
  })

  content_type = "application/json"
}

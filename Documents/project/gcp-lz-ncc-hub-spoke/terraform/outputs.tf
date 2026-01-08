# Outputs - For Downstream Modules
# These outputs are stored in GCS for other repositories to consume

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

output "vpc_spoke_ids" {
  description = "Map of VPC spoke names to their IDs"
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

output "transit_spoke_id" {
  description = "Transit RA spoke ID (if deployed)"
  value       = var.deploy_transit_spoke ? module.transit_ra_spoke[0].spoke_id : null
}

output "transit_router_id" {
  description = "Transit Cloud Router ID (if deployed)"
  value       = var.deploy_transit_spoke ? module.transit_ra_spoke[0].router_id : null
}

output "transit_router_self_link" {
  description = "Transit Cloud Router self-link (if deployed)"
  value       = var.deploy_transit_spoke ? module.transit_ra_spoke[0].router_self_link : null
}

# Store outputs in GCS for downstream modules to consume
resource "google_storage_bucket_object" "ncc_outputs" {
  name    = "outputs/ncc-hub-spoke.json"
  bucket  = var.outputs_bucket
  content = jsonencode({
    ncc_hub_id            = module.ncc_hub.hub_id
    ncc_hub_name          = module.ncc_hub.hub_name
    ncc_hub_uri           = module.ncc_hub.hub_uri
    vpc_spoke_ids         = { for key, spoke in module.vpc_spokes : key => spoke.spoke_id }
    vpc_spoke_uris        = { for key, spoke in module.vpc_spokes : key => spoke.spoke_uri }
    transit_spoke_id      = var.deploy_transit_spoke ? module.transit_ra_spoke[0].spoke_id : null
    transit_router_id     = var.deploy_transit_spoke ? module.transit_ra_spoke[0].router_id : null
    transit_router_self_link = var.deploy_transit_spoke ? module.transit_ra_spoke[0].router_self_link : null
    deployment_timestamp  = timestamp()
    deployed_by          = "terraform"
  })

  content_type = "application/json"
}

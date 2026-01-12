# Local values for VPC Foundation Module
# Processes YAML configurations and prepares data structures

locals {
  # Load YAML configurations
  model_vpcs_config          = yamldecode(file(var.model_vpcs_config_file))
  infrastructure_vpcs_config = yamldecode(file(var.infrastructure_vpcs_config_file))
  service_accounts_config    = yamldecode(file(var.service_accounts_config_file))

  # Extract model VPCs (M1P, M1NP, M3P, M3NP)
  model_vpcs = local.model_vpcs_config.model_vpcs

  # Extract infrastructure VPCs (Transit, Security, Shared Services)
  infrastructure_vpcs = local.infrastructure_vpcs_config.infrastructure_vpcs

  # Extract service accounts
  service_accounts = local.service_accounts_config.service_accounts

  # Merge all VPCs for unified processing
  all_vpcs = merge(
    local.model_vpcs,
    local.infrastructure_vpcs
  )

  # Generate Cloud Router configurations for all regions
  # Cloud Routers are named: {region}-cr1 (e.g., useast4-cr1)
  cloud_routers = merge([
    for vpc_key, vpc in local.all_vpcs : {
      for subnet in vpc.subnets : "${vpc.vpc_name}-${subnet.region}" => {
        name       = replace("${subnet.region}-cr1", "_", "")
        vpc_key    = vpc_key
        vpc_name   = vpc.vpc_name
        project_id = vpc.project_id
        region     = subnet.region
        asn        = try(vpc.cloud_routers.asn, 16550)  # Default ASN or from config
      }
    } if try(vpc.cloud_routers.enabled, var.enable_cloud_routers)
  ]...)

  # Generate Cloud NAT configurations for all regions
  # Cloud NATs are named: {region}-{vpc_key}-cnat1 (e.g., useast4-m1p-cnat1)
  cloud_nats = merge([
    for vpc_key, vpc in local.all_vpcs : {
      for subnet in vpc.subnets : "${vpc.vpc_name}-${subnet.region}" => {
        name       = replace("${subnet.region}-${vpc_key}-cnat1", "_", "")
        vpc_key    = vpc_key
        vpc_name   = vpc.vpc_name
        project_id = vpc.project_id
        region     = subnet.region
        router_key = "${vpc.vpc_name}-${subnet.region}"
      }
    } if try(vpc.cloud_nat.enabled, var.enable_cloud_nat) && contains(try(vpc.cloud_nat.regions, []), subnet.region)
  ]...)

  # Extract unique projects for validation
  all_projects = distinct([
    for vpc in local.all_vpcs : vpc.project_id
  ])

  # Count resources for summary
  resource_counts = {
    model_vpcs          = length(local.model_vpcs)
    infrastructure_vpcs = length(local.infrastructure_vpcs)
    total_vpcs          = length(local.all_vpcs)
    total_subnets       = sum([for vpc in local.all_vpcs : length(vpc.subnets)])
    cloud_routers       = length(local.cloud_routers)
    cloud_nats          = length(local.cloud_nats)
    projects            = length(local.all_projects)
    service_accounts    = length(local.service_accounts)
  }
}

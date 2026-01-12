# Main Terraform Configuration for VPC Foundation Module
# Per Carrier LLD v1.0 - Creates 8 VPCs with subnets, Cloud Routers, Cloud NAT, and Service Accounts
# 
# Architecture:
# - 4 Model VPCs: M1P, M1NP, M3P, M3NP (shared-services project)
# - 4 Infrastructure VPCs: Transit, Security Data, Security Mgmt, Shared Services
# - Cloud Routers in all regions (ASN 16550 for Transit)
# - Cloud NAT for internet connectivity
# - Service Accounts with Viewer IAM bindings

# ============================================================================
# VPC Creation - All 8 VPCs
# ============================================================================

module "vpcs" {
  source   = "./modules/vpc"
  for_each = local.all_vpcs

  vpc_name                        = each.value.vpc_name
  project_id                      = each.value.project_id
  description                     = each.value.description
  routing_mode                    = each.value.routing_mode
  auto_create_subnetworks         = each.value.auto_create_subnetworks
  delete_default_routes_on_create = each.value.delete_default_routes_on_create
  enable_ula_internal_ipv6        = try(each.value.enable_ula_internal_ipv6, false)
  
  subnets = each.value.subnets
  labels  = var.labels
}

# ============================================================================
# Cloud Routers - Regional routers for Cloud NAT and BGP
# ============================================================================

module "cloud_routers" {
  source   = "./modules/cloud-router"
  for_each = local.cloud_routers

  name       = each.value.name
  project_id = each.value.project_id
  region     = each.value.region
  network    = module.vpcs[each.value.vpc_key].vpc_self_link
  asn        = each.value.asn

  depends_on = [module.vpcs]
}

# ============================================================================
# Cloud NAT - NAT gateway for internet connectivity
# ============================================================================

module "cloud_nats" {
  source   = "./modules/cloud-nat"
  for_each = local.cloud_nats

  name       = each.value.name
  project_id = each.value.project_id
  region     = each.value.region
  router     = module.cloud_routers[each.value.router_key].router_name

  depends_on = [module.cloud_routers]
}

# ============================================================================
# Service Accounts - One per project with Viewer access
# ============================================================================

module "service_accounts" {
  source   = "./modules/service-account"
  for_each = local.service_accounts

  account_id   = each.value.account_id
  display_name = each.value.display_name
  description  = each.value.description
  project_id   = each.value.project_id
}

# ============================================================================
# IAM Bindings - Grant Viewer access to service accounts
# ============================================================================

module "iam_bindings" {
  source   = "./modules/iam-binding"
  for_each = local.service_accounts

  project_id            = each.value.project_id
  service_account_email = module.service_accounts[each.key].service_account_email
  roles                 = each.value.roles

  depends_on = [module.service_accounts]
}

# Outputs for VPC Foundation Module
# Per Carrier LLD v1.0 - Outputs for downstream modules

# ============================================================================
# VPC Outputs
# ============================================================================

output "vpc_ids" {
  description = "Map of VPC keys to their IDs"
  value = {
    for key, vpc in module.vpcs : key => vpc.vpc_id
  }
}

output "vpc_self_links" {
  description = "Map of VPC keys to their self-links"
  value = {
    for key, vpc in module.vpcs : key => vpc.vpc_self_link
  }
}

output "vpc_names" {
  description = "Map of VPC keys to their names"
  value = {
    for key, vpc in module.vpcs : key => vpc.vpc_name
  }
}

# ============================================================================
# Subnet Outputs
# ============================================================================

output "subnet_ids" {
  description = "Map of VPC keys to their subnet IDs"
  value = {
    for key, vpc in module.vpcs : key => vpc.subnet_ids
  }
}

output "subnet_self_links" {
  description = "Map of VPC keys to their subnet self-links"
  value = {
    for key, vpc in module.vpcs : key => vpc.subnet_self_links
  }
}

output "subnet_regions" {
  description = "Map of VPC keys to their subnet regions"
  value = {
    for key, vpc in module.vpcs : key => vpc.subnet_regions
  }
}

# ============================================================================
# Cloud Router Outputs
# ============================================================================

output "cloud_router_ids" {
  description = "Map of Cloud Router keys to their IDs"
  value = {
    for key, router in module.cloud_routers : key => router.router_id
  }
}

output "cloud_router_names" {
  description = "Map of Cloud Router keys to their names"
  value = {
    for key, router in module.cloud_routers : key => router.router_name
  }
}

# ============================================================================
# Cloud NAT Outputs
# ============================================================================

output "cloud_nat_ids" {
  description = "Map of Cloud NAT keys to their IDs"
  value = {
    for key, nat in module.cloud_nats : key => nat.nat_id
  }
}

output "cloud_nat_names" {
  description = "Map of Cloud NAT keys to their names"
  value = {
    for key, nat in module.cloud_nats : key => nat.nat_name
  }
}

# ============================================================================
# Service Account Outputs
# ============================================================================

output "service_account_emails" {
  description = "Map of service account keys to their emails"
  value = {
    for key, sa in module.service_accounts : key => sa.service_account_email
  }
}

output "service_account_ids" {
  description = "Map of service account keys to their IDs"
  value = {
    for key, sa in module.service_accounts : key => sa.service_account_id
  }
}

# ============================================================================
# Summary Outputs
# ============================================================================

output "resource_summary" {
  description = "Summary of all resources created"
  value = {
    vpcs = {
      model_vpcs          = length([for k, v in local.model_vpcs : k])
      infrastructure_vpcs = length([for k, v in local.infrastructure_vpcs : k])
      total_vpcs          = length(local.all_vpcs)
    }
    subnets = {
      total_subnets = local.resource_counts.total_subnets
    }
    networking = {
      cloud_routers = length(module.cloud_routers)
      cloud_nats    = length(module.cloud_nats)
    }
    iam = {
      service_accounts = length(module.service_accounts)
    }
    projects = local.all_projects
  }
}

# ============================================================================
# Outputs for NCC Hub-Spoke Module Integration
# ============================================================================

output "vpc_details_for_ncc" {
  description = "VPC details formatted for NCC Hub-Spoke module consumption"
  value = {
    for key, vpc in local.all_vpcs : key => {
      vpc_name       = vpc.vpc_name
      project_id     = vpc.project_id
      vpc_id         = module.vpcs[key].vpc_id
      vpc_self_link  = module.vpcs[key].vpc_self_link
      regions        = distinct([for subnet in vpc.subnets : subnet.region])
    }
  }
}

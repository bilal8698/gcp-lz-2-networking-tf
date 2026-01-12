# CHANGELOG

All notable changes to the VPC Foundation module will be documented in this file.

## [1.0.0] - 2026-01-13

### Added
- Initial release of VPC Foundation module
- Created 8 VPCs per Carrier LLD v1.0:
  - 4 Model VPCs: M1P, M1NP, M3P, M3NP (shared-services project)
  - 4 Infrastructure VPCs: Transit, Security Data, Security Mgmt, Shared Services
- Implemented 48 subnets across 6 regions:
  - us-east4, us-central1, europe-west1, europe-west3, asia-east2, asia-southeast1
- Created Cloud Routers in all regions (ASN 16550 for Transit)
- Configured Cloud NAT for internet connectivity
- YAML-driven configuration following Vijay's pattern
- Flow logs enabled on all subnets
- Global routing mode for all VPCs
- Complete documentation and deployment guide

### Configuration
- Model VPCs: Reserved /16 pools for BlueCat IPAM subnet vending
- Infrastructure VPCs: /24 subnets per region
- Cloud Routers: Named `{region}-cr1`
- Cloud NAT: Named `{region}-{vpc_key}-cnat1`

### Modules
- `vpc/` - VPC and subnet creation
- `cloud-router/` - Cloud Router for BGP and NAT
- `cloud-nat/` - Cloud NAT configuration

### Documentation
- README.md - Complete module documentation
- Deployment guide with phase breakdown
- CIDR allocation tables
- Integration examples with NCC Hub-Spoke module

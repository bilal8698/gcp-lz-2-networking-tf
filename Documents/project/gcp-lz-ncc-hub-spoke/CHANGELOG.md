# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2026-01-08

### Added
- Initial implementation following Vijay's modular pattern
- NCC Hub module with YAML configuration
- VPC Spoke module for M1P, M1NP, M3P, M3NP
- Router Appliance spoke module for Transit VPC
- Complete YAML-driven configuration
- GCS outputs for downstream modules
- GitHub Actions CI/CD workflows
- Mandatory Carrier tags enforcement
- Lowercase naming conventions

### Architecture
- Module-based structure (inside: resources, outside: orchestration)
- YAML configuration files (no .tfvars)
- GCS backend for state storage
- Output sharing via GCS bucket

### Compliance
- ✅ Modular repository structure
- ✅ YAML-driven variablization
- ✅ No hard-coded values
- ✅ Mandatory tags enforced
- ✅ Lowercase naming
- ✅ Model 1/3/5 zoning support

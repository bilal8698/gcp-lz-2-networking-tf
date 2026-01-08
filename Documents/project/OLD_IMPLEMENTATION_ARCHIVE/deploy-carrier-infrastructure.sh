#!/bin/bash
################################################################################
# Carrier Infrastructure Deployment Script
# Date: January 6, 2026
# Purpose: Unified deployment script for Networking + Palo Alto Bootstrap
#
# Components:
# 1. Networking Infrastructure (NCC, VPCs, Subnets, Routers, HA-VPN)
# 2. Palo Alto VM-Series Firewalls & Bootstrap
# 3. Load Balancers (External & Internal)
# 4. Security & Compliance Checks
################################################################################

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NETWORKING_DIR="${SCRIPT_DIR}/gcp-lz-2-networking-tf"
BOOTSTRAP_DIR="${SCRIPT_DIR}/gcp-palo-alto-bootstrap"
LOG_DIR="${SCRIPT_DIR}/deployment-logs"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_FILE="${LOG_DIR}/deployment_${TIMESTAMP}.log"

# Create log directory
mkdir -p "${LOG_DIR}"

################################################################################
# Helper Functions
################################################################################

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "${LOG_FILE}"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a "${LOG_FILE}"
}

log_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1" | tee -a "${LOG_FILE}"
}

log_info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $1" | tee -a "${LOG_FILE}"
}

print_header() {
    echo ""
    echo "================================================================================" | tee -a "${LOG_FILE}"
    echo "  $1" | tee -a "${LOG_FILE}"
    echo "================================================================================" | tee -a "${LOG_FILE}"
    echo ""
}

print_section() {
    echo ""
    echo "────────────────────────────────────────────────────────────────────────────" | tee -a "${LOG_FILE}"
    echo "  $1" | tee -a "${LOG_FILE}"
    echo "────────────────────────────────────────────────────────────────────────────" | tee -a "${LOG_FILE}"
    echo ""
}

check_prerequisites() {
    print_section "Checking Prerequisites"
    
    local missing_tools=()
    
    # Check required tools
    if ! command -v terraform &> /dev/null; then
        missing_tools+=("terraform")
    fi
    
    if ! command -v gcloud &> /dev/null; then
        missing_tools+=("gcloud")
    fi
    
    if ! command -v git &> /dev/null; then
        missing_tools+=("git")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        exit 1
    fi
    
    log "✅ All required tools are installed"
    
    # Check Terraform version
    TERRAFORM_VERSION=$(terraform version -json | grep -o '"terraform_version":"[^"]*' | cut -d'"' -f4)
    log_info "Terraform version: ${TERRAFORM_VERSION}"
    
    # Check GCP authentication
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
        log_error "Not authenticated with GCP. Run: gcloud auth login"
        exit 1
    fi
    
    log "✅ GCP authentication verified"
}

################################################################################
# Networking Infrastructure Functions
################################################################################

validate_networking_config() {
    print_section "Validating Networking Configuration"
    
    cd "${NETWORKING_DIR}"
    
    # Check YAML configuration files
    log "Checking YAML configuration files..."
    
    local yaml_files=("data/shared-vpc-config.yaml" "data/ncc-config.yaml" "data/network-projects.yaml" "data/network-subnets.yaml")
    
    for yaml_file in "${yaml_files[@]}"; do
        if [ -f "${yaml_file}" ]; then
            log "✅ ${yaml_file}"
        else
            log_error "❌ Missing: ${yaml_file}"
            exit 1
        fi
    done
    
    # Check Terraform files
    log "Checking Terraform files..."
    
    local tf_files=(
        "main.tf" "variables.tf" "locals.tf" "outputs.tf" "backend.tf"
        "network-vpc.tf" "network-ncc.tf" "network-subnets-infrastructure.tf"
        "network-subnets-vending.tf" "network-cloud-routers.tf" "network-nat.tf"
        "network-ha-vpn.tf" "network-interconnect.tf" "network-nsi.tf"
        "network-projects.tf" "network-sa.tf"
    )
    
    for tf_file in "${tf_files[@]}"; do
        if [ -f "${tf_file}" ]; then
            log "✅ ${tf_file}"
        else
            log_warning "⚠️  Missing: ${tf_file}"
        fi
    done
    
    # Terraform format check
    log "Running Terraform format check..."
    if terraform fmt -check -recursive; then
        log "✅ Terraform format check passed"
    else
        log_warning "⚠️  Format issues found - auto-fixing..."
        terraform fmt -recursive
        log "✅ Format issues fixed"
    fi
    
    # Terraform validate
    log "Running Terraform validate..."
    terraform init -backend=false > /dev/null 2>&1
    if terraform validate; then
        log "✅ Terraform validation passed"
    else
        log_error "❌ Terraform validation failed"
        exit 1
    fi
}

check_mandatory_tags() {
    print_section "Verifying Mandatory Tags Compliance"
    
    cd "${NETWORKING_DIR}"
    
    log "Checking for mandatory Carrier tags..."
    
    local mandatory_tags=("cost_center" "owner" "application" "leanix_app_id")
    local tags_found=0
    
    for tag in "${mandatory_tags[@]}"; do
        if grep -r "\"${tag}\"" *.tf > /dev/null 2>&1; then
            log "✅ Tag '${tag}' found in configuration"
            ((tags_found++))
        else
            log_warning "⚠️  Tag '${tag}' not found - may need to be added"
        fi
    done
    
    if [ ${tags_found} -eq ${#mandatory_tags[@]} ]; then
        log "✅ All mandatory tags present"
    else
        log_warning "⚠️  Some mandatory tags missing - please verify"
    fi
}

deploy_networking() {
    print_section "Deploying Networking Infrastructure"
    
    cd "${NETWORKING_DIR}"
    
    log "Initializing Terraform..."
    if terraform init; then
        log "✅ Terraform initialized"
    else
        log_error "❌ Terraform initialization failed"
        exit 1
    fi
    
    log "Creating Terraform plan..."
    if terraform plan -out=networking.tfplan; then
        log "✅ Terraform plan created"
    else
        log_error "❌ Terraform plan failed"
        exit 1
    fi
    
    log_info "Terraform plan saved to: networking.tfplan"
    log_warning "Review the plan before applying!"
    
    # Ask for confirmation
    read -p "Do you want to apply the networking infrastructure? (yes/no): " -r
    echo
    if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        log "Applying Terraform changes..."
        if terraform apply networking.tfplan; then
            log "✅ Networking infrastructure deployed successfully"
        else
            log_error "❌ Terraform apply failed"
            exit 1
        fi
    else
        log_warning "Deployment skipped by user"
    fi
}

################################################################################
# Palo Alto Bootstrap Functions
################################################################################

validate_bootstrap_config() {
    print_section "Validating Palo Alto Bootstrap Configuration"
    
    cd "${BOOTSTRAP_DIR}"
    
    # Check bootstrap directory structure
    log "Checking bootstrap directory structure..."
    
    local regions=("region1" "region2" "region3")
    local firewalls=("fw01" "fw02")
    
    for region in "${regions[@]}"; do
        for firewall in "${firewalls[@]}"; do
            local fw_dir="bootstrap-files/${region}-${firewall}"
            if [ -d "${fw_dir}" ]; then
                log "✅ ${fw_dir}"
                
                # Check subdirectories
                for subdir in "config" "content" "software" "license"; do
                    if [ -d "${fw_dir}/${subdir}" ]; then
                        log "  ✅ ${subdir}/"
                    else
                        log_warning "  ⚠️  ${subdir}/ missing"
                    fi
                done
            else
                log_error "❌ Missing: ${fw_dir}"
            fi
        done
    done
    
    # Check Terraform configuration
    log "Checking Terraform configuration..."
    
    cd "${BOOTSTRAP_DIR}/terraform"
    
    local tf_files=("main.tf" "variables.tf" "firewalls.tf" "load-balancers.tf" "outputs.tf")
    
    for tf_file in "${tf_files[@]}"; do
        if [ -f "${tf_file}" ]; then
            log "✅ ${tf_file}"
        else
            log_error "❌ Missing: ${tf_file}"
            exit 1
        fi
    done
    
    # Check for terraform.tfvars
    if [ -f "terraform.tfvars" ]; then
        log "✅ terraform.tfvars configured"
    else
        if [ -f "terraform.tfvars.example" ]; then
            log_warning "⚠️  terraform.tfvars not found - please copy from terraform.tfvars.example"
        else
            log_error "❌ No terraform.tfvars or example found"
        fi
    fi
    
    # Terraform validate
    log "Running Terraform validate..."
    terraform init -backend=false > /dev/null 2>&1
    if terraform validate; then
        log "✅ Terraform validation passed"
    else
        log_error "❌ Terraform validation failed"
        exit 1
    fi
}

check_bootstrap_files() {
    print_section "Checking Bootstrap Files Completeness"
    
    cd "${BOOTSTRAP_DIR}"
    
    log "Checking init-cfg.txt files for placeholder values..."
    
    local placeholder_found=0
    
    while IFS= read -r -d '' init_cfg; do
        if grep -q "REPLACE_WITH" "${init_cfg}"; then
            log_warning "⚠️  Placeholder found in: ${init_cfg}"
            log_warning "     Please update license and VM auth key"
            ((placeholder_found++))
        else
            log "✅ ${init_cfg} configured"
        fi
    done < <(find bootstrap-files -name "init-cfg.txt" -print0)
    
    if [ ${placeholder_found} -gt 0 ]; then
        log_warning "⚠️  ${placeholder_found} init-cfg.txt files need configuration"
    else
        log "✅ All init-cfg.txt files configured"
    fi
}

deploy_bootstrap() {
    print_section "Deploying Palo Alto Bootstrap Infrastructure"
    
    cd "${BOOTSTRAP_DIR}/terraform"
    
    log "Initializing Terraform..."
    if terraform init; then
        log "✅ Terraform initialized"
    else
        log_error "❌ Terraform initialization failed"
        exit 1
    fi
    
    log "Creating Terraform plan..."
    if terraform plan -out=bootstrap.tfplan; then
        log "✅ Terraform plan created"
    else
        log_error "❌ Terraform plan failed"
        exit 1
    fi
    
    log_info "Terraform plan saved to: bootstrap.tfplan"
    log_warning "Review the plan before applying!"
    
    # Ask for confirmation
    read -p "Do you want to apply the Palo Alto bootstrap infrastructure? (yes/no): " -r
    echo
    if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        log "Applying Terraform changes..."
        if terraform apply bootstrap.tfplan; then
            log "✅ Palo Alto bootstrap infrastructure deployed successfully"
        else
            log_error "❌ Terraform apply failed"
            exit 1
        fi
    else
        log_warning "Deployment skipped by user"
    fi
}

################################################################################
# Security & Compliance Functions
################################################################################

run_security_checks() {
    print_section "Running Security & Compliance Checks"
    
    log "Checking for sensitive data in configuration files..."
    
    # Check for potential secrets
    local sensitive_patterns=("password" "secret" "api_key" "private_key" "auth_key")
    local issues_found=0
    
    for pattern in "${sensitive_patterns[@]}"; do
        if grep -r -i "${pattern}" "${NETWORKING_DIR}"/*.tf "${BOOTSTRAP_DIR}"/terraform/*.tf 2>/dev/null | grep -v "variable\|description\|#" > /dev/null; then
            log_warning "⚠️  Found potential sensitive data: ${pattern}"
            ((issues_found++))
        fi
    done
    
    if [ ${issues_found} -eq 0 ]; then
        log "✅ No obvious sensitive data found in configuration files"
    else
        log_warning "⚠️  Found ${issues_found} potential security issues - please review"
    fi
    
    # Check for .gitignore
    log "Checking .gitignore configuration..."
    
    if [ -f "${SCRIPT_DIR}/.gitignore" ]; then
        if grep -q "terraform.tfvars" "${SCRIPT_DIR}/.gitignore" && grep -q "*.tfstate" "${SCRIPT_DIR}/.gitignore"; then
            log "✅ .gitignore properly configured"
        else
            log_warning "⚠️  .gitignore may be missing important entries"
        fi
    else
        log_warning "⚠️  No .gitignore found in project root"
    fi
}

################################################################################
# Verification Functions
################################################################################

verify_deployment() {
    print_section "Post-Deployment Verification"
    
    log "Verifying GCP resources..."
    
    # Check if project ID is set
    PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
    
    if [ -z "${PROJECT_ID}" ]; then
        log_warning "⚠️  No GCP project selected"
        return
    fi
    
    log_info "Current GCP Project: ${PROJECT_ID}"
    
    # Check VPCs
    log "Checking VPCs..."
    VPC_COUNT=$(gcloud compute networks list --format="value(name)" 2>/dev/null | wc -l)
    log_info "Found ${VPC_COUNT} VPC(s)"
    
    # Check Cloud Routers
    log "Checking Cloud Routers..."
    ROUTER_COUNT=$(gcloud compute routers list --format="value(name)" 2>/dev/null | wc -l)
    log_info "Found ${ROUTER_COUNT} Cloud Router(s)"
    
    # Check VM instances (Palo Alto firewalls)
    log "Checking VM instances..."
    VM_COUNT=$(gcloud compute instances list --format="value(name)" 2>/dev/null | wc -l)
    log_info "Found ${VM_COUNT} VM instance(s)"
    
    # Check Load Balancers
    log "Checking Load Balancers..."
    LB_COUNT=$(gcloud compute forwarding-rules list --format="value(name)" 2>/dev/null | wc -l)
    log_info "Found ${LB_COUNT} Load Balancer forwarding rule(s)"
    
    # Check GCS buckets (bootstrap buckets)
    log "Checking GCS buckets..."
    BUCKET_COUNT=$(gsutil ls 2>/dev/null | wc -l)
    log_info "Found ${BUCKET_COUNT} GCS bucket(s)"
    
    log "✅ Verification complete"
}

################################################################################
# Main Deployment Flow
################################################################################

show_menu() {
    print_header "Carrier Infrastructure Deployment"
    
    echo "This script will deploy:"
    echo "  1. Networking Infrastructure (NCC, VPCs, Subnets, Routers, HA-VPN)"
    echo "  2. Palo Alto VM-Series Firewalls & Bootstrap"
    echo "  3. Load Balancers (External & Internal)"
    echo ""
    echo "Deployment Options:"
    echo "  [1] Full Deployment (Networking + Palo Alto)"
    echo "  [2] Networking Only"
    echo "  [3] Palo Alto Bootstrap Only"
    echo "  [4] Validation & Security Checks Only"
    echo "  [5] Post-Deployment Verification"
    echo "  [6] Exit"
    echo ""
    read -p "Select an option [1-6]: " -r choice
    echo
    
    return $choice
}

main() {
    log "Starting Carrier Infrastructure Deployment Script"
    log "Timestamp: ${TIMESTAMP}"
    log "Log file: ${LOG_FILE}"
    
    # Check prerequisites
    check_prerequisites
    
    # Show menu
    show_menu
    choice=$?
    
    case $choice in
        1)
            print_header "Full Deployment"
            
            # Networking
            validate_networking_config
            check_mandatory_tags
            
            # Palo Alto
            validate_bootstrap_config
            check_bootstrap_files
            
            # Security
            run_security_checks
            
            # Deploy
            log_warning "Ready to deploy full infrastructure"
            deploy_networking
            deploy_bootstrap
            
            # Verify
            verify_deployment
            
            log "✅ Full deployment completed"
            ;;
            
        2)
            print_header "Networking Deployment"
            validate_networking_config
            check_mandatory_tags
            run_security_checks
            deploy_networking
            verify_deployment
            log "✅ Networking deployment completed"
            ;;
            
        3)
            print_header "Palo Alto Bootstrap Deployment"
            validate_bootstrap_config
            check_bootstrap_files
            run_security_checks
            deploy_bootstrap
            verify_deployment
            log "✅ Palo Alto bootstrap deployment completed"
            ;;
            
        4)
            print_header "Validation & Security Checks"
            validate_networking_config
            check_mandatory_tags
            validate_bootstrap_config
            check_bootstrap_files
            run_security_checks
            log "✅ All checks completed"
            ;;
            
        5)
            print_header "Post-Deployment Verification"
            verify_deployment
            log "✅ Verification completed"
            ;;
            
        6)
            log "Exiting..."
            exit 0
            ;;
            
        *)
            log_error "Invalid option"
            exit 1
            ;;
    esac
    
    print_header "Deployment Summary"
    
    echo "Deployment completed successfully!" | tee -a "${LOG_FILE}"
    echo "" | tee -a "${LOG_FILE}"
    echo "Log file: ${LOG_FILE}" | tee -a "${LOG_FILE}"
    echo "" | tee -a "${LOG_FILE}"
    echo "Next Steps:" | tee -a "${LOG_FILE}"
    echo "  1. Review deployment logs" | tee -a "${LOG_FILE}"
    echo "  2. Verify resources in GCP Console" | tee -a "${LOG_FILE}"
    echo "  3. Test connectivity and routing" | tee -a "${LOG_FILE}"
    echo "  4. Configure Panorama/StrataCom integration" | tee -a "${LOG_FILE}"
    echo "  5. Enable monitoring and logging" | tee -a "${LOG_FILE}"
    echo "" | tee -a "${LOG_FILE}"
}

# Run main function
main "$@"

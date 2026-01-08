################################################################################
# Carrier Infrastructure Deployment Script (PowerShell)
# Date: January 6, 2026
# Purpose: Unified deployment script for Networking + Palo Alto Bootstrap
#
# Components:
# 1. Networking Infrastructure (NCC, VPCs, Subnets, Routers, HA-VPN)
# 2. Palo Alto VM-Series Firewalls & Bootstrap
# 3. Load Balancers (External & Internal)
# 4. Security & Compliance Checks
################################################################################

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Full", "Networking", "Bootstrap", "Validate", "Verify")]
    [string]$Mode = "Menu"
)

$ErrorActionPreference = "Stop"

# Configuration
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$NETWORKING_DIR = Join-Path $SCRIPT_DIR "gcp-lz-2-networking-tf"
$BOOTSTRAP_DIR = Join-Path $SCRIPT_DIR "gcp-palo-alto-bootstrap"
$LOG_DIR = Join-Path $SCRIPT_DIR "deployment-logs"
$TIMESTAMP = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$LOG_FILE = Join-Path $LOG_DIR "deployment_${TIMESTAMP}.log"

# Create log directory
if (-not (Test-Path $LOG_DIR)) {
    New-Item -ItemType Directory -Path $LOG_DIR | Out-Null
}

################################################################################
# Helper Functions
################################################################################

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Level: $Message"
    
    switch ($Level) {
        "ERROR"   { Write-Host $logMessage -ForegroundColor Red }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
        "INFO"    { Write-Host $logMessage -ForegroundColor Cyan }
        default   { Write-Host $logMessage }
    }
    
    Add-Content -Path $LOG_FILE -Value $logMessage
}

function Write-Header {
    param([string]$Title)
    
    $line = "=" * 80
    Write-Host ""
    Write-Host $line -ForegroundColor Blue
    Write-Host "  $Title" -ForegroundColor Blue
    Write-Host $line -ForegroundColor Blue
    Write-Host ""
    
    Add-Content -Path $LOG_FILE -Value ""
    Add-Content -Path $LOG_FILE -Value $line
    Add-Content -Path $LOG_FILE -Value "  $Title"
    Add-Content -Path $LOG_FILE -Value $line
    Add-Content -Path $LOG_FILE -Value ""
}

function Write-Section {
    param([string]$Title)
    
    $line = "-" * 80
    Write-Host ""
    Write-Host $line -ForegroundColor Gray
    Write-Host "  $Title" -ForegroundColor Gray
    Write-Host $line -ForegroundColor Gray
    Write-Host ""
    
    Add-Content -Path $LOG_FILE -Value ""
    Add-Content -Path $LOG_FILE -Value $line
    Add-Content -Path $LOG_FILE -Value "  $Title"
    Add-Content -Path $LOG_FILE -Value $line
    Add-Content -Path $LOG_FILE -Value ""
}

function Test-Prerequisites {
    Write-Section "Checking Prerequisites"
    
    $missingTools = @()
    
    # Check Terraform
    if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
        $missingTools += "terraform"
    }
    
    # Check gcloud
    if (-not (Get-Command gcloud -ErrorAction SilentlyContinue)) {
        $missingTools += "gcloud"
    }
    
    # Check git
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        $missingTools += "git"
    }
    
    if ($missingTools.Count -gt 0) {
        Write-Log "Missing required tools: $($missingTools -join ', ')" "ERROR"
        exit 1
    }
    
    Write-Log "All required tools are installed" "SUCCESS"
    
    # Check Terraform version
    $terraformVersion = (terraform version -json | ConvertFrom-Json).terraform_version
    Write-Log "Terraform version: $terraformVersion" "INFO"
    
    # Check GCP authentication
    try {
        $activeAccount = gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>&1
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrEmpty($activeAccount)) {
            Write-Log "Not authenticated with GCP. Run: gcloud auth login" "ERROR"
            exit 1
        }
        Write-Log "GCP authentication verified: $activeAccount" "SUCCESS"
    }
    catch {
        Write-Log "GCP authentication check failed" "ERROR"
        exit 1
    }
}

################################################################################
# Networking Infrastructure Functions
################################################################################

function Test-NetworkingConfig {
    Write-Section "Validating Networking Configuration"
    
    Push-Location $NETWORKING_DIR
    
    try {
        # Check YAML configuration files
        Write-Log "Checking YAML configuration files..." "INFO"
        
        $yamlFiles = @(
            "data\shared-vpc-config.yaml",
            "data\ncc-config.yaml",
            "data\network-projects.yaml",
            "data\network-subnets.yaml"
        )
        
        foreach ($yamlFile in $yamlFiles) {
            if (Test-Path $yamlFile) {
                Write-Log "✅ $yamlFile" "SUCCESS"
            }
            else {
                Write-Log "❌ Missing: $yamlFile" "ERROR"
                exit 1
            }
        }
        
        # Check Terraform files
        Write-Log "Checking Terraform files..." "INFO"
        
        $tfFiles = @(
            "main.tf", "variables.tf", "locals.tf", "outputs.tf", "backend.tf",
            "network-vpc.tf", "network-ncc.tf", "network-subnets-infrastructure.tf",
            "network-subnets-vending.tf", "network-cloud-routers.tf", "network-nat.tf",
            "network-ha-vpn.tf", "network-interconnect.tf", "network-nsi.tf",
            "network-projects.tf", "network-sa.tf"
        )
        
        foreach ($tfFile in $tfFiles) {
            if (Test-Path $tfFile) {
                Write-Log "✅ $tfFile" "SUCCESS"
            }
            else {
                Write-Log "⚠️  Missing: $tfFile" "WARNING"
            }
        }
        
        # Terraform format check
        Write-Log "Running Terraform format check..." "INFO"
        $fmtResult = terraform fmt -check -recursive 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Terraform format check passed" "SUCCESS"
        }
        else {
            Write-Log "Format issues found - auto-fixing..." "WARNING"
            terraform fmt -recursive | Out-Null
            Write-Log "Format issues fixed" "SUCCESS"
        }
        
        # Terraform validate
        Write-Log "Running Terraform validate..." "INFO"
        terraform init -backend=false | Out-Null
        $validateResult = terraform validate 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Terraform validation passed" "SUCCESS"
        }
        else {
            Write-Log "Terraform validation failed" "ERROR"
            Write-Log $validateResult "ERROR"
            exit 1
        }
    }
    finally {
        Pop-Location
    }
}

function Test-MandatoryTags {
    Write-Section "Verifying Mandatory Tags Compliance"
    
    Push-Location $NETWORKING_DIR
    
    try {
        Write-Log "Checking for mandatory Carrier tags..." "INFO"
        
        $mandatoryTags = @("cost_center", "owner", "application", "leanix_app_id")
        $tagsFound = 0
        
        foreach ($tag in $mandatoryTags) {
            $found = Select-String -Path "*.tf" -Pattern "`"$tag`"" -Quiet
            if ($found) {
                Write-Log "✅ Tag '$tag' found in configuration" "SUCCESS"
                $tagsFound++
            }
            else {
                Write-Log "⚠️  Tag '$tag' not found - may need to be added" "WARNING"
            }
        }
        
        if ($tagsFound -eq $mandatoryTags.Count) {
            Write-Log "All mandatory tags present" "SUCCESS"
        }
        else {
            Write-Log "Some mandatory tags missing - please verify" "WARNING"
        }
    }
    finally {
        Pop-Location
    }
}

function Deploy-Networking {
    Write-Section "Deploying Networking Infrastructure"
    
    Push-Location $NETWORKING_DIR
    
    try {
        Write-Log "Initializing Terraform..." "INFO"
        $initResult = terraform init 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Terraform initialized" "SUCCESS"
        }
        else {
            Write-Log "Terraform initialization failed" "ERROR"
            Write-Log $initResult "ERROR"
            exit 1
        }
        
        Write-Log "Creating Terraform plan..." "INFO"
        $planResult = terraform plan -out=networking.tfplan 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Terraform plan created" "SUCCESS"
        }
        else {
            Write-Log "Terraform plan failed" "ERROR"
            Write-Log $planResult "ERROR"
            exit 1
        }
        
        Write-Log "Terraform plan saved to: networking.tfplan" "INFO"
        Write-Log "Review the plan before applying!" "WARNING"
        
        # Ask for confirmation
        $response = Read-Host "Do you want to apply the networking infrastructure? (yes/no)"
        if ($response -eq "yes") {
            Write-Log "Applying Terraform changes..." "INFO"
            $applyResult = terraform apply networking.tfplan 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Networking infrastructure deployed successfully" "SUCCESS"
            }
            else {
                Write-Log "Terraform apply failed" "ERROR"
                Write-Log $applyResult "ERROR"
                exit 1
            }
        }
        else {
            Write-Log "Deployment skipped by user" "WARNING"
        }
    }
    finally {
        Pop-Location
    }
}

################################################################################
# Palo Alto Bootstrap Functions
################################################################################

function Test-BootstrapConfig {
    Write-Section "Validating Palo Alto Bootstrap Configuration"
    
    Push-Location $BOOTSTRAP_DIR
    
    try {
        # Check bootstrap directory structure
        Write-Log "Checking bootstrap directory structure..." "INFO"
        
        $regions = @("region1", "region2", "region3")
        $firewalls = @("fw01", "fw02")
        
        foreach ($region in $regions) {
            foreach ($firewall in $firewalls) {
                $fwDir = "bootstrap-files\${region}-${firewall}"
                if (Test-Path $fwDir) {
                    Write-Log "✅ $fwDir" "SUCCESS"
                    
                    # Check subdirectories
                    $subdirs = @("config", "content", "software", "license")
                    foreach ($subdir in $subdirs) {
                        $subdirPath = Join-Path $fwDir $subdir
                        if (Test-Path $subdirPath) {
                            Write-Log "  ✅ $subdir/" "SUCCESS"
                        }
                        else {
                            Write-Log "  ⚠️  $subdir/ missing" "WARNING"
                        }
                    }
                }
                else {
                    Write-Log "❌ Missing: $fwDir" "ERROR"
                }
            }
        }
        
        # Check Terraform configuration
        Write-Log "Checking Terraform configuration..." "INFO"
        
        Push-Location "terraform"
        
        $tfFiles = @("main.tf", "variables.tf", "firewalls.tf", "load-balancers.tf", "outputs.tf")
        
        foreach ($tfFile in $tfFiles) {
            if (Test-Path $tfFile) {
                Write-Log "✅ $tfFile" "SUCCESS"
            }
            else {
                Write-Log "❌ Missing: $tfFile" "ERROR"
                exit 1
            }
        }
        
        # Check for terraform.tfvars
        if (Test-Path "terraform.tfvars") {
            Write-Log "terraform.tfvars configured" "SUCCESS"
        }
        else {
            if (Test-Path "terraform.tfvars.example") {
                Write-Log "terraform.tfvars not found - please copy from terraform.tfvars.example" "WARNING"
            }
            else {
                Write-Log "No terraform.tfvars or example found" "ERROR"
            }
        }
        
        # Terraform validate
        Write-Log "Running Terraform validate..." "INFO"
        terraform init -backend=false | Out-Null
        $validateResult = terraform validate 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Terraform validation passed" "SUCCESS"
        }
        else {
            Write-Log "Terraform validation failed" "ERROR"
            exit 1
        }
        
        Pop-Location
    }
    finally {
        Pop-Location
    }
}

function Test-BootstrapFiles {
    Write-Section "Checking Bootstrap Files Completeness"
    
    Push-Location $BOOTSTRAP_DIR
    
    try {
        Write-Log "Checking init-cfg.txt files for placeholder values..." "INFO"
        
        $placeholderFound = 0
        $initCfgFiles = Get-ChildItem -Path "bootstrap-files" -Filter "init-cfg.txt" -Recurse
        
        foreach ($initCfg in $initCfgFiles) {
            $content = Get-Content $initCfg.FullName -Raw
            if ($content -match "REPLACE_WITH") {
                Write-Log "⚠️  Placeholder found in: $($initCfg.FullName)" "WARNING"
                Write-Log "     Please update license and VM auth key" "WARNING"
                $placeholderFound++
            }
            else {
                Write-Log "✅ $($initCfg.FullName) configured" "SUCCESS"
            }
        }
        
        if ($placeholderFound -gt 0) {
            Write-Log "$placeholderFound init-cfg.txt files need configuration" "WARNING"
        }
        else {
            Write-Log "All init-cfg.txt files configured" "SUCCESS"
        }
    }
    finally {
        Pop-Location
    }
}

function Deploy-Bootstrap {
    Write-Section "Deploying Palo Alto Bootstrap Infrastructure"
    
    $bootstrapTerraform = Join-Path $BOOTSTRAP_DIR "terraform"
    Push-Location $bootstrapTerraform
    
    try {
        Write-Log "Initializing Terraform..." "INFO"
        $initResult = terraform init 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Terraform initialized" "SUCCESS"
        }
        else {
            Write-Log "Terraform initialization failed" "ERROR"
            exit 1
        }
        
        Write-Log "Creating Terraform plan..." "INFO"
        $planResult = terraform plan -out=bootstrap.tfplan 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Terraform plan created" "SUCCESS"
        }
        else {
            Write-Log "Terraform plan failed" "ERROR"
            exit 1
        }
        
        Write-Log "Terraform plan saved to: bootstrap.tfplan" "INFO"
        Write-Log "Review the plan before applying!" "WARNING"
        
        # Ask for confirmation
        $response = Read-Host "Do you want to apply the Palo Alto bootstrap infrastructure? (yes/no)"
        if ($response -eq "yes") {
            Write-Log "Applying Terraform changes..." "INFO"
            $applyResult = terraform apply bootstrap.tfplan 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Palo Alto bootstrap infrastructure deployed successfully" "SUCCESS"
            }
            else {
                Write-Log "Terraform apply failed" "ERROR"
                exit 1
            }
        }
        else {
            Write-Log "Deployment skipped by user" "WARNING"
        }
    }
    finally {
        Pop-Location
    }
}

################################################################################
# Security & Compliance Functions
################################################################################

function Test-SecurityCompliance {
    Write-Section "Running Security & Compliance Checks"
    
    Write-Log "Checking for sensitive data in configuration files..." "INFO"
    
    # Check for potential secrets
    $sensitivePatterns = @("password", "secret", "api_key", "private_key", "auth_key")
    $issuesFound = 0
    
    foreach ($pattern in $sensitivePatterns) {
        $networkingMatches = Select-String -Path "$NETWORKING_DIR\*.tf" -Pattern $pattern -Exclude "variable*","#*" -ErrorAction SilentlyContinue
        $bootstrapMatches = Select-String -Path "$BOOTSTRAP_DIR\terraform\*.tf" -Pattern $pattern -Exclude "variable*","#*" -ErrorAction SilentlyContinue
        
        if ($networkingMatches -or $bootstrapMatches) {
            Write-Log "⚠️  Found potential sensitive data: $pattern" "WARNING"
            $issuesFound++
        }
    }
    
    if ($issuesFound -eq 0) {
        Write-Log "No obvious sensitive data found in configuration files" "SUCCESS"
    }
    else {
        Write-Log "Found $issuesFound potential security issues - please review" "WARNING"
    }
    
    # Check for .gitignore
    Write-Log "Checking .gitignore configuration..." "INFO"
    
    $gitignorePath = Join-Path $SCRIPT_DIR ".gitignore"
    if (Test-Path $gitignorePath) {
        $gitignoreContent = Get-Content $gitignorePath -Raw
        if ($gitignoreContent -match "terraform.tfvars" -and $gitignoreContent -match "\*.tfstate") {
            Write-Log ".gitignore properly configured" "SUCCESS"
        }
        else {
            Write-Log ".gitignore may be missing important entries" "WARNING"
        }
    }
    else {
        Write-Log "No .gitignore found in project root" "WARNING"
    }
}

################################################################################
# Verification Functions
################################################################################

function Test-Deployment {
    Write-Section "Post-Deployment Verification"
    
    Write-Log "Verifying GCP resources..." "INFO"
    
    # Check if project ID is set
    $projectId = gcloud config get-value project 2>&1
    
    if ([string]::IsNullOrEmpty($projectId)) {
        Write-Log "No GCP project selected" "WARNING"
        return
    }
    
    Write-Log "Current GCP Project: $projectId" "INFO"
    
    try {
        # Check VPCs
        Write-Log "Checking VPCs..." "INFO"
        $vpcCount = (gcloud compute networks list --format="value(name)" 2>&1 | Measure-Object).Count
        Write-Log "Found $vpcCount VPC(s)" "INFO"
        
        # Check Cloud Routers
        Write-Log "Checking Cloud Routers..." "INFO"
        $routerCount = (gcloud compute routers list --format="value(name)" 2>&1 | Measure-Object).Count
        Write-Log "Found $routerCount Cloud Router(s)" "INFO"
        
        # Check VM instances (Palo Alto firewalls)
        Write-Log "Checking VM instances..." "INFO"
        $vmCount = (gcloud compute instances list --format="value(name)" 2>&1 | Measure-Object).Count
        Write-Log "Found $vmCount VM instance(s)" "INFO"
        
        # Check Load Balancers
        Write-Log "Checking Load Balancers..." "INFO"
        $lbCount = (gcloud compute forwarding-rules list --format="value(name)" 2>&1 | Measure-Object).Count
        Write-Log "Found $lbCount Load Balancer forwarding rule(s)" "INFO"
        
        # Check GCS buckets
        Write-Log "Checking GCS buckets..." "INFO"
        $bucketCount = (gsutil ls 2>&1 | Measure-Object).Count
        Write-Log "Found $bucketCount GCS bucket(s)" "INFO"
        
        Write-Log "Verification complete" "SUCCESS"
    }
    catch {
        Write-Log "Error during verification: $_" "ERROR"
    }
}

################################################################################
# Main Menu
################################################################################

function Show-Menu {
    Write-Header "Carrier Infrastructure Deployment"
    
    Write-Host "This script will deploy:"
    Write-Host "  1. Networking Infrastructure (NCC, VPCs, Subnets, Routers, HA-VPN)"
    Write-Host "  2. Palo Alto VM-Series Firewalls & Bootstrap"
    Write-Host "  3. Load Balancers (External & Internal)"
    Write-Host ""
    Write-Host "Deployment Options:"
    Write-Host "  [1] Full Deployment (Networking + Palo Alto)"
    Write-Host "  [2] Networking Only"
    Write-Host "  [3] Palo Alto Bootstrap Only"
    Write-Host "  [4] Validation & Security Checks Only"
    Write-Host "  [5] Post-Deployment Verification"
    Write-Host "  [6] Exit"
    Write-Host ""
    
    $choice = Read-Host "Select an option [1-6]"
    return $choice
}

################################################################################
# Main Execution
################################################################################

Write-Log "Starting Carrier Infrastructure Deployment Script" "INFO"
Write-Log "Timestamp: $TIMESTAMP" "INFO"
Write-Log "Log file: $LOG_FILE" "INFO"

# Check prerequisites
Test-Prerequisites

# Determine execution mode
if ($Mode -eq "Menu") {
    $choice = Show-Menu
}
else {
    $choice = switch ($Mode) {
        "Full" { "1" }
        "Networking" { "2" }
        "Bootstrap" { "3" }
        "Validate" { "4" }
        "Verify" { "5" }
    }
}

switch ($choice) {
    "1" {
        Write-Header "Full Deployment"
        
        # Networking
        Test-NetworkingConfig
        Test-MandatoryTags
        
        # Palo Alto
        Test-BootstrapConfig
        Test-BootstrapFiles
        
        # Security
        Test-SecurityCompliance
        
        # Deploy
        Write-Log "Ready to deploy full infrastructure" "WARNING"
        Deploy-Networking
        Deploy-Bootstrap
        
        # Verify
        Test-Deployment
        
        Write-Log "Full deployment completed" "SUCCESS"
    }
    
    "2" {
        Write-Header "Networking Deployment"
        Test-NetworkingConfig
        Test-MandatoryTags
        Test-SecurityCompliance
        Deploy-Networking
        Test-Deployment
        Write-Log "Networking deployment completed" "SUCCESS"
    }
    
    "3" {
        Write-Header "Palo Alto Bootstrap Deployment"
        Test-BootstrapConfig
        Test-BootstrapFiles
        Test-SecurityCompliance
        Deploy-Bootstrap
        Test-Deployment
        Write-Log "Palo Alto bootstrap deployment completed" "SUCCESS"
    }
    
    "4" {
        Write-Header "Validation & Security Checks"
        Test-NetworkingConfig
        Test-MandatoryTags
        Test-BootstrapConfig
        Test-BootstrapFiles
        Test-SecurityCompliance
        Write-Log "All checks completed" "SUCCESS"
    }
    
    "5" {
        Write-Header "Post-Deployment Verification"
        Test-Deployment
        Write-Log "Verification completed" "SUCCESS"
    }
    
    "6" {
        Write-Log "Exiting..." "INFO"
        exit 0
    }
    
    default {
        Write-Log "Invalid option" "ERROR"
        exit 1
    }
}

# Summary
Write-Header "Deployment Summary"

Write-Host ""
Write-Host "Deployment completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Log file: $LOG_FILE"
Write-Host ""
Write-Host "Next Steps:"
Write-Host "  1. Review deployment logs"
Write-Host "  2. Verify resources in GCP Console"
Write-Host "  3. Test connectivity and routing"
Write-Host "  4. Configure Panorama/StrataCom integration"
Write-Host "  5. Enable monitoring and logging"
Write-Host ""

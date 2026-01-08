# Terraform Testing Script - PowerShell Version
# Date: January 3, 2026
# Tests all configurations before deployment

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   Terraform Configuration Testing" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Navigate to repository
Set-Location "c:\Users\HP\Documents\project\gcp-lz-2-networking-tf.worktrees\worktree-2026-01-03T12-07-55"

# Test 1: Check Terraform version
Write-Host "=== Test 1: Terraform Version ===" -ForegroundColor Yellow
terraform version
Write-Host ""

# Test 2: Format check
Write-Host "=== Test 2: Terraform Format Check ===" -ForegroundColor Yellow
$formatCheck = terraform fmt -check -recursive
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Format check passed" -ForegroundColor Green
} else {
    Write-Host "⚠️  Format issues found - running auto-fix" -ForegroundColor Yellow
    terraform fmt -recursive
}
Write-Host ""

# Test 3: Validate syntax
Write-Host "=== Test 3: Terraform Validate (Syntax) ===" -ForegroundColor Yellow
terraform validate
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Validation passed" -ForegroundColor Green
} else {
    Write-Host "❌ Validation failed" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Test 4: Check YAML files
Write-Host "=== Test 4: YAML Configuration Files ===" -ForegroundColor Yellow
$yamlFiles = @(
    "data/shared-vpc-config.yaml",
    "data/ncc-config.yaml",
    "data/network-projects.yaml",
    "data/network-subnets.yaml"
)

foreach ($file in $yamlFiles) {
    if (Test-Path $file) {
        Write-Host "✅ $file exists" -ForegroundColor Green
    } else {
        Write-Host "❌ $file missing" -ForegroundColor Red
    }
}
Write-Host ""

# Test 5: Check Terraform files
Write-Host "=== Test 5: Terraform Files Check ===" -ForegroundColor Yellow
$terraformFiles = @(
    "main.tf",
    "variables.tf",
    "locals.tf",
    "outputs.tf",
    "backend.tf",
    "network-vpc.tf",
    "network-ncc.tf",
    "network-subnets-infrastructure.tf",
    "network-cloud-routers.tf",
    "network-nat.tf",
    "network-ha-vpn.tf",
    "network-interconnect.tf"
)

foreach ($file in $terraformFiles) {
    if (Test-Path $file) {
        Write-Host "✅ $file exists" -ForegroundColor Green
    } else {
        Write-Host "❌ $file missing" -ForegroundColor Red
    }
}
Write-Host ""

# Test 6: Initialize Terraform (dry run)
Write-Host "=== Test 6: Terraform Init (without backend) ===" -ForegroundColor Yellow
Write-Host "Note: This is a dry run without actual GCS backend connection" -ForegroundColor Cyan
terraform init -backend=false
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Init successful" -ForegroundColor Green
} else {
    Write-Host "❌ Init failed" -ForegroundColor Red
}
Write-Host ""

# Test 7: Plan (dry run)
Write-Host "=== Test 7: Terraform Plan (dry run) ===" -ForegroundColor Yellow
Write-Host "Note: This will show what would be created" -ForegroundColor Cyan
terraform plan -out=test.tfplan
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Plan successful" -ForegroundColor Green
} else {
    Write-Host "❌ Plan failed" -ForegroundColor Red
}
Write-Host ""

# Summary
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   Testing Complete" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Review the output above for any errors." -ForegroundColor Yellow
Write-Host "If all tests passed, the code is ready for deployment." -ForegroundColor Green
Write-Host ""

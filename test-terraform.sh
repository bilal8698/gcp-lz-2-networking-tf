#!/bin/bash
# Terraform Testing Script
# Date: January 3, 2026
# Tests all configurations before deployment

echo "============================================"
echo "   Terraform Configuration Testing"
echo "============================================"
echo ""

# Navigate to repository
cd "c:\Users\HP\Documents\project\gcp-lz-2-networking-tf.worktrees\worktree-2026-01-03T12-07-55"

# Test 1: Check Terraform version
echo "=== Test 1: Terraform Version ==="
terraform version
echo ""

# Test 2: Format check
echo "=== Test 2: Terraform Format Check ==="
terraform fmt -check -recursive
if [ $? -eq 0 ]; then
    echo "✅ Format check passed"
else
    echo "⚠️  Format issues found - running auto-fix"
    terraform fmt -recursive
fi
echo ""

# Test 3: Validate syntax
echo "=== Test 3: Terraform Validate (Syntax) ==="
terraform validate
if [ $? -eq 0 ]; then
    echo "✅ Validation passed"
else
    echo "❌ Validation failed"
    exit 1
fi
echo ""

# Test 4: Check YAML files
echo "=== Test 4: YAML Configuration Files ==="
if [ -f "data/shared-vpc-config.yaml" ]; then
    echo "✅ shared-vpc-config.yaml exists"
else
    echo "❌ shared-vpc-config.yaml missing"
fi

if [ -f "data/ncc-config.yaml" ]; then
    echo "✅ ncc-config.yaml exists"
else
    echo "❌ ncc-config.yaml missing"
fi

if [ -f "data/network-projects.yaml" ]; then
    echo "✅ network-projects.yaml exists"
else
    echo "❌ network-projects.yaml missing"
fi

if [ -f "data/network-subnets.yaml" ]; then
    echo "✅ network-subnets.yaml exists"
else
    echo "❌ network-subnets.yaml missing"
fi
echo ""

# Test 5: Check Terraform files
echo "=== Test 5: Terraform Files Check ==="
terraform_files=(
    "main.tf"
    "variables.tf"
    "locals.tf"
    "outputs.tf"
    "backend.tf"
    "network-vpc.tf"
    "network-ncc.tf"
    "network-subnets-infrastructure.tf"
    "network-cloud-routers.tf"
    "network-nat.tf"
    "network-ha-vpn.tf"
    "network-interconnect.tf"
)

for file in "${terraform_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file exists"
    else
        echo "❌ $file missing"
    fi
done
echo ""

# Test 6: Initialize Terraform (dry run)
echo "=== Test 6: Terraform Init (without backend) ==="
echo "Note: This is a dry run without actual GCS backend connection"
terraform init -backend=false
if [ $? -eq 0 ]; then
    echo "✅ Init successful"
else
    echo "❌ Init failed"
fi
echo ""

# Test 7: Plan (dry run)
echo "=== Test 7: Terraform Plan (dry run) ==="
echo "Note: This will show what would be created"
terraform plan -out=test.tfplan
if [ $? -eq 0 ]; then
    echo "✅ Plan successful"
else
    echo "❌ Plan failed"
fi
echo ""

# Summary
echo "============================================"
echo "   Testing Complete"
echo "============================================"
echo ""
echo "Review the output above for any errors."
echo "If all tests passed, the code is ready for deployment."
echo ""

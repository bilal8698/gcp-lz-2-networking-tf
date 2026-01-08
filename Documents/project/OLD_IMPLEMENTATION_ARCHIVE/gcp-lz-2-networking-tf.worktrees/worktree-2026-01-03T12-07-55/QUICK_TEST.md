# Quick Terraform Test Commands
# Copy and paste these commands in your terminal

# Navigate to repository
cd c:\Users\HP\Documents\project\gcp-lz-2-networking-tf.worktrees\worktree-2026-01-03T12-07-55

# Test 1: Check Terraform is installed
terraform version

# Test 2: Format check
terraform fmt -check -recursive

# Test 3: Validate configuration (syntax check)
terraform validate

# Test 4: Initialize (without backend for testing)
terraform init -backend=false

# Test 5: Plan (see what will be created)
terraform plan

# If all tests pass, you're ready to deploy!

# Quick Validation Test
# Run this before the Carrier meeting to ensure everything is ready

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  CARRIER MEETING - PRE-FLIGHT CHECK" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$allGood = $true

# Check 1: Main scripts exist
Write-Host "Checking deployment scripts..." -ForegroundColor Yellow
$scripts = @(
    "deploy-carrier-infrastructure.ps1",
    "deploy-carrier-infrastructure.sh"
)

foreach ($script in $scripts) {
    if (Test-Path $script) {
        Write-Host "  ✅ $script" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $script MISSING" -ForegroundColor Red
        $allGood = $false
    }
}

# Check 2: Documentation exists
Write-Host "`nChecking documentation..." -ForegroundColor Yellow
$docs = @(
    "README.md",
    "UNIFIED_DEPLOYMENT_GUIDE.md",
    "CARRIER_MEETING_QUICK_REF.md",
    "ARCHITECTURE_VISUAL_DIAGRAMS.md",
    "MANAGER_SUMMARY.md"
)

foreach ($doc in $docs) {
    if (Test-Path $doc) {
        Write-Host "  ✅ $doc" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $doc MISSING" -ForegroundColor Red
        $allGood = $false
    }
}

# Check 3: Infrastructure directories exist
Write-Host "`nChecking infrastructure directories..." -ForegroundColor Yellow
$dirs = @(
    "gcp-lz-2-networking-tf",
    "gcp-palo-alto-bootstrap"
)

foreach ($dir in $dirs) {
    if (Test-Path $dir) {
        Write-Host "  ✅ $dir/" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $dir/ MISSING" -ForegroundColor Red
        $allGood = $false
    }
}

# Check 4: Required tools
Write-Host "`nChecking required tools..." -ForegroundColor Yellow

if (Get-Command terraform -ErrorAction SilentlyContinue) {
    $tfVersion = (terraform version -json | ConvertFrom-Json).terraform_version
    Write-Host "  ✅ Terraform ($tfVersion)" -ForegroundColor Green
} else {
    Write-Host "  ❌ Terraform NOT INSTALLED" -ForegroundColor Red
    $allGood = $false
}

if (Get-Command gcloud -ErrorAction SilentlyContinue) {
    Write-Host "  ✅ gcloud CLI" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  gcloud CLI not found (optional for demo)" -ForegroundColor Yellow
}

if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Host "  ✅ Git" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Git not found (optional for demo)" -ForegroundColor Yellow
}

# Check 5: Configuration files
Write-Host "`nChecking configuration files..." -ForegroundColor Yellow
$configs = @(
    "gcp-lz-2-networking-tf\data\shared-vpc-config.yaml",
    "gcp-lz-2-networking-tf\data\ncc-config.yaml",
    "gcp-lz-2-networking-tf\data\network-projects.yaml",
    "gcp-lz-2-networking-tf\data\network-subnets.yaml"
)

foreach ($config in $configs) {
    if (Test-Path $config) {
        Write-Host "  ✅ $config" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  $config not found" -ForegroundColor Yellow
    }
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
if ($allGood) {
    Write-Host "  ✅ ALL CHECKS PASSED" -ForegroundColor Green
    Write-Host "  Ready for Carrier Meeting!" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  SOME ISSUES FOUND" -ForegroundColor Yellow
    Write-Host "  Review errors above" -ForegroundColor Yellow
}
Write-Host "========================================`n" -ForegroundColor Cyan

# Next steps
Write-Host "NEXT STEPS FOR MEETING:" -ForegroundColor Cyan
Write-Host "  1. Review: CARRIER_MEETING_QUICK_REF.md"
Write-Host "  2. Run demo: .\deploy-carrier-infrastructure.ps1 -Mode Validate"
Write-Host "  3. Have ready: ARCHITECTURE_VISUAL_DIAGRAMS.md"
Write-Host ""

# File summary
Write-Host "FILE SUMMARY:" -ForegroundColor Cyan
Write-Host "  - Deployment Scripts: 2 files (PowerShell + Bash)"
Write-Host "  - Documentation: 5 comprehensive guides"
Write-Host "  - Infrastructure: Networking + Palo Alto configs"
Write-Host "  - Total: Complete integrated solution"
Write-Host ""

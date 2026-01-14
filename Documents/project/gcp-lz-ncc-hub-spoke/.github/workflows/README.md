# GitHub Actions Workflows - NCC Hub & Spoke

This directory contains automated CI/CD workflows for the NCC (Network Connectivity Center) Hub and Spoke infrastructure.

## 📋 Available Workflows

### 1. **validation.yaml** - Code Quality & Security Checks
- **Trigger:** Pull requests and pushes to main/develop
- **Purpose:** Validates Terraform code quality before merging
- **Checks:**
  - Terraform formatting (`terraform fmt`)
  - Linting with TFLint
  - Terraform syntax validation
  - YAML configuration validation
  - Sensitive data detection
  - TODO/FIXME comment detection

### 2. **terraform-plan.yaml** - Infrastructure Planning
- **Trigger:** Pull requests to main/develop, manual dispatch
- **Purpose:** Shows what changes will be made to infrastructure
- **Features:**
  - Security scanning with Checkov
  - Generates detailed plan output
  - Comments plan on PR
  - Saves plan as artifact for 30 days
  - Manual control over transit spoke deployment

### 3. **terraform-apply.yaml** - Infrastructure Deployment
- **Trigger:** Push to main branch, manual dispatch
- **Purpose:** Applies infrastructure changes to GCP
- **Features:**
  - Requires production environment approval
  - Pre-apply plan generation
  - Captures and uploads outputs to GCS
  - Creates deployment summary
  - Artifact retention for 90 days

### 4. **terraform-destroy.yaml** - Infrastructure Teardown
- **Trigger:** Manual dispatch only
- **Purpose:** Safely destroys infrastructure
- **Safety Features:**
  - Requires typing "destroy" to confirm
  - Creates state backup before destruction
  - Supports targeted resource destruction
  - Uploads state backup (90-day retention)

## 🔐 Required GitHub Secrets

Set these in your repository settings (Settings → Secrets and variables → Actions):

| Secret Name | Description | Example |
|------------|-------------|---------|
| `GCP_CREDENTIALS` | GCP service account JSON key | `{"type": "service_account", ...}` |
| `OUTPUTS_BUCKET` | GCS bucket for Terraform outputs | `carrier-terraform-outputs` |

## 🚀 Usage Guide

### Running Validation
Validation runs automatically on every push and PR. To manually validate:
```bash
# Locally
terraform fmt -recursive -check
terraform validate
tflint --recursive
```

### Creating Infrastructure Plan
1. Create a feature branch
2. Make your changes
3. Push to GitHub
4. Open a PR to `main` or `develop`
5. Plan will run automatically and comment results

### Deploying Infrastructure
**Option 1: Automatic (Recommended)**
1. Merge PR to `main` branch
2. Apply workflow runs automatically

**Option 2: Manual**
1. Go to Actions → Terraform Apply
2. Click "Run workflow"
3. Select branch (usually `main`)
4. Choose transit spoke option
5. Click "Run workflow"

### Destroying Infrastructure
⚠️ **Use with extreme caution!**

1. Go to Actions → Terraform Destroy
2. Click "Run workflow"
3. Type `destroy` in confirmation field
4. (Optional) Specify target resources
5. Click "Run workflow"

## 🎯 Workflow Behavior

### Development Flow
```
feature branch → PR → validation + plan → review → merge → apply
```

### Transit Spoke Control
The `deploy_transit_spoke` variable controls whether the Transit Router Appliance spoke is deployed:
- **Default:** `false` (Transit spoke not deployed)
- **Set to `true`:** Only after Palo Alto firewalls are deployed and configured

## 📊 Monitoring and Artifacts

### Artifacts Generated
| Workflow | Artifact | Retention | Description |
|----------|----------|-----------|-------------|
| Plan | `terraform-plan-{sha}` | 30 days | Plan file and output |
| Apply | `terraform-outputs-{sha}` | 90 days | Infrastructure outputs |
| Apply | `pre-apply-plan-{sha}` | 30 days | Plan before apply |
| Destroy | `state-backup-{sha}` | 90 days | State before destroy |

### Output Storage
Terraform outputs are automatically uploaded to GCS:
- **Path:** `gs://{OUTPUTS_BUCKET}/ncc-hub-spoke/`
- **Files:**
  - `outputs-{sha}.json` - Version-specific outputs
  - `outputs-latest.json` - Latest outputs

## 🔧 Configuration Variables

### Workflow Environment Variables
```yaml
TF_VERSION: '1.5.0'        # Terraform version
WORKING_DIR: 'terraform'    # Terraform code directory
```

### Terraform Variables
```hcl
outputs_bucket        # GCS bucket for outputs
deploy_transit_spoke  # Deploy transit spoke (true/false)
project_id           # GCP project ID (from YAML config)
region               # GCP region (from YAML config)
```

## 📝 Best Practices

1. **Always review plans** before approving applies
2. **Use feature branches** for development
3. **Enable branch protection** on `main` with required status checks
4. **Set up production environment protection** rules
5. **Monitor workflow runs** in the Actions tab
6. **Check GCS outputs** after successful applies
7. **Backup state** before manual destroy operations

## 🛡️ Security Considerations

- GCP credentials stored as GitHub secrets (encrypted)
- Production environment requires manual approval
- Destroy operation requires explicit confirmation
- State backups created before destructive operations
- Sensitive data detection in validation workflow
- Security scanning with Checkov

## 🐛 Troubleshooting

### Plan Fails
1. Check Terraform formatting: `terraform fmt -recursive`
2. Validate syntax: `terraform validate`
3. Review TFLint output
4. Check GCP credentials

### Apply Fails
1. Review pre-apply plan
2. Check GCP permissions
3. Verify state file access
4. Check resource quotas

### Authentication Issues
1. Verify `GCP_CREDENTIALS` secret is set correctly
2. Check service account permissions
3. Ensure service account has required IAM roles

## 📚 Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GCP Network Connectivity Center](https://cloud.google.com/network-connectivity/docs/network-connectivity-center)
- [TFLint Rules](https://github.com/terraform-linters/tflint)
- [Checkov Policies](https://www.checkov.io/5.Policy%20Index/terraform.html)

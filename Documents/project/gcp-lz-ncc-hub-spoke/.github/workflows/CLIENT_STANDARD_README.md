# GitHub Actions Workflows - NCC Hub & Spoke (Client Standard)

This directory contains CI/CD workflows following the client's automation standards for the NCC (Network Connectivity Center) Hub and Spoke infrastructure.

## 📋 Workflow Architecture

This implementation follows the **Google Cloud Foundation Fabric** pattern with reusable workflows and Workload Identity Federation.

### Workflow Structure
```
pull-requests.yaml (CI) → tf-plan.yml → Plan & Comment on PR
merge.yaml (CD) → tf-plan.yml → Plan → tf-apply.yml → Deploy
```

## 🔄 Available Workflows

### 1. **pull-requests.yaml** - Continuous Integration (CI)
- **Trigger:** Pull requests to `main` branch
- **Purpose:** Validate and plan infrastructure changes
- **Actions:**
  - Calls reusable `tf-plan.yml` workflow
  - Runs plan without applying changes
  - Comments plan output on PR for review

### 2. **merge.yaml** - Continuous Deployment (CD)
- **Trigger:** Push to `main` branch (after PR merge)
- **Purpose:** Deploy infrastructure changes to GCP
- **Actions:**
  - Runs plan job first (validation)
  - Runs apply job (requires plan success)
  - Uploads outputs to GCS
  - Creates deployment artifacts

### 3. **tf-plan.yml** - Reusable Plan Workflow
- **Type:** Reusable workflow (called by CI/CD)
- **Purpose:** Standardized Terraform planning
- **Features:**
  - Workload Identity Federation authentication
  - Downloads provider config from GCS
  - Downloads dependency outputs from GCS
  - Runs terraform fmt, init, validate, plan
  - Comments plan results on PR

### 4. **tf-apply.yml** - Reusable Apply Workflow
- **Type:** Reusable workflow (called by CD)
- **Purpose:** Standardized Terraform deployment
- **Features:**
  - Workload Identity Federation authentication
  - Downloads dependencies and providers
  - Applies infrastructure changes
  - Uploads outputs to GCS (versioned + latest)
  - Creates deployment summary

## 🔐 Required GitHub Secrets

Configure these in repository settings (Settings → Secrets and variables → Actions):

### Core Secrets (Required)
| Secret Name | Description | Example |
|------------|-------------|---------|
| `WIF_PROVIDER` | Workload Identity Federation Provider | `projects/123.../providers/gh-provider` |
| `SERVICE_ACCOUNT` | Service Account Email for deployment | `cicd-sa@project.iam.gserviceaccount.com` |
| `OUTPUTS_BUCKET` | GCS bucket for outputs storage | `carrier-terraform-outputs` |

### Organization Secrets (Optional)
| Secret Name | Description | Required For |
|------------|-------------|--------------|
| `ORGANIZATION_ID` | GCP Organization ID | Multi-org deployments |
| `ORGANIZATION_DOMAIN` | Organization domain | Domain-based configs |
| `CUSTOMER_ID` | Google Workspace Customer ID | Workspace integration |
| `BILLING_ACCOUNT_ID` | GCP Billing Account ID | New project creation |
| `REPOSITORY_ORGANIZATION` | GitHub org name | Multi-repo setups |

## 🚀 Usage Guide

### For Developers

#### Making Infrastructure Changes
1. Create feature branch:
   ```bash
   git checkout -b feature/add-vpc-spoke
   ```

2. Make your Terraform changes in `terraform/` directory

3. Push and create PR:
   ```bash
   git push origin feature/add-vpc-spoke
   ```

4. **CI workflow runs automatically:**
   - Authenticates using WIF
   - Downloads dependencies from GCS
   - Runs Terraform plan
   - Comments plan on PR

5. Review plan output in PR comments

6. Get approval and merge to `main`

7. **CD workflow runs automatically:**
   - Runs plan again for verification
   - Applies changes to infrastructure
   - Uploads outputs to GCS

### Workflow Execution Flow

#### Pull Request Flow (CI)
```
Developer creates PR
    ↓
pull-requests.yaml triggers
    ↓
Calls tf-plan.yml with stage='ncc-hub-spoke'
    ↓
Authenticates with WIF
    ↓
Downloads providers & outputs from GCS
    ↓
Runs terraform plan
    ↓
Comments plan on PR
    ↓
Team reviews & approves
```

#### Merge Flow (CD)
```
PR merged to main
    ↓
merge.yaml triggers
    ↓
Job 1: Plan (validation)
    ↓
Job 2: Apply (if plan succeeds)
    ↓
Terraform apply runs
    ↓
Outputs uploaded to GCS
    ↓
Artifacts saved
    ↓
Deployment complete
```

## 🏗️ Infrastructure Dependencies

### Input Dependencies
The workflows automatically download these from GCS if available:
- `vpc-foundation-outputs.json` - VPC network information
- `palo-alto-outputs.json` - Firewall appliance details

### Output Artifacts
Uploaded to GCS bucket after successful apply:
- `gs://{OUTPUTS_BUCKET}/outputs/ncc-hub-spoke-outputs.json` (latest)
- `gs://{OUTPUTS_BUCKET}/outputs/ncc-hub-spoke-outputs-{sha}.json` (versioned)
- `gs://{OUTPUTS_BUCKET}/providers/ncc-hub-spoke-providers.tf` (provider config)

## 🔧 Configuration Details

### Stage Configuration
- **Stage Name:** `ncc-hub-spoke`
- **Working Directory:** `terraform/`
- **Terraform Version:** `>= 1.5`

### Environment Variables
```yaml
TF_IN_AUTOMATION: true       # Enables automation-friendly output
TF_CLI_ARGS: '-no-color'     # Disables colored output for logs
```

### Permissions
```yaml
permissions:
  contents: read              # Read repository content
  id-token: write            # Required for WIF authentication
  pull-requests: write       # Comment on PRs
```

## 🛡️ Security Features

### Workload Identity Federation (WIF)
- **No service account keys stored** - Uses WIF for secure authentication
- Short-lived tokens generated per workflow run
- Follows Google Cloud security best practices

### Least Privilege Access
- Service account has minimal required permissions
- Production environment protection enabled
- Read-only access for plan operations

### Audit Trail
- All deployments tracked in GitHub Actions history
- GCS outputs versioned by commit SHA
- Plan artifacts retained for review

## 📊 Monitoring & Artifacts

### GitHub Actions Artifacts
| Workflow | Artifact | Retention | Description |
|----------|----------|-----------|-------------|
| Apply | `ncc-hub-spoke-outputs-{sha}` | 90 days | Terraform outputs JSON |

### GCS Storage Structure
```
gs://{OUTPUTS_BUCKET}/
├── outputs/
│   ├── ncc-hub-spoke-outputs.json          # Latest
│   ├── ncc-hub-spoke-outputs-{sha}.json    # Versioned
│   ├── vpc-foundation-outputs.json         # Dependency
│   └── palo-alto-outputs.json              # Dependency
└── providers/
    └── ncc-hub-spoke-providers.tf          # Provider config
```

## 🔍 Troubleshooting

### Common Issues

#### 1. Authentication Failures
**Error:** "Failed to authenticate to Google Cloud"
**Solution:**
- Verify `WIF_PROVIDER` secret is correct
- Check service account email in `SERVICE_ACCOUNT` secret
- Ensure WIF pool and provider exist in GCP
- Verify GitHub repository is registered in WIF pool

#### 2. Missing Dependencies
**Error:** "Failed to download output dependencies"
**Solution:**
- Check that prerequisite stages are deployed
- Verify `OUTPUTS_BUCKET` secret is correct
- Ensure service account has Storage Object Viewer role

#### 3. Plan/Apply Failures
**Error:** "Terraform plan/apply failed"
**Solution:**
- Review Terraform error in workflow logs
- Check GCP resource quotas
- Verify service account IAM permissions
- Ensure backend state bucket exists

#### 4. Provider Configuration Missing
**Error:** "Error configuring provider"
**Solution:**
- Workflows download provider config from GCS
- If first run, provider config will be uploaded after first apply
- Ensure `providers.tf` exists in `terraform/` directory

### Debugging Steps

1. **Check workflow logs in GitHub Actions tab**
2. **Verify all secrets are configured:**
   ```bash
   # Required secrets
   WIF_PROVIDER, SERVICE_ACCOUNT, OUTPUTS_BUCKET
   ```
3. **Test WIF authentication manually:**
   ```bash
   gcloud auth login --brief --cred-file=<wif-token>
   ```
4. **Verify GCS bucket access:**
   ```bash
   gcloud storage ls gs://{OUTPUTS_BUCKET}/
   ```

## 📝 Best Practices

### Development Workflow
1. ✅ Always create feature branches
2. ✅ Review plan output in PR before merging
3. ✅ Keep PRs focused and small
4. ✅ Update documentation with infrastructure changes
5. ✅ Tag releases after major deployments

### Branch Protection
Configure on `main` branch:
- ✅ Require pull request reviews
- ✅ Require status checks to pass (CI plan)
- ✅ Require branches to be up to date
- ✅ Require conversation resolution

### Secret Management
- ✅ Use WIF instead of service account keys
- ✅ Rotate secrets periodically
- ✅ Use GitHub Environments for production
- ✅ Limit secret access to necessary workflows

## 🆚 Differences from Previous Implementation

### Previous (Old) Workflows
- ❌ Service account JSON key authentication
- ❌ Direct GCP credentials in secrets
- ❌ Separate plan/apply workflows
- ❌ Manual secret management

### Current (Client Standard) Workflows
- ✅ Workload Identity Federation
- ✅ Reusable workflow pattern
- ✅ Automated dependency management
- ✅ Standardized across all stages
- ✅ Better security posture
- ✅ Follows Google Cloud best practices

## 🔗 Related Documentation

- [Workload Identity Federation Setup](https://cloud.google.com/iam/docs/workload-identity-federation)
- [GitHub Actions Reusable Workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows)
- [Terraform in Automation](https://www.terraform.io/docs/cloud/guides/recommended-practices/part1.html)
- [Google Cloud Foundation Fabric](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric)

## 📞 Support

For issues or questions:
1. Check workflow logs in Actions tab
2. Review this documentation
3. Check GCP IAM permissions
4. Contact DevOps team

---

**Last Updated:** January 14, 2026  
**Compliance:** Google Cloud Foundation Fabric Pattern  
**Security:** Workload Identity Federation Enabled

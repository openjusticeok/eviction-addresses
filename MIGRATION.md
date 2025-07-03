# Migration Guide: googleCloudRunner to OpenTofu + GitHub Actions

This document outlines the migration from the previous googleCloudRunner-based infrastructure to modern OpenTofu and GitHub Actions.

## Overview

The migration replaces:
- R-based infrastructure definition (googleCloudRunner) → OpenTofu infrastructure-as-code
- Manual Cloud Build triggers → GitHub Actions CI/CD pipelines
- Programmatic deployments → Declarative infrastructure management

## What Changed

### Infrastructure Management

**Before:**
- Infrastructure defined in R scripts (`inst/cloudbuild/build.R`, `inst/cloudbuild/build_test.R`)
- Cloud Build triggers created programmatically
- Manual execution of R scripts for deployment

**After:**
- Infrastructure defined in OpenTofu (`infrastructure/` directory)
- GitHub Actions for automated CI/CD
- Declarative infrastructure with version control

### Deployment Process

**Before:**
```r
# Run R script to deploy
source("inst/cloudbuild/build.R")
```

**After:**
```bash
# Push to main/test branch triggers automatic deployment
git push origin main   # deploys to production
git push origin test   # deploys to test environment

# Or manually run infrastructure changes
cd infrastructure/environments/production
tofu init
tofu plan
tofu apply
```

### Secrets Management

**Before:**
- Secrets hardcoded in R scripts
- Manual secret creation

**After:**
- Secrets managed through Secret Manager
- Proper IAM roles and permissions
- Environment-specific secret naming

## Directory Structure

```
├── infrastructure/
│   ├── environments/
│   │   ├── production/     # Production environment config
│   │   └── test/          # Test environment config
│   └── modules/
│       └── eviction-addresses-services/  # Reusable module
├── dockerfiles/           # Improved multi-stage Dockerfiles
│   ├── Dockerfile.api
│   ├── Dockerfile.dashboard
│   └── Dockerfile.job
├── .github/workflows/     # GitHub Actions workflows
│   ├── deploy.yml         # Main CI/CD pipeline
│   ├── infrastructure.yml # Infrastructure management
│   └── R-CMD-check.yaml   # R package testing
└── inst/cloudbuild/       # Legacy (to be removed)
```

## Migration Steps

### 1. Set up Terraform State Bucket (One-time setup)

```bash
# Create bucket for Terraform state (if not exists)
gsutil mb gs://ojo-database-terraform-state
```

### 2. Set up GitHub Secrets

In your GitHub repository settings, add:
- `GCP_SA_KEY`: Service account key with permissions for:
  - Cloud Run Admin
  - Secret Manager Admin  
  - Storage Admin
  - Service Account User

### 3. Deploy Test Environment

```bash
cd infrastructure/environments/test
tofu init
tofu plan -var="service_image_tag=test"
tofu apply
```

### 4. Deploy Production Environment

```bash
cd infrastructure/environments/production
tofu init
tofu plan -var="service_image_tag=latest"
tofu apply
```

### 5. Remove Legacy Infrastructure

Once the new infrastructure is verified working:

1. Remove old Cloud Build triggers (if any)
2. Delete legacy R scripts:
   - `inst/cloudbuild/build.R`
   - `inst/cloudbuild/build_test.R`
3. Remove `googleCloudRunner` dependency from DESCRIPTION

## Key Improvements

### Security
- Multi-stage Docker builds with non-root users
- Proper secret mounting via Secret Manager
- IAM roles with least privilege

### Maintainability
- Infrastructure as code with version control
- Automated CI/CD pipelines
- Environment-specific configurations

### Observability
- Health checks for all services
- Deployment summaries in GitHub Actions
- Infrastructure planning with PR comments

## Troubleshooting

### Common Issues

1. **Permission denied errors**: Ensure GCP service account has proper roles
2. **Terraform state conflicts**: Use workspace separation or different state buckets
3. **Docker build failures**: Check package dependencies in Dockerfiles

### Rollback Strategy

If issues occur:
1. Revert to previous git commit
2. Use legacy R scripts temporarily
3. Fix issues in new infrastructure
4. Re-deploy when ready

## Environment Variables

The following environment variables are used:

- `R_CONFIG_ACTIVE=docker`: R configuration environment
- `PORT`: Port for the service (set automatically by Cloud Run)
- `PROJECT_ID`: GCP project ID
- `REGION`: GCP region

## Service URLs

After deployment, services are available at:
- API: `https://eviction-addresses-api-{environment}-{random}.run.app`
- Dashboard: `https://eviction-addresses-dashboard-{environment}-{random}.run.app`
- Job: `https://eviction-addresses-job-{environment}-{random}.run.app`

URLs are output by the Terraform deployment and shown in GitHub Actions summaries.

## Next Steps

1. Monitor new infrastructure for stability
2. Update any external systems that depend on service URLs
3. Consider adding monitoring and alerting
4. Implement automated testing for infrastructure changes
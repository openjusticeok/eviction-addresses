# Eviction Addresses Infrastructure

This directory contains the OpenTofu (Terraform-compatible) infrastructure configuration for the eviction-addresses project.

## Structure

- `environments/` - Environment-specific configurations (production, test)
- `modules/` - Reusable OpenTofu modules
- `variables.tf` - Common variable definitions
- `outputs.tf` - Common output definitions

## Requirements

- [OpenTofu](https://opentofu.org/) (or Terraform)
- Google Cloud SDK
- Appropriate GCP permissions

## Usage

### Deploy to Test Environment

```bash
cd infrastructure/environments/test
tofu init
tofu plan
tofu apply
```

### Deploy to Production Environment

```bash
cd infrastructure/environments/production
tofu init
tofu plan
tofu apply
```

## Components

The infrastructure manages three main Cloud Run services:

1. **API Service** - Plumber R API for eviction data processing
2. **Dashboard Service** - Shiny dashboard for data entry and visualization  
3. **Job Service** - Background processing jobs for data refresh

## Migration Notes

This replaces the previous googleCloudRunner-based infrastructure setup with modern infrastructure-as-code practices using OpenTofu and GitHub Actions for CI/CD.
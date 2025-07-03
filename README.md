# eviction-addresses

This repo contains a data-entry dashboard, as well as an API to facilitate the collection and validation of eviction addresses from OSCN.

## Infrastructure

The project uses modern infrastructure-as-code with OpenTofu and GitHub Actions for deployment:

- **Infrastructure**: Defined in `infrastructure/` using OpenTofu (Terraform-compatible)
- **CI/CD**: Automated deployment via GitHub Actions
- **Environments**: Separate test and production deployments
- **Services**: Three Cloud Run services (API, Dashboard, Job)

### Deployment

Deployment occurs automatically when you push code:
- Push to `test` branch → deploys to test environment
- Push to `main` branch → deploys to production environment

The GitHub Actions workflow:
1. Runs R package tests
2. Builds Docker images for each service
3. Deploys infrastructure using OpenTofu
4. Updates Cloud Run services

For manual infrastructure management, see [MIGRATION.md](MIGRATION.md).

## Scheduled Runs

We have created scheduled triggers to call the /refresh and /hydrate endpoints on the API periodically. The /refresh endpoint searches for new eviction cases and their associated documents in the database. It also gathers minutes from previosuly collected cases, since documents are uploaded to OSCN as a case progresses. These records are entered into the case and document tables in the eviction_addresses schema. Next, the queue table is cleansed of jobs that have already been completed. New cases with at least one document are then added to the queue.

This is a long process, so care must be taken to ensure timeouts do not occur. The job service is configured with appropriate timeouts for these operations.

## Address Validation, Verification, and Geocoding

We use Postgrid as our address verification service. We are billed per address, so only use the live Postgrid API key when you need to, not for testing.

## Services

The application consists of three main services:

- **API** (`eviction-addresses-api`): Plumber R API for data processing
- **Dashboard** (`eviction-addresses-dashboard`): Shiny dashboard for data entry
- **Job** (`eviction-addresses-job`): Background processing service

Each service is containerized and deployed to Google Cloud Run with proper secret management and health checks.

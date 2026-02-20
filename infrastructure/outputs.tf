output "api_service_url" {
  description = "URL of the deployed API service"
  value       = module.eviction_addresses_services.api_service_url
}

output "dashboard_service_url" {
  description = "URL of the deployed dashboard service"
  value       = module.eviction_addresses_services.dashboard_service_url
}

output "job_service_url" {
  description = "URL of the deployed job service"
  value       = module.eviction_addresses_services.job_service_url
}

output "project_id" {
  description = "The GCP project ID"
  value       = var.project_id
}

output "region" {
  description = "The GCP region"
  value       = var.region
}

output "environment" {
  description = "The environment name"
  value       = var.environment
}
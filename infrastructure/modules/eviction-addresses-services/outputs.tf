output "api_service_url" {
  description = "URL of the deployed API service"
  value       = google_cloud_run_v2_service.api.uri
}

output "dashboard_service_url" {
  description = "URL of the deployed dashboard service"
  value       = google_cloud_run_v2_service.dashboard.uri
}

output "job_service_url" {
  description = "URL of the deployed job service"
  value       = google_cloud_run_v2_service.job.uri
}

output "api_service_name" {
  description = "Name of the API service"
  value       = google_cloud_run_v2_service.api.name
}

output "dashboard_service_name" {
  description = "Name of the dashboard service"
  value       = google_cloud_run_v2_service.dashboard.name
}

output "job_service_name" {
  description = "Name of the job service"
  value       = google_cloud_run_v2_service.job.name
}

output "service_account_email" {
  description = "Email of the Cloud Run service account"
  value       = google_service_account.cloud_run.email
}
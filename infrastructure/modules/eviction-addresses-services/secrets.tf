# Secret Manager Secrets
resource "google_secret_manager_secret" "service_account" {
  secret_id = "eviction-addresses-service-account-${var.environment}"
  
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "dashboard_service_account" {
  secret_id = "eviction-addresses-dashboard-service-account-${var.environment}"
  
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "api_config" {
  secret_id = "eviction-addresses-api-config-${var.environment}"
  
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "dashboard_config" {
  secret_id = "eviction-addresses-dashboard-config-${var.environment}"
  
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "api_renviron" {
  secret_id = "eviction-addresses-api-renviron-${var.environment}"
  
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "dashboard_renviron" {
  secret_id = "eviction-addresses-dashboard-renviron-${var.environment}"
  
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "client_id" {
  secret_id = "eviction-addresses-client-id-${var.environment}"
  
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "ssl_certs" {
  secret_id = "eviction-addresses-ssl-certs-${var.environment}"
  
  replication {
    auto {}
  }
}

# Service Account for Cloud Run services
resource "google_service_account" "cloud_run" {
  account_id   = "eviction-addresses-run-${var.environment}"
  display_name = "Eviction Addresses Cloud Run Service Account (${var.environment})"
  description  = "Service account for Cloud Run services in ${var.environment} environment"
}

# IAM binding for Secret Manager
resource "google_secret_manager_secret_iam_member" "service_account_access" {
  for_each = {
    service_account           = google_secret_manager_secret.service_account.secret_id
    dashboard_service_account = google_secret_manager_secret.dashboard_service_account.secret_id
    api_config               = google_secret_manager_secret.api_config.secret_id
    dashboard_config         = google_secret_manager_secret.dashboard_config.secret_id
    api_renviron            = google_secret_manager_secret.api_renviron.secret_id
    dashboard_renviron      = google_secret_manager_secret.dashboard_renviron.secret_id
    client_id               = google_secret_manager_secret.client_id.secret_id
    ssl_certs              = google_secret_manager_secret.ssl_certs.secret_id
  }
  
  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cloud_run.email}"
}

# IAM binding for Cloud SQL (if needed)
resource "google_project_iam_member" "cloud_sql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloud_run.email}"
}

# IAM binding for Cloud Storage (if needed)
resource "google_project_iam_member" "storage_object_viewer" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.cloud_run.email}"
}
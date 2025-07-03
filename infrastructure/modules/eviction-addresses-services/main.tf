terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Cloud Run API Service
resource "google_cloud_run_v2_service" "api" {
  name     = "eviction-addresses-api-${var.environment}"
  location = var.region
  
  template {
    service_account = google_service_account.cloud_run.email
    
    containers {
      image = "gcr.io/${var.project_id}/eviction-addresses-api:${var.service_image_tag}"
      
      ports {
        container_port = 3838
      }
      
      resources {
        limits = {
          cpu    = var.api_cpu
          memory = var.api_memory
        }
      }
      
      env {
        name  = "R_CONFIG_ACTIVE"
        value = "docker"
      }
      
      env {
        name  = "PORT"
        value = "3838"
      }
      
      # Service account key
      volume_mounts {
        name       = "service-account"
        mount_path = "/workspace"
      }
      
      # Config file
      volume_mounts {
        name       = "config"
        mount_path = "/workspace"
      }
      
      # SSL certificates - simplified to mount the directory with all certs
      volume_mounts {
        name       = "ssl-certs"
        mount_path = "/workspace/shiny-apps-certs"
      }
    }
    
    volumes {
      name = "service-account"
      secret {
        secret = google_secret_manager_secret.service_account.secret_id
        items {
          version = "latest"
          path    = "eviction-addresses-service-account.json"
        }
      }
    }
    
    volumes {
      name = "config"
      secret {
        secret = google_secret_manager_secret.api_config.secret_id
        items {
          version = "latest"
          path    = "config.yml"
        }
      }
    }
    
    volumes {
      name = "ssl-certs"
      secret {
        secret = google_secret_manager_secret.ssl_cert.secret_id
        items {
          version = "latest"
          path    = "client-cert.pem"
        }
      }
    }
    
    scaling {
      max_instance_count = var.max_instances
    }
    
    max_instance_request_concurrency = var.concurrency
    timeout                         = "${var.timeout}s"
  }
  
  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }
}

# IAM policy for API service (only for test environment)
resource "google_cloud_run_service_iam_member" "api_noauth" {
  count = var.environment == "test" ? 1 : 0
  
  location = google_cloud_run_v2_service.api.location
  project  = google_cloud_run_v2_service.api.project
  service  = google_cloud_run_v2_service.api.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Cloud Run Dashboard Service
resource "google_cloud_run_v2_service" "dashboard" {
  name     = "eviction-addresses-dashboard-${var.environment}"
  location = var.region
  
  template {
    service_account = google_service_account.cloud_run.email
    
    containers {
      image = "gcr.io/${var.project_id}/eviction-addresses-dashboard:${var.service_image_tag}"
      
      ports {
        container_port = 3838
      }
      
      resources {
        limits = {
          cpu    = var.dashboard_cpu
          memory = var.dashboard_memory
        }
      }
      
      env {
        name  = "R_CONFIG_ACTIVE"
        value = "docker"
      }
      
      env {
        name  = "PORT"
        value = "3838"
      }
      
      volume_mounts {
        name       = "service-account"
        mount_path = "/workspace"
      }
      
      volume_mounts {
        name       = "dashboard-service-account"
        mount_path = "/workspace"
      }
      
      volume_mounts {
        name       = "config"
        mount_path = "/workspace"
      }
      
      volume_mounts {
        name       = "client-id"
        mount_path = "/workspace"
      }
      
      volume_mounts {
        name       = "renviron"
        mount_path = "/workspace"
      }
      
      volume_mounts {
        name       = "ssl-certs"
        mount_path = "/workspace/shiny-apps-certs"
      }
    }
    
    volumes {
      name = "service-account"
      secret {
        secret = google_secret_manager_secret.service_account.secret_id
        items {
          version = "latest"
          path    = "eviction-addresses-service-account.json"
        }
      }
    }
    
    volumes {
      name = "dashboard-service-account"
      secret {
        secret = google_secret_manager_secret.dashboard_service_account.secret_id
        items {
          version = "latest"
          path    = "eviction-addresses-dashboard-service-account.json"
        }
      }
    }
    
    volumes {
      name = "config"
      secret {
        secret = google_secret_manager_secret.dashboard_config.secret_id
        items {
          version = "latest"
          path    = "config.yml"
        }
      }
    }
    
    volumes {
      name = "client-id"
      secret {
        secret = google_secret_manager_secret.client_id.secret_id
        items {
          version = "latest"
          path    = "client-id.json"
        }
      }
    }
    
    volumes {
      name = "renviron"
      secret {
        secret = google_secret_manager_secret.dashboard_renviron.secret_id
        items {
          version = "latest"
          path    = ".Renviron"
        }
      }
    }
    
    volumes {
      name = "ssl-certs"
      secret {
        secret = google_secret_manager_secret.ssl_cert.secret_id
        items {
          version = "latest"
          path    = "client-cert.pem"
        }
      }
    }
    
    scaling {
      max_instance_count = var.max_instances
    }
    
    max_instance_request_concurrency = var.concurrency
    timeout                         = "${var.timeout}s"
  }
  
  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }
}

# Cloud Run Job Service
resource "google_cloud_run_v2_service" "job" {
  name     = "eviction-addresses-job-${var.environment}"
  location = var.region
  
  template {
    service_account = google_service_account.cloud_run.email
    
    containers {
      image = "gcr.io/${var.project_id}/eviction-addresses-job:${var.service_image_tag}"
      
      ports {
        container_port = 8080
      }
      
      resources {
        limits = {
          cpu    = var.job_cpu
          memory = var.job_memory
        }
      }
      
      env {
        name  = "R_CONFIG_ACTIVE"
        value = "docker"
      }
      
      env {
        name  = "PORT"
        value = "8080"
      }
      
      volume_mounts {
        name       = "service-account"
        mount_path = "/workspace"
      }
      
      volume_mounts {
        name       = "config"
        mount_path = "/workspace"
      }
      
      volume_mounts {
        name       = "ssl-certs"
        mount_path = "/workspace/shiny-apps-certs"
      }
    }
    
    volumes {
      name = "service-account"
      secret {
        secret = google_secret_manager_secret.service_account.secret_id
        items {
          version = "latest"
          path    = "eviction-addresses-service-account.json"
        }
      }
    }
    
    volumes {
      name = "config"
      secret {
        secret = google_secret_manager_secret.api_config.secret_id
        items {
          version = "latest"
          path    = "config.yml"
        }
      }
    }
    
    volumes {
      name = "ssl-certs"
      secret {
        secret = google_secret_manager_secret.ssl_cert.secret_id
        items {
          version = "latest"
          path    = "client-cert.pem"
        }
      }
    }
    
    scaling {
      max_instance_count = var.max_instances
    }
    
    max_instance_request_concurrency = var.concurrency
    timeout                         = "${var.timeout}s"
  }
  
  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }
}
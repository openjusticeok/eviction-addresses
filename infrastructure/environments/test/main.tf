terraform {
  required_version = ">= 1.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
  
  backend "gcs" {
    bucket = "ojo-database-terraform-state"
    prefix = "eviction-addresses/test"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "eviction_addresses_services" {
  source = "../../modules/eviction-addresses-services"
  
  project_id         = var.project_id
  region            = var.region
  environment       = "test"
  service_image_tag = var.service_image_tag
  
  # Test environment resource allocations (smaller)
  api_cpu        = "0.5"
  api_memory     = "1Gi"
  dashboard_cpu  = "0.5"
  dashboard_memory = "512Mi"
  job_cpu        = "0.5"
  job_memory     = "1Gi"
  
  max_instances = 1
  concurrency  = 80
  timeout      = 3600
}
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
    prefix = "eviction-addresses/production"
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
  environment       = "production"
  service_image_tag = var.service_image_tag
  
  # Production resource allocations
  api_cpu        = "1"
  api_memory     = "2Gi"
  dashboard_cpu  = "1"
  dashboard_memory = "1Gi"
  job_cpu        = "1"
  job_memory     = "2Gi"
  
  max_instances = 1
  concurrency  = 80
  timeout      = 3600
}
variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default     = "ojo-database"
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "service_image_tag" {
  description = "Docker image tag for services"
  type        = string
  default     = "latest"
}
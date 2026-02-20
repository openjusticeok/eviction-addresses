variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name (test, production)"
  type        = string
}

variable "service_image_tag" {
  description = "Docker image tag for services"
  type        = string
  default     = "latest"
}

variable "api_cpu" {
  description = "CPU allocation for API service"
  type        = string
  default     = "1"
}

variable "api_memory" {
  description = "Memory allocation for API service"
  type        = string
  default     = "2Gi"
}

variable "dashboard_cpu" {
  description = "CPU allocation for dashboard service"
  type        = string
  default     = "1"
}

variable "dashboard_memory" {
  description = "Memory allocation for dashboard service"
  type        = string
  default     = "1Gi"
}

variable "job_cpu" {
  description = "CPU allocation for job service"
  type        = string
  default     = "1"
}

variable "job_memory" {
  description = "Memory allocation for job service"
  type        = string
  default     = "2Gi"
}

variable "max_instances" {
  description = "Maximum number of instances for services"
  type        = number
  default     = 1
}

variable "concurrency" {
  description = "Maximum concurrent requests per instance"
  type        = number
  default     = 80
}

variable "timeout" {
  description = "Request timeout in seconds"
  type        = number
  default     = 3600
}
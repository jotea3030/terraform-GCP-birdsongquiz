variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"  # Free tier eligible region
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

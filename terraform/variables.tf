variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "gcp_service_apis" {
  description = "List of GCP service APIs to be enabled within the project"
  type        = list
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-east1"
}
# These values MUST be configured
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}
variable "media_bucket" {
  description = "GCS Bucket ID for Wordpress Media"
  type        = string
}
variable "artifact_repo" {
  description = "Artifact Registry Repository"
  type        = string
}

# Google Cloud Resource Locations
# These can be left as-is to run in South Carolina
variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-east1"
}
variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-east1-b"
}

# Google Cloud Compute Resource Names
# These values MUST be configured
variable "mysql_vm" {
  description = "MySQL VM"
  type        = string
}
variable "run_service" {
  description = "Cloud Run Service"
  type        = string
}

# External IP of MySQL VM
# This value will be updated during the provisioning process

# TO DO: WHERE IS THIS NEEDED?

# GitHub Username and Repo
# These values MUST be replaced

# TO DO: WHERE IS THIS NEEDED?

# Wordpress Configuration
# The table prefix can be left as-is, but DB values MUST be replaced

# TO DO: WHERE IS THIS NEEDED?

variable "gcp_service_apis" {
  description = "The GCP Service APIs to be enabled within the project"
  type        = list(string)
}

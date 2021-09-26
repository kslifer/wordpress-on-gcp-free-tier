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

# GitHub Username, Repo, and Branch
# These values MUST be configured (except Branch)
variable "gh_username" {
  description = "GitHub User Name"
  type        = string
}
variable "gh_repo" {
  description = "GitHub Repo Name"
  type        = string
}
variable "gh_branch" {
  description = "GitHub Repo Branch"
  type        = string
  default     = "^master$"
}

# Wordpress Configuration
# The table prefix can be left as-is, but DB values MUST be configured
variable "wordpress_table_prefix" {
  description = "WordPress DB Table Prefix"
  type        = string
}
variable "wordpress_db_name" {
  description = "WordPress DB Table Name"
  type        = string
}
variable "wordpress_db_user" {
  description = "WordPress DB User Name"
  type        = string
}
variable "wordpress_db_password" {
  description = "WordPress DB Password"
  type        = string
}

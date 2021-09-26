terraform {
  required_version = ">= 1.0.7, < 2.0.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 3.5"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 3.5"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}
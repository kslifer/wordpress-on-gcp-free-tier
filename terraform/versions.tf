terraform {
  required_version = ">= 1.5.0, <= 1.5.7"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.81.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 4.81.0"
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
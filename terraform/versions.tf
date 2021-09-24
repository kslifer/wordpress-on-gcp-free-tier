terraform {
  required_version = ">= 1.0.7, < 2.0.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 3.5"
    }
  }
}
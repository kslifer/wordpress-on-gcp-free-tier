terraform {
  required_version = ">= 1.0.6, < 2.0.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 3.5"
    }
  }
}
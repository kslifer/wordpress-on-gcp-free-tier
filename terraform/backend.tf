terraform {
  backend "gcs" {
    bucket = "KEY_PROJECT_ID-tfstate"
    prefix = "project/"
  }

  # For local testing
  #backend "local" {
  #  path = "terraform.tfstate"
  #}
}
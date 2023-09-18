terraform {
  backend "gcs" {
    bucket = "KEY_PROJECT_ID-tfstate"
    prefix = "project/"
  }
}
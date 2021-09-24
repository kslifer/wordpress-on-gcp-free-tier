# Enable Google Cloud Service APIs
resource "google_project_service" "gcp-services" {
  provider = google
  for_each                   = toset(var.gcp_service_apis)
  service                    = each.key
  disable_dependent_services = true
}

# Create GCS Bucket
resource "google_storage_bucket" "media-bucket" {
  provider = google
  name          = var.media_bucket
  location      = var.region
  storage_class = "STANDARD"

  versioning {
    enabled = "true"
  }
}

resource "google_storage_bucket_access_control" "public-media-rule" {
  provider = google
  bucket = google_storage_bucket.media-bucket.name
  role   = "READER"
  entity = "allUsers"
}

# Create Artifact Registry Docker Repository
resource "google_artifact_registry_repository" "docker-repo" {
  provider = google-beta

  location      = var.region
  repository_id = var.artifact_repo
  description = "Docker Repository"
  format = "DOCKER"
}


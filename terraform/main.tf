# Enable Google Cloud Service APIs
resource "google_project_service" "gcp-services" {
  for_each                   = toset(var.gcp_service_apis)
  service                    = each.key
  disable_dependent_services = true
}

resource "google_storage_bucket" "media-bucket" {
  name          = var.media_bucket
  location      = var.region
  storage_class = "STANDARD"

  versioning {
    enabled = "true"
  }
}

resource "google_storage_bucket_access_control" "public-media-rule" {
  bucket = google_storage_bucket.media-bucket.name
  role   = "READER"
  entity = "allUsers"
}

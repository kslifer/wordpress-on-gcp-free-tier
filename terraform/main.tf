# Enable Google Cloud Service APIs
resource "google_project_service" "gcp_services" {
  for_each = var.gcp_service_apis

  project = var.project_id
  service = each.value

  disable_dependent_services = true
}
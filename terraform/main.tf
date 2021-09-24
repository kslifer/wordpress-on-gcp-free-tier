# Enable Google Cloud Service APIs
resource "google_project_service" "gcp_services" {
  for_each = toset(var.gcp_service_apis)

  project = var.project_id
  service = each.key

  disable_dependent_services = true
}
# Enable the Cloud Resource Manager API
resource "google_project_service" "gcp_resource_manager_api" {
  project = var.project_id
  service = "cloudresourcemanager.googleapis.com"
}

# Enable Google Cloud Service APIs
resource "google_project_service" "gcp_services" {
  count   = length(var.gcp_service_list)
  project = var.project_id
  service = var.gcp_service_list[count.index]

  disable_dependent_services = true

  depends_on = [
    google_project_service.gcp_resource_manager_api,
  ]
}
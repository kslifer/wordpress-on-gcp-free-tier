# These values MUST be configured
project_id    = "huevos-hoy-1234" #"wp-yourdomain-com"
media_bucket  = "huevos-hoy-1234" #"media-yourdomain-com"
artifact_repo = "huevos-hoy-1234" #"docker-yourdomain-com"

# Google Cloud Resource Locations
# These can be left as-is to run in South Carolina
region = "us-east1"
zone   = "us-east1-b"

# Google Cloud Compute Resource Names
# These values MUST be configured
mysql_vm    = "mysql-huevos-com" #"mysql-yourdomain-com"
run_service = "wp-huevos-com"    #"wp-yourdomain-com"





gcp_service_apis = [
  "cloudresourcemanager.googleapis.com",
  "cloudbuild.googleapis.com",
  "compute.googleapis.com",
  "run.googleapis.com",
  "osconfig.googleapis.com",
  "artifactregistry.googleapis.com",
  "containeranalysis.googleapis.com",

]

# Create GCS Bucket
resource "google_storage_bucket" "media-bucket" {
  provider      = google
  name          = var.media_bucket
  location      = var.region
  storage_class = "STANDARD"
}

resource "google_storage_bucket_access_control" "public-media-rule" {
  provider = google
  bucket   = google_storage_bucket.media-bucket.name
  role     = "READER"
  entity   = "allUsers"
}

# Create Artifact Registry Docker Repository
resource "google_artifact_registry_repository" "docker-repo" {
  provider      = google-beta
  location      = var.region
  repository_id = var.artifact_repo
  description   = "Docker Repository"
  format        = "DOCKER"
}

# Create Service Accounts and IAM Roles
resource "google_service_account" "sa-mysql-vm" {
  project      = var.project_id
  account_id   = var.mysql_vm_sa
  display_name = "Service Account for MySQL VM"
}
resource "google_project_iam_member" "mysql-vm-log-writer-binding" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.sa-mysql-vm.email}"
}
resource "google_project_iam_member" "mysql-vm-metric-writer-binding" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.sa-mysql-vm.email}"
}

resource "google_service_account" "sa-run-service" {
  project      = var.project_id
  account_id   = var.run_service_sa
  display_name = "Service Account for Cloud Run Service"
}
resource "google_project_iam_member" "run-service-log-writer-binding" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.sa-run-service.email}"
}
resource "google_project_iam_member" "run-service-metric-writer-binding" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.sa-run-service.email}"
}

# Create network stack
resource "google_compute_network" "vpc-network" {
  provider                = google
  name                    = var.vpc_network
  auto_create_subnetworks = "false"
  routing_mode            = "GLOBAL"
}

resource "google_compute_subnetwork" "vpc-subnet" {
  name                     = var.vpc_subnet
  ip_cidr_range            = "10.0.0.0/24"
  region                   = var.region
  network                  = google_compute_network.vpc-network.id
  private_ip_google_access = "true"
}

resource "google_compute_firewall" "allow-iap-ssh-ingress" {
  name      = "allow-iap-ssh-ingress"
  network   = google_compute_network.vpc-network.name
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "ingress-mysql-internal" {
  name      = "allow-mysql-ingress"
  network   = google_compute_network.vpc-network.name
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }

  source_ranges = ["10.0.0.0/24"]
}

resource "google_compute_address" "mysql-internal-ip" {
  name         = var.mysql_vm
  address_type = "INTERNAL"
  subnetwork   = google_compute_subnetwork.vpc-subnet.id
  purpose      = "GCE_ENDPOINT"
}

# Create compute stack
resource "google_compute_resource_policy" "snapshot-schedule-weekly" {
  name   = "snapshot-schedule-weekly"
  region = var.region
  snapshot_schedule_policy {
    schedule {
      weekly_schedule {
        day_of_weeks {
          day        = "SUNDAY"
          start_time = "04:00"
        }
      }
    }
    retention_policy {
      max_retention_days    = 7
      on_source_disk_delete = "APPLY_RETENTION_POLICY"
    }
    snapshot_properties {
      storage_locations = [var.region]
      guest_flush       = "false"
    }
  }
}

resource "google_compute_instance" "mysql-vm" {
  name         = var.mysql_vm
  machine_type = "e2-micro"
  zone         = var.zone

  tags = ["mysql"]

  boot_disk {
    auto_delete = "false"
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = "30"
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.vpc-subnet.name
    network_ip = google_compute_address.mysql-internal-ip.address
    access_config {
    }
  }

  shielded_instance_config {
    enable_secure_boot = "true"
  }

  service_account {
    email  = google_service_account.sa-mysql-vm.email
    scopes = ["cloud-platform"]
  }

  allow_stopping_for_update = "true"
  desired_status            = "RUNNING"
}

resource "google_compute_disk_resource_policy_attachment" "mysql-backup" {
  name = google_compute_resource_policy.snapshot-schedule-weekly.name
  disk = google_compute_instance.mysql-vm.name
  zone = var.zone
}

# Enable OS Patch Management
resource "google_compute_project_metadata" "vm-manager" {
  metadata = {
    enable-guest-attributes = "TRUE"
    enable-osconfig         = "TRUE"
  }
}
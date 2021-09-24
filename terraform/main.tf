# Enable Google Cloud Service APIs
resource "google_project_service" "gcp-services" {
  provider                   = google
  for_each                   = toset(var.gcp_service_apis)
  service                    = each.key
  disable_dependent_services = true
}

# Create GCS Bucket
resource "google_storage_bucket" "media-bucket" {
  provider      = google
  name          = var.media_bucket
  location      = var.region
  storage_class = "STANDARD"

  versioning {
    enabled = "true"
  }
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

# Create network stack
resource "google_compute_network" "vpc-network" {
  provider                = google
  name                    = "network"
  auto_create_subnetworks = "false"
  routing_mode            = "GLOBAL"
}

resource "google_compute_subnetwork" "vpc-subnet" {
  name                     = "subnet"
  ip_cidr_range            = "192.168.1.0/28"
  region                   = var.region
  network                  = google_compute_network.vpc-network.id
  private_ip_google_access = "true"
}

resource "google_compute_firewall" "ingress-ssh-iap" {
  name      = "allow-ssh-ingress-from-iap"
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

resource "google_compute_firewall" "ingress-mysql-all" {
  name      = "allow-mysql-ingress-all"
  network   = google_compute_network.vpc-network.name
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }

  source_ranges = ["0.0.0.0/0"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_address" "mysql-external-ip" {
  name         = var.mysql_vm
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"
}

# Create compute stack
resource "google_compute_resource_policy" "snapshot-schedule" {
  name   = "snapshot-schedule"
  region = var.region
  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = "04:00"
      }
    }
    retention_policy {
      max_retention_days    = 3
      on_source_disk_delete = "KEEP_AUTO_SNAPSHOTS"
    }
    snapshot_properties {
      storage_locations = [var.region]
      guest_flush       = "true"
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
      image = "debian-cloud/debian-10"
      size  = "30"
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.vpc-subnet.name
    access_config {
      nat_ip = google_compute_address.mysql-external-ip.address
    }
  }

  shielded_instance_config {
    enable_secure_boot = "true"
  }

  service_account {
    scopes = ["cloud-platform"]
  }

  allow_stopping_for_update = "true"
  desired_status = "RUNNING"
}


# Enable OS Patch Management
resource "google_compute_project_metadata" "vm-manager" {
  metadata = {
    enable-guest-attributes = "TRUE"
    enable-osconfig         = "TRUE"
  }
}
output "project_id" {
  value = var.project_id
}

output "media_bucket" {
  value = var.media_bucket
}

output "artifact_repo" {
  value = var.artifact_repo
}

output "vpc_network" {
  value = google_compute_network.vpc-network.name
}

output "vpc_subnet" {
  value = google_compute_subnetwork.vpc-subnet.name
}

output "region" {
  value = var.region
}

output "zone" {
  value = var.zone
}

output "mysql_vm" {
  value = var.mysql_vm
}

output "run_service" {
  value = var.run_service
}

output "run_service_sa" {
  value = google_service_account.sa-run-service.email
}

output "mysql_vm_int_ip" {
  value = google_compute_address.mysql-internal-ip.address
}

output "gh_username" {
  value = var.gh_username
}

output "gh_repo" {
  value = var.gh_repo
}

output "gh_branch" {
  value = var.gh_branch
}

output "wordpress_table_prefix" {
  value = var.wordpress_table_prefix
}

output "wordpress_db_name" {
  value = var.wordpress_db_name
}

output "wordpress_db_user" {
  value = var.wordpress_db_user
}

output "wordpress_db_password" {
  value = var.wordpress_db_password
}
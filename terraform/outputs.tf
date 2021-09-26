output "project_id" {
  value = var.project_id
}

output "media_bucket" {
  value = var.media_bucket
}

output "artifact_repo" {
  value = var.artifact_repo
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

output "mysql_vm_ext_ip" {
  value = google_compute_address.mysql-external-ip.address
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
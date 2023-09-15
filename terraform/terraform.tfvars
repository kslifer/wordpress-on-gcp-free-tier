# These values MUST be configured
project_id    = "wp-chev-in-d01"
media_bucket  = "media-wp-chev-in-d01"
artifact_repo = "docker-wp-chev-in-d01"

# Google Cloud Resource Locations
# These can be left as-is to run in South Carolina
region = "us-east1"
zone   = "us-east1-b"

# Google Cloud Compute Resource Names
# These values MUST be configured
mysql_vm    = "mysql-wp-chev-in-d01"
run_service = "wp-chev-in-d01"

# GitHub Username, Repo, and Branch
# These values MUST be configured (except Branch)
gh_username = "kslifer"
gh_repo     = "wordpress-on-gcp-free-tier"
gh_branch   = "^dev-2023-q4-enhancements$"

# Wordpress Configuration
# The table prefix can be left as-is, but DB values MUST be configured
wordpress_table_prefix = "wp_"
wordpress_db_name      = "wordpress"
wordpress_db_user      = "wordpress"
wordpress_db_password  = "WordPass1234!"

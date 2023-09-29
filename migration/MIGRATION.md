# Wordpress on GCP Free Tier - Migrating from V1 → V2
This guide outlines the steps to migrate from older versions of the solution to the latest that was released in September 2023.

This solution is continously evolving, so not all "older versions" will be the same. An "older version" implies:
 - Not having Terraform-managed infrastructure.
 - Using MySQL for the DB.

The September 2023 release was implemented in a way that would provide a migration path from earlier versions within the same host GCP project:
 - GCP resource names have been altered to allow both old and new versions to co-exist, with the exception of the GCS bucket that hosts website media. Changing the name of the media bucket would impact the website. As a result, this resource needs to be imported to Terraform state, and automation is provided to accomplish this.
 - The network has been changed from a Class C (192.168.0.0) to a Class A (10.0.0.0), to provide isolation between old and new versions.

 The process outlined below are the steps that I took to migrate four websites. The migration of each website took between 1-2 hours.


 ## Pre-Migration Configuration
  - Create a new "migration" branch of your private repo that holds your current site configuration to implement and test the migration changes. Clone it to your workstation, then **move** all files/folders within the clone to a temporary location where they can be referenced - making your branch empty.
  - Clone the latest master branch of the [template repo](https://github.com/kslifer/wordpress-on-gcp-free-tier), then **copy** all files/folders from the clone into the new empty branch of your private repo.
  - "Migrate" (a.k.a. copy and paste) your site-specific configurations from your private repo clone that was moved to a temporary location back into the new set of files/folders that were copied from the template repo. This will include:
    - install/variables.conf: To be used in the next step, to migrate your variables.
    - wordpress-core/Dockerfile: The Wordpress version, if you're pinned to something that isn't the latest.
    - wordpress-themes: The list of theme URLs (or zip files).
    - wordpress-plugins: The list of plugin URLS (or zip files).
    - install/pipeline/customization.sh: Any custom scripting that was implemented, plus any related assets.
    - **Anything else** that was added to your private repo that should continue to be there.
  - "Migrate" your site-specific variables:
    - Make a copy of terraform/terraform.tfvars.template (as terraform.tfvars)
    - Transpose your configuration from variables.conf into this new format:
      - project_id/media_bucket: Add your current configurations
      - artifact_repo: Adopt the new naming convention
      - region/zone: Leave as-is if you're operating in us-east1 (recommended)
      - vpc_network/vpc_subnet: Leave as-is, unless you have a desire to change the name
      - mysql_vm/run_service: Adopt the new naming convention
      - mysql_vm_sa/run_service_sa: Adopt the new naming convention
      - gh_username/gh_repo/gh_branch: Add your current configurations, but change the branch to your migration branch (for now)
      - wordpress_ configurations: Add your current configurations
  - Commit the changes to the migration branch, which will be cloned into the Cloud Shell and used to execute the migration.

 ## Provisioning the New GCP Infrastructure
  - Follow the standard [install procedure](https://github.com/kslifer/wordpress-on-gcp-free-tier/blob/master/INSTALL.md) up to the [Provision the GCP Infrastructure](https://github.com/kslifer/wordpress-on-gcp-free-tier/blob/master/INSTALL.md#provision-the-gcp-infrastructure) step, paying attention to the following:
    - When cloning the repo into the Cloud Shell, reference your migration branch, NOT the master branch.
    - The script that deletes the default network resources will generate errors if they don't exist; these errors can be ignored.
    - The Terraform plan should only indicate the addition of resources, not deletion.
    - The Terraform apply will generate an error when attempting to create the media bucket because it already exists. This error can be ignored, and will be addressed later - the remaining resources will still be created successfully.
    - Manually run the **terraform-import** Cloud Build job that was created to import the media bucket (both the GCS bucket and the public ACL policy) into Terraform state, resolving future Terraform apply errors.
    - The **terraform-plan** and **terraform-apply** Cloud Build jobs can be manually run again to prove that the configuration matches the state.

## Backup the MySQL DB
- Clean the DB to minimize the size of what will be migrated; I personally use the [WP-Optimize](https://wordpress.org/plugins/wp-optimize/) plugin.
- The Cloud Shell will be used as a bridge to transfer the DB between old and new servers. Run `gcloud compute ssh mysql-<yourdomain-yourtld> --tunnel-through-iap --zone=<yourzone>` to connect to the existing MySQL server.
- Run `sudo mysqldump --databases wordpress -u root -p > wp_db_backup.sql` to generate a backup of the MySQL DB on the server. The root password will need to be provided. Then run `exit` to return to the Cloud Shell.
- Run `gcloud compute scp mysql-<yourdomain-yourtld>:~/wp_db_backup.sql . --zone=<yourzone> --tunnel-through-iap` to transfer the backup to the Cloud Shell.
- At this point, I highly recommend downloading a copy of the file from your Cloud Shell and placing it into the **migration** folder of your migration branch, to be stored in your repo. In the event that there's an issue with MariaDB after the migration is complete and old resources are torn down, this can be used to restore the MySQL database.
- Run `sed -i 's/utf8mb4_0900_ai_ci/utf8mb4_unicode_ci/g' wp_db_backup.sql` to address a collation compatability issue between MySQL and MariaDB that would result in errors when attempting to import the DB.
- Run `gcloud compute scp ./wp_db_backup.sql mariadb--<yourdomain-yourtld>:~ --zone=<yourzone> --tunnel-through-iap` to copy the DB export to the new MariaDB server.

## Configure the MariaDB VM
- Resume the standard [install procedure](https://github.com/kslifer/wordpress-on-gcp-free-tier/blob/master/INSTALL.md#transfer-configuration-script-to-the-mariadb-vm) at the step where the MariaDB VM is configured, up to the `sudo mariadb-secure-installation` step. **DO NOT CREATE THE DATABASE OR USERNAME.**
- While in the same SSH session to the MariaDB VM, run `mariadb -u root -p < wp_db_backup.sql` to import the DB backup. The root password that was just set will need to be provided.
- Run `mariadb -u root -p`, then `show databases;` to verify that the **wordpress** database was successfully imported and exists.
- While in the same MariaDB session, follow the last steps in [MariaDB VM Configuration](https://github.com/kslifer/wordpress-on-gcp-free-tier/blob/master/INSTALL.md#mysql-vm-configuration) to recreate the same user and password in use by your existing site.
- Manually run the **wordpress-build-deploy** Cloud Build job to deploy your new Wordpress frontend service. Click the vanity Cloud Run URL to verify that your site loads - if it does, the new service can successfully connect to the new MariaDB databse and read your site's data.
- Perform a cutover by following the steps in [Map Your Domain to Cloud Run](https://github.com/kslifer/wordpress-on-gcp-free-tier/blob/master/INSTALL.md#map-your-domain-to-cloud-run). If you're using the native Cloud Run domain mapping, the process only involves deleting the existing mappings and configuring new mappings to your new Cloud Run service (wpsvc-yourdomain-yourtld). DNS entries don't need to be updated, but your website will go through a temporary outage as the new Cloud Run domain mappings propagate.
- At this point, the old MySQL VM can be stopped to manage cost - and to confirm that all traffic is using the new site deployment and MariaDB database.


## Post-Migration Merge
Once the migration is complete and your site is validated, take the final steps below to re-establish normal operating procedures in the master branch:
 - Update the **gh_branch** value to "^master$" in terraform.tfvars of the migration branch.
 - Delete the **variables.conf** file from the migration branch (it's superseded by terraform.tfvars).
 - Manually update the four [Cloud Build triggers](https://console.cloud.google.com/cloud-build/triggers) to use the master branch instead of the migration branch.
 - Commit the changes to the migration branch, then merge the migration branch back into master.
 - Validate that all four pipelines run successfully.

## Old Resource Teardown
The final step of the migration is to tear down all of the old infrastructure. This can be done manually in the Cloud Console.

There are some dependencies in the deletion of resources; I recommend this sequence:
 - The **github-trigger** Cloud Build trigger (Region is global).
 - The 1st Gen Cloud Build repository link (Region is global).
 - The **docker-yourdomain-yourtld** Artifact Registry.
 - The **wp-yourdomain-yourtld** Cloud Run Service.
 - The **mysql-yourdomain-yourtold** GCE instance, and the associated Persistent Disk with the same name.
 - The **snapshot-schedule** snapshot schedule that was attached to the MySQL VM, and any associated historical disk snapshots.
 - The **mysql-yourdomain-yourtold** reserved internal IP address, which should show as not being in use.
 - The **network** VPC, which will in turn delete the associated subnet and firewall rules.

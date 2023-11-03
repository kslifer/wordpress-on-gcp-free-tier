# Wordpress on GCP Free Tier - Install Guide
This install guide outlines the steps to build, configure, and deploy this solution into a Google Cloud Platform (GCP) project. Previous exposure to GCP and Wordpress are beneficial, but not required.

These instructions will leverage the use of two interfaces into your GCP environment:
- The [Cloud Console](https://cloud.google.com/cloud-console): a web-based admin interface
- The [Cloud Shell](https://cloud.google.com/shell): a Linux terminal command line interface

Provisioning steps are a combination of bash scripts that wrap [Cloud SDK](https://cloud.google.com/sdk/) `gcloud` commands, [Terraform](https://www.terraform.io/) automation through a [Cloud Build](https://cloud.google.com/build) pipeline, and some unavoidable point-and-click steps in the Cloud Console.


## Environment Setup
Log into the Cloud Console at https://console.cloud.google.com/, then activate the Cloud Shell interface.

First, ensure that you're logged in to the Google Account that has Owner permissions on the GCP project, and that your Cloud Shell session is configured to the GCP project that you'd like to use by going through the `gcloud init` workflow and verifying or updating the configuration.

Clone your private repo into your working Cloud Shell directory. This will require creating a (classic) [Personal Access Token](https://github.com/settings/tokens) with OATH scope to "repo" (the first checkbox).

The following commands can be used **(with your details substituted)**:

    export GH_USERNAME="your_username"
    export GH_REPO="wordpress-on-gcp-free-tier-yourdomain-yourtld"
    export GH_BRANCH="master"
    export GH_TOKEN="your_token"
    
    git clone https://${GH_USERNAME}:${GH_TOKEN}@github.com/${GH_USERNAME}/${GH_REPO}.git -b ${GH_BRANCH}
    cd $GH_REPO


### Load Terraform variables into the environment
Run the following script in the Cloud Shell to load the variables defined in **terraform.tfvars** into the environment for reuse:

    source ./install/load_environment_vars.sh

### Enable the GCP Service APIs that will be used
 Run the following script in the Cloud Shell to enable the required APIs (this is done to avoid Terraform failures due to API enablement being eventually consistent):

    bash ./install/enable_gcp_apis.sh

### Delete the default VPC network
 If a new GCP project was created and will only be used to host Wordpress, run the following script in the Cloud Shell to delete the default VPC network and its firewall rules that are auto-created with a new GCP project. If these resources weren't created or were already deleted, the gcloud commands will throw errors that can be ignored.

    bash ./install/delete_default_network.sh


### Elevate permissions for the Cloud Build SA so it can act on behalf of the Terraform and Wordpress pipelines
  Run the following commands in the Cloud Shell to update the IAM permissions:
 
    export PROJECT_NUM=$(gcloud projects list --filter="$GOOGLE_CLOUD_PROJECT" --format="value(PROJECT_NUMBER)")
    gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT --member="serviceAccount:${PROJECT_NUM}@cloudbuild.gserviceaccount.com" --role='roles/owner'


## Connect Cloud Build to GitHub
Run the following commands in the Cloud Shell to create a GitHub connection:

    export PROJECT_NUM=$(gcloud projects list --filter="$GOOGLE_CLOUD_PROJECT" --format="value(PROJECT_NUMBER)")
    CLOUD_BUILD_SERVICE_AGENT="service-${PROJECT_NUM}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
    gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT --member="serviceAccount:${CLOUD_BUILD_SERVICE_AGENT}" --role="roles/secretmanager.admin"
    
    gcloud builds connections create github github-connection --region=${region}

An authorization step via web browser is required. Once the connection is established, load the [Repositories Page](https://console.cloud.google.com/cloud-build/repositories/) to verify. A manual step will still be required to either install the Cloud Build GitHub App, or to link the connection to an existing installation. When the Status indicator for the connection shows a green check and an **Enabled** status, the setup is complete.

Run the following command in the Cloud Shell to add the GitHub repository:

    gcloud builds repositories create ${gh_repo} --remote-uri="https://github.com/${gh_username}/${gh_repo}.git" --connection=github-connection --region=${region}

Once the connection is established, load the [Repositories Page](https://console.cloud.google.com/cloud-build/repositories/) again to verify. The repository should show up underneath the GitHub connection.

## Configure the Terraform and Wordpress Pipelines
Run the following commands in the Cloud Shell to configure plan and apply triggers for the Terraform CI/CD pipeline.

The plan trigger will run the Terraform workflow through to plan when a commit is made. The apply trigger will run the full Terraform workflow through to apply as a push-button.

    gcloud builds triggers create github \
    --name="terraform-plan" \
    --repository=projects/$GOOGLE_CLOUD_PROJECT/locations/${region}/connections/github-connection/repositories/${gh_repo} \
    --branch-pattern="${gh_branch}" \
    --build-config="terraform-pipeline.yaml" \
    --region=${region} \
    --included-files="terraform/*, terraform-pipeline.yaml" \
    --substitutions _TF_STEP=plan

    gcloud builds triggers create github \
    --name="terraform-apply" \
    --repository=projects/$GOOGLE_CLOUD_PROJECT/locations/${region}/connections/github-connection/repositories/${gh_repo} \
    --branch-pattern="${gh_branch}" \
    --build-config="terraform-pipeline.yaml" \
    --region=${region} \
    --ignored-files="**" \
    --substitutions _TF_STEP=apply

**Optionally** run the following command in the Cloud Shell to configure an import trigger. This trigger will run Terraform import as a push-button, and can be used to bring resources in the environment under Terraform control by following [these guidelines](https://cloud.google.com/docs/terraform/resource-management/import#import-resources-one-at-a-time). The default behavior of this trigger is to import the media bucket, to support the migration from pre-Terraform versions of this project.

    gcloud builds triggers create github \
    --name="terraform-import" \
    --repository=projects/$GOOGLE_CLOUD_PROJECT/locations/${region}/connections/github-connection/repositories/${gh_repo} \
    --branch-pattern="${gh_branch}" \
    --build-config="terraform-import.yaml" \
    --region=${region} \
    --ignored-files="**" \
    --substitutions _MEDIA_BUCKET=${media_bucket}

Run the following command in the Cloud Shell to configure the Cloud Build CI/CD pipeline for the Wordpress frontend.

    gcloud builds triggers create github \
    --name="wordpress-build-deploy" \
    --repository=projects/$GOOGLE_CLOUD_PROJECT/locations/${region}/connections/github-connection/repositories/${gh_repo} \
    --branch-pattern="${gh_branch}" \
    --require-approval \
    --build-config="wordpress-pipeline.yaml" \
    --region=${region} \
    --included-files="**" \
    --ignored-files="**/*.md,install/variables.conf,diagrams/**,terraform/**" \
    --substitutions _ARTIFACT_REPO=${artifact_repo},_REGION=${region},_RUN_SERVICE=${run_service},_RUN_SERVICE_SA=${run_service_sa}@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com,_VPC_NETWORK=${vpc_network},_VPC_SUBNET=${vpc_subnet}


## Provision the GCP Infrastructure
If all of the Terraform configuration changes and project-specific terraform.tvfars file has been committed to the GitHub repository, the Terraform pipeline can be executed by going to the [Triggers Page](https://console.cloud.google.com/cloud-build/triggers;region=us-east1) and clicking on the **Run** button in the "terraform-plan" trigger, followed by the "terraform-apply" trigger. Otherwise, committing the latest changes will trigger the pipeline.

The build process can be monitored in the Cloud Console at the [Build History](https://console.cloud.google.com/cloud-build/builds) page.

If the build won't execute with an error message **Failed to trigger build: failed precondition: due to quota restrictions, cannot run builds in this region. Please contact support**, it's because the quota "Concurrent Build CPUs (Regional Public Pool) per region per build_origin" has a default value of 0 and an increase needs to be requested (which takes several days to be addressed). This appears to be a problem with the second generation GitHub connector.


## Transfer configuration script to the MariaDB VM
Run the following command in the Cloud Shell to transfer the **configure_mysql_vm.sh** script out to the MariaDB VM, so it can be run there:

    gcloud compute scp ./install/configure_mysql_vm.sh ${mysql_vm}:~ --zone=$zone --tunnel-through-iap --quiet

This command could fail while the VM creation is propagating across Google Cloud. If it does, try again in a minute.


## MariaDB VM Configuration
Run the following commands in the Cloud Shell to SSH into the MariaDB VM:

    gcloud compute ssh ${mysql_vm} --tunnel-through-iap --zone=$zone

Execute the **configure_mysql_vm.sh** script that was copied over:

    bash configure_mysql_vm.sh

This script will allocate a memory swap file on the persistent disk, install the GCP Cloud Ops agent and MariaDB, then apply server configuration changes to MariaDB. **Note: The initial apt-upgrade may take 5-10 minutes, but will run successfully. Have patience.**

**NOTE: Write down the password that you create for the 'root' user!**

After the install completes, run `sudo systemctl status mariadb` to verify that MySQL is active and operational.

Now run `sudo mariadb-secure-installation` to harden the install:
- Press 'Enter' when asked for the current root password
- Enter `n` to decline switching to unix_socket authentication
- Enter `Y` to change the root password (then change it)
- Enter `Y` to remove anonymous users
- Enter `Y` to disallow root login remotely
- Enter `Y` to remove the test database
- Enter `Y` to reload privilege tables

To perform the Wordpress-specific configuration of the MySQL database, follow [the official Wordpress support directions](https://developer.wordpress.org/advanced-administration/before-install/creating-database/#using-the-mysql-client) (adapted for MariaDB):
- Run `mariadb -u root -p` to log in
- Run `CREATE DATABASE wordpress;` to create the WP database (use whatever value matches your terraform.tfvars)
- Run `CREATE USER "wordpress"@"%" IDENTIFIED VIA mysql_native_password USING PASSWORD("WordPass1234!");` to create the WP username and password (use whatever values match your variable.conf)
- Run `GRANT ALL PRIVILEGES ON wordpress.* TO "wordpress"@"%";` to assign the permissions (using your WP database name for the first value, and your WP username for the second value)
- Run `FLUSH PRIVILEGES;`
- Run `EXIT`

**Note: Write down the WP database name, username and password!**


## Deploy Wordpress
The application pipeline can be executed by going to the [Triggers Page](https://console.cloud.google.com/cloud-build/triggers;region=us-east1) and clicking on the **Run** button for the "wordpress-build-deploy" trigger. Otherwise, committing a change will trigger the pipeline. The build will need to be approved.

The build process can be monitored in the Cloud Console at the [Build History](https://console.cloud.google.com/cloud-build/builds) page.

After the build successfully completes, navigate to [Cloud Run](https://console.cloud.google.com/run). If there's a service with a green check, the deployment was successful. Navigate into the service and click the **run.app** service URL. If you see the Wordpress setup screen, the install process has run successfully and the Wordpress frontend is connecting to the MySQL database!


## Map Your Domain to Cloud Run
Cloud Run supports mapping a custom domain directly to a service, with a fully managed SSL certificate. The directions to complete this process through the Cloud Console are [here](https://cloud.google.com/run/docs/mapping-custom-domains).

If your domain is registered through [Google Domains](https://domains.google/), this setup process is very simple. If not, some additional steps will be required to verify domain ownership that are outside of the scope of these instructions.

Some notes on DNS updates:
- Separate entries are required for [yourdomain.com](https://yourdomain.com) and [www.yourdomain.com](https://www.yourdomain.com) (as a subdomain) in order for both to successfully load
- Multiple A and AAA DNS records are provided; they should each be consolidated into single A and AAA entries
- A separate "www" CNAME mapping will be provided to perform the www redirect

Domain verification, DNS propagation, and the SSL certification process can take some time to work through. Proceed when nevigating to [www.yourdomain.com](https://www.yourdomain.com) in a web browser loads the Wordpress configuration screen. Wordpress assumes  permalink values from the URL, and configuring it through the Cloud Run service URL will result in an incorrect configuration.


## Cloud Operations
In the Cloud Console, navigate to [Cloud Monitoring](https://console.cloud.google.com/monitoring) and build a monitoring workspace for the project.

Basic observability can be achieved through the following:
- Configure an Alerting Notification Channel to your email address
- Configure an Uptime Check; global HTTPS checks to your root domain URL every 15 minutes are a good baseline
- Cloud Run metrics can be viewed in the Cloud Console on the Metrics tab of the [Cloud Run service](https://console.cloud.google.com/run) 
- MySQL VM metrics can be viewed in the Cloud Console on the Monitoring tab of the [Compute Engine instance](https://console.cloud.google.com/compute/instances)


## Configure Wordpress
At this point, it's safe to nevigate to [www.yourdomain.com](https://www.yourdomain.com) in a web browser and run through the five minute Wordpress setup.

**NOTE: Write down the WP admin username and password!**

Themes and Plugins that were built into the image will be available in the Dashboard. Activate and customize them - changes will be persisted into the MySQL database.

The WP-Stateless plugin should be activated first and configured to your GCP project and the GCS media bucket configured in terraform.tfvars through the automated setup process. Don't setup a new GCP project and bucket! This plugin will redirect all media uploads to a GCS bucket in GCP, ensuring that the media is persisted across container instances and the Wordpress frontend remains stateless.

Happy blogging!

# Wordpress on GCP Free Tier - Install Guide
This install guide outlines the steps to build, configure, and deploy this solution into a Google Cloud Platform (GCP) project. Previous exposure to GCP and Wordpress are beneficial, but not required.

These instructions will leverage the use of two interfaces into your GCP environment:
- The [Cloud Console](https://cloud.google.com/cloud-console): a web-based admin interface
- The [Cloud Shell](https://cloud.google.com/shell): a Linux terminal command line interface

Provisioning steps are a combination of bash scripts that wrap [Cloud SDK](https://cloud.google.com/sdk/) `gcloud` commands, [Terraform](https://www.terraform.io/) automation through a [Cloud Build](https://cloud.google.com/build) pipeline, and some unavoidable point-and-click steps in the Cloud Console.


## Environment Setup
Log into the Cloud Console at https://console.cloud.google.com/, then activate the Cloud Shell interface.

First, ensure that you're logged in to the Google Account that has Owner permissions on the GCP project, and that your Cloud Shell session is configured to the GCP project that you'd like to use by going through the `gcloud init` workflow and verifying or updating the configuration.

Clone your private repo into your working Cloud Shell directory. This will require creating a [Personal Access Token](https://github.com/settings/tokens) with OATH scope to "repo" (the first checkbox).

The following commands can be used **(replacing the variables with your configuration)**:

    export GH_USERNAME="your_username"
    export GH_TOKEN="your_token"
    export GH_REPO="wordpress-on-gcp-free-tier-yourdomain-com"
    export GH_BRANCH="master"

    git clone https://${GH_USERNAME}:${GH_TOKEN}@github.com/${GH_USERNAME}/${GH_REPO}.git -b ${GH_BRANCH}


### Enable the GCP Service APIs that will be used
 Run the following script in the Cloud Shell to enable the required APIs (this is done to avoid Terraform failures due to API enablement being eventually consistent):

    bash $GH_REPO/install/enable_gcp_apis.sh

### Delete the default VPC network
 If a new GCP project was created and will only be used to host Wordpress, run the following script in the Cloud Shell to delete the default VPC network and its firewall rules (that are auto-created with a new GCP project):

    bash $GH_REPO/install/delete_default_network.sh


### Elevate permissions for the Cloud Build SA so it can act on behalf of the infra and app pipelines
  Run the following commands in the Cloud Shell to update the IAM permissions:
 
    export PROJECT_NUM=$(gcloud projects list --filter="$GOOGLE_CLOUD_PROJECT" --format="value(PROJECT_NUMBER)")
    gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT --member="serviceAccount:${PROJECT_NUM}@cloudbuild.gserviceaccount.com" --role='roles/owner'


## Connect Cloud Build to GitHub
Run the following commands in the Cloud Shell to create a GitHub connection:

    export PROJECT_NUM=$(gcloud projects list --filter="$GOOGLE_CLOUD_PROJECT" --format="value(PROJECT_NUMBER)")
    CLOUD_BUILD_SERVICE_AGENT="service-${PROJECT_NUM}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
    gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT --member="serviceAccount:${CLOUD_BUILD_SERVICE_AGENT}" --role="roles/secretmanager.admin"
    
    export REGION="us-east1"
    gcloud builds connections create github github-connection --region=${REGION}

An authorization step via web browser is required. Once the connection is established, load the [Repositories Page](https://console.cloud.google.com/cloud-build/repositories/) to verify. A manual step will still be required to either install the Cloud Build GitHub App, or to link the connection to an existing installation. When the Status indicator for the connection shows a green check and an **Enabled** status, the setup is complete.

Run the following commands in the Cloud Shell to add the GitHub repository:

    export GH_REPO="wordpress-on-gcp-free-tier-yourdomain-com"
    export GH_USERNAME="your_username"
    export GH_REPO_URI="https://github.com/${GH_USERNAME}/${GH_REPO}.git"
    export REGION="us-east1"

    gcloud builds repositories create ${GH_REPO} --remote-uri=${GH_REPO_URI} --connection=github-connection --region=${REGION}

Once the connection is established, load the [Repositories Page](https://console.cloud.google.com/cloud-build/repositories/) again to verify. The repository should show up underneath the GitHub connection.

## Configure the Infra Pipeline
Run the following commands in the Cloud Shell **(replacing the variables with your configuration)** to configure plan and apply triggers for the Terraform CI/CD pipeline.

The plan trigger will run the Terraform workflow through to plan when a commit is made. The apply trigger will run the full Terraform workflow through to apply as a push-button.

    export GH_CONNECTION="github-connection"
    export GH_REPO="wordpress-on-gcp-free-tier-yourdomain-com"
    export GH_BRANCH_PATTERN="^master$"
    export BUILD_CONFIG_FILE="infra-pipeline.yaml"
    export REGION="us-east1"

    gcloud builds triggers create github \
    --name="github-trigger-infra-plan" \
    --repository=projects/$GOOGLE_CLOUD_PROJECT/locations/${REGION}/connections/${GH_CONNECTION}/repositories/${GH_REPO} \
    --branch-pattern=${GH_BRANCH_PATTERN} \
    --build-config="infra-pipeline.yaml" \
    --region=${REGION} \
    --included-files="terraform/*, infra-pipeline.yaml" \
    --substitutions _TF_STEP=plan

    gcloud builds triggers create github \
    --name="github-trigger-infra-apply" \
    --repository=projects/$GOOGLE_CLOUD_PROJECT/locations/${REGION}/connections/${GH_CONNECTION}/repositories/${GH_REPO} \
    --branch-pattern=${GH_BRANCH_PATTERN} \
    --build-config="infra-pipeline.yaml" \
    --region=${REGION} \
    --ignored-files="**" \
    --substitutions _TF_STEP=apply


## Provision the GCP Infrastructure
If all of the Terraform configuration changes and project-specific terraform.tvfars file has been committed to the GitHub repository, the infrastructure pipeline can be executed by going to the [Cloud Build Triggers page](https://console.cloud.google.com/cloud-build/triggers;region=us-east1) and clicking on the **Run** button in the "-plan" trigger, followed by the "-apply" trigger. Otherwise, committing the latest changes will trigger the pipeline.

The build process can be monitored in the Cloud Console at the [Cloud Build History](https://console.cloud.google.com/cloud-build/builds) page.


## Configure the App Pipeline
After the infrastructure is successfully configured, run the following commands in the Cloud Shell **(replacing the variables with your configuration)** to configure the Cloud Build CI/CD pipeline for the application.


    export GH_CONNECTION="github-connection"
    export GH_REPO="wordpress-on-gcp-free-tier-yourdomain-com"
    export GH_BRANCH_PATTERN="^master$"
    export BUILD_CONFIG_FILE="app-pipeline.yaml"
    export REGION="us-east1"

    export ARTIFACT_REPO="docker-yourdomain-com"
    export RUN_SERVICE="wp-yourdomain-com"

    export RUN_SERVICE_SA="sa-run-service@wp-yourdomain-com.iam.gserviceaccount.com"
    export VPC_NETWORK="network"
    export VPC_SUBNET="subnet"


    gcloud builds triggers create github \
    --name="github-trigger-app" \
    --repository=projects/$GOOGLE_CLOUD_PROJECT/locations/${REGION}/connections/${GH_CONNECTION}/repositories/${GH_REPO} \
    --branch-pattern=${GH_BRANCH_PATTERN} \
    --require-approval \
    --build-config=${BUILD_CONFIG_FILE} \
    --region=${REGION} \
    --included-files="**" \
    --ignored-files="**/*.md,install/variables.conf,diagrams/**,terraform/**" \
    --substitutions _ARTIFACT_REPO=${ARTIFACT_REPO},_REGION=${REGION},_RUN_SERVICE=${RUN_SERVICE},_RUN_SERVICE_SA=${RUN_SERVICE_SA},_VPC_NETWORK=${VPC_NETWORK},_VPC_SUBNET=${VPC_SUBNET}


## Transfer configuration script to the MySQL VM
Run the following commands in the Cloud Shell **(replacing the variables with your configuration)** to copy the **configure_mysql_vm.sh** script out to the MySQL VM, so it can be run there:

    export GH_REPO="wordpress-on-gcp-free-tier-yourdomain-com"
    export MYSQL_VM="mysql-yourdomain-com"
    export ZONE="us-east1-b"

    gcloud compute scp $GH_REPO/install/configure_mysql_vm.sh ${MYSQL_VM}:~ --zone=$ZONE --tunnel-through-iap

This command could fail while the VM creation is propagating across Google Cloud. If it does, try again in a minute.


## MySQL VM Configuration
Run the following commands in the Cloud Shell to SSH into the MySQL VM:

    export MYSQL_VM="mysql-yourdomain-com"
    export ZONE="us-east1-b"

    gcloud compute ssh ${MYSQL_VM} --tunnel-through-iap --zone=$ZONE

Execute the **configure_mysql_vm.sh** script that was copied over:

    bash configure_mysql_vm.sh

This script will allocate a memory swap file on the persistent disk, install the GCP OS Config agent, and start the MariaDB installer. Interaction is required.

**NOTE: Write down the password that you create for the 'root' user!**

After the install completes, run `sudo systemctl status mariadb` to verify that MySQL is active and operational.

Now run `sudo mariadb-secure-installation` to harden the install:
- Press 'Enter' when asked for the current root password
- Enter `2` to decline switching to unix_socket authentication
- Enter `Y` to change the root password
- Enter `Y` to remove anonymous users
- Enter `Y` to disallow root login remotely
- Enter `Y` to remove the test database
- Enter `Y` to reload privilege tables

To perform the Wordpress-specific configuration of the MySQL database, follow [the official Wordpress support directions](https://developer.wordpress.org/advanced-administration/before-install/creating-database/#using-the-mysql-client) (adapted for MariaDB):
- Run `mariadb -u root -p` to log in
- Run `CREATE DATABASE wordpress;` to create the WP database (use whatever value matches your terraform.tfvars)
- Run `CREATE  USER "wordpress"@"%" IDENTIFIED VIA mysql_native_password USING PASSWORD("WordPass1234!");` to create the WP username and password (use whatever values match your variable.conf)
- Run `GRANT ALL PRIVILEGES ON wordpress.* TO "wordpress"@"%";` to assign the permissions (using your WP database name for the first value, and your WP username for the second value)
- Run `FLUSH PRIVILEGES;`
- Run `EXIT`

**Note: Write down the WP database name, username and password!**

Run `sudo sed -i s/127.0.0.1/0.0.0.0/g /etc/mysql/mariadb.conf.d/50-server.cnf` to allow remote connections to the database.

Then run `sudo service mariadb restart` to restart the MySQL service, then `exit` to exit the SSH session with the VM and return to the Cloud Shell session.


## Deploy Wordpress
Forcing an execution of the application pipeline requires a new commit in one of the Wordpress folders. This can be as simple as committing a newline, simply to kickstart the first run of the pipeline.

The build process can be monitored in the Cloud Console at the [Cloud Build History](https://console.cloud.google.com/cloud-build/builds) page.

After the build successfully completes, navigate to [Cloud Run](https://console.cloud.google.com/run). If there's a service with a green check, the deployment was successful. Navigate into the service and click the **run.app** service URL. If you see the Wordpress setup screen, the install process has run successfully and the Wordpress frontend is connecting to the MySQL database!


## Map Your Domain to Cloud Run
Cloud Run supports mapping a custom domain directly to a service, with a fully managed SSL certificate. The directions to complete this process through the Cloud Console are [here](https://cloud.google.com/run/docs/mapping-custom-domains).

If your domain is registered through [Google Domains](https://domains.google/), this setup process is very simple. If not, some additional steps will be required to verify domain ownership that are outside of the scope of these instructions.

Some notes on DNS updates:
- Separate entried are required for [yourdomain.com](https://yourdomain.com) and [www.yourdomain.com](https://www.yourdomain.com) (as a subdomain) in order for both to successfully load
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

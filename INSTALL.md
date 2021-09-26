# Wordpress on GCP Free Tier - Install Guide
This install guide outlines the steps to build, configure, and deploy this solution into a Google Cloud Platform (GCP) project. Previous exposure to GCP and Wordpress are beneficial, but not required.

These instructions will leverage the use of two interfaces into your GCP environment:
- The [Cloud Console](https://cloud.google.com/cloud-console): a web-based admin interface
- The [Cloud Shell](https://cloud.google.com/shell): a Linux terminal command line interface

Provisioning steps are a combination of bash scripts that wrap [Cloud SDK](https://cloud.google.com/sdk/) `gcloud` commands, [Terraform](https://www.terraform.io/) automation through a [Cloud Build](https://cloud.google.com/build) pipeline, and some unavoidable point-and-click steps in the Cloud Console.


## Environment Setup
Log into the Cloud Console at https://console.cloud.google.com/, then activate the Cloud Shell interface.

Clone your private repo into your working Cloud Shell directory. This will require creating a [Personal Access Token](https://github.com/settings/tokens) with OATH scope to "repo" (the first checkbox).

The following commands can be used **(replacing the variables with your configuration)**:

    export GH_USERNAME="your_username"
    export GH_TOKEN="token"
    export GH_REPO="wordpress-on-gcp-free-tier-yourdomain-com"
    export GH_BRANCH="master"

    git clone https://${GH_USERNAME}:${GH_TOKEN}@github.com/${GH_USERNAME}/${GH_REPO}.git -b ${GH_BRANCH}


### Enable the GCP Service APIs that will be used
 Run the following script in the Cloud Shell to enable the required APIs (this is done to avoid Terraform failures because API enablement is eventually consistent):

    bash $GH_REPO/install/enable_gcp_apis.sh


### Elevate permissions for the Cloud Build SA so it can act on behalf of the infra and app pipelines
  Run the following commands in the Cloud Shell to update the IAM permissions:
 
    export PROJECT_NUM=$(gcloud projects list --filter="$GOOGLE_CLOUD_PROJECT" --format="value(PROJECT_NUMBER)")
    gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT --member="serviceAccount:${PROJECT_NUM}@cloudbuild.gserviceaccount.com" --role='roles/owner'


## Install the Cloud Build Github App
In the Cloud Console, follow steps [in this article](https://cloud.google.com/cloud-build/docs/automating-builds/create-github-app-triggers).

**NOTE: Skip the option to create a sample trigger. Only connect the repository**


## Configure the Infra Pipeline
Run the following commands in the Cloud Shell **(replacing the variables with your configuration)** to configure a trigger for the Terraform CI/CD pipeline:

    export GH_USERNAME="username"
    export GH_REPO="wordpress-on-gcp-free-tier-yourdomain-com"
    export GH_BRANCH_PATTERN="^master$"

    gcloud beta builds triggers create github --name="github-trigger-infra" --repo-owner=${GH_USERNAME} --repo-name="${GH_REPO}" --branch-pattern=${GH_BRANCH_PATTERN} --included-files="terraform/*, infra-pipeline.yaml" --build-config="infra-pipeline.yaml"


## Provision the GCP Infrastructure
Forcing an execution of the infrastructure pipeline requires a new commit in one of the Terraform (.tf) files. This can be as simple as committing a newline, simply to kickstart the first run of the pipeline.

The build process can be monitored in the Cloud Console at the [Cloud Build History](https://console.cloud.google.com/cloud-build/builds) page.


## Transfer configuration script to the MySQL VM
Run the following commands in the Cloud Shell **(replacing the variables with your configuration)** to copy the **configure_mysql_vm.sh** script out to the MySQL VM, so it can be run there:

    export MYSQL_VM="mysql-yourdomain-com"
    export ZONE="us-east1-b"

    gcloud compute scp configure_mysql_vm.sh ${MYSQL_VM}:~ --zone=$ZONE --tunnel-through-iap

This command could fail while the VM creation is propagating across Google Cloud. If it does, try again in a minute.


## MySQL VM Configuration
Run the following commands in the Cloud Shell to SSH into the MySQL VM:

    gcloud compute ssh ${MYSQL_VM} --tunnel-through-iap --zone=$ZONE

Execute the **configure_mysql_vm.sh** script that was copied over:

    bash configure_mysql_vm.sh

This script will allocate a memory swap file on the persistent disk, install the GCP OS Config agent, and start the MySQL installer. Interaction is required.

**NOTE: Write down the password that you create for the 'root' user!**

After the install completes, run `sudo systemctl status mysql` to verify that MySQL is active and operational.

Now run `mysql_secure_installation` to harden the install:
- Enter the root password that was set during the install
- Enter `Y` to setup the validate password plugin
- Enter `2` for the password strength level
- Enter `N` to change the root user password at this time
- Enter `Y` for the rest of the prompts

Once this process completes, run `mysqladmin -u root -p version` to further verify that MySQL is functional.

To perform the Wordpress-specific configuration of the MySQL database, follow [the official Wordpress support directions](https://wordpress.org/support/article/creating-database-for-wordpress/#using-the-mysql-client):
- Run `mysql -u root -p` to log in
- Run `CREATE DATABASE wordpress;` to create the WP database (use whatever value matches your terraform.tfvars)
- Run `CREATE USER "wordpress"@"%" IDENTIFIED BY "WordPass1234!";` to create the WP username and password (use whatever values match your variable.conf)
- Run `GRANT ALL PRIVILEGES ON wordpress.* TO "wordpress"@"%";` to assign the permissions (using your WP database name for the first value, and your WP username for the second value)
- Run `FLUSH PRIVILEGES;`
- Run `EXIT`

**Note: Write down the WP database name, username and password!**

Run `sudo service mysql restart` to restart the MySQL service, then `exit` to exit the SSH session with the VM and return to the Cloud Shell session.


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

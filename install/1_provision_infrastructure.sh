#!/bin/sh

# Load config values
echo "Loading variables..."
source ./variables.conf

# Set the gcloud context
gcloud config set project $PROJECT_ID

# Enable Google Cloud Service APIs
echo "Enabling Google APIs..."
gcloud services enable compute.googleapis.com
gcloud services enable run.googleapis.com
# Serverless VPC access for internal-only MySQL connectivity
#gcloud services enable vpcaccess.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable osconfig.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable containeranalysis.googleapis.com

# Create GCS Bucket
echo "Creating GCS bucket for media..."
if ! [ $(gsutil ls -b gs://$MEDIA_BUCKET/) ]
then
    echo "Bucket gs://$MEDIA_BUCKET/ doesn't exist. Creating..."
    gsutil mb -b off -c standard -l $REGION gs://$MEDIA_BUCKET
    gsutil acl ch -u AllUsers:R gs://$MEDIA_BUCKET
else
    echo "Bucket gs://$MEDIA_BUCKET/ exists (not unique); exiting..."
    exit 0
fi

# Create Artifact Registry Docker Repository
echo "Creating Artifact Registry Docker repository..."
gcloud artifacts repositories create $ARTIFACT_REPO --repository-format=docker --location=$REGION --description="Docker Repository"

# Create network stack
echo "Creating network resources..."
gcloud compute networks create network --subnet-mode=custom --bgp-routing-mode=global
gcloud compute networks subnets create subnet --network=network --range=192.168.1.0/28 --region=$REGION --enable-private-ip-google-access
# Router / NAT for internal IP connectivity to MySQL
#gcloud compute routers create router --network=network --region=$REGION
#gcloud compute routers nats create nat --router=router --region=$REGION --auto-allocate-nat-external-ips --nat-all-subnet-ip-ranges
gcloud compute firewall-rules create allow-ssh-ingress-from-iap --network=network --direction=INGRESS --action=allow --rules=tcp:22 --source-ranges=35.235.240.0/20 --enable-logging
# Create a firewall rule to allow connectivity to MySQL server
gcloud compute firewall-rules create allow-mysql-ingress-all --network=network --direction=INGRESS --action=allow --rules=tcp:3306 --source-ranges=0.0.0.0/0 --enable-logging
# Serverless VPC connector for internal IP connectivity to MySQL
#gcloud compute networks vpc-access connectors create serverless-connect --network=network --region=$REGION --range=192.168.10.0/28
# Reserve a static external IP
gcloud compute addresses create ${MYSQL_VM} --network-tier=PREMIUM --region=$REGION

# Create compute stack
echo "Creating compute resources..."
gcloud compute resource-policies create snapshot-schedule ${MYSQL_VM}-backup --max-retention-days=3 --start-time=04:00 --daily-schedule --region=$REGION --storage-location=$REGION
# Without external IP
#gcloud compute instances create ${MYSQL_VM} --zone=$ZONE --machine-type=f1-micro --image-project=debian-cloud --image-family=debian-10 --boot-disk-type=pd-standard --boot-disk-size=30GB --no-boot-disk-auto-delete --network=network --subnet=subnet --no-address
# With external IP
gcloud compute instances create ${MYSQL_VM} --zone=$ZONE --machine-type=f1-micro --image-project=debian-cloud --image-family=debian-10 --boot-disk-type=pd-standard --boot-disk-size=30GB --no-boot-disk-auto-delete --network=network --subnet=subnet --tags=mysql --address=${MYSQL_VM}
gcloud compute disks add-resource-policies ${MYSQL_VM} --resource-policies=${MYSQL_VM}-backup --zone=$ZONE

# Enable OS Patch Management
echo "Enabling OS patch management..."
gcloud compute project-info add-metadata --project ${PROJECT_ID} --metadata=enable-guest-attributes=TRUE,enable-osconfig=TRUE

# Update variables.conf with the external IP address
echo "Writing the external IP address to variables.conf..."
export EXTERNAL_IP=$(gcloud compute addresses describe ${MYSQL_VM} --region=$REGION --format="value(address)")
sed -i $"s/127.0.0.1/$EXTERNAL_IP/g" variables.conf
echo "Done - commit and push the new variables.conf file back to the repo before continuing"
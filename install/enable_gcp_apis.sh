#!/bin/sh

echo "Enabling GCP APIs..."
gcloud services enable cloudbuild.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable osconfig.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable containeranalysis.googleapis.com
gcloud services enable secretmanager.googleapis.com
gcloud services enable iam.googleapis.com
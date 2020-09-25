#!/bin/sh

# Load config values
echo "Loading variables..."
source ./variables.conf

export PROJECT_NUM=$(gcloud projects list --filter="$PROJECT_ID" --format="value(PROJECT_NUMBER)")
echo $PROJECT_NUM

gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:${PROJECT_NUM}@cloudbuild.gserviceaccount.com" --role='roles/run.admin'
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:${PROJECT_NUM}@cloudbuild.gserviceaccount.com" --role='roles/iam.serviceAccountUser'

gcloud beta builds triggers create github --name="github-trigger" --repo-owner=${GH_USERNAME} --repo-name="${GH_REPO}" --branch-pattern="^master$" --included-files="**" --ignored-files="**/*.md, install/variables.conf, diagrams/**" --build-config="cicd-pipeline.yaml" --substitutions _REGION=${REGION},_ZONE=${ZONE},_MYSQL_VM=${MYSQL_VM},_RUN_SERVICE=${RUN_SERVICE},_WORDPRESS_TABLE_PREFIX=${WORDPRESS_TABLE_PREFIX},_WORDPRESS_DB_NAME=${WORDPRESS_DB_NAME},_WORDPRESS_DB_USER=${WORDPRESS_DB_USER},_WORDPRESS_DB_PASSWORD=${WORDPRESS_DB_PASSWORD}
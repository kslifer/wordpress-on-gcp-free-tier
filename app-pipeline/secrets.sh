#!/bin/sh

# failsafe
set -eEuo pipefail

# Create the directory in the build context
mkdir -p ./run/secrets

# Generate the Docker Secret files
echo $(cat ./WORDPRESS_TABLE_PREFIX) > ./run/secrets/WORDPRESS_TABLE_PREFIX
echo $(cat ./WORDPRESS_DB_NAME) > ./run/secrets/WORDPRESS_DB_NAME
echo $(cat ./WORDPRESS_DB_USER) > ./run/secrets/WORDPRESS_DB_USER
echo $(cat ./WORDPRESS_DB_PASSWORD) > ./run/secrets/WORDPRESS_DB_PASSWORD
echo $(cat ./MYSQL_VM_EXT_IP) > ./run/secrets/MYSQL_VM_EXT_IP

pwd
ls -l
cd ./run/secrets
ls -l
echo $(cat WORDPRESS_TABLE_PREFIX)
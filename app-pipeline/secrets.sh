#!/bin/sh

# failsafe
set -eEuo pipefail

# Load config values
# echo "Loading variables..."
# source ./install/variables.conf
pwd
# Echo substitution variables
#echo $WORDPRESS_TABLE_PREFIX
#echo $WORDPRESS_DB_NAME
#echo $WORDPRESS_DB_USER
#echo $WORDPRESS_DB_PASSWORD
#echo $MYSQL_VM_EXT_IP
cat ./WORDPRESS_TABLE_PREFIX
cat ./WORDPRESS_DB_NAME
cat ./WORDPRESS_DB_USER
cat ./WORDPRESS_DB_PASSWORD
cat ./MYSQL_VM_EXT_IP

# Create the directory in the build context
mkdir -p ./run/secrets

# Generate the Docker Secret files
#echo $WORDPRESS_TABLE_PREFIX > run/secrets/WORDPRESS_TABLE_PREFIX
#echo $WORDPRESS_DB_NAME > run/secrets/WORDPRESS_DB_NAME
#echo $WORDPRESS_DB_USER > run/secrets/WORDPRESS_DB_USER
#echo $WORDPRESS_DB_PASSWORD > run/secrets/WORDPRESS_DB_PASSWORD
#echo $MYSQL_VM_EXT_IP > run/secrets/WORDPRESS_DB_HOST

echo $(cat ./WORDPRESS_TABLE_PREFIX) > run/secrets/WORDPRESS_TABLE_PREFIX
echo $(cat ./WORDPRESS_DB_NAME) > run/secrets/WORDPRESS_DB_NAME
echo $(cat ./WORDPRESS_DB_USER) > run/secrets/WORDPRESS_DB_USER
echo $(cat ./WORDPRESS_DB_PASSWORD) > run/secrets/WORDPRESS_DB_PASSWORD
echo $(cat ./MYSQL_VM_EXT_IP) > run/secrets/MYSQL_VM_EXT_IP
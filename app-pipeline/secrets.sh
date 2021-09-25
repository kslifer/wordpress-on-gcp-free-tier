#!/bin/sh

# failsafe
set -eEuo pipefail

# Load config values
echo "Loading variables..."
source ./install/variables.conf

# Create the directory in the build context
mkdir -p ./run/secrets

# Generate the Docker Secret files
echo $WORDPRESS_TABLE_PREFIX > run/secrets/WORDPRESS_TABLE_PREFIX
echo $WORDPRESS_DB_NAME > run/secrets/WORDPRESS_DB_NAME
echo $WORDPRESS_DB_USER > run/secrets/WORDPRESS_DB_USER
echo $WORDPRESS_DB_PASSWORD > run/secrets/WORDPRESS_DB_PASSWORD
echo $MYSQL_VM_EXT_IP > run/secrets/WORDPRESS_DB_HOST
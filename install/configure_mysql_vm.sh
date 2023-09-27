#!/bin/sh

echo "Allocating a memory swap file..."
sudo fallocate -l 1G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

sudo apt update
sudo apt -y upgrade

echo "Starting GCP Cloud Ops Agent install process..."
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install

echo "Starting MariaDB install process..."
sudo apt -y install mariadb-server

echo "Applying post-MariaDB install configuration changes..."
sudo sed -i s/127.0.0.1/0.0.0.0/g /etc/mysql/mariadb.conf.d/50-server.cnf
sudo sed -i s/#skip-name-resolve/skip-name-resolve=on/g /etc/mysql/mariadb.conf.d/50-server.cnf
sudo service mariadb restart
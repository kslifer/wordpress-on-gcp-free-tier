#!/bin/sh

echo "Allocating a memory swap file..."
sudo fallocate -l 1G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

echo "Starting GCP OS Agent install process..."
sudo apt update
sudo apt -y upgrade
sudo apt -y install google-osconfig-agent
sudo su -c "echo 'deb http://packages.cloud.google.com/apt \
google-compute-engine-buster-stable main'> /etc/apt/sources.list.d/google-compute-engine.list"
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
sudo apt-key add -

echo "Starting MySQL install process..."
sudo apt update
sudo apt -y upgrade
sudo apt -y install gnupg
sudo apt -y install wget
cd /tmp
wget https://dev.mysql.com/get/mysql-apt-config_0.8.19-1_all.deb
sudo dpkg -i mysql-apt-config*
sudo apt update
sudo apt -y install mysql-server
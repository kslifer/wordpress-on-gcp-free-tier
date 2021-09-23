#!/bin/sh

# install wget
apt-get update
apt-get install -y wget

# download zip files from download.txt in the same directory
wget -i download.txt
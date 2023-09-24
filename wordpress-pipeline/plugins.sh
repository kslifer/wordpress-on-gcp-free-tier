#!/bin/sh

# failsafe
set -eEuo pipefail

# copy and run the download script
cp ./wordpress-pipeline/download.sh ./wordpress-plugins
cd wordpress-plugins
chmod +x download.sh
./download.sh
cd ..

# remove default plugins
rm -r ./wordpress-core/wordpress/wp-content/plugins/*

# unpack custom plugins
apt-get update
apt-get install -y unzip
cd wordpress-plugins
for zip in *.zip
do
    dirname=`echo $zip | sed 's/\.zip$//'`
    if mkdir "$dirname-temp"
    then
    if cd "$dirname-temp"
    then
        unzip ../"$zip"
        mv * ..
        cd ..
        rm -f $zip
        rm -d "$dirname-temp"
    else
        echo "Could not unpack $zip - cd failed"
        exit 0
    fi
    else
    echo "Could not unpack $zip - mkdir failed"
    exit 0
    fi
done
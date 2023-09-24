#!/bin/sh

# failsafe
set -eEuo pipefail

# copy and run the download script
cp ./wordpress-pipeline/download.sh ./wordpress-themes
cd wordpress-themes
chmod +x download.sh
./download.sh
cd ..

# remove default themes
rm -r ./wordpress-core/wordpress/wp-content/themes/*

# unpack custom themes
apt-get update
apt-get install -y unzip
cd wordpress-themes
for zip in *.zip
do
    dirname=`echo $zip | sed 's/\.zip$//'`
    if mkdir "$dirname-temp"
    then
    if cd "$dirname-temp"
    then
        unzip ../"$zip"
        # Remove '__MACOSX' directory
        rm -rf ./__MACOSX
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

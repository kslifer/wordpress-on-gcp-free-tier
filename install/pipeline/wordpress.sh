#!/bin/sh

# failsafe
set -eEuo pipefail

# unpack wordpress
apt-get update
apt-get install -y unzip
cd wordpress-core
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
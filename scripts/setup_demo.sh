#!/bin/bash 
set -e

# check if the target directory exists and throw error if it does
if [ -d "/data/DemoData" ]; then
    echo "Demo directory (at /data/DemoData) already exists. Please remove it before re-running this script."
    exit 1
fi

# copy the demo data from the raw directory to the target directory
cp -R /demo /data/DemoData

echo "Demo data has been successfully copied to /data/DemoData."
exit 0
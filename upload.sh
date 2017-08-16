#!/bin/bash

source conf.sh

if [ $# -lt 1 ]; then
    echo "Usage: `basename $0` {file}" 1>&2
    exit 255
fi

file=$1
PID=$$
echo "Starting upload of file [${file}] with username [${REGISTRY_USERNAME}]"
echo "---------------------------"
curl -o /tmp/upload-${PID} -X POST -H "Content-Type: multipart/form-data" -F "fname=@${file}" -F "scripted=1" https://${REGISTRY_USERNAME}:${REGISTRY_PASSWORD}@opdebug.coscale.com:8443/
echo "---------------------------"
cat /tmp/upload-${PID}
echo "---------------------------"
rm /tmp/upload-${PID}
echo "Done."


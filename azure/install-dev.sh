#!/bin/bash

KEY=$1
EMAIL=$2
PASSWORD=$3
DNS=$4

# Change directory to cop

cd $(dirname $(readlink -f $0))/..

# Fill in the configuration

REGUSER=`echo $KEY | awk -F: '{ print $1; }'`
REGPASSWD=`echo $KEY | awk -F: '{ print $2; }'`

sed -i "s|REGISTRY_USERNAME=.*|REGISTRY_USERNAME=$REGUSER|" conf.sh
sed -i "s|REGISTRY_PASSWORD=.*|REGISTRY_PASSWORD=$REGPASSWD|" conf.sh

sed -i "s|API_URL=.*|API_URL=http://$DNS|" conf.sh
sed -i "s|APP_URL=.*|APP_URL=http://$DNS|" conf.sh

sed -i "s|API_SUPER_USER=.*|API_SUPER_USER=$EMAIL|" conf.sh
sed -i "s|API_SUPER_PASSWD=.*|API_SUPER_PASSWD=$PASSWORD|" conf.sh

# Store the data on the data disk

sed -i "s|data/cassandra|/data/cassandra|" volumes/cassandra
sed -i "s|data/elasticsearch|/data/elasticsearch|" volumes/elasticsearch
sed -i "s|data/postgresql|/data/postgresql|" volumes/postgresql

mkdir -p /data/cassandra /data/elasticsearch /data/postgresql

./pull.sh
./run.sh

# Start CoScale on reboot

cat << EOF > /etc/systemd/system/coscale.service
[Unit]
Description=CoScale
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
WorkingDirectory=/home/cs/cop
ExecStartPre=/home/cs/cop/stop.sh
ExecStart=/home/cs/cop/run.sh

[Install]
WantedBy=default.target
EOF

systemctl enable coscale.service

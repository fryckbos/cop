#!/bin/bash

source custom-settings.sh

if [ $# -ne 2 ]; then
    echo "$0: usage: <fqdn> <DEST>"
    exit 1
fi

fqdn=$1
DEST=$2

#you can put this inside the block
# debug yes

cat << EOF | nsupdate
server ${DNS1}
update delete $fqdn CNAME
update add $fqdn 86400 CNAME $DEST
send
EOF


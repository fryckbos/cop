#!/bin/bash

source host.conf

if [ $# -ne 2 ]; then
    echo "$0: usage: <fqdn> <ip>"
    exit 1
fi

fqdn=$1
ip=$2

#you can put this inside the block
# debug yes

cat << EOF | nsupdate
server ${DNS1}
update delete $fqdn A
update add $fqdn 86400 A $ip
send
EOF


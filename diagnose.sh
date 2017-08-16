#!/bin/bash

# Change working directory
cd `dirname $0`

# Load configuration and services
source conf.sh
source services.sh

function usage {
    echo "$0 <action> ..."
    echo ""
    echo "Actions"
    echo "    check-containers: check whether all containers are running"
    echo "    htop: execute htop for the machine"
    echo "    log-dump: create a log dump for the last 24 hours for all services in logs.tgz"
    echo "    backup: create a PostgreSQL backup in backup.tgz"
    exit 0
}

function check_containers {
    UP=1
    CONTAINERS_DOWN=""

    for SERVICE in $DATA_SERVICES $COSCALE_SERVICES $LB_SERVICE; do
        OUTPUT=`docker inspect -f {{.State.Running}} coscale_$SERVICE 2>/dev/null`
        if [ "$?" == "1" -o "$OUTPUT" == "false" ]; then
            UP=0
            CONTAINERS_DOWN="$SERVICE $CONTAINERS_DOWN"
        fi
    done

    if [ "$UP" == "1" ]; then
        echo "All containers are running."
        exit 0
    else
        echo "The following containers are down: $CONTAINERS_DOWN"
        exit 1
    fi
}

function do_htop {
    if [ "$1" == "upload" ]; then
        docker run --pid=host -it coscale/diag ./htop.sh > htop.html
        upload "htop" "htop.html" rm
        rm htop.html
    else
        docker run --pid=host -it coscale/diag htop
    fi
}

function get_logs {
    HOURS=$1
    MINUTES=$(($HOURS * 60))
    echo "Gathering logs for $HOURS hours..."

    mkdir -p logs

    for SERVICE in $COSCALE_SERVICES; do
        echo "  Processing $SERVICE"
        DIR=/var/log/$SERVICE
        ./connect.sh $SERVICE 'if [ -e '"$DIR"' ]; then cd '"$DIR"'; tar czf /logs.tgz `find . -cmin -'"$MINUTES"'`; else exit 1; fi'
        if [ "$?" -eq "0" ]; then
            docker cp coscale_$SERVICE:/logs.tgz logs/${SERVICE}-logs.tgz
            ./connect.sh $SERVICE "rm /logs.tgz"
        fi
    done

    tar czf logs.tgz logs
    rm -Rf logs
    echo "Done gathering"

    if [ "$2" == "upload" ]; then
        upload "logs" "logs.tgz" rm
    fi
}

function do_backup {
    echo "Creating database backup..."
    ./connect.sh postgresql 'sudo -u postgres pg_dump global' > global.sql
    ./connect.sh postgresql 'sudo -u postgres pg_dump app' > app.sql
    tar czf backup.tgz global.sql app.sql
    rm global.sql app.sql
    echo "Your backup is ready in backup.tgz"

    if [ "$1" == "upload" ]; then
        upload "backup" "backup.tgz" rm
    fi
}

function upload {
    echo
    echo "Uploading $1..."
    ./upload.sh $2
    if [ "$3" == "rm" ]; then rm $2; fi
    echo "Done uploading"
}

ACTION=${1:-help}

if [ "$ACTION" == "check-containers" ]; then
    check_containers
elif [ "$ACTION" == "htop" ]; then
    if [ "$2" == "-u" ]; then UPLOAD="upload"; else UPLOAD=""; fi
    do_htop $UPLOAD
elif [ "$ACTION" == "log-dump" ]; then
    if [ "$2" == "-u" ]; then shift; UPLOAD="upload"; else UPLOAD=""; fi
    HOURS=${2:-24}
    get_logs $HOURS $UPLOAD
elif [ "$ACTION" == "backup" ]; then
    if [ "$2" == "-u" ]; then UPLOAD="upload"; else UPLOAD=""; fi
    do_backup $UPLOAD
else
    usage
fi

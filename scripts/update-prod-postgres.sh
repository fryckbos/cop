#/bin/bash -e
DIR=/tmp/prod-pg-dump
rm -rf $DIR
mkdir -p $DIR
DATE=`date +%Y%m%d`
BACKUPHOST=root@infra002.coscale.com

echo "Downloading latest production postgres dump ..."
rsync -vrP ${BACKUPHOST}:/opt/coscale/backup/postgresql/${DATE}* $DIR

echo "Extracting ..."
tar xvf $DIR/*

echo "Replacing smappli -> coscale in global.sql ..."
sed -i 's/smappli/coscale/g' global.sql
echo "Replacing smappli -> coscale in app.sql ..."
sed -i 's/smappli/coscale/g' app.sql

./stop.sh api

./connect.sh postgresql "sudo -u postgres psql -c 'DROP DATABASE app;'" && \
./connect.sh postgresql "sudo -u postgres psql -c 'DROP DATABASE global;'" && \
./connect.sh postgresql "sudo -u postgres psql -c 'CREATE DATABASE app WITH OWNER coscale;'" && \
./connect.sh postgresql "sudo -u postgres psql -c 'CREATE DATABASE global WITH OWNER coscale;'" && \
./connect.sh postgresql "sudo -u postgres psql -d app -c 'ALTER SCHEMA public OWNER TO coscale;'" && \
./connect.sh postgresql "sudo -u postgres psql -d global -c 'ALTER SCHEMA public OWNER TO coscale;'" && \
docker exec -i coscale_postgresql /bin/bash -c "PGPASSWORD=coscale psql -h localhost -U coscale -d app" < app.sql && \
docker exec -i coscale_postgresql /bin/bash -c "PGPASSWORD=coscale psql -h localhost -U coscale -d global" < global.sql

./run.sh api


./connect.sh kafka kafka-consumer-groups --bootstrap-server localhost:9092 --reset-offsets --to-latest --execute --all-topics --group $1

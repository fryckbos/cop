./connect.sh kafka JMX_PORT=1234 /root/kafka/bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --reset-offsets --to-latest --all-topics --group $1

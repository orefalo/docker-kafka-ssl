#!/bin/bash
echo "test 1" | kafka-console-producer --broker-list localhost:9094 --topic test --producer.config ./client_ssl.properties

#kafka-console-producer.sh --broker-list localhost:9093 --topic test --producer.config client-ssl.properties
#kafka-console-consumer.sh --bootstrap-server localhost:9093 --topic test --consumer.config client-ssl.properties

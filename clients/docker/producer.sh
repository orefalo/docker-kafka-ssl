#!/bin/bash

echo "test docker" | docker exec --interactive dockerkafkassl_kafka_1 /opt/kafka/bin/kafka-console-producer.sh --broker-list kafka.docker.ssl:9094 --topic test --producer.config /certs/client_ssl.properties

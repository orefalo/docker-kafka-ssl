#!/bin/bash
#echo "test 1" | kafka-console-producer --broker-list localhost:9094 --topic test --producer.config ./client_ssl.properties

#echo "test msg" | docker exec --interactive dockerkafkassl_kafka_1 /opt/kafka/bin/kafka-console-producer.sh --broker-list localhost:9094 --topic test --producer.config /certs/client_ssl.properties
echo "test msg" | docker exec --interactive dockerkafkassl_kafka_1 /opt/kafka/bin/kafka-console-producer.sh --broker-list kafka.docker.ssl:9094 --topic test --producer.config /certs/client_ssl.properties


#kafka-console-producer.sh --broker-list localhost:9093 --topic test --producer.config client-ssl.properties
#kafka-console-consumer.sh --bootstrap-server localhost:9093 --topic test --consumer.config client-ssl.properties
#echo "echo This is how we pipe to docker exec" | sudo docker exec --interactive CONTAINER_NAME /bin/bash - 
#bash -c "clear && docker exec -it dockerkafkassl_kafka_1 sh"
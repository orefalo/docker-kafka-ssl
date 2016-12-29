# docker-kafka-ssl

Playing with SSL enabeled Kafka in Docker.

## Requirements

* openssl
* keytool
* docker
* docker-compose

## Instructions

Generate the required certificates and keystores:

    ./generate-docker-kafka-ssl-certs.sh
    
Run Kafka and Zookeeper

    docker-compose up

Verify the SSL connection

    openssl s_client -debug -connect localhost:9093 -tls1

NOTE: This currently fails to verify the handshake.
    
Put some messages into Kafka    
    
    echo "Something" | kafkacat -P -b 127.0.0.1:9092 -t test -X security.protocol=ssl -X ssl.key.location=./certs/docker.kafka.server.keystore.pem

## References

* http://docs.confluent.io/2.0.0/kafka/ssl.html#configuring-kafka-brokers
* https://www.confluent.io/blog/apache-kafka-security-authorization-authentication-encryption/
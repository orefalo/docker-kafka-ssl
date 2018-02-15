# docker-kafka-ssl

Enables 2 ways SSL communication on Kafka.

Certificates are selfsigned with a master CA, one for the broker, the other for the client.

## Requirements

* openssl
* keytool
* docker
* docker-compose

## Instructions

add to your /etc/hosts

    127.0.0.1 kafka.docker.ssl

Generate the required certificates and keystores:

    ./generate-docker-kafka-ssl-certs.sh
    
Run Kafka and Zookeeper

    docker-compose up

Verify the SSL connection

    openssl s_client -debug -connect localhost:9093 -tls1

In the output of this command you should see server's certificate, such as:

```
-----BEGIN CERTIFICATE-----
{variable sized random bytes}
-----END CERTIFICATE-----
subject=/C=US/ST=CA/L=Santa Clara/O=org/OU=org/CN=Sriharsha Chintalapani
issuer=/C=US/ST=CA/L=Santa Clara/O=org/OU=org/CN=kafka/emailAddress=test@test.com
```


    
Put some messages into Kafka    
    
    echo "Something" | kafkacat -P -b 127.0.0.1:9092 -t test -X security.protocol=ssl -X ssl.key.location=./certs/docker.kafka.server.keystore.pem

# docker-kafka-ssl

Enables 2 ways SSL communication on Kafka.

Note that Kafka only support 2 ways SSL with a **SINGLE CA ROOT**,

Port 9094 is 2 ways SSL client authenticated and encrypted.

## Requirements

* openssl
* keytool
* docker
* docker-compose

## Setup Instructions

add to your /etc/hosts

    127.0.0.1 kafka.docker.ssl

Generate the required certificates and keystores:

    ./generate-docker-kafka-ssl-certs.sh
    
Run Kafka and Zookeeper

    docker-compose up

Verify the SSL connection

    openssl s_client -debug -connect kafka.docker.ssl:9094 -tls1

In the output of this command you should see server's certificate, such as:

```
-----BEGIN CERTIFICATE-----
{variable sized random bytes}
-----END CERTIFICATE-----
subject=/C=US/ST=CA/L=Santa Clara/O=org/OU=org/CN=Sriharsha Chintalapani
issuer=/C=US/ST=CA/L=Santa Clara/O=org/OU=org/CN=kafka/emailAddress=test@test.com
```

## Generte some messages
    
Pick the client of your choice

### Local

```
cd clients/local  
./local_producer.sh
```

### docker

```
cd clients/docker  
./producer.sh
```

### node

```
cd clients/node
npm i  
node index.js
```

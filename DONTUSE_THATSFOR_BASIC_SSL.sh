#!/bin/bash
# References:
# http://docs.confluent.io/2.0.0/kafka/ssl.html
# http://stackoverflow.com/questions/2846828/converting-jks-to-p12

PASSWORD="kafkadocker"
SERVER_KEYSTORE_JKS="docker.kafka.server.keystore.jks"
SERVER_KEYSTORE_P12="docker.kafka.server.keystore.p12"
SERVER_KEYSTORE_PEM="docker.kafka.server.keystore.pem"
SERVER_TRUSTSTORE_JKS="docker.kafka.server.truststore.jks"
CLIENT_TRUSTSTORE_JKS="docker.kafka.client.truststore.jks"
VALIDITY=1825

echo "Clearing existing Kafka SSL certs..."
rm -rf certs
mkdir certs

(
echo "Generating new Kafka SSL certs..."
cd certs


# Generate SSL key and certificate for each Kafka broker
keytool -keystore $SERVER_KEYSTORE_JKS -alias localhost -validity $VALIDITY -genkey -storepass $PASSWORD -keypass $PASSWORD \
  -dname "OU=None, O=None, L=Miami, S=FL, C=USA"

# Generate my own CA (to sign certificates)
openssl req -new -x509 -keyout ca-key -out ca-cert -days $VALIDITY -passout pass:$PASSWORD \
   -subj "/C=UK/S=FL/L=Miami/O=None/OU=None"

# Import the CA in client & server trust stores
keytool -keystore $SERVER_TRUSTSTORE_JKS -alias CARoot -import -file ca-cert -storepass $PASSWORD -noprompt
keytool -keystore $CLIENT_TRUSTSTORE_JKS -alias CARoot -import -file ca-cert -storepass $PASSWORD -noprompt

# Now.. Sign the certificate with the CA
# For this, we first need to export the cert (from previous step) on file system
keytool -keystore $SERVER_KEYSTORE_JKS -alias localhost -certreq -file cert-file -storepass $PASSWORD -noprompt
# sign it
openssl x509 -req -CA ca-cert -CAkey ca-key -in cert-file -out cert-signed -days $VALIDITY -CAcreateserial -passin pass:$PASSWORD
# Finally, you need to import both the certificate of the CA and the signed certificate into the keystore
keytool -keystore $SERVER_KEYSTORE_JKS -alias CARoot -import -file ca-cert -storepass $PASSWORD -noprompt
keytool -keystore $SERVER_KEYSTORE_JKS -alias localhost -import -file cert-signed -storepass $PASSWORD -noprompt

#keytool -importkeystore -srckeystore $SERVER_KEYSTORE_JKS -destkeystore $SERVER_KEYSTORE_P12 -srcstoretype JKS -deststoretype PKCS12 -srcstorepass $PASSWORD -deststorepass $PASSWORD -noprompt
# PEM for KafkaCat -P12 to PEM
#openssl pkcs12 -in $SERVER_KEYSTORE_P12 -out $SERVER_KEYSTORE_PEM -nodes -passin pass:$PASSWORD

chmod 700 *
)

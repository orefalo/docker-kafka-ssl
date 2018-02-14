#!/bin/bash
# References:
# http://docs.confluent.io/2.0.0/kafka/ssl.html
# 

PASSWORD="kafkadocker"
CLIENT_KEYSTORE_JKS="docker.kafka.client.keystore.jks"
SERVER_KEYSTORE_JKS="docker.kafka.server.keystore.jks"
SERVER_TRUSTSTORE_JKS="docker.kafka.server.truststore.jks"
CLIENT_TRUSTSTORE_JKS="docker.kafka.client.truststore.jks"
VALIDITY=1825

echo "Clearing existing Kafka SSL certs..."
rm -rf certs
mkdir certs

(

cd certs

echo "Generating cert & key for the kafka broken..."
keytool -keystore $SERVER_KEYSTORE_JKS -alias localhost -validity $VALIDITY -genkey -storepass $PASSWORD -keypass $PASSWORD  -dname "OU=None, O=None, L=Miami, S=FL, C=USA"

echo "Generate a top level CA to stamp certificates"
openssl req -new -x509 -keyout ca-key -out ca-cert -days $VALIDITY -passout pass:$PASSWORD -subj "/C=USA/S=FL/L=Miami/O=None/OU=None"

echo "Import the CA in client & server trust stores"
keytool -keystore $SERVER_TRUSTSTORE_JKS -alias CARoot -import -file ca-cert -storepass $PASSWORD -noprompt
keytool -keystore $CLIENT_TRUSTSTORE_JKS -alias CARoot -import -file ca-cert -storepass $PASSWORD -noprompt

# Now.. Sign the certificate with the CA
# For this, we first need to export the cert (from previous step) on file system
echo "Sign broker certificate with CA"
keytool -keystore $SERVER_KEYSTORE_JKS -alias localhost -certreq -file cert-file -storepass $PASSWORD -noprompt
# Sign it
openssl x509 -req -CA ca-cert -CAkey ca-key -in cert-file -out cert-signed -days $VALIDITY -CAcreateserial -passin pass:$PASSWORD
# Finally, you need to import both the certificate of the CA and the signed certificate into the keystore
echo "Import Signed Cert into broker keystore"
keytool -keystore $SERVER_KEYSTORE_JKS -alias CARoot -import -file ca-cert -storepass $PASSWORD -noprompt
keytool -keystore $SERVER_KEYSTORE_JKS -alias localhost -import -file cert-signed -storepass $PASSWORD -noprompt

echo "Now generate the client cert & key"
keytool -keystore $CLIENT_KEYSTORE_JKS -alias localhost -validity $VALIDITY -genkey -storepass $PASSWORD -dname "OU=Qv, O=Qv, L=Miami, S=FL, C=USA"
echo "1"
keytool -keystore $CLIENT_KEYSTORE_JKS -alias localhost -certreq -file cert-file -storepass $PASSWORD -noprompt
echo "2"
openssl x509 -req -CA ca-cert -CAkey ca-key -in cert-file -out cert-signed -days $VALIDITY -CAcreateserial -passin pass:$PASSWORD
echo "3"
keytool -keystore $CLIENT_KEYSTORE_JKS -alias CARoot -import -file ca-cert -storepass $PASSWORD -noprompt
echo "4"
keytool -keystore $CLIENT_KEYSTORE_JKS -alias localhost -import -file cert-signed -storepass $PASSWORD -noprompt

chmod 700 *
)

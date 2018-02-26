#!/bin/bash
#
# 2 ways SSL generation
#
# References:
# http://docs.confluent.io/2.0.0/kafka/ssl.html
# 
GREEN='\033[0;32m'
NC='\033[0m' # No Color


PASSWORD="kafkadocker"
CLIENT_KEYSTORE_JKS="docker.kafka.client.keystore.jks"
SERVER_KEYSTORE_JKS="docker.kafka.server.keystore.jks"
SERVER_TRUSTSTORE_JKS="docker.kafka.server.truststore.jks"
CLIENT_TRUSTSTORE_JKS="docker.kafka.client.truststore.jks"
VALIDITY=1825

CLIENT_HOSTNAME="localhost"
SERVER_HOSTNAME="kafka.docker.ssl"

SERVER_CA_CERT="ca-hw-cert"
SERVER_CA_KEY="ca-hw-key"

CLIENT_CA_CERT="ca-qv-cert"
CLIENT_CA_KEY="ca-qv-key"


echo "Clearing existing Kafka SSL certs..."
rm -rf certs
mkdir certs

(

cd certs

# IMPORTANT: Kafka 2 way SSL only works with ONE CA ROOT!!

echo -e "${GREEN}Generating cert & key for the kafka Server...${NC}"
keytool -keystore $SERVER_KEYSTORE_JKS -alias server -validity $VALIDITY -genkey -storepass $PASSWORD -keypass $PASSWORD  -dname "CN=$SERVER_HOSTNAME, OU=None, O=Hw, L=Miami, S=Miami, C=US"

echo -e "${GREEN}Generating cert & key for the kafka Client...${NC}"
keytool -keystore $CLIENT_KEYSTORE_JKS -alias client -validity $VALIDITY -genkey -storepass $PASSWORD -keypass $PASSWORD  -dname "CN=$CLIENT_HOSTNAME, OU=None, O=Qv, L=Miami, S=Miami, C=US"

echo -e "${GREEN}Generate a top level server CA to stamp client certificates${NC}"
openssl req -new -x509 -keyout ca-hw-key -out ca-hw-cert -days $VALIDITY -passout pass:$PASSWORD -subj "/C=US/S=Miami/L=Miami/O=Hw/OU=None/CN=$SERVER_HOSTNAME"

echo -e "${GREEN}Generate a top level client CA to stamp server certificates${NC}"
openssl req -new -x509 -keyout ca-qv-key -out ca-qv-cert -days $VALIDITY -passout pass:$PASSWORD -subj "/C=US/S=Miami/L=Miami/O=Qv/OU=None/CN=$CLIENT_HOSTNAME"

echo -e "${GREEN}Import the CA in their respective trust stores${NC}"
keytool -keystore $SERVER_TRUSTSTORE_JKS -alias CARoot -import -file ca-qv-cert -storepass $PASSWORD -noprompt
keytool -keystore $CLIENT_TRUSTSTORE_JKS -alias CARoot -import -file ca-hw-cert -storepass $PASSWORD -noprompt

# At this point we have two jks TrustStore
#  hw server trust store contains CA ROOT ca-qv-cert
#  qv client trust store contains CA ROOT ca-hw-cert
# 
#  We also have match private keys for each in the local folder: ca-hw-key & ca-qv-key
# Last but not least, we have two ClientStore, with unsigned keys
#  hw server client store contains an unsigned key called "server"
#  qv server client store contains an unsigned key called "client"

# Now.. we need to sign each clients cert with the other companie's CA

# For this, we first need to export the cert for each client on file system
echo -e "${GREEN}Sign Server with Client CA${NC}"
rm cert-file
keytool -keystore $SERVER_KEYSTORE_JKS -alias server -certreq -file cert-file -storepass $PASSWORD -noprompt
# Sign it
openssl x509 -req -CA ca-qv-cert -CAkey ca-qv-key -in cert-file -out cert-signed -days $VALIDITY -CAcreateserial -passin pass:$PASSWORD
# Finally, you need to import both the certificate of the CA and the signed certificate into the keystore
keytool -keystore $SERVER_KEYSTORE_JKS -alias CARoot -import -file ca-qv-cert -storepass $PASSWORD -noprompt
keytool -keystore $SERVER_KEYSTORE_JKS -alias server -import -file cert-signed -storepass $PASSWORD -noprompt

echo -e "${GREEN}Sign Client with Server CA${NC}"
rm cert-file
keytool -keystore $CLIENT_KEYSTORE_JKS -alias client -certreq -file cert-file -storepass $PASSWORD -noprompt
# Sign it
openssl x509 -req -CA ca-hw-cert -CAkey ca-hw-key -in cert-file -out cert-signed -days $VALIDITY -CAcreateserial -passin pass:$PASSWORD
# Finally, you need to import both the certificate of the CA and the signed certificate into the keystore
keytool -keystore $CLIENT_KEYSTORE_JKS -alias CARoot -import -file ca-hw-cert -storepass $PASSWORD -noprompt
keytool -keystore $CLIENT_KEYSTORE_JKS -alias client -import -file cert-signed -storepass $PASSWORD -noprompt


chmod 700 *
)


#keytool -keystore kafka.client.keystore.jks -alias localhost -certreq -file cert-file
#openssl x509 -req -CA ca-cert -CAkey ca-key -in cert-file -out cert-signed -days $VALIDITY -CAcreateserial -passin pass:$PASSWORD
#keytool -keystore kafka.client.keystore.jks -alias CARoot -import -file ca-cert
#keytool -keystore kafka.client.keystore.jks -alias localhost -import -file cert-signed


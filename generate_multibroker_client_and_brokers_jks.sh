#!/bin/bash
#
# 2 ways SSL generation
#
# References:
# http://docs.confluent.io/2.0.0/kafka/ssl.html
# 
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# jks passwords to access contents
PASSWORD_CLIENT="testkafkaclient"
PASSWORD_SERVER="testkafkaserver"

PASSWORD_CA="testca"

# name of files
CLIENT_KEYSTORE_JKS="kafka.client.keystore.jks"
CLIENT_KEYSTORE_P12="kafka.client.keystore.p12"
SERVER_KEYSTORE_JKS="kafka.server.keystore.jks"
SERVER_TRUSTSTORE_JKS="kafka.server.truststore.jks"
CLIENT_TRUSTSTORE_JKS="kafka.client.truststore.jks"

# validity in days
VALIDITY=7300

# minimum rsa size is 1024 or you might get an error from JCE
KEYLEN=1024

CLIENT_HOSTNAME="RACK5_SLOT5"
# Replace with your broker external fqdn
SERVER_HOSTNAME1="TB-F1-S1"
SERVER_HOSTNAME2="TB-F1-S2"
SERVER_HOSTNAME3="TB-F1-S3"

SERVER_CA_CERT="ca-hw-cert"
SERVER_CA_KEY="ca-hw-key"

# IMPORTANT: Kafka 2 ways SSL only works with ONE CA ROOT!!
CLIENT_CA_CERT=$SERVER_CA_CERT
CLIENT_CA_KEY=$SERVER_CA_KEY

echo "Clearing existing Kafka SSL certs..."
rm -rf sslcerts

mkdir sslcerts
mkdir sslcerts/kafkaclient
mkdir sslcerts/kafkaserver
mkdir sslcerts/kafkaserver/broker1
mkdir sslcerts/kafkaserver/broker2
mkdir sslcerts/kafkaserver/broker3

(

cd sslcerts


#==========================================================================================
#  Generation of Server keystore for each of the Kafka Brokers in Server
#==========================================================================================

cd kafkaserver/broker1
echo -e "${GREEN}Generating cert & key for the kafka Server Broker 1...${NC}"
keytool -keystore $SERVER_KEYSTORE_JKS -alias server -validity $VALIDITY -genkey -storepass $PASSWORD_SERVER -keypass $PASSWORD_SERVER  -dname "CN=$SERVER_HOSTNAME1, OU=None, O=Hw, L=Tegu, ST=FM, C=HN" -keyalg RSA -keysize $KEYLEN

cd ../../kafkaserver/broker2
echo -e "${GREEN}Generating cert & key for the kafka Server Broker 2...${NC}"
keytool -keystore $SERVER_KEYSTORE_JKS -alias server -validity $VALIDITY -genkey -storepass $PASSWORD_SERVER -keypass $PASSWORD_SERVER  -dname "CN=$SERVER_HOSTNAME2, OU=None, O=Hw, L=Tegu, ST=FM, C=HN" -keyalg RSA -keysize $KEYLEN

cd ../../kafkaserver/broker3
echo -e "${GREEN}Generating cert & key for the kafka Server Broker 3...${NC}"
keytool -keystore $SERVER_KEYSTORE_JKS -alias server -validity $VALIDITY -genkey -storepass $PASSWORD_SERVER -keypass $PASSWORD_SERVER  -dname "CN=$SERVER_HOSTNAME3, OU=None, O=Hw, L=Tegu, ST=FM, C=HN" -keyalg RSA -keysize $KEYLEN

cd ../..

#==========================================================================================
#  Generation of Client keysore - for kafka Client
#==========================================================================================

cd kafkaclient

echo -e "${GREEN}Generating cert & key for the kafka Client...${NC}"
keytool -keystore $CLIENT_KEYSTORE_JKS -alias client -validity $VALIDITY -genkey -storepass $PASSWORD_CLIENT -keypass $PASSWORD_CLIENT  -dname "CN=$CLIENT_HOSTNAME, OU=None, O=Qv, L=Tegu, ST=FM, C=HN" -keyalg RSA -keysize $KEYLEN

cd ..

#==============================================================================================
#  CA Certificate - Generation of CARoot Certificate - common to both Kafka Client and Server
#==============================================================================================

echo -e "${GREEN}Generate a top level server CA to stamp client certificates${NC}"
openssl req -new -newkey rsa:$KEYLEN -x509 -keyout $SERVER_CA_KEY -out $SERVER_CA_CERT -days $VALIDITY -passout pass:$PASSWORD_CA -subj "/C=HN/ST=FM/L=Tegu/O=Hw/OU=None/CN=$SERVER_HOSTNAME1"

# IMPORTANT: Kafka 2 ways SSL only works with ONE CA ROOT!!
#echo -e "${GREEN}Generate a top level client CA to stamp server certificates${NC}"
#openssl req -new -x509 -keyout $CLIENT_CA_KEY -out $CLIENT_CA_CERT -days $VALIDITY -passout pass:$PASSWORD -subj "/C=HN/ST=FM/L=Tegu/O=Qv/OU=None/CN=$CLIENT_HOSTNAME"

cp ca-hw-cert ca-hw-key kafkaclient
cp ca-hw-cert ca-hw-key kafkaserver/broker1
cp ca-hw-cert ca-hw-key kafkaserver/broker2
cp ca-hw-cert ca-hw-key kafkaserver/broker3

#==========================================================================================
#  Create Server truststore and Import the CARoot certificate
#==========================================================================================

cd kafkaserver/broker1
echo -e "${GREEN}Import the CA in server trust stores of Broker 1${NC}"
keytool -keystore $SERVER_TRUSTSTORE_JKS -storepass $PASSWORD_SERVER -alias CARoot -import -file $CLIENT_CA_CERT  -noprompt

cd ../../kafkaserver/broker2
echo -e "${GREEN}Import the CA in server trust stores of Broker 2${NC}"
keytool -keystore $SERVER_TRUSTSTORE_JKS -storepass $PASSWORD_SERVER -alias CARoot -import -file $CLIENT_CA_CERT  -noprompt

cd ../../kafkaserver/broker3
echo -e "${GREEN}Import the CA in server trust stores of Broker 3${NC}"
keytool -keystore $SERVER_TRUSTSTORE_JKS -storepass $PASSWORD_SERVER -alias CARoot -import -file $CLIENT_CA_CERT  -noprompt

cd ../..

#==========================================================================================
#  Create Client truststore and Import the CARoot certificate
#==========================================================================================

cd kafkaclient

echo -e "${GREEN}Import the CA in client trust stores${NC}"
keytool -keystore $CLIENT_TRUSTSTORE_JKS -storepass $PASSWORD_CLIENT -alias CARoot -import -file $SERVER_CA_CERT  -noprompt

cd ..

#==========================================================================================
#  Sign the Server keystore certificate of each broker with CARoot certificate
#     - Server keystore -> unsigned certificate
#     - Sign the unsigned certificate with CARoot certificate
#     - Server keystore <-  CARoot certificate + Signed Server certificate
#==========================================================================================

# At this point we have two jks TrustStore
#  hw server trust store contains CA ROOT ca-qv-cert
#  qv client trust store contains CA ROOT ca-hw-cert
# 
#  We also have match private keys for each in the local folder: ca-hw-key & ca-qv-key
# Last but not least, we have two ClientStore, with unsigned keys
#  hw server client store contains an unsigned key called "server"
#  qv server client store contains an unsigned key called "client"

# Now.. we need to sign each clients cert with the other companie's CA

cd kafkaserver/broker1

# For this, we first need to export the cert for each client on file system
echo -e "${GREEN}Sign Server with Client CA${NC}"
rm -f cert-file
keytool -keystore $SERVER_KEYSTORE_JKS -alias server -certreq -file cert-file -storepass $PASSWORD_SERVER -noprompt
# Sign it
openssl x509 -req -CA $CLIENT_CA_CERT -CAkey $CLIENT_CA_KEY -in cert-file -out cert-signed -days $VALIDITY -CAcreateserial -passin pass:$PASSWORD_CA
# Finally, you need to import both the certificate of the CA and the signed certificate into the keystore
keytool -keystore $SERVER_KEYSTORE_JKS -alias CARoot -import -file $CLIENT_CA_CERT -storepass $PASSWORD_SERVER -noprompt
keytool -keystore $SERVER_KEYSTORE_JKS -alias server -import -file cert-signed -storepass $PASSWORD_SERVER -noprompt

cd ../../kafkaserver/broker2

# For this, we first need to export the cert for each client on file system
echo -e "${GREEN}Sign Server with Client CA${NC}"
rm -f cert-file
keytool -keystore $SERVER_KEYSTORE_JKS -alias server -certreq -file cert-file -storepass $PASSWORD_SERVER -noprompt
# Sign it
openssl x509 -req -CA $CLIENT_CA_CERT -CAkey $CLIENT_CA_KEY -in cert-file -out cert-signed -days $VALIDITY -CAcreateserial -passin pass:$PASSWORD_CA
# Finally, you need to import both the certificate of the CA and the signed certificate into the keystore
keytool -keystore $SERVER_KEYSTORE_JKS -alias CARoot -import -file $CLIENT_CA_CERT -storepass $PASSWORD_SERVER -noprompt
keytool -keystore $SERVER_KEYSTORE_JKS -alias server -import -file cert-signed -storepass $PASSWORD_SERVER -noprompt

cd ../../kafkaserver/broker3

# For this, we first need to export the cert for each client on file system
echo -e "${GREEN}Sign Server with Client CA${NC}"
rm -f cert-file
keytool -keystore $SERVER_KEYSTORE_JKS -alias server -certreq -file cert-file -storepass $PASSWORD_SERVER -noprompt
# Sign it
openssl x509 -req -CA $CLIENT_CA_CERT -CAkey $CLIENT_CA_KEY -in cert-file -out cert-signed -days $VALIDITY -CAcreateserial -passin pass:$PASSWORD_CA
# Finally, you need to import both the certificate of the CA and the signed certificate into the keystore
keytool -keystore $SERVER_KEYSTORE_JKS -alias CARoot -import -file $CLIENT_CA_CERT -storepass $PASSWORD_SERVER -noprompt
keytool -keystore $SERVER_KEYSTORE_JKS -alias server -import -file cert-signed -storepass $PASSWORD_SERVER -noprompt

cd ../..

#==========================================================================================
#  Sign the Client keystore certificate with CARoot certificate
#     - Client keystore -> unsigned certificate
#     - Sign the unsigned certificate with CARoot certificate
#     - Client keystore <-  CARoot certificate + Signed Client certificate
#==========================================================================================
#### CLIENT STUFF ####

cd kafkaclient

echo -e "${GREEN}Sign Client with Server CA${NC}"
rm -f cert-file
keytool -keystore $CLIENT_KEYSTORE_JKS -alias client -certreq -file cert-file -storepass $PASSWORD_CLIENT -noprompt
# Sign it
openssl x509 -req -CA $SERVER_CA_CERT -CAkey $SERVER_CA_KEY -in cert-file -out cert-signed -days $VALIDITY -CAcreateserial -passin pass:$PASSWORD_CA
# Finally, you need to import both the certificate of the CA and the signed certificate into the keystore
keytool -keystore $CLIENT_KEYSTORE_JKS -alias CARoot -import -file $SERVER_CA_CERT -storepass $PASSWORD_CLIENT -noprompt
keytool -keystore $CLIENT_KEYSTORE_JKS -alias client -import -file cert-signed -storepass $PASSWORD_CLIENT -noprompt

# PEM for KafkaCat native client (optional)
# Extract key (pem) from client JKS, this take a transition state via a pkcs12
keytool -importkeystore -srckeystore $CLIENT_KEYSTORE_JKS -destkeystore $CLIENT_KEYSTORE_P12 -srcstoretype JKS -deststoretype PKCS12 -srcstorepass $PASSWORD_CLIENT -deststorepass $PASSWORD_CLIENT -noprompt
openssl pkcs12 -in $CLIENT_KEYSTORE_P12 -nocerts -nodes -passin pass:$PASSWORD_CLIENT | openssl rsa -out client.key 
openssl pkcs12 -in $CLIENT_KEYSTORE_P12 -nokeys -clcerts -nodes -passin pass:$PASSWORD_CLIENT | openssl x509 -out client.pem
openssl pkcs12 -in $CLIENT_KEYSTORE_P12 -nokeys -cacerts -nodes -passin pass:$PASSWORD_CLIENT | grep -v -e '^\s' | grep -v '^\(Bag\|subject\|issuer\)' > client.ca-bundle.crt

cd ..

chmod 700 *
)
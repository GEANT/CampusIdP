#!/bin/bash
#
# /tmp/key.pem              -- a private key
# /tmp/cert.pem             -- a certificate with full chain
# /tmp/jetty-cert.pkcs12    -- PKCS12 format
# /opt/jetty/etc/keystore   -- final keystore for Jetty
#
# $1    -- JETTY_VERSION set in Dockerfile
# $2    -- a private key password
# $3    -- a password for PKCS12 format
# $4    -- a keystore password
# $5    -- SHIBBOLETH_HOSTNAME set in Dockerfile

JETTY_VERSION=$1
PASSWORDKEY=$2
PASSWORDPKCS12=$3
PASSWORDKEYSTORE=$4
SHIBBOLETH_HOSTNAME=$5

obfpass() {
    java -cp /opt/jetty-distribution-$JETTY_VERSION/lib/jetty-util-$JETTY_VERSION.jar org.eclipse.jetty.util.security.Password $1 2>&1 | grep OBF\:
}

openssl pkcs12 -export -inkey /tmp/key.pem -in /tmp/cert.pem -out /tmp/jetty-cert.pkcs12 -passin pass:$PASSWORDKEY -passout pass:$PASSWORDPKCS12
rm -f /opt/jetty/etc/keystore
keytool -importkeystore -srckeystore /tmp/jetty-cert.pkcs12 -srcstoretype PKCS12 -destkeystore /opt/jetty/etc/keystore -storepass $PASSWORDKEYSTORE -srcstorepass $PASSWORDPKCS12 -noprompt

OBFPASS1=$(obfpass $PASSWORDPKCS12)
OBFPASS2=$(obfpass $PASSWORDKEYSTORE)

sed -i.bak "s%#\ jetty.sslContext.keyStorePassword=.*%jetty.sslContext.keyStorePassword=$OBFPASS2%; \
    s%#\ jetty.sslContext.keyManagerPassword=.*%jetty.sslContext.keyManagerPassword=$OBFPASS1%; \
    s%#\ jetty.sslContext.trustStorePassword=.*%jetty.sslContext.trustStorePassword=$OBFPASS2%" \
    /opt/jetty/start.d/ssl.ini

rm -f /tmp/key.pem /tmp/cert.pem /tmp/jetty-cert.pkcs12


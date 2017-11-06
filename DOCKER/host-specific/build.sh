#!/bin/bash

if [[ -z $1 ]]; then
    echo "Missing hostname of the target machine."
    exit
fi

source ./hosts/$1/buildenv.conf

docker image build \
    --build-arg JETTY_VERSION=$JETTY_VERSION \
    --build-arg PASSWORD_CERT_KEY=$PASSWORD_CERT_KEY \
    --build-arg PASSWORD_PKCS12=$PASSWORD_PKCS12 \
    --build-arg PASSWORD_KEYSTORE=$PASSWORD_KEYSTORE \
    --build-arg SHIBBOLETH_VERSION=$SHIBBOLETH_VERSION \
    --build-arg SHIBBOLETH_SCOPE=$SHIBBOLETH_SCOPE \
    --build-arg SHIBBOLETH_ENTITYID=$SHIBBOLETH_ENTITYID \
    --build-arg SHIBBOLETH_HOSTNAME=$SHIBBOLETH_HOSTNAME \
    --build-arg SHIBBOLETH_PASSWORD_SEALER=$SHIBBOLETH_PASSWORD_SEALER \
    --build-arg SHIBBOLETH_PASSWORD_KEYSTORE=$SHIBBOLETH_PASSWORD_KEYSTORE \
    -t idp-$SHIBBOLETH_HOSTNAME .


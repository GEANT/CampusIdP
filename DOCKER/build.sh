#!/bin/bash

if [[ $1 == "tag" ]]; then
    TAG=`date +:%Y%m%d-%H%M%S`
elif [[ -n $1 ]]; then
    TAG=":$1"
else
    TAG=":latest"
fi

source ./buildenv.conf
docker image build \
    --build-arg JAVA_HOME=$JAVA_HOME \
    --build-arg JETTY_VERSION=$JETTY_VERSION \
    --build-arg JETTY_KEY=$JETTY_KEY \
    --build-arg PASSWORD_CERT_KEY=$PASSWORD_CERT_KEY \
    --build-arg PASSWORD_PKCS12=$PASSWORD_PKCS12 \
    --build-arg PASSWORD_KEYSTORE=$PASSWORD_KEYSTORE \
    -t stretch-shib-idp-test01$TAG .


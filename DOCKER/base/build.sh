#!/usr/bin/env bash

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
    --build-arg SHIBBOLETH_VERSION=$SHIBBOLETH_VERSION \
    -t shibboleth-idp$TAG .


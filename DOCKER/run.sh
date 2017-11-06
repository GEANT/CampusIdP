#!/bin/bash

source ./buildenv.conf

mkdir -p /var/tmp/docker-logs-jetty \
         /var/tmp/docker-logs-shibboleth

if [[ $1 ]]; then
    TAG=":$1"
fi

docker container run \
    -it \
    --rm \
    --detach \
    --name idp-$SHIBBOLETH_HOSTNAME \
    --hostname idp-$SHIBBOLETH_HOSTNAME \
    -p 80:8080 -p 443:8443 \
    -v /var/tmp/docker-logs-jetty:/opt/jetty/logs \
    -v /var/tmp/docker-logs-shibboleth:/opt/shibboleth-idp/logs \
    idp-$SHIBBOLETH_HOSTNAME$TAG


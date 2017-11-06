#!/bin/bash

mkdir -p /var/tmp/docker-logs-jetty \
         /var/tmp/docker-logs-shibboleth

if [[ $1 ]]; then
    TAG=":$1"
fi

docker container run \
    -it \
    --rm \
    --detach \
    --name stretch-shib-idp-test01 \
    --hostname stretch-shib-idp-test01 \
    -p 80:8080 -p 443:8443 \
    -v /var/tmp/docker-logs-jetty:/opt/jetty/logs \
    -v /var/tmp/docker-logs-shibboleth:/opt/shibboleth-idp/logs \
    stretch-shib-idp-test01$TAG

#!/bin/bash

if [[ -z $1 ]]; then
    echo "Missing hostname of the target machine."
    exit
fi

source ./hosts/$1/buildenv.conf

mkdir -p /var/tmp/docker-logs-jetty \
         /var/tmp/docker-logs-shibboleth

docker container run \
    -it \
    --rm \
    --detach \
    --name idp-$SHIBBOLETH_HOSTNAME \
    --hostname idp-$SHIBBOLETH_HOSTNAME \
    -p 80:8080 -p 443:8443 \
    --mount source=vol-$SHIBBOLETH_HOSTNAME,destination=/opt \
    -v /var/tmp/docker-logs-jetty:/opt/jetty/logs \
    -v /var/tmp/docker-logs/shibboleth:/opt/shibboleth-idp/logs \
    idp-$SHIBBOLETH_HOSTNAME


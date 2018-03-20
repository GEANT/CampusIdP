#!/usr/bin/env bash

PORT_HTTP=80
PORT_HTTPS=443

if [[ -z $1 ]]; then
    echo "Missing hostname of the target machine."
    exit
fi

if [[ -z $2 ]]; then
    echo "No port for HTTP specified, using 80."
else
    PORT_HTTP=$2
    echo "Using port ${PORT_HTTP} for HTTP."
fi

if [[ -z $3 ]]; then
    echo "No port for HTTPS specified, using 443."
else
    PORT_HTTPS=$3
    echo "Using port ${PORT_HTTPS} for HTTPS."
fi

source ./hosts/$1/buildenv.conf

echo "Using Docker Volume vol-${SHIBBOLETH_HOSTNAME}..."

mkdir -p /var/tmp/docker-logs-jetty \
         /var/tmp/docker-logs-shibboleth

docker container run \
    -it \
    --rm \
    --detach \
    --name idp-$SHIBBOLETH_HOSTNAME \
    --hostname idp-$SHIBBOLETH_HOSTNAME \
    -p $PORT_HTTP:8080 -p $PORT_HTTPS:8443 \
    --mount source=vol-$SHIBBOLETH_HOSTNAME,destination=/opt \
    -v /var/tmp/docker-logs-jetty:/opt/jetty/logs \
    -v /var/tmp/docker-logs/shibboleth:/opt/shibboleth-idp/logs \
    idp-$SHIBBOLETH_HOSTNAME


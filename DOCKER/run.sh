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

source ./conf/$1.conf

echo "Using Docker Volume vol-${SHIBBOLETH_HOSTNAME}..."

if [ "$(uname)" == "Darwin" ]; then
    DOCKER_LOGS_JETTY=/tmp/docker-logs-jetty
    DOCKER_LOGS_SHIBBOLETH=/tmp/docker-logs-shibboleth
elif [ "$(uname)" == "Linux" ]; then
    DOCKER_LOGS_JETTY=/var/tmp/docker-logs-jetty
    DOCKER_LOGS_SHIBBOLETH=/var/tmp/docker-logs-shibboleth
fi

mkdir -p $DOCKER_LOGS_JETTY $DOCKER_LOGS_SHIBBOLETH

docker container run \
    -it \
    --rm \
    --detach \
    --name idp-$SHIBBOLETH_HOSTNAME \
    --hostname idp-$SHIBBOLETH_HOSTNAME \
    --link mysql-$SHIBBOLETH_HOSTNAME:mysql \
    -p $PORT_HTTP:8080 -p $PORT_HTTPS:8443 \
    --mount source=vol-$SHIBBOLETH_HOSTNAME,destination=/opt \
    -v $DOCKER_LOGS_JETTY:/opt/jetty/logs \
    -v $DOCKER_LOGS_SHIBBOLETH:/opt/shibboleth-idp/logs \
    idp-$SHIBBOLETH_HOSTNAME


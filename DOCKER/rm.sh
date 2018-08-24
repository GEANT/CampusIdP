#!/usr/bin/env bash

if [[ -z $1 ]]; then
    echo "Missing hostname of the target machine."
    exit
fi

source ./env/$1.conf

echo "Removing Docker image for ${SHIBBOLETH_HOSTNAME}..."
docker image rm idp-$SHIBBOLETH_HOSTNAME

echo "Removing Docker volume for ${SHIBBOLETH_HOSTNAME}..."
docker volume rm vol-$SHIBBOLETH_HOSTNAME


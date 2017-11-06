#!/bin/bash

if [[ $1 ]]; then
    TAG=":$1"
fi

docker container run \
    -it \
    --rm \
    --detach \
    --name shibboleth-idp \
    --hostname shibboleth-idp \
    shibboleth-idp$TAG


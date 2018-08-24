#!/usr/bin/env bash

if [[ -z $1 ]]; then
    echo "Missing hostname of the target machine."
    exit
fi

source ./env/$1.conf

docker container exec -it idp-$SHIBBOLETH_HOSTNAME /bin/bash


#!/usr/bin/env bash

if [[ -z $1 ]]; then
    echo "Missing hostname of the target machine."
    exit
fi

source ./conf/$1.conf

docker container stop idp-$SHIBBOLETH_HOSTNAME


#!/bin/bash

if [[ -z $1 ]]; then
    echo "Missing hostname of the target machine."
    exit
fi

source ./hosts/$1/buildenv.conf

docker container stop idp-$SHIBBOLETH_HOSTNAME


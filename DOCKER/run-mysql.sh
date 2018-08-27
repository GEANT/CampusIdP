#!/usr/bin/env bash

if [[ -z $1 ]]; then
    echo "Missing hostname of the target machine."
    exit
fi

source ./conf/$1.conf

docker container run \
    -it \
    --rm \
    --detach \
    --name mysql-$SHIBBOLETH_HOSTNAME \
    --hostname mysql-$SHIBBOLETH_HOSTNAME \
    -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD \
    -e MYSQL_DATABASE=$MYSQL_DATABASE \
    -e MYSQL_USER=$MYSQL_USER \
    -e MYSQL_PASSWORD=$MYSQL_PASSWORD \
    -v `pwd`/mysql:/docker-entrypoint-initdb.d \
    mysql:5 \
    --character-set-server=utf8mb4 \
    --collation-server=utf8mb4_unicode_ci \

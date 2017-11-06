#!/bin/bash

source ./buildenv.conf

docker container stop idp-$SHIBBOLETH_HOSTNAME


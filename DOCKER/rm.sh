#!/bin/bash

source ./buildenv.conf

docker image rm idp-$SHIBBOLETH_HOSTNAME


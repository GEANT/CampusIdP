#!/bin/bash

if [[ $1 == "tag" ]]; then
    TAG=`date +:%Y%m%d-%H%M%S`
elif [[ -n $1 ]]; then
    TAG=":$1"
else
    TAG=":latest"
fi

source ./buildenv.conf
docker image build \
    --build-arg JAVA_HOME=$JAVA_HOME \
    -t stretch-shib-idp-test01$TAG .


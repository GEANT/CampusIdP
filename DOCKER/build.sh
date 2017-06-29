#!/bin/bash

if [[ $1 == "tag" ]]; then
    TAG=`date +:%Y%m%d-%H%M%S`
else
    TAG=":latest"
fi

docker build -t stretch-shib-idp-test01$TAG .


#!/bin/bash

version=`docker version --format '{{.Client.Version}}'`
current_year=`date +"%y"`

if [[ "$version" == *"$current_year"* ]]; then
  docker container exec -it stretch-shib-idp-test01 /bin/bash
else
  # keep backward compatibility with older versions of Docker Engine
  docker exec -it stretch-shib-idp-test01 /bin/bash
fi

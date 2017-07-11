#!/bin/bash

# This script will work only if Docker CE is installed.
# Please use install.sh script to install all the dependencies
# needed to run a container.

mkdir -p /var/tmp/docker-logs-jetty \
         /var/tmp/docker-logs-shibboleth

if [[ $1 ]]; then
    TAG=":$1"
fi

# Verify that Docker CE is installed
is_installed=$( which docker )

if [[ "$?" -eq 0  ]]; then

  # Docker major versions now have year as thier version with month
  # extension, e.g. version 17.06 means it's created in June 2017.
  # Next two lines are used to compare the short year number and Docker version.
  # If they match, use the extended Docker command for running containers.

  version=`docker version --format '{{.Client.Version}}'`
  current_year=`date +"%y"`

  if [[ "$version" == *"$current_year"* ]]; then
      docker container run \
      --detach \
      --name stretch-shib-idp-test01 \
      --hostname stretch-shib-idp-test01 \
      -p 8080:8080 -p 8443:8443 \
      -v /var/tmp/docker-logs-jetty:/opt/jetty/logs \
      -v /var/tmp/docker-logs-shibboleth:/opt/shibboleth-idp/logs \
      stretch-shib-idp-test01$TAG
    else
      docker run \
      --detach \
      --name stretch-shib-idp-test01 \
      --hostname stretch-shib-idp-test01 \
      -p 8080:8080 -p 8443:8443 \
      -v /var/tmp/docker-logs-jetty:/opt/jetty/logs \
      -v /var/tmp/docker-logs-shibboleth:/opt/shibboleth-idp/logs \
      stretch-shib-idp-test01$TAG
    fi
else
  printf "Docker CE is not installed.\n"
  printf "Please use install.sh script to install Docker CE!\n"
fi

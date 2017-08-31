#!/bin/bash

# **************************NOTICE*************************************
# * Docker Compose does not work with kernel versions lower than 3.10 *
# *********************************************************************
# Current Docker Compose version
dockerComposeVersion = '1.14.0'

# Download shell script for Docker Compose
curl -L \
https://github.com/docker/compose/releases/download/$dockerComposeVersion/docker-compose-`uname -s`-`uname -m` \
> /usr/local/bin/docker-compose && chmod 744 /usr/local/bin/docker-compose

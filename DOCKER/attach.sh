#!/bin/bash

source ./buildenv.conf

docker container exec -it idp-$SHIBBOLETH_HOSTNAME /bin/bash


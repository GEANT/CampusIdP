#!/bin/bash

# Get container name
container_name=(`docker container ps --format "{{.Names}}"`)
length=${#container_name[@]}

# Stop the container(s) with the specified name(s) and remove it.
# It helps to keep the Docker environment clean.
# Use for testing purposes.

if [[ $length -eq "1" ]]; then

  echo "Container with name $container_name will be stopped and removed `date +%Y.%m.%d-%H:%M:%S`" >> /tmp/docker.log
  docker container stop $container_name && docker container rm $container_name

elif [[ $length -gt "1" ]]; then
  for ((i=0; i<length; i++))
  do
    echo "Container with name ${container_name[i]} will be stopped and removed `date +%Y.%m.%d-%H:%M:%S`" >> /tmp/docker.log
    docker container stop ${container_name[i]} && docker container rm ${container_name[i]}
  done

else
  echo "There are not any running containers at the moment! Run one by using the run.sh script in this directory!"
fi

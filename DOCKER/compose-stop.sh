#!/bin/bash

# Stop Docker Compose and remove all used images
docker-compose down -v --rmi all

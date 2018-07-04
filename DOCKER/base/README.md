# What's this?

This directory contains a `Dockerfile` for building a base image to run Shibboleth IdP on top of Jetty and OpenJDK 8.

You can specify Jetty and Shibboleth IdP versions (as well as the GPG keys used to sign the source codes) in `buildenv.conf` file using `JETTY_VERSION`, `JETTY_KEY`, `SHIBBOLETH_VERSION` and `SHIBBOLETH_KEY` variables. Although all the variables are set, you might like to check them in order a newer version is available.

There's also `jetty/` directory containing two configuration files for Jetty, which you might like to check if they fit to your needs. They should.

## What to do with this?

Simply run `./build.sh` to build this base Docker image.

You can start the image after it's built using `./run.sh` command, however, it doesn't contain anything important. This script is there just for debugging purposes as well as `./attach.sh` and `./stop.sh`.

To delete the image built using `./build.sh`, you can use `./rm.sh` script.


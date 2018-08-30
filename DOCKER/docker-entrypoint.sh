#!/usr/bin/env bash

set -e

/tmp/index.sh

/opt/shibboleth-idp && \
    ../shibboleth-rebuild.expect

sed -i.bak 's%<!-- <ref bean="c14n/SAML2Persistent" /> -->%<ref bean="c14n/SAML2Persistent" />%' /opt/shibboleth-idp/conf/c14n/subject-c14n.xml

exec java \
    -Djetty.logging.dir=/opt/jetty/logs \
    -Djetty.home=/opt/jetty-distribution-$JETTY_VERSION \
    -Djetty.base=/opt/jetty \
    -Djava.io.tmpdir=/tmp \
    -jar \
    /opt/jetty-distribution-$JETTY_VERSION/start.jar \
    jetty.state=/opt/jetty/jetty.state \
    jetty-logging.xml \
    jetty-started.xml \
    start-log-file=/opt/jetty/logs/start.log


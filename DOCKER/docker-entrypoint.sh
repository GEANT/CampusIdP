#!/usr/bin/env bash

set -e

/opt/shibboleth-idp && \
    ../shibboleth-rebuild.expect

sed -i.bak 's%<!-- <ref bean="c14n/SAML2Persistent" /> -->%<ref bean="c14n/SAML2Persistent" />%' /opt/shibboleth-idp/conf/c14n/subject-c14n.xml

for f in /tmp/shibboleth-idp/conf/*; do
    cp $f /opt/shibboleth-idp/conf/
done

for f in /tmp/shibboleth-idp/credentials/*; do
    cp $f /opt/shibboleth-idp/credentials/
done


/tmp/index.sh

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


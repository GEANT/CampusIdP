#!/usr/bin/env bash

set -e

/tmp/jetty-keystore.sh $JETTY_VERSION $JETTY_CERT_KEY $JETTY_CERT_PKCS12 $SHIBBOLETH_HOSTNAME

### Build Shibboleth IdP
SHIBBOLETH_PASSWORD_SEALER=`tr -cd '[:alnum:]' < /dev/urandom | fold -w30 | head -n1`
SHIBBOLETH_PASSWORD_KEYSTORE=`tr -cd '[:alnum:]' < /dev/urandom | fold -w30 | head -n1`

cat <<EOF > /opt/idp.install.properties
idp.no.tidy=true
EOF

cat <<EOF > /opt/idp.merge.properties
idp.scope=$SHIBBOLETH_SCOPE
idp.entityID=$SHIBBOLETH_ENTITYID
idp.sealer.storePassword=$SHIBBOLETH_PASSWORD_SEALER
idp.sealer.keyPassword=$SHIBBOLETH_PASSWORD_SEALER
EOF

/opt/shibboleth-identity-provider-$SHIBBOLETH_VERSION/bin/install.sh \
    -Didp.property.file=/opt/idp.install.properties \
    -Didp.merge.properties=/opt/idp.merge.properties \
    -Didp.src.dir=/opt/shibboleth-identity-provider-$SHIBBOLETH_VERSION \
    -Didp.target.dir=/opt/shibboleth-idp \
    -Didp.scope=$SHIBBOLETH_SCOPE \
    -Didp.host.name=$SHIBBOLETH_HOSTNAME \
    -Didp.sealer.password=$SHIBBOLETH_PASSWORD_SEALER \
    -Didp.keystore.password=$SHIBBOLETH_PASSWORD_KEYSTORE \
    -Didp.noprompt=true
###

cd /opt/shibboleth-idp && \
    ../shibboleth-rebuild.expect

sed -i.bak 's%<!-- <ref bean="c14n/SAML2Persistent" /> -->%<ref bean="c14n/SAML2Persistent" />%' /opt/shibboleth-idp/conf/c14n/subject-c14n.xml

for f in /tmp/shibboleth-idp/conf/*; do
    cp $f /opt/shibboleth-idp/conf/
done

for f in /tmp/shibboleth-idp/credentials/*; do
    cp $f /opt/shibboleth-idp/credentials/
done

### Change passwords
sed \
    -i.bak \
    -e "s/idp\.sealer\.storePassword\=\s*.*/idp.sealer.storePassword= ${SHIBBOLETH_PASSWORD_SEALER}/" \
    -e "s/idp\.sealer\.keyPassword\=\s*.*/idp.sealer.keyPassword= ${SHIBBOLETH_PASSWORD_SEALER}/" \
    /opt/shibboleth-idp/conf/idp.properties
###

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


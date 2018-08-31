#!/usr/bin/env bash

set -e

/tmp/jetty-keystore.sh $JETTY_VERSION $JETTY_CERT_KEY $SHIBBOLETH_HOSTNAME

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

for f in /tmp/shibboleth-idp/conf/*; do
    cp $f /opt/shibboleth-idp/conf/
done

for f in /tmp/shibboleth-idp/credentials/*; do
    cp $f /opt/shibboleth-idp/credentials/
done

sed \
    -i.bak \
    -e "s/idp\.sealer\.storePassword\=\s*.*/idp.sealer.storePassword= ${SHIBBOLETH_PASSWORD_SEALER}/" \
    -e "s/idp\.sealer\.keyPassword\=\s*.*/idp.sealer.keyPassword= ${SHIBBOLETH_PASSWORD_SEALER}/" \
    /opt/shibboleth-idp/conf/idp.properties

sed \
    -i.bak \
    -e "s%^#idp.authn.LDAP.authenticator\s*=.*%idp.authn.LDAP.authenticator= "${LDAP_AUTHENTICATOR}"%" \
    -e "s%^idp.authn.LDAP.ldapURL\s*=.*%idp.authn.LDAP.ldapURL= "${LDAP_LDAPURL}"%" \
    -e "s%^#idp.authn.LDAP.useStartTLS\s*=.*%idp.authn.LDAP.useStartTLS= "${LDAP_USESTARTTLS}"%" \
    -e "s%^#idp.authn.LDAP.useSSL\s*=.*%idp.authn.LDAP.useSSL= "${LDAP_USESSL}"%" \
    -e "s%^#idp.authn.LDAP.sslConfig\s*=.*%idp.authn.LDAP.sslConfig= "${LDAP_SSLCONFIG}"%" \
    -e "s%^idp.authn.LDAP.baseDN\s*=.*%idp.authn.LDAP.baseDN= "${LDAP_BASEDN}"%" \
    -e "s%^#idp.authn.LDAP.subtreeSearch\s*=.*%idp.authn.LDAP.subtreeSearch= "${LDAP_SUBTREESEARCH}"%" \
    -e "s%^idp.authn.LDAP.bindDN\s*=.*%idp.authn.LDAP.bindDN= ${LDAP_BINDDN}%" \
    -e "s%^idp.authn.LDAP.bindDNCredential\s*=.*%idp.authn.LDAP.bindDNCredential= "${LDAP_BINDDNCREDENTIAL}"%" \
    /opt/shibboleth-idp/conf/ldap.properties

sed \
    -i.bak \
    -e "s%^#idp.persistentId.sourceAttribute\s*=.*%idp.persistentId.sourceAttribute = "${PERSISTENTID_SOURCEATTRIBUTE}"%" \
    -e "s%^#idp.persistentId.salt\s*=.*%idp.persistentId.salt = "${PERSISTENTID_SALT}"%" \
    -e "s%^#idp.persistentId.generator\s*=.*%idp.persistentId.generator = shibboleth.StoredPersistentIdGenerator%" \
    -e "s%^#idp.persistentId.dataSource\s*=.*%idp.persistentId.dataSource = shibboleth.MySQLDataSource%" \
    /opt/shibboleth-idp/conf/saml-nameid.properties

sed \
    -i.bak \
    -e '37d;39d' \
    /opt/shibboleth-idp/conf/saml-nameid.xml

sed \
    -i.bak \
    "s%^#idp.consent.StorageService\s*=.*%idp.consent.StorageService= shibboleth.JPAStorageService%" \
    /opt/shibboleth-idp/conf/idp.properties

sed \
    -i.bak \
    's%<!-- <ref bean="c14n/SAML2Persistent" /> -->%<ref bean="c14n/SAML2Persistent" />%' \
    /opt/shibboleth-idp/conf/c14n/subject-c14n.xml

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


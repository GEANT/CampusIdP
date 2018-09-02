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

PERSISTENTID=`cat <<EOF
    <!-- StoredID Data Connector -->
    <DataConnector id="myStoredId"
        xsi:type="StoredId"
        sourceAttributeID="${PERSISTENTID_SOURCEATTRIBUTE}"
        generatedAttributeID="storedId"
        salt="${PERSISTENTID_SALT}"
        queryTimeout="0">
    <Dependency ref="uid" />
    <BeanManagedConnection>shibboleth.MySQLDataSource</BeanManagedConnection>
    </DataConnector>
EOF
`
sed \
    -i.bak \
    '$d' \
    /opt/shibboleth-idp/conf/attribute-resolver.xml

echo "${PERSISTENTID}" >> /opt/shibboleth-idp/conf/attribute-resolver.xml
echo -e "\n\n</AttributeResolver>" >> /opt/shibboleth-idp/conf/attribute-resolver.xml

CONFIGURATION=`cat <<EOF
<bean id="shibboleth.MySQLDataSource"
    class="org.apache.commons.dbcp2.BasicDataSource"
    p:driverClassName="com.mysql.jdbc.Driver"
    p:url="jdbc:mysql://db:3306/shibboleth"
    p:username="${MYSQL_USER}"
    p:password="${MYSQL_PASSWORD}" />

<bean id="shibboleth.JPAStorageService"
    class="org.opensaml.storage.impl.JPAStorageService"
    p:cleanupInterval="%{idp.storage.cleanupInterval:PT10M}"
    c:factory-ref="shibboleth.JPAStorageService.entityManagerFactory" />

<bean id="shibboleth.JPAStorageService.entityManagerFactory"
    class="org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean">
    <property name="packagesToScan" value="org.opensaml.storage.impl"/>
    <property name="dataSource" ref="shibboleth.MySQLDataSource"/>
    <property name="jpaVendorAdapter" ref="shibboleth.JPAStorageService.JPAVendorAdapter"/>
    <property name="jpaDialect">
        <bean class="org.springframework.orm.jpa.vendor.HibernateJpaDialect" />
    </property>
</bean>

<bean id="shibboleth.JPAStorageService.JPAVendorAdapter"
    class="org.springframework.orm.jpa.vendor.HibernateJpaVendorAdapter"
    p:generateDdl="true"
    p:database="MYSQL"
    p:databasePlatform="org.hibernate.dialect.MySQL5Dialect" />
EOF
`
sed \
    -i.bak \
    '$d' \
    /opt/shibboleth-idp/conf/global.xml

echo "${CONFIGURATION}" >> /opt/shibboleth-idp/conf/global.xml
echo -e "\n\n</beans>" >> /opt/shibboleth-idp/conf/global.xml

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

UIINFO=`cat <<EOF
            <mdui:UIInfo>
                <mdui:DisplayName xml:lang="en">${UIINFO_DISPLAYNAME_EN}</mdui:DisplayName>
                <mdui:DisplayName xml:lang="cs">${UIINFO_DISPLAYNAME_CS}</mdui:DisplayName>
                <mdui:Description xml:lang="en">${UIINFO_DESCRIPTION_EN}</mdui:Description>
                <mdui:Description xml:lang="cs">${UIINFO_DESCRIPTION_CS}</mdui:Description>
                <mdui:InformationURL xml:lang="en">${UIINFO_INFORMATIONURL_EN}</mdui:InformationURL>
                <mdui:InformationURL xml:lang="cs">${UIINFO_INFORMATIONURL_CS}</mdui:InformationURL>
                <mdui:Logo width="${UIINFO_LOGO_WIDTH}" height="${UIINFO_LOGO_HEIGHT}">${UIINFO_LOGO}</mdui:Logo>
            </mdui:UIInfo>
EOF
`

ORGANIZATION=`cat <<EOF
<Organization>
    <OrganizationName xml:lang="en">${ORGANIZATION_NAME_EN}</OrganizationName>
    <OrganizationName xml:lang="cs">${ORGANIZATION_NAME_CS}</OrganizationName>
    <OrganizationDisplayName xml:lang="en">${ORGANIZATION_DISPLAYNAME_EN}</OrganizationDisplayName>
    <OrganizationDisplayName xml:lang="cs">${ORGANIZATION_DISPLAYNAME_CS}</OrganizationDisplayName>
    <OrganizationURL xml:lang="en">${ORGANIZATION_URL_EN}</OrganizationURL>
    <OrganizationURL xml:lang="cs">${ORGANIZATION_URL_CS}</OrganizationURL>
</Organization>
EOF
`

CONTACTPERSON=`cat <<EOF
<ContactPerson contactType="technical">
    <GivenName>${CONTACTPERSON_GIVENNAME}</GivenName>
    <SurName>${CONTACTPERSON_SURNAME}</SurName>
    <EmailAddress>mailto:${CONTACTPERSON_EMAIL}</EmailAddress>
</ContactPerson>
EOF
`

sed \
    -i.bak \
    -e '2,7d;14,22d' \
    /opt/shibboleth-idp/metadata/idp-metadata.xml

ed -s /opt/shibboleth-idp/metadata/idp-metadata.xml <<EOF
8i
${UIINFO}
.
wq
EOF

ed -s /opt/shibboleth-idp/metadata/idp-metadata.xml <<EOF
207i
${ORGANIZATION}
.
wq
EOF

ed -s /opt/shibboleth-idp/metadata/idp-metadata.xml <<EOF
215i
${CONTACTPERSON}
.
wq
EOF

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


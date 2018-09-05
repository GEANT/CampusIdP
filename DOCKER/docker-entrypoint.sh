#!/usr/bin/env bash

set -e

########################################################################
# Functions ############################################################
########################################################################

function jetty_https() (
    PASSWORDPKCS12=`tr -cd '[:alnum:]' < /dev/urandom | fold -w30 | head -n1`
    PASSWORDKEYSTORE=`tr -cd '[:alnum:]' < /dev/urandom | fold -w30 | head -n1`

    function obfpass() {
        java -cp /opt/jetty-distribution-$JETTY_VERSION/lib/jetty-util-$JETTY_VERSION.jar org.eclipse.jetty.util.security.Password $1 2>&1 | grep OBF\:
    }

    openssl pkcs12 -export -inkey /tmp/jetty/key.pem -in /tmp/jetty/cert.pem -out /tmp/jetty-cert.pkcs12 -passin pass:$JETTY_CERT_KEY -passout pass:$PASSWORDPKCS12
    rm -f /opt/jetty/etc/keystore
    keytool -importkeystore -srckeystore /tmp/jetty-cert.pkcs12 -srcstoretype PKCS12 -destkeystore /opt/jetty/etc/keystore -storepass $PASSWORDKEYSTORE -srcstorepass $PASSWORDPKCS12 -noprompt

    OBFPASS1=$(obfpass $PASSWORDPKCS12)
    OBFPASS2=$(obfpass $PASSWORDKEYSTORE)

    sed -i.bak "s%#\ jetty.sslContext.keyStorePassword=.*%jetty.sslContext.keyStorePassword=$OBFPASS2%; \
        s%#\ jetty.sslContext.keyManagerPassword=.*%jetty.sslContext.keyManagerPassword=$OBFPASS1%; \
        s%#\ jetty.sslContext.trustStorePassword=.*%jetty.sslContext.trustStorePassword=$OBFPASS2%" \
        /opt/jetty/start.d/ssl.ini

    rm -f /tmp/jetty-cert.pkcs12
)

function idp_install_properties() {
cat <<EOF > /opt/idp.install.properties
idp.no.tidy=true
EOF
}

function idp_merge_properties() {
SHIBBOLETH_PASSWORD_SEALER=`tr -cd '[:alnum:]' < /dev/urandom | fold -w30 | head -n1`
SHIBBOLETH_PASSWORD_KEYSTORE=`tr -cd '[:alnum:]' < /dev/urandom | fold -w30 | head -n1`

cat <<EOF > /opt/idp.merge.properties
idp.scope=$SHIBBOLETH_SCOPE
idp.entityID=$SHIBBOLETH_ENTITYID
idp.sealer.storePassword=$SHIBBOLETH_PASSWORD_SEALER
idp.sealer.keyPassword=$SHIBBOLETH_PASSWORD_SEALER
EOF
}

function idp_install {
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

}

function shibboleth_conf() {
    for f in /tmp/shibboleth-idp/conf/*; do
        cp $f /opt/shibboleth-idp/conf/
    done
}

function shibboleth_credentials() {
    for f in /tmp/shibboleth-idp/credentials/*; do
        cp $f /opt/shibboleth-idp/credentials/
    done
}

function shibboleth_idp_properties() {
    sed \
        -i.bak \
        -e "s/idp\.sealer\.storePassword\=\s*.*/idp.sealer.storePassword= ${SHIBBOLETH_PASSWORD_SEALER}/" \
        -e "s/idp\.sealer\.keyPassword\=\s*.*/idp.sealer.keyPassword= ${SHIBBOLETH_PASSWORD_SEALER}/" \
        /opt/shibboleth-idp/conf/idp.properties
}

function shibboleth_ldap_properties() {
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
}

function shibboleth_persistentid() {
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
CONFIGURATION=`cat <<EOF
<bean id="shibboleth.MySQLDataSource"
    class="org.apache.commons.dbcp2.BasicDataSource"
    p:driverClassName="com.mysql.jdbc.Driver"
    p:url="jdbc:mysql://db:3306/shibboleth"
    p:username="shibboleth"
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
        /opt/shibboleth-idp/conf/attribute-resolver.xml

    echo "${PERSISTENTID}" >> /opt/shibboleth-idp/conf/attribute-resolver.xml
    echo -e "\n\n</AttributeResolver>" >> /opt/shibboleth-idp/conf/attribute-resolver.xml

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
}

function shibboleth_metadata() {
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
}

function generate_indexhtml() {
ATTRIBUTEDEF=/opt/shibboleth-idp/conf/attribute-resolver.xml
HEADER="$(cat <<EOF
<!DOCTYPE html>

<html lang="en">
<head>
    <meta charset="utf-8">
    <title>Identity Provider Information Page</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="author" content="Jan Oppolzer; jan@oppolzer.cz">
    <meta name="generator" content="VIM - Vi IMproved 8.0">
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" integrity="sha256-916EbMg70RQy9LHiGkXzG8hSg9EdNy97GazNG/aiY1w= sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u sha256-6MXa8B6uaO18Hid6blRMetEIoPqHf7Ux1tnyIQdpt9qI5OACx7C+O3IVTr98vwGnlcg0LOLa02i9Y1HpVhlfiw==" crossorigin="anonymous">
    <link rel="stylesheet" href="css/style.css">
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.2.1/jquery.min.js" integrity="sha256-hwg4gsxgFZhOsEEamdOYGBf13FyQuiTwlAQgxVSNgt4= sha384-xBuQ/xzmlsLoJpyjoggmTEz8OWUFM0/RC5BsqQBDX2v5cMvDHcMakNTNrHIW2I5f sha512-3P8rXCuGJdNZOnUx/03c1jOTnMn3rP63nBip5gOP2qmUh5YAdVAvFZ1E+QLZZbC1rtMrQb+mah3AfYW11RUrWA==" crossorigin="anonymous"></script>
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js" integrity="sha256-U5ZEeKfGNOja007MMD3YBI0A3OSZOQbeG6z2f2Y0hu8= sha384-Tc5IQib027qvyjSMfHjOMaLkfuWVxZxUPnCJA7l2mCWNIpG9mGCD8wGNIcPD7Txa sha512-iztkobsvnjKfAtTNdHkGVjAYTrrtlC7mGp/54c40wowO7LhURYl3gVzzcEqGl/qKXQltJ2HwMrdLcNUdo+N/RQ==" crossorigin="anonymous"></script>
</head>
<body>

<div class="container">

    <div class="row">
        <div class="col-md-12">

                <div class="jumbotron text-center">
                    <h1>Indentity Provider </h1>
                    <p>of</p>
                    <h2>${UIINFO_DISPLAYNAME_EN}</h2>
            </div>

        </div>
    </div>

    <div class="row">
        <div class="col-md-12">

            <p>This is an Identity Provider for <em>${UIINFO_DISPLAYNAME_EN}</em> running <a
            href="https://www.shibboleth.net/products/identity-provider/">Shibboleth
            Identity Provider</a> inside a Docker container. It is a live
            implementation of <em>GÉANT</em> project called <em>Campus
            IdP</em>.</p>

            <h2>Technical Information</h2>
            <p>To register this Identity Provider to a federation, use this <a
            href="/idp/shibboleth">metadata</a>, however, be careful as it might
            be needed to tweak it a little bit depending on federation's
            policy.</p>
            <p>In case of any technical issues with this IdP, contact <a
            href="mailto:${CONTACTPERSON_EMAIL}">${CONTACTPERSON_GIVENNAME} ${CONTACTPERSON_SURNAME}</a> of <a
            href="${ORGANIZATION_URL_EN}">${ORGANIZATION_DISPLAYNAME_EN}</a>.</p>

            <h2>Available Attributes</h2>
            <p>This Identity Provider implements attributes listed in the table
            below. It does not mean that all attributes are available to all
            federated services, tough. Contact technical support in case
            something does not work as expected.</p>

            <div class="table-responsive">
                <table class="table table-striped table-bordered table-hover">
                    <thead>
                        <tr>
                            <th>Attribute Name</th>
                            <th>Attribute Meaning</th>
                        </tr>
                    </thead>
                    <tbody>
EOF
)"
FOOTER="$(cat <<EOF
                    </tbody>
                </table>
            </div>

            <hr>

            <p class="text-right"><small>Any issues should be reported to <a href="mailto:jan.oppolzer@cesnet.cz">Jan Oppolzer</a>.</small></p>
        </div>
    </div>

</div>

</body>
</html>
EOF
)"
OUTPUT="/opt/jetty/webapps/root/index.html"

attributes=$(grep '<AttributeDefinition' ${ATTRIBUTEDEF} | sed -nr 's/.*id="([a-zA-Z]+)".*/\1/p')

name[0]=givenName
name[1]=sn
name[2]=cn
name[3]=displayName
name[4]=mail
name[5]=o
name[6]=ou
name[7]=eduPersonScopedAffiliation
name[8]=eduPersonTargetedID
name[9]=eduPersonEntitlement
name[10]=eduPersonPrincipalName
name[11]=eduPersonUniqueId

declare -A description
description[givenName]='First name'
description[sn]='Last name'
description[cn]='Full name'
description[displayName]='Display name'
description[mail]='Email address'
description[o]='Organization'
description[ou]='Organization unit'
description[eduPersonScopedAffiliation]='Role(s) in organization'
description[eduPersonTargetedID]='Unique pseudoanonymous identifier'
description[eduPersonEntitlement]='Permissions for specific services'
description[eduPersonPrincipalName]='Unique identifier'
description[eduPersonUniqueId]='Unique persistent identifier'

echo "${HEADER}" > ${OUTPUT}

for attribute in ${name[*]}; do
    if [[ "$attributes" == *$attribute* ]]; then
        printf "                        <tr><td><code>%s</code></td><td>%s</td></tr>\n" "${attribute}" "${description[${attribute}]}" >> ${OUTPUT}
    fi
done

echo "${FOOTER}" >> ${OUTPUT}

}

function shibboleth_cust_editwebapp() {
    if [[ -d /tmp/shibboleth-idp/edit-webapp/ ]]; then
        cp -r /tmp/shibboleth-idp/edit-webapp/* /opt/shibboleth-idp/edit-webapp/
    fi
}

function shibboleth_cust_views() {
    if [[ -d /tmp/shibboleth-idp/views/ ]]; then
        cd /tmp/shibboleth-idp/
        for d in `find views/ -type d`; do
            for f in `find $d -type f`; do
                cp $f /opt/shibboleth-idp/$f
            done
        done
    fi
}

function shibboleth_cust_messages() {
    MESSAGES=/opt/shibboleth-idp/messages/messages.properties
    echo "idp.logo = ${IDP_LOGO}" >> ${MESSAGES}
    echo "idp.logo.alt-text = logo: ${UIINFO_DISPLAYNAME_EN}" >> ${MESSAGES}
}

function shibboleth_rebuild_war() {
    /opt/shibboleth-idp/bin/build.sh -Didp.target.dir=/opt/shibboleth-idp
}

########################################################################

########################################################################
# Variables ############################################################
########################################################################

IDP_CONF_FILE=/opt/shibboleth-idp/conf/.configured

########################################################################

########################################################################
# Configure IdP and Jetty if not already done  #########################
########################################################################
if [[ ! -f ${IDP_CONF_FILE} ]]; then
    echo "============================================"
    echo "Shibboleth IdP and Jetty not yet configured."
    echo "============================================"
    echo ""

    echo "Configuring an HTTPS certificate for Jetty..."
    jetty_https
    echo "Done."
    echo ""

    echo "Preparing configuration for Shibboleth IdP installation proces..."
    idp_install_properties
    idp_merge_properties
    echo "Done."
    echo ""

    echo "Installing Shibboleth IdP..."
    idp_install
    echo "Done."
    echo ""

    echo "Copy files to shibboleth-idp/conf/ directory..."
    shibboleth_conf
    echo "Done."
    echo ""

    echo "Copy files to shibboleth-idp/credentials/ directory..."
    shibboleth_credentials
    echo "Done."
    echo ""

    echo "Configure shibboleth-idp/conf/idp.properties..."
    shibboleth_idp_properties
    echo "Done."
    echo ""

    echo "Configure shibboleth-idp/conf/ldap.properties..."
    shibboleth_ldap_properties
    echo "Done."
    echo ""

    echo "Configure persistent-id aka eduPersonTargetedID..."
    shibboleth_persistentid
    echo "Done."
    echo ""

    echo "Configure shibboleth-idp/metadata/idp-metadata.xml..."
    shibboleth_metadata
    echo "Done."
    echo ""

    echo "Generate index.html..."
    generate_indexhtml
    echo "Done."
    echo ""

    echo "Customize Shibboleth IdP..."
    echo ""

    echo "Copy edit-webapp/..."
    shibboleth_cust_editwebapp
    echo "Done."
    echo ""

    echo "Copy views/..."
    shibboleth_cust_views
    echo "Done."
    echo ""

    echo "Customizing messages/..."
    shibboleth_cust_messages
    echo "Done."
    echo ""

    echo "Rebuilding customized idp.war..."
    shibboleth_rebuild_war
    echo "Done."
    echo ""

    echo `date +%Y-%m-%d\ %H:%M:%S` >> ${IDP_CONF_FILE}

fi

echo "============================================"
echo "Shibboleth IdP and Jetty already configured."
echo "Starting Jetty...                           "
echo "============================================"
echo ""

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


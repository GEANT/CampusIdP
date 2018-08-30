FROM debian:stretch

MAINTAINER Jan Oppolzer <jan@oppolzer.cz>

RUN apt-get -qq update && \
    apt-get -qq -y --no-install-recommends install \
        wget \
        expect \
        openjdk-8-jre-headless \
        gnupg2 \
        dirmngr && \
    rm -rf /var/lib/apt/lists/*

ARG JAVA_HOME
ENV JAVA_HOME=$JAVA_HOME

ARG JETTY_VERSION
ENV JETTY_VERSION=$JETTY_VERSION

COPY gpg/joakim.erdfelt_gmail.com.key /root/gpg/
RUN gpg -q --import /root/gpg/joakim.erdfelt_gmail.com.key

RUN groupadd idp && \
    useradd -m -g idp -s /bin/bash idp && \
    mkdir -p /opt/src /opt/jetty && \
    chown idp:idp /opt/src /opt/jetty && \
    wget -q -P /opt/src http://central.maven.org/maven2/org/eclipse/jetty/jetty-distribution/$JETTY_VERSION/jetty-distribution-$JETTY_VERSION.tar.gz \
                        http://central.maven.org/maven2/org/eclipse/jetty/jetty-distribution/$JETTY_VERSION/jetty-distribution-$JETTY_VERSION.tar.gz.sha1 \
                        http://central.maven.org/maven2/org/eclipse/jetty/jetty-distribution/$JETTY_VERSION/jetty-distribution-$JETTY_VERSION.tar.gz.asc && \
    echo `cat /opt/src/jetty-distribution-$JETTY_VERSION.tar.gz.sha1` /opt/src/jetty-distribution-$JETTY_VERSION.tar.gz | sha1sum -c && \
    gpg -q --verify /opt/src/jetty-distribution-$JETTY_VERSION.tar.gz.asc && \
    tar -xzf /opt/src/jetty-distribution-$JETTY_VERSION.tar.gz -C /opt && \
    chown -R idp:idp /opt/jetty-distribution-$JETTY_VERSION && \
    ln -snf /opt/jetty-distribution-$JETTY_VERSION/bin/jetty.sh /etc/init.d/jetty && \
    echo "JETTY_HOME=/opt/jetty-distribution-$JETTY_VERSION/" > /etc/default/jetty && \
    echo "JETTY_BASE=/opt/jetty" >> /etc/default/jetty && \
    echo "JETTY_USER=idp" >> /etc/default/jetty && \
    cd /opt/jetty && \
    java -jar /opt/jetty-distribution-$JETTY_VERSION/start.jar --add-to-startd=http,https,logging,deploy,jsp,jstl,plus,servlets,annotations,ext,resources,logging,requestlog && \
    wget -q -P /opt/jetty/lib/ext https://aaiwiki.cesnet.cz/idp_files/commons-dbcp2-2.1.1.jar \
                                  https://aaiwiki.cesnet.cz/idp_files/commons-pool2-2.4.2.jar \
                                  https://aaiwiki.cesnet.cz/idp_files/commons-logging-api-1.1.jar && \
    wget -q -P /opt/src https://aaiwiki.cesnet.cz/idp_files/mysql-connector-java-5.1.39.tar.gz && \
    tar -xzf /opt/src/mysql-connector-java-5.1.39.tar.gz -C /opt/src && \
    cp /opt/src/mysql-connector-java-5.1.39/mysql-connector-java-5.1.39-bin.jar /opt/jetty/lib/ext && \
    mkdir -p /opt/jetty/webapps/root && \
    echo etc/tweak-ssl.xml >> /opt/jetty/start.d/https.ini && \
    chown -R idp:idp /opt/jetty/ /opt/jetty-distribution*/

COPY conf/common/jetty/idp.xml /opt/jetty/webapps
COPY conf/common/jetty/tweak-ssl.xml /opt/jetty/etc

ARG SHIBBOLETH_VERSION
ENV SHIBBOLETH_VERSION=$SHIBBOLETH_VERSION

COPY gpg/tzeller_dragonacea.biz.key /root/gpg/
RUN gpg -q --import /root/gpg/tzeller_dragonacea.biz.key

RUN wget -q -P /opt/src/ https://shibboleth.net/downloads/identity-provider/$SHIBBOLETH_VERSION/shibboleth-identity-provider-$SHIBBOLETH_VERSION.tar.gz \
                         https://shibboleth.net/downloads/identity-provider/$SHIBBOLETH_VERSION/shibboleth-identity-provider-$SHIBBOLETH_VERSION.tar.gz.asc \
                         https://shibboleth.net/downloads/identity-provider/$SHIBBOLETH_VERSION/shibboleth-identity-provider-$SHIBBOLETH_VERSION.tar.gz.sha256 && \
    cd /opt/src && sha256sum -c shibboleth-identity-provider-$SHIBBOLETH_VERSION.tar.gz.sha256 && \
    gpg -q --verify /opt/src/shibboleth-identity-provider-$SHIBBOLETH_VERSION.tar.gz.asc && \
    tar -xzf /opt/src/shibboleth-identity-provider-$SHIBBOLETH_VERSION.tar.gz -C /opt

####################################################
#                                                  #
# All the stuff bellow should go to entryscript.sh #
#                                                  #
####################################################

# Container dependent variables
## Jetty
ARG JETTY_CERT_KEY
ARG JETTY_CERT_PKCS12
ARG JETTY_CERT_KEYSTORE
ENV JETTY_CERT_KEY=$JETTY_CERT_KEY \
    JETTY_CERT_PKCS12=$JETTY_CERT_PKCS12 \
    JETTY_CERT_KEYSTORE=$JETTY_CERT_KEYSTORE

## Shibboleth IdP
ARG SHIBBOLETH_SCOPE
ARG SHIBBOLETH_ENTITYID
ARG SHIBBOLETH_HOSTNAME
ARG SHIBBOLETH_PASSWORD_SEALER
ARG SHIBBOLETH_PASSWORD_KEYSTORE
ENV SHIBBOLETH_SCOPE=$SHIBBOLETH_SCOPE \
    SHIBBOLETH_ENTITYID=$SHIBBOLETH_ENTITYID \
    SHIBBOLETH_HOSTNAME=$SHIBBOLETH_HOSTNAME \
    SHIBBOLETH_PASSWORD_SEALER=$SHIBBOLETH_PASSWORD_SEALER \
    SHIBBOLETH_PASSWORD_KEYSTORE=$SHIBBOLETH_PASSWORD_KEYSTORE

# Jetty -- container dependent steps
COPY conf/common/scripts/jetty-keystore.sh conf/$SHIBBOLETH_HOSTNAME/jetty/key.pem conf/$SHIBBOLETH_HOSTNAME/jetty/cert.pem /tmp/
COPY conf/common/web/* /tmp/
RUN /tmp/jetty-keystore.sh $JETTY_VERSION $JETTY_CERT_KEY $JETTY_CERT_PKCS12 $JETTY_CERT_KEYSTORE $SHIBBOLETH_HOSTNAME

# Shibboleth IdP -- container dependent steps
RUN echo idp.no.tidy=true>>/opt/idp.install.properties && \
    echo idp.scope=$SHIBBOLETH_SCOPE>>/opt/idp.merge.properties && \
    echo idp.entityID=$SHIBBOLETH_ENTITYID>>/opt/idp.merge.properties && \
    echo idp.sealer.storePassword=$SHIBBOLETH_PASSWORD_SEALER>>/opt/idp.merge.properties && \
    echo idp.sealer.keyPassword=$SHIBBOLETH_PASSWORD_SEALER>>/opt/idp.merge.properties && \
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

# Shibboleth IdP -- copy host-specific configuration files
COPY conf/$SHIBBOLETH_HOSTNAME/shibboleth-idp/conf/attribute-filter.xml \
     conf/$SHIBBOLETH_HOSTNAME/shibboleth-idp/conf/attribute-resolver.xml \
     conf/$SHIBBOLETH_HOSTNAME/shibboleth-idp/conf/global.xml \
     conf/$SHIBBOLETH_HOSTNAME/shibboleth-idp/conf/idp.properties \
     conf/$SHIBBOLETH_HOSTNAME/shibboleth-idp/conf/ldap.properties \
     conf/$SHIBBOLETH_HOSTNAME/shibboleth-idp/conf/metadata-providers.xml \
     conf/$SHIBBOLETH_HOSTNAME/shibboleth-idp/conf/saml-nameid.properties \
     conf/$SHIBBOLETH_HOSTNAME/shibboleth-idp/conf/saml-nameid.xml \
     /opt/shibboleth-idp/conf/

COPY conf/$SHIBBOLETH_HOSTNAME/shibboleth-idp/credentials/idp-encryption.??? \
     conf/$SHIBBOLETH_HOSTNAME/shibboleth-idp/credentials/idp-signing.??? \
     conf/$SHIBBOLETH_HOSTNAME/shibboleth-idp/credentials/ldap-server.crt \
     conf/$SHIBBOLETH_HOSTNAME/shibboleth-idp/credentials/metadata.eduid.cz.crt.pem \
     /opt/shibboleth-idp/credentials/

COPY conf/common/scripts/shibboleth-rebuild.expect /opt

EXPOSE 8080 8443

COPY docker-entrypoint.sh /
RUN chmod 700 ./docker-entrypoint.sh

ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["${JETTY_VERSION}"]


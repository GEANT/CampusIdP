FROM debian:stretch

MAINTAINER Jan Oppolzer <jan.oppolzer@cesnet.cz>

# Common variables
## Java
ARG JAVA_HOME
ENV JAVA_HOME=$JAVA_HOME

## Jetty
ARG JETTY_VERSION
ARG JETTY_KEY
ENV JETTY_VERSION=$JETTY_VERSION \
    JETTY_KEY=$JETTY_KEY

## Shibboleth IdP
ARG SHIBBOLETH_VERSION
ARG SHIBBOLETH_KEY
ENV SHIBBOLETH_VERSION=$SHIBBOLETH_VERSION \
    SHIBBOLETH_KEY=$SHIBBOLETH_KEY

# update APT cache and install required packages
RUN apt-get -qq update && \
    apt-get -qq -y --no-install-recommends install \
    wget \
    openjdk-8-jre-headless \
    gnupg2 \
    dirmngr && \
    rm -rf /var/lib/apt/lists/*

# Jetty -- common steps
RUN groupadd idp && \
    useradd -m -g idp -s /bin/bash idp && \
    mkdir -p /opt/src /opt/jetty && \
    chown idp:idp /opt/src /opt/jetty && \
    wget -q -P /opt/src http://central.maven.org/maven2/org/eclipse/jetty/jetty-distribution/$JETTY_VERSION/jetty-distribution-$JETTY_VERSION.tar.gz \
                        http://central.maven.org/maven2/org/eclipse/jetty/jetty-distribution/$JETTY_VERSION/jetty-distribution-$JETTY_VERSION.tar.gz.sha1 \
                        http://central.maven.org/maven2/org/eclipse/jetty/jetty-distribution/$JETTY_VERSION/jetty-distribution-$JETTY_VERSION.tar.gz.asc \
                        http://central.maven.org/maven2/org/eclipse/jetty/jetty-distribution/$JETTY_VERSION/jetty-distribution-$JETTY_VERSION.tar.gz.asc.sha1 && \
    echo `cat /opt/src/jetty-distribution-$JETTY_VERSION.tar.gz.sha1` /opt/src/jetty-distribution-$JETTY_VERSION.tar.gz | sha1sum -c && \
    gpg -q --keyserver pgp.mit.edu --recv-keys $JETTY_KEY && \
    gpg -q --verify /opt/src/jetty-distribution-$JETTY_VERSION.tar.gz.asc && \
    tar -xzf /opt/src/jetty-distribution-$JETTY_VERSION.tar.gz -C /opt && \
    chown -R idp:idp /opt/jetty-distribution-$JETTY_VERSION && \
    ln -snf /opt/jetty-distribution-$JETTY_VERSION/bin/jetty.sh /etc/init.d/jetty && \
    echo "JETTY_HOME=/opt/jetty-distribution-$JETTY_VERSION/" > /etc/default/jetty && \
    echo "JETTY_BASE=/opt/jetty" >> /etc/default/jetty && \
    echo "JETTY_USER=idp" >> /etc/default/jetty && \
    cd /opt/jetty && \
    java -jar /opt/jetty-distribution-$JETTY_VERSION/start.jar --add-to-startd=http,https,logging,deploy,jsp,jstl,plus,servlets,annotations,ext,resources,logging,requestlog && \
    mkdir -p /opt/jetty/webapps/root && \
    echo etc/tweak-ssl.xml >> /opt/jetty/start.d/https.ini && \
    chown -R idp:idp /opt/jetty/ /opt/jetty-distribution*/

COPY jetty/idp.xml /opt/jetty/webapps
COPY jetty/tweak-ssl.xml /opt/jetty/etc

# Shibboleth IdP -- common steps
RUN wget -q -P /opt/src/ https://shibboleth.net/downloads/identity-provider/$SHIBBOLETH_VERSION/shibboleth-identity-provider-$SHIBBOLETH_VERSION.tar.gz \
                         https://shibboleth.net/downloads/identity-provider/$SHIBBOLETH_VERSION/shibboleth-identity-provider-$SHIBBOLETH_VERSION.tar.gz.asc \
                         https://shibboleth.net/downloads/identity-provider/$SHIBBOLETH_VERSION/shibboleth-identity-provider-$SHIBBOLETH_VERSION.tar.gz.sha256 && \
    cd /opt/src && sha256sum -c shibboleth-identity-provider-$SHIBBOLETH_VERSION.tar.gz.sha256 && \
    gpg -q --keyserver pgp.mit.edu --recv-keys $SHIBBOLETH_KEY && \
    gpg -q --verify /opt/src/shibboleth-identity-provider-$SHIBBOLETH_VERSION.tar.gz.asc && \
    tar -xzf /opt/src/shibboleth-identity-provider-$SHIBBOLETH_VERSION.tar.gz -C /opt

# Clean packages
RUN apt-get -qq -y purge \
    wget \
    gnupg2 \
    dirmngr && \
    apt-get -qq -y autoremove

# Clean source codes
RUN rm -rf /opt/src

# Container dependent variables
## Jetty
ARG PASSWORD_CERT_KEY
ARG PASSWORD_PKCS12
ARG PASSWORD_KEYSTORE
ENV PASSWORD_CERT_KEY=$PASSWORD_CERT_KEY \
    PASSWORD_PKCS12=$PASSWORD_PKCS12 \
    PASSWORD_KEYSTORE=$PASSWORD_KEYSTORE

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
COPY jetty-keystore.sh hosts/$SHIBBOLETH_HOSTNAME/key.pem hosts/$SHIBBOLETH_HOSTNAME/cert.pem /tmp/
RUN echo $SHIBBOLETH_ENTITYID >> /opt/jetty/webapps/root/index.html && \
    /tmp/jetty-keystore.sh $JETTY_VERSION $PASSWORD_CERT_KEY $PASSWORD_PKCS12 $PASSWORD_KEYSTORE $SHIBBOLETH_HOSTNAME

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
COPY hosts/$SHIBBOLETH_HOSTNAME/attribute-filter.xml \
     hosts/$SHIBBOLETH_HOSTNAME/attribute-resolver.xml \
     hosts/$SHIBBOLETH_HOSTNAME/ldap.properties \
     hosts/$SHIBBOLETH_HOSTNAME/metadata-providers.xml \
     hosts/$SHIBBOLETH_HOSTNAME/relying-party.xml \
     /opt/shibboleth-idp/conf/

COPY hosts/$SHIBBOLETH_HOSTNAME/ldap-server.crt \
     hosts/$SHIBBOLETH_HOSTNAME/metadata.eduid.cz.crt.pem \
     /opt/shibboleth-idp/credentials/

EXPOSE 8080 8443

#CMD ["/bin/bash"]

CMD ["sh", "-c", "java \
    -Djetty.logging.dir=/opt/jetty/logs \
    -Djetty.home=/opt/jetty-distribution-$JETTY_VERSION \
    -Djetty.base=/opt/jetty \
    -Djava.io.tmpdir=/tmp \
    -jar \
    /opt/jetty-distribution-$JETTY_VERSION/start.jar \
    jetty.state=/opt/jetty/jetty.state \
    jetty-logging.xml \
    jetty-started.xml \
    start-log-file=/opt/jetty/logs/start.log"]


FROM shibboleth-idp:latest

MAINTAINER Jan Oppolzer <jan@oppolzer.cz>

# Common variables
## Jetty
ARG JETTY_VERSION
ENV JETTY_VERSION=$JETTY_VERSION

## Shibboleth IdP
ARG SHIBBOLETH_VERSION
ENV SHIBBOLETH_VERSION=$SHIBBOLETH_VERSION

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

RUN apt-get update && \
    apt-get -qq -y install patch

COPY hosts/$SHIBBOLETH_HOSTNAME/idp-metadata.patch \
     /opt/shibboleth-idp/metadata/

RUN cd /opt/shibboleth-idp/metadata && \
    patch idp-metadata.xml idp-metadata.patch

COPY hosts/$SHIBBOLETH_HOSTNAME/idp.properties \
     /opt/shibboleth-idp/conf/

COPY hosts/$SHIBBOLETH_HOSTNAME/idp-encryption.??? \
     hosts/$SHIBBOLETH_HOSTNAME/idp-signing.??? \
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


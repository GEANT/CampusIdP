FROM debian:stretch

MAINTAINER Jan Oppolzer <jan.oppolzer@cesnet.cz>

ENV JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64/jre"

# update APT cache and install required packages
RUN apt-get update && \
    apt-get -y --no-install-recommends install \
    wget \
    openjdk-8-jre \
    vim \
    less && \
    rm -rf /var/lib/apt/lists/*

# Jetty
ENV JETTY_VERSION="9.3.20.v20170531"\
    PASSWORD_CERT_KEY="jo7ahrie6aecoog2Eeng" \
    PASSWORD_PKCS12="aiveibooch1Ohk9ahxi3" \
    PASSWORD_KEYSTORE="oe7taiXiopiex2jusei8"

COPY jetty-keystore.sh key.pem cert.pem /tmp/

RUN groupadd idp && \
    useradd -m -g idp -s /bin/bash idp && \
    mkdir -p /opt/src /opt/jetty && \
    chown idp:idp /opt/src /opt/jetty && \
    wget -q -P /opt/src http://central.maven.org/maven2/org/eclipse/jetty/jetty-distribution/$JETTY_VERSION/jetty-distribution-$JETTY_VERSION.tar.gz \
                        http://central.maven.org/maven2/org/eclipse/jetty/jetty-distribution/$JETTY_VERSION/jetty-distribution-$JETTY_VERSION.tar.gz.sha1 \
                        http://central.maven.org/maven2/org/eclipse/jetty/jetty-distribution/$JETTY_VERSION/jetty-distribution-$JETTY_VERSION.tar.gz.asc \
                        http://central.maven.org/maven2/org/eclipse/jetty/jetty-distribution/$JETTY_VERSION/jetty-distribution-$JETTY_VERSION.tar.gz.asc.sha1 && \
    echo `cat /opt/src/jetty-distribution-$JETTY_VERSION.tar.gz.sha1` /opt/src/jetty-distribution-$JETTY_VERSION.tar.gz | sha1sum -c && \
    # FIXME check GPG
    tar -xzf /opt/src/jetty-distribution-$JETTY_VERSION.tar.gz -C /opt && \
    chown -R idp:idp /opt/jetty-distribution-$JETTY_VERSION && \
    ln -snf /opt/jetty-distribution-$JETTY_VERSION/bin/jetty.sh /etc/init.d/jetty && \
    echo "JETTY_HOME=/opt/jetty-distribution-$JETTY_VERSION/" > /etc/default/jetty && \
    echo "JETTY_BASE=/opt/jetty" >> /etc/default/jetty && \
    echo "JETTY_USER=idp" >> /etc/default/jetty && \
    cd /opt/jetty && \
    java -jar /opt/jetty-distribution-$JETTY_VERSION/start.jar --add-to-startd=http,https,logging,deploy,jsp,jstl,plus,servlets,annotations,ext,resources,logging,requestlog && \
    mkdir -p /opt/jetty/webapps/root && \
    echo "stretch-shib-idp-test01" >> /opt/jetty/webapps/root/index.html && \
    wget -q -P /opt/jetty/webapps https://www.eduid.cz/_media/cs/tech/idp/idp.xml && \
    wget -q -P /opt/jetty/etc https://www.eduid.cz/_media/cs/tech/idp/tweak-ssl.xml && \
    echo etc/tweak-ssl.xml >> /opt/jetty/start.d/https.ini && \
    chown -R idp:idp /opt/jetty/ /opt/jetty-distribution*/ && \
    /tmp/jetty-keystore.sh $JETTY_VERSION $PASSWORD_CERT_KEY $PASSWORD_PKCS12 $PASSWORD_KEYSTORE

# Shibboleth IdP
ENV SHIBBOLETH_VERSION="3.3.1" \
    SHIBBOLETH_SCOPE="devnull.cesnet.cz" \
    SHIBBOLETH_ENTITYID="https://devnull.cesnet.cz/idp/shibboleth" \
    SHIBBOLETH_HOSTNAME="devnull.cesnet.cz" \
    SHIBBOLETH_PASSWORD_SEALER="aif8ohx6sheetai0Gae1" \
    SHIBBOLETH_PASSWORD_KEYSTORE="yifohToh5cafoonai5ie"

RUN wget -q -P /opt/src/ https://shibboleth.net/downloads/identity-provider/$SHIBBOLETH_VERSION/shibboleth-identity-provider-$SHIBBOLETH_VERSION.tar.gz \
                         https://shibboleth.net/downloads/identity-provider/$SHIBBOLETH_VERSION/shibboleth-identity-provider-$SHIBBOLETH_VERSION.tar.gz.asc \
                         https://shibboleth.net/downloads/identity-provider/$SHIBBOLETH_VERSION/shibboleth-identity-provider-$SHIBBOLETH_VERSION.tar.gz.sha256 && \
    cd /opt/src && sha256sum -c shibboleth-identity-provider-$SHIBBOLETH_VERSION.tar.gz.sha256 && \
    # FIXME check GPG
    tar -xzf /opt/src/shibboleth-identity-provider-$SHIBBOLETH_VERSION.tar.gz -C /opt && \
    echo idp.no.tidy=true>>/opt/idp.install.properties && \
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

# Clean packages
RUN apt-get -y purge wget && \
    apt-get -y autoremove

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


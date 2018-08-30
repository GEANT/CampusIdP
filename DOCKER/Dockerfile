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

ARG JETTY_VERSION
ARG SHIBBOLETH_VERSION
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre \
    JETTY_VERSION=$JETTY_VERSION \
    SHIBBOLETH_VERSION=$SHIBBOLETH_VERSION

COPY gpg/ /root/gpg/
RUN gpg -q --import /root/gpg/joakim.erdfelt_gmail.com.key && \
    gpg -q --import /root/gpg/tzeller_dragonacea.biz.key

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

RUN wget -q -P /opt/src/ https://shibboleth.net/downloads/identity-provider/$SHIBBOLETH_VERSION/shibboleth-identity-provider-$SHIBBOLETH_VERSION.tar.gz \
                         https://shibboleth.net/downloads/identity-provider/$SHIBBOLETH_VERSION/shibboleth-identity-provider-$SHIBBOLETH_VERSION.tar.gz.asc \
                         https://shibboleth.net/downloads/identity-provider/$SHIBBOLETH_VERSION/shibboleth-identity-provider-$SHIBBOLETH_VERSION.tar.gz.sha256 && \
    cd /opt/src && sha256sum -c shibboleth-identity-provider-$SHIBBOLETH_VERSION.tar.gz.sha256 && \
    gpg -q --verify /opt/src/shibboleth-identity-provider-$SHIBBOLETH_VERSION.tar.gz.asc && \
    tar -xzf /opt/src/shibboleth-identity-provider-$SHIBBOLETH_VERSION.tar.gz -C /opt

ARG JETTY_CERT_KEY
ARG JETTY_CERT_PKCS12
ENV JETTY_CERT_KEY=$JETTY_CERT_KEY \
    JETTY_CERT_PKCS12=$JETTY_CERT_PKCS12

ARG SHIBBOLETH_SCOPE
ARG SHIBBOLETH_ENTITYID
ARG SHIBBOLETH_HOSTNAME
ENV SHIBBOLETH_SCOPE=$SHIBBOLETH_SCOPE \
    SHIBBOLETH_ENTITYID=$SHIBBOLETH_ENTITYID \
    SHIBBOLETH_HOSTNAME=$SHIBBOLETH_HOSTNAME

COPY conf/common/scripts/ /tmp/
COPY docker-entrypoint.sh /

EXPOSE 8080 8443

ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["${JETTY_VERSION}"]


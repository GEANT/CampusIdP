# GEANT GN4.2 JRA3 Task 1 Campus IdP - Cloud IDP on Docker
# Using CentOS base image
# Version 0.0

# Pull the rhel image from the local repository
FROM centos:latest
USER root

MAINTAINER mario.reale@garr.it


ENV JAVA_HOME=/usr/lib/jvm/jre
ENV IDP_SRC=/usr/local/src/shibboleth-identity-provider-3.3.1



# Update image
RUN yum update -y
RUN yum install -y dnf install vim-enhanced java-1.8.0-openjdk java-1.8.0-openjdk-devel ca-certificates openssl httpd mod_ssl expat wget tar ntp initscripts.x86_64


RUN set -x; \
    echo "127.0.0.1 geantsrv7.ct1.garrservices.it geantsrv7" >> /etc/hosts; \
    cat /etc/hosts

RUN set -x; \
    touch /etc/environment; \
    echo "JAVA_HOME=/usr/lib/jvm/jre" >> /etc/environment; \
    echo "IDP_SRC=/usr/local/src/shibboleth-identity-provider-3.3.1" >> /etc/environment; \
    cat  /etc/environment

RUN set -x; \
    mkdir -p /root/certificates

ADD idp-cert-server.crt /root/certificates/idp-cert-server.crt
ADD idp-key-server.key /root/certificates/idp-key-server.key
ADD DigiCertCA.crt /root/certificates/DigiCertCA.crt

RUN set -x; \
    chmod 400 /root/certificates/idp-key-server.key; \
    chmod 644 /root/certificates/idp-cert-server.crt; \
    chmod 644 /root/certificates/DigiCertCA.crt

RUN  set -x; \
     echo 1 | update-alternatives --config java ; \
     echo 1 | update-alternatives --config javac 

RUN set -x; \
    touch /etc/default/jetty; \
    echo "JETTY_HOME=/usr/local/src/jetty-src" >> /etc/default/jetty; \
    echo "JETTY_BASE=/opt/jetty" >> /etc/default/jetty; \
    echo "JETTY_USER=jetty" >> /etc/default/jetty; \
    echo "JETTY_LOGS=/var/log/jetty" >>  /etc/default/jetty; \
    echo "TMPDIR=/opt/jetty/tmp" >> /etc/default/jetty; \
    echo "JAVA_OPTIONS=\"-Djava.awt.headless=true -XX:+DisableExplicitGC -XX:+UseParallelOldGC -Xms256m -Xmx2g -Djava.security.egd=file:/dev/./urandom -Didp.home=/opt/shibboleth-idp\"" >> /etc/default/jetty 

WORKDIR /usr/local/src

RUN  set -x; \
     wget http://repo1.maven.org/maven2/org/eclipse/jetty/jetty-distribution/9.3.11.v20160721/jetty-distribution-9.3.11.v20160721.tar.gz; \
     tar xzvf jetty-distribution-9.3.11.v20160721.tar.gz; \
     ln -s jetty-distribution-9.3.11.v20160721 jetty-src; \ 
     useradd -r -m jetty; \
     mkdir /opt/jetty

WORKDIR /opt/jetty

ADD start.ini /opt/jetty/start.ini 

RUN set -x; \
    mkdir /opt/jetty/tmp ; \
    chown jetty:jetty /opt/jetty/tmp; \
    chown -R jetty:jetty /opt/jetty/ /usr/local/src/jetty-src

WORKDIR /etc/init.d

RUN set -x; \
    ln -s /usr/local/src/jetty-src/bin/jetty.sh jetty; \
    chkconfig jetty on; \
    mkdir /var/log/jetty; \ 
    chown jetty:jetty /var/log/jetty

EXPOSE 4443 8443


CMD ["start"]
ENTRYPOINT ["jetty.sh"]

CMD ["check"]
ENTRYPOINT ["jetty.sh"]


# Install Shibboleth

WORKDIR /usr/local/src

RUN set -x; \
    wget http://shibboleth.net/downloads/identity-provider/3.3.1/shibboleth-identity-provider-3.3.1.tar.gz; \
    tar -xzvf shibboleth-identity-provider-3.3.1.tar.gz; 

WORKDIR  /usr/local/src/shibboleth-identity-provider-3.3.1

## need to sort out : how to run the shib install.sh script within the container



# Dockerized Campus IdP platform

This document briefly describes dockerized *Campus IdP* platform. It has been developed and tested using `Docker version 18.03.1-ce` and `docker-compose version 1.21.2` so it is recommended to use the versions mentioned or newer.

The primary way to run this is to use `docker-compose` command, but prior to taht two configuration files have to be prepared.

## debian:stretch-slim

Using `debian:stretch` official Debian Docker image produces resulting image 340MB in size. There is also `debian:stretch-slim`, which is 46 MB smaller compared to `debian:stretch`. In case such saving is desirable, changing the first line of `Dockerfile` and also putting `mkdir -p /usr/share/man/man1` right before `apt-get install` command due to a [reported bug][] is enough.

| Docker image                       | Size  |
| ---------------------------------- | -----:|
| `debian:stretch` (base image)      | 101MB |
| `debian:stretch-slim` (base image) |  55MB |
| `debian:stretch` (Campus IdP)      | 340MB |
| `debian:stretch-slim` (Campus IdP) | 287MB |
| `mysql:5` (base image)             | 372MB |
| `mariadb:10.1` (base image)        | 407MB |

Althoug, `db` container for storing values of `persistent-id` (aka `eduPersonTargetedID` attribute) consumes _372MB_, so saving 53MB could make a difference for someone.

It could be saved additional 48MB by deleting `/opt/shibboleth-identity-provider-$SHIBBOLETH_VERSION/` directory which is not neccessary after it has been installed using `install.sh` script. However, that assumes the installation is run from the `Dockerfile` not `docker-entrypoint.sh`. And I am sure it is not worth it.

## MySQL or MariaDB

Although the current `docker-compose.yml` deploys MySQL (`mysql:5`), it has been tested with MariaDB (`mariadb:10.1`) as well. Switching to MariaDB is as easy as tweaking `docker-compose.yml` file as follows:

```
  db:
-   image: mysql:5
+   image: mariadb:10.1
-   hostname: mysql
+   hostname: mariadb
```

## Configure an IdP

Prior to running an IdP, two configuration files must be prepared as already mentioned.

FIXME: `JETTY_VERSION` and `SHIBBOLETH_VERSION`.

### idp.conf

In this file, which is loaded automatically by `docker-compose.yml`, all "internal" configuration for the IdP itself is defined. These variables are not necessary for building the image, these are required only when `docker-entrypoint.sh` is run to configure built image, i.e. installed IdP. There are mostly various passwords, however, _scope_ and _entityID_ definitions for the IdP etc. should be paid attention to as well. All variables should be easily understood.

One of the most important variable, which might be somehow confusing, is `JETTY_CERT_KEY` -- the password to the HTTPS certificate.

```
JETTY_CERT_KEY=iemooP4mu3neuPhiequi

SHIBBOLETH_SCOPE=idp.example.org
SHIBBOLETH_ENTITYID=https://idp.example.org/idp/shibboleth
SHIBBOLETH_HOSTNAME=idp.example.org

LDAP_AUTHENTICATOR=bindSearchAuthenticator
LDAP_LDAPURL=ldaps://ldap.example.org:636
LDAP_USESTARTTLS=false
LDAP_USESSL=true
LDAP_SSLCONFIG=certificateTrust
LDAP_BASEDN=ou=people,dc=example,dc=org
LDAP_SUBTREESEARCH=false
LDAP_BINDDN=uid=shibboleth,ou=special users,dc=example,dc=org
LDAP_BINDDNCREDENTIAL=taiSh9aishaimoo7tiey

PERSISTENTID_SOURCEATTRIBUTE=uid
PERSISTENTID_SALT=SWmGA5tfBJMI+PZHyKbp9D/CA9rw+omRcFcNw4XftbGDVduF

UIINFO_DISPLAYNAME_EN=ORGANIZATION
UIINFO_DISPLAYNAME_CS=ORGANIZACE
UIINFO_DESCRIPTION_EN=Identity Provider for ORGANIZATION employees.
UIINFO_DESCRIPTION_CS=Poskytovatel identity pro zaměstnance ORGANIZACE.
UIINFO_INFORMATIONURL_EN=https://www.example.org/en
UIINFO_INFORMATIONURL_CS=https://www.example.org/cs
UIINFO_LOGO=https://idp.example.org/idp/images/logo.png
UIINFO_LOGO_WIDTH=100
UIINFO_LOGO_HEIGHT=50

ORGANIZATION_NAME_EN=ORGANIZATION
ORGANIZATION_NAME_CS=ORGANIZACE
ORGANIZATION_DISPLAYNAME_EN=ORGANIZATION
ORGANIZATION_DISPLAYNAME_CS=ORGANIZACE
ORGANIZATION_URL_EN=https://www.example.org/en
ORGANIZATION_URL_CS=https://www.example.org/cs

CONTACTPERSON_GIVENNAME=John
CONTACTPERSON_SURNAME=Doe
CONTACTPERSON_EMAIL=john.doe@example.org
```

### db.conf

This file contains all database stuff, such as root password, database name, etc. Database is used for storing attribute release consents and computed `persistent-id`s aka `eduPersonTargetedID`.

```
MYSQL_ROOT_PASSWORD=shie9aez5Ahzakah9aen
MYSQL_DATABASE=shibboleth
MYSQL_USER=shibboleth
MYSQL_PASSWORD=miehaiph3chohghoaXah
```

## Run an IdP

In order to run an IdP a variable $HOST must be defined and its value is expected to be the subdirectory name under `conf/` directory where all configuration (IdP and database) is defined. Either `export HOST` variable or type `HOST` variable at the beginning of `docker-compose` command.

### Start your IdP

Now it is possible to run `docker-compose` command. It is a very good idea to specify "a project name" using `-p` parameter. For example, a domain name or server host name would be a great choice.

```bash
HOST=idp.example.org docker-compose -p example up -d --build
```

## Stop an IdP

To shut down the IdP including database, run:

```bash
docker-compose -p example down
```

### Stop and deleting everything

To stop and delete running container, delete all built images and data volumes, run the following command:

```bash
docker-compose -p example down --rmi local -v --remove-orphans
```

Using `all` argument for `--rmi` option would delete even images downloaded from internet. Nobody would want to use that since it is just a waste of bandwidth on both sides.

[reported bug]: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=863199


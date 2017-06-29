# How to use this?

In case, you have:

1. Working Docker environment.
2. A certificate with the full chain in `cert.pem` file.
3. A private key in `key.pem` file.

You just need to follow these steps:

1. Clone the repository.
2. Tweak at least `PASSWORD_CERT_KEY` (private key for the certificate) variable in `Dockerfile`.
3. Execute `build.sh`.
4. Execute `run.sh`.
5. In case you would like to go into the container, execute `attach.sh`.
6. To stop the container, execute `stop.sh`.

To get Shibboleth IdP up and running. However, no configuration (LDAP etc.) is available at this moment.


# How to use this?

In case, you have:

1. Working Docker environment. The official latest version required -- 17.09.0-ce.
2. A certificate with the full chain in `certificates/$FQDN.crt.pem` file.
3. A private key in `certificates/$FQDN.key.pem` file.

You just need to follow these steps:

1. Clone the repository.
2. Tweak at least `PASSWORD_CERT_KEY` (private key for the certificate) variable in `Dockerfile`.
3. Execute `build.sh`.
4. Execute `run.sh`.
5. In case you would like to go into the container, execute `attach.sh`.
6. To stop the container, execute `stop.sh`.

To get Shibboleth IdP up and running. However, no configuration (LDAP etc.) is available at this moment.

You can check that the IdP is running by accessing ports `8080` (*HTTP*) and `8443` (*HTTPS*). For example, to show IdP's metadata go to the following URL address:
* `https://your_machine_IP_address:8443/idp/shibboleth`

Status of the IdP can be obtained using a shell. One just need to attach the running Docker container and check `idp-process.log` log file which should contain the following line:
```bash
$ ./attach.sh
root@stretch-shib-idp-test01:/# grep REMOTE_USER /opt/shibboleth-idp/logs/idp-process.log
2017-09-07 08:45:52,971 - INFO [net.shibboleth.idp.authn.impl.RemoteUserAuthServlet:193] - RemoteUserAuthServlet will process REMOTE_USER, along with attributes [] and headers []
```


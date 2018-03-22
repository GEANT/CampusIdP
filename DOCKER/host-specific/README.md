# What's this?

This directory contains (almost) everything you need to build your own Shibboleth IdP using Docker.

You'll need the following:

1. Working Docker environment. The official latest version required -- 17.09.0-ce.
2. A certificate with the full chain in `hosts/$FQDN/cert.pem` file.
3. A private key in `hosts/$FQDN/key.pem` file.

You just need to follow these steps:

1. Clone the repository. (I mean the whole repository, not just this subdirectory as you need to build base Docker image.)
2. Copy `hosts/idp.example.org/buildenv.conf` configuration file to a subdirectory `hosts/$FQDN/buildenv.conf`.
3. Tweak at least `PASSWORD_CERT_KEY` (private key for the certificate) variable in `hosts/$FQDN/buildenv.conf`.
4. Execute `build.sh`.
5. Run MySQL container for storing persistent-ids (eduPersonTargetedIDs) by calling `./run-mysql.sh`.
6. Execute `run.sh`.
7. In case you would like to go into the container, execute `attach.sh`.
8. To stop the container, execute `stop.sh`.
9. Grab IdP's metadata (`https://your_machine_IP_address/idp/shibboleth`) and insert it into your (testing?) federation.
10. Wait for metadata to propagate.
11. Select a service from your (testing?) federation and try to log in using the newly installed IdP.

You can check that the IdP is running by accessing ports `80` (*HTTP*) and `443` (*HTTPS*). For example, to show IdP's metadata go to the following URL address:
* `https://your_machine_IP_address/idp/shibboleth`

Status of the IdP can be obtained using a shell. One just need to attach the running Docker container and check `idp-process.log` log file which should contain the following line:
```bash
$ ./attach.sh
root@stretch-shib-idp-test01:/# grep REMOTE_USER /opt/shibboleth-idp/logs/idp-process.log
2017-09-07 08:45:52,971 - INFO [net.shibboleth.idp.authn.impl.RemoteUserAuthServlet:193] - RemoteUserAuthServlet will process REMOTE_USER, along with attributes [] and headers []
```


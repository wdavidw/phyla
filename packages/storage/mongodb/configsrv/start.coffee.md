
# MongoDB Config Server Start

Run the command `./bin/ryba start -m @rybajs/storage/mongodb/configsrv` to start the 
MongoDB Config server using Ryba.

By default, the pid of the running server is stored in
"/var/run/mongod/mongod-config-server-{fqdn}.pid".

    module.exports = header: 'MongoDB Config Server Start', handler: ({options}) ->

## Service

Start the MongDB Config server. You can also start the server manually with one of the
following commands:

```
service mongod-config-server start
systemctl start mongod-config-server
su -l mongod -c "/usr/bin/mongod --quiet -f /etc/mongod-config-server/conf/mongod.conf run"
```

      @service.start name: 'mongod-config-server'


# MongoDB Shard Server Start

Run the command `./bin/ryba start -m ryba/mongodb/shard` to start the 
MongoDB Shard server using Ryba.

By default, the pid of the running server is stored in
"/var/run/mongod/mongod-shard-server-{fqdn}.pid".

    module.exports = header: 'MongoDB Shard Server Start', label_true: 'STARTED', handler: (options) ->

## Service

Start the MongDB Config server. You can also start the server manually with one of the
following commands:

```
service mongod-shard-server start
systemctl start mongod-shard-server
su -l mongod -c "/usr/bin/mongod --quiet -f /etc/mongod-shard-server/conf/mongod.conf run"
```

      @service.start name: 'mongod-shard-server'

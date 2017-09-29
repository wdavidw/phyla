
## Configure

    module.exports = (service) ->
      service = migration.call @, service, 'ryba/mongodb/shard', ['ryba', 'mongodb', 'shard'], require('nikita/lib/misc').merge require('.').use,
        iptables: key: ['iptables']
        krb5_client: key: ['krb5_client']
        locale: key: ['locale']
        ssl: key: ['ssl']
        repo: key: ['ryba','mongodb','repo']
        config_servers: key: ['ryba', 'mongodb', 'configsrv']
        shard_servers: key: ['ryba', 'mongodb', 'shard']
      @config.ryba ?= {}
      @config.ryba.mongodb ?= {}
      options = @config.ryba.mongodb.shard = service.options

## Identities

By default, merge group and user from the MongoDb config server.

      options.group = merge service.use.config_servers[0].options.group, options.group
      options.user = merge service.use.config_servers[0].options.user, options.user

## Configuration

      options.conf_dir ?= '/etc/mongod-shard-server/conf'
      options.pid_dir ?= '/var/run/mongod'
      #mongo admin user for mongod instances belonging to a replica set
      options.admin ?= {}
      options.admin.name ?= 'admin'
      options.admin.password ?= 'admin123'
      options.root ?= {}
      options.root.name ?= 'root_admin'
      options.root.password ?= 'root123'
      # Misc
      options.fqdn ?= service.node.fqdn
      options.hostname = service.node.hostname
      options.iptables ?= service.use.iptables and service.use.iptables.options.action is 'start'
      options.clean_logs ?= false
      options.config ?= {}
      # setting the role of mongod process as a mongodb config server
      options.config.sharding ?= {}
      options.config.sharding.clusterRole ?= 'shardsvr'

## Logs

      options.config.systemLog ?= {}
      options.config.systemLog.destination ?= 'file'
      options.config.systemLog.logAppend ?= true
      options.config.systemLog.path ?= "/var/log/mongodb/mongod-shard-server-#{service.node.hostname}.log"

## Storage

From 3.2, config servers for sharded clusters can be deployed as a replica set.
The replica set config servers must run the WiredTiger storage engine

      options.config.storage ?= {}
      options.config.storage.dbPath ?= "#{options.user.home}/shard/db"
      options.config.storage.journal ?= {}
      options.config.storage.journal.enabled ?= true
      options.config.storage.engine ?= 'wiredTiger'
      options.config.storage.repairPath ?= "#{options.config.storage.dbPath}/repair" unless options.config.storage.engine is 'wiredTiger'
      throw Error 'Need WiredTiger Storage for shard server as replica set' unless options.config.storage.engine is 'wiredTiger'
      if options.config.storage.repairPath?.indexOf(options.config.storage.dbPath) is -1
        throw Error 'Must use a repairpath that is a subdirectory of dbpath when using journaling' if options.config.storage.journal.enabled

## Replica Set Sharding

Custom layout is mandatory, ryba does not create replicaset automatically.
The property `ryba.options.replicaset` contains the replicaset name whom the shard server belongs to.
Ryba will go through every ryba/mongodb/shard to compute the replica sets and check the layout.
Ryba user must provide the replica set master by set the boolean property `ryba.options.is_master`.

      options.config.replication ?= {}
      throw Error 'Missing Replica Set Name ryba.options.replicaset' unless options.replicaset?
      options.replicasets = {}
      options.is_master ?= false
      for srv in service.use.shard_servers
        options.replicasets[srv.options.replicaset] ?= {}
        options.replicasets[srv.options.replicaset]['hosts'] ?= []
        options.replicasets[srv.options.replicaset]['hosts'].push srv.node.fqdn
        options.replicaset_master = srv.node.fqdn if srv.options.is_master and (srv.options.replicaset is options.replicaset)
      options.config.replication ?= {}
      options.config.replication.replSetName ?= options.replicaset
      throw Error 'No master defined for replica' unless options.replicaset_master

## ShardServer to ConfigServer Mapping

Each Shard Cluster must be attributed to only one Config server Replica set.
In the configuration, administrator must set the property `ryba.options.config_replicat_set`, to designated which
config servers replica set will hold metadata.

      # we  check if shard Cluster is not attributed to different config replica set
      #for now shard server only know to which shard server replica set it is attributed.
      # lest attribute it to a config server replicat set if not one is defnied.
      throw Error 'Missing Config Server Replicat Set Name' unless options.config_replicaset?

## Process

      options.config.processManagement ?= {}
      options.config.processManagement.fork ?= true
      options.config.processManagement.pidFilePath ?= "#{options.pid_dir}/mongod-shard-server-#{@config.host}.pid"

## Network

[Configuring][mongod-ssl] ssl for the mongod process.

      options.config.net ?= {}
      options.config.net.port ?= 27019
      options.config.net.bindIp ?= '0.0.0.0'
      options.config.net.unixDomainSocket ?= {}
      options.config.net.unixDomainSocket.pathPrefix ?= "#{options.pid_dir}"

## Security

      # disables the apis
      options.config.net.http ?=  {}
      options.config.net.http.enabled ?= false
      options.config.net.http.JSONPEnabled ?= false
      options.config.net.http.RESTInterfaceEnabled ?= false
      options.config.security ?= {}
      options.config.security.clusterAuthMode ?= 'x509'

## SSL

      options.ssl = merge {}, service.use.ssl?.options, options.ssl
      options.ssl.enabled = !!service.use.ssl
      if options.ssl.enabled
        throw Error "Required Option: ssl.cert" if  not options.ssl.cert
        throw Error "Required Option: ssl.key" if not options.ssl.key
        throw Error "Required Option: ssl.cacert" if not options.ssl.cacert
      switch options.config.security.clusterAuthMode
        when 'x509'
          options.config.net.ssl ?= {}
          options.config.net.ssl.mode ?= 'preferSSL'
          options.config.net.ssl.PEMKeyFile ?= "#{options.conf_dir}/key.pem"
          options.config.net.ssl.PEMKeyPassword ?= "mongodb123"
          # use PEMkeyfile by default for membership authentication
          # options.config.net.ssl.clusterFile ?= "#{mongodb.options.configsrv.conf_dir}/cluster.pem" # this is the mongodb version of java trustore
          # options.config.net.ssl.clusterPassword ?= "mongodb123"
          options.config.net.ssl.CAFile ?=  "#{options.conf_dir}/cacert.pem"
          options.config.net.ssl.allowConnectionsWithoutCertificates ?= false
          options.config.net.ssl.allowInvalidCertificates ?= false
          options.config.net.ssl.allowInvalidHostnames ?= false
        when 'keyFile'
          mongodb.sharedsecret ?= 'sharedSecretForMongodbCluster'
        else
          throw Error ' unsupported cluster authentication Mode'

## ACL's

      options.config.security.authorization ?= 'enabled'

## Kerberos
Kerberos authentication is only avaiable in enterprise edition.
Should work nonetheless.

      options.krb5 ?= {}
      options.krb5.realm ?= service.use.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      # Admin Information
      options.krb5.admin ?= service.use.krb5_client.options.admin[options.krb5.realm]
      options.config.security.sasl ?= {}
      options.config.security.sasl.hostName ?= service.node.fqdn
      options.config.security.sasl.serviceName ?= 'mongodb' # Can override only on interprise edition
      options.sasl_password  ?= 'mongodb123'

## Wait

      options.wait_krb5_client = service.use.krb5_client.options.wait
      options.wait = {}
      options.wait.tcp = for srv in service.use.shard_servers
        host: srv.node.fqdn
        port: options.config.net.port
      options.wait.local =
        host: service.node.fqdn
        port: options.config.net.port

## Dependencies

    migration = require 'masson/lib/migration'
    {merge} = require 'nikita/lib/misc'

[mongod-ssl]:(https://docs.mongodb.org/manual/reference/configuration-options/#net.ssl.mode)

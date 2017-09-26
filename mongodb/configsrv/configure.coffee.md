
## Configure
Mongodb Config servers have physically no dependances on other mongodb services.
They can be installed and configured on their own.


    module.exports = (service) ->
      service = migration.call @, service, 'ryba/mongodb/configsrv', ['ryba', 'mongodb', 'configsrv'], require('nikita/lib/misc').merge require('.').use,
        iptables: key: ['iptables']
        krb5_client: key: ['krb5_client']
        locale: key: ['locale']
        ssl: key: ['ssl']
        repo: key: ['ryba','mongodb','repo']
        config_servers: key: ['ryba', 'mongodb', 'configsrv']
      @config.ryba ?= {}
      @config.ryba.mongodb ?= {}
      options = @config.ryba.mongodb.configsrv = service.options
      options.iptables = service.use.iptables
      configsrv_hosts = service.use.config_servers.map( (srv)-> srv.node.fqdn)

## Identities

      # Group
      options.group = name: options.group if typeof options.group is 'string'
      options.group ?= {}
      options.group.name ?= 'mongod'
      options.group.system ?= true
      # User
      options.user = name: options.user if typeof options.user is 'string'
      options.user ?= {}
      options.user.name ?= 'mongod'
      options.user.gid = options.group.name
      options.user.system ?= true
      options.user.comment ?= 'MongoDB User'
      options.user.home ?= '/var/lib/mongod'
      options.user.limits ?= {}
      options.user.limits.nofile ?= 64000
      options.user.limits.nproc ?= true

# Configuration

      options.conf_dir ?= '/etc/mongod-config-server/conf'
      options.pid_dir ?= '/var/run/mongod'
      #mongo admin user
      options.admin ?= {}
      options.admin.name ?= 'admin'
      options.admin.password ?= 'admin123'
      options.root ?= {}
      options.root.name ?= 'root_admin'
      options.root.password ?= 'root123'
      #Misc
      options.fqdn ?= service.node.fqdn
      options.hostname = service.node.hostname
      options.clean_logs ?= false
      config = options.config ?= {}
      # setting the role of mongod process as a mongodb config server
      config.sharding ?= {}
      config.sharding.clusterRole ?= 'configsvr'

## Logs

      config.systemLog ?= {}
      config.systemLog.destination ?= 'file'
      config.systemLog.logAppend ?= true
      config.systemLog.path ?= "/var/log/mongodb/mongod-config-server-#{service.node.fqdn}.log"

## Storage

From 3.2, config servers for sharded clusters can be deployed as a replica set.
The replica set config servers must run the WiredTiger storage engine

      config.storage ?= {}
      config.storage.dbPath ?= "#{options.user.home}/configsrv/db"
      config.storage.journal ?= {}
      config.storage.journal.enabled ?= true
      config.storage.engine ?= 'wiredTiger'
      config.storage.repairPath ?= "#{config.storage.dbPath}/repair" unless config.storage.engine is 'wiredTiger'
      throw Error 'Need WiredTiger Storage for config server as replica set' unless config.storage.engine is 'wiredTiger'
      if config.storage.repairPath?.indexOf(config.storage.dbPath) is -1
        throw Error 'Must use a repairpath that is a subdirectory of dbpath when using journaling' if config.storage.journal.enabled

## Process

      config.processManagement ?= {}
      config.processManagement.fork ?= true
      config.processManagement.pidFilePath ?= "#{options.pid_dir}/mongod-config-server-#{service.node.fqdn}.pid"

## Network

[Configuring][mongod-ssl] ssl for the mongod process.

      config.net ?= {}
      config.net.port ?=  27017
      config.net.bindIp ?=  '0.0.0.0'

## Security

      # disables the apis
      config.net.http ?=  {}
      config.net.http.enabled ?= false
      config.net.http.JSONPEnabled ?= false
      config.net.http.RESTInterfaceEnabled ?= false
      config.net.unixDomainSocket ?= {}
      config.net.unixDomainSocket.pathPrefix ?= "#{options.pid_dir}"
      config.security ?= {}
      config.security.clusterAuthMode ?= 'x509'

## SSL

      options.ssl = merge {}, service.use.ssl?.options, options.ssl
      options.ssl.enabled = !!service.use.ssl
      if options.ssl.enabled
        throw Error "Required Option: ssl.cert" if  not options.ssl.cert
        throw Error "Required Option: ssl.key" if not options.ssl.key
        throw Error "Required Option: ssl.cacert" if not options.ssl.cacert
      switch config.security.clusterAuthMode
        when 'x509'
          throw Error 'can not use x509' unless options.ssl.enabled
          config.net.ssl ?= {}
          config.net.ssl.mode ?= 'preferSSL'
          config.net.ssl.PEMKeyFile ?= "#{options.conf_dir}/key.pem"
          config.net.ssl.PEMKeyPassword ?= "mongodb123"
          # use PEMkeyfile by default for membership authentication
          # config.net.ssl.clusterFile ?= "#{mongodb.configsrv.conf_dir}/cluster.pem" # this is the mongodb version of java trustore
          # config.net.ssl.clusterPassword ?= "mongodb123"
          config.net.ssl.CAFile ?=  "#{options.conf_dir}/cacert.pem"
          config.net.ssl.allowConnectionsWithoutCertificates ?= false
          config.net.ssl.allowInvalidCertificates ?= false
          config.net.ssl.allowInvalidHostnames ?= false
        when 'keyFile'
          options.sharedsecret ?= 'sharedSecretForMongodbCluster'
        else
          throw Error ' unsupported cluster authentication Mode'

## ACL's

      config.security.authorization ?= 'enabled'

## Kerberos
Kerberos authentication is only avaiable in enterprise edition.

      options.krb5 ?= {}
      options.krb5.realm ?= service.use.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      # Admin Information
      options.krb5.admin ?= service.use.krb5_client.options.admin[options.krb5.realm]
      config.security.sasl ?= {}
      config.security.sasl.hostName ?= service.node.fqdn
      config.security.sasl.serviceName ?= 'mongodb' # Can override only on enterprise edition
      options.sasl_password  ?= 'mongodb123'

## Replicat Set Discovery
Deploys config server as replica set. You can configure a custom layout by giving
an object containing a list of replica set name and the associated hosts.
By default Ryba deploys only one replica set for all the config server.

By default config servers replica set layout is not defined `mongodb.configsrv.replica_sets`.
Ryba uses all the config server available to create a replica set of config server.
Note: September 2017
Now custom layout is mandatory, ryba does not create replicaset automatically anymore.
The property `ryba.mongodb.configsrv.replicaset` contains the replicaset name whom the config server belongs to.
Ryba will go through every ryba/mongodb/configsrv to compute the replica sets and check the layout.

Ryba user must provide the replica set master by set the boolean property `ryba.mongodb.configsrv.replicaset_master`.

      throw Error 'Missing Replica Set Name ryba.mongodb.configsrv.replicaset' unless options.replicaset?
      options.replicasets = {}
      options.is_master ?= false
      for srv in service.use.config_servers
        options.replicasets[srv.options.replicaset] ?= {}
        options.replicasets[srv.options.replicaset]['hosts'] ?= []
        options.replicasets[srv.options.replicaset]['hosts'].push srv.node.fqdn
        options.replicaset_master = srv.node.fqdn if srv.options.is_master and (srv.options.replicaset is options.replicaset)
      options.config.replication ?= {}
      options.config.replication.replSetName ?= options.replicaset
      throw Error 'No master defined for replica' unless options.replicaset_master

## Wait

      options.wait_krb5_client = service.use.krb5_client.options.wait
      options.wait = {}
      options.wait.tcp = for srv in service.use.config_servers
        host: srv.node.fqdn
        port: options.config.net.port
      options.wait.local =
        host: service.node.fqdn
        port: options.config.net.port

## Dependencies

    path = require 'path'
    migration = require 'masson/lib/migration'
    {merge} = require 'nikita/lib/misc'


[mongod-ssl]:(https://docs.mongodb.org/manual/reference/configuration-options/#net.ssl.mode)

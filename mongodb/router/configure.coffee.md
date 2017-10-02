
## Configure

    module.exports = (service) ->
      service = migration.call @, service, 'ryba/mongodb/router', ['ryba', 'mongodb', 'router'], require('nikita/lib/misc').merge require('.').use,
        iptables: key: ['iptables']
        locale: key: ['locale']
        ssl: key: ['ssl']
        repo: key: ['ryba','mongodb','repo']
        config_servers: key: ['ryba', 'mongodb', 'configsrv']
        shard_servers: key: ['ryba', 'mongodb', 'shard']
        router_servers: key: ['ryba', 'mongodb', 'router']
      @config.ryba ?= {}
      @config.ryba.mongodb ?= {}
      options = @config.ryba.mongodb.router = service.options
      options.version ?= '3.4'

## Identities

By default, merge group and user from the MongoDb config server.

      options.group = merge service.use.config_servers[0].options.group, options.group
      options.user = merge service.use.config_servers[0].options.user, options.user

## Configuration

      # Config
      options.conf_dir ?= '/etc/mongod-router-server/conf'
      options.pid_dir ?= '/var/run/mongod'
      # Misc
      options.fqdn ?= service.node.fqdn
      options.hostname = service.node.hostname
      options.iptables ?= service.use.iptables and service.use.iptables.options.action is 'start'
      options.clean_logs ?= false
      options.config ?= {}

# Replica Set Discovery and Attribution

Each query router (mongos instance) is attributed to a config, and shard server replica set.
- Config server discovery
  Ryba administrators should specify to which config server replicaset the router belongs.
  a Router can only be assigned to one replicaset.
  the property is `ryba.mongodb.router.config_replicaset`
- Shard Config Server discovery
  Router routes Application query to the different Shard Cluster (sharding server replica set).
  Ryba does compute the shard cluster it reroute the query by reading configuration from shard and config
  replica sets.
- Notes
  Its mongos router's Job to add a shard Cluster to the mongodb cluster. So by specifying Shard cluster('s')
  to mongo router,  the router will apply the addShard Command, which will designates the
  Shard Cluster metadata to be stored on the Config server Replica Set.

```json
{
  "master1.ryba":
    "ryba": {
    "mongo_router_for_configsrv": "configsrvRepSet1"
    }
}


      # Mongos instances are the routers for the cluster.
      # they need to know to which config servers they speak with (only one replicat set of config servers is allowed)
      # they need to know which shard are linked with the config server to be able to route the client
      # to the good shards
      # Config Server Replica Set Discovery
      throw Error 'missing Config Server Replica set mongodb.router.config_replicaset' unless options.config_replicaset?
      options.my_shards_repl_sets ?= {}
      #computing shard  replica sets
      for srv in service.use.shard_servers
        #shard server is attribute to config server
        if srv.options.config_replicaset is options.config_replicaset
          options.my_shards_repl_sets[srv.options.replicaset] ?= {}
          options.my_shards_repl_sets[srv.options.replicaset].name ?= srv.options.replicaset
          options.my_shards_repl_sets[srv.options.replicaset].port ?= srv.options.config.net.port
          options.my_shards_repl_sets[srv.options.replicaset].root_name ?= srv.options.root.name
          options.my_shards_repl_sets[srv.options.replicaset].root_password ?= srv.options.root.password
          options.my_shards_repl_sets[srv.options.replicaset].master ?= srv.node.fqdn if srv.options.is_master
          options.my_shards_repl_sets[srv.options.replicaset].hosts ?= []
          options.my_shards_repl_sets[srv.options.replicaset].hosts.push srv.node.fqdn

      options.config.sharding ?= {}
      #autosplit option remove since 3.4
      #https://docs.mongodb.com/manual/reference/configuration-options/#mongos-only-options
      if (parseInt(options.version[2]) < 4) and (parseInt(options.version[0]) <= 3)
        options.config.sharding.chunkSize ?= 64
        options.config.sharding.autoSplit ?= true
      else
        throw Error 'option not supported' if options.config.sharding.autoSplit? or options.config.sharding.chunkSize?
      cfsrv_connect = service.use.config_servers.filter( (srv) ->
        srv.options.config.replication.replSetName is options.config_replicaset
      ).map( (srv) ->   "#{srv.node.fqdn}:#{srv.options.config.net.port}" ).join(',')
      options.config.sharding.configDB ?= "#{options.config_replicaset}/#{cfsrv_connect}"
      # size of a chunk in MB
## Logs

      options.config.systemLog ?= {}
      options.config.systemLog.destination ?= 'file'
      options.config.systemLog.logAppend ?= true
      options.config.systemLog.path ?= "/var/log/mongodb/mongod-router-server-#{@config.host}.log"

## Process

      options.config.processManagement ?= {}
      options.config.processManagement.fork ?= true
      options.config.processManagement.pidFilePath ?= "#{options.pid_dir}/mongod-router-server-#{@config.host}.pid"

## Network

[Configuring][mongod-ssl] ssl for the mongod process.

By changing the default port, we can allow different mongo service to run on the same host

      options.config.net ?= {}
      options.config.net.port ?= 27018
      options.config.net.bindIp ?=  '0.0.0.0'
      options.config.net.unixDomainSocket ?= {}
      options.config.net.unixDomainSocket.pathPrefix ?= "#{options.pid_dir}"

## Security

      # disables the apis
      options.config.net.http ?=  {}
      options.config.net.http.enabled ?= false
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
          options.sharedsecret ?= 'sharedSecretForMongodbCluster'
        else
          throw Error ' unsupported cluster authentication Mode'

# Wait

      options.wait = {}
      options.wait_configsrv ?= service.use.config_servers[0].options.wait
      options.wait_shardsrv ?= service.use.shard_servers[0].options.wait
      options.wait.tcp = for srv in service.use.router_servers
        host: srv.node.fqdn
        port: options.config.net.port or 27018
      options.wait.local =
        host: service.node.fqdn
        port: options.config.net.port or 27018

## Dependencies

    migration = require 'masson/lib/migration'
    {merge} = require 'nikita/lib/misc'

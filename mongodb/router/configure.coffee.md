
## Configure

    module.exports = ->
      mongodb_configsrvs = @contexts 'ryba/mongodb/configsrv'
      throw new Error 'No mongo config server configured ' unless mongodb_configsrvs.length > 0
      mongodb_shards = @contexts 'ryba/mongodb/shard'
      mongodb = @config.ryba.mongodb ?= {}
      mongodb.version ?= '3.4'

## Identities

      # Group
      mongodb.group = name: mongodb.group if typeof mongodb.group is 'string'
      mongodb.group ?= {}
      mongodb.group.name ?= 'mongod'
      mongodb.group.system ?= true
      mongodb.user.limits ?= {}
      mongodb.user.limits.nofile ?= 64000
      mongodb.user.limits.nproc ?= true
      # User
      mongodb.user = name: mongodb.user if typeof mongodb.user is 'string'
      mongodb.user ?= {}
      mongodb.user.name ?= 'mongod'
      mongodb.user.gid = mongodb.group.name
      mongodb.user.system ?= true
      mongodb.user.comment ?= 'MongoDB User'
      mongodb.user.home ?= '/var/lib/mongod'

## Configuration

      # Config
      mongodb.router ?= {}
      mongodb.router.conf_dir ?= '/etc/mongod-router-server/conf'
      mongodb.router.pid_dir ?= '/var/run/mongod'
      config = mongodb.router.config ?= {}

# Replica Set Discovery and Attribution

Each query router (mongos instance) is attributed to a config, and shard server replica set.
- Config server discovery
  If only one Replica set of config server is deployed, Ryba attributes it to every router.
  In case severa Replica set are deployed, the user must configure each mongo with one and only one
  config server replica set, with the property: `@config.ryba.mongo_router_for_configsrv` (string)
- Shard Config Server discovery
  Router routes Application query to the different Shard Cluster (sharding server replica set).
  If only one Shard Cluster is deployed, Ryba attributes it to every router.
  In case several Shard Cluster are deployed, the user must configure each mongo with at least one
  Shard Cluster Replicat set name
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
      replSetNames = mongodb_configsrvs[0].config.ryba.mongodb.configsrv.replica_sets
      throw Error 'No replica sets found for config servers ' unless replSetNames
      replSetNames = Object.keys replSetNames
      my_cfgsrv_repl_set = @config.ryba.mongo_router_for_configsrv
      my_cfgsrv_repl_set = @config.ryba.mongo_router_for_configsrv = replSetNames[0]  if replSetNames.length == 1 and not my_cfgsrv_repl_set?
      throw Error "No config server replica set attributed for router #{@config.host}"  unless my_cfgsrv_repl_set?
      throw Error "Only one Replica set of config servers must be attributed to router #{@config.host}" unless typeof my_cfgsrv_repl_set is 'string'
      throw Error "Unknown Config Server Replicat Set #{my_cfgsrv_repl_set}" unless replSetNames.indexOf my_cfgsrv_repl_set > -1
      mongodb.router.my_cfgsrv_repl_set = my_cfgsrv_repl_set
      # we now exactly which config server is attributed to the router
      # building the quorum of mongodb config server belonging to the replica set attributed to router
      cfsrv_connect = mongodb_configsrvs.filter( (ctx) ->
        ctx.config.ryba.mongodb.configsrv.config.replication.replSetName is my_cfgsrv_repl_set
      ).map( (ctx) ->   "#{ctx.config.host}:#{ctx.config.ryba.mongodb.configsrv.config.net.port}" ).join(',')
      config.sharding ?= {}
      #autosplit option remove since 3.4
      #https://docs.mongodb.com/manual/reference/configuration-options/#mongos-only-options
      if (parseInt(mongodb.version[2]) < 4) and (parseInt(mongodb.version[0]) <= 3)
        config.sharding.chunkSize ?= 64
        config.sharding.autoSplit ?= true
      else
        throw Error 'option not supported' if config.sharding.autoSplit? or config.sharding.chunkSize?
      config.sharding.configDB ?= "#{my_cfgsrv_repl_set}/#{cfsrv_connect}"
      # size of a chunk in MB

## Shard to ConfigServer Mapping
Get The Shard Server Replica Set to which the client request will be re-routed based
on the Config Server Replica Set Name `ryba.mongo_router_for_configsrv`

      mongodb.router.my_shards_repl_sets = []
      for shardReplSetName, layout of mongodb_shards[0].config.ryba.mongodb.shard.replica_sets
        mongodb.router.my_shards_repl_sets.push shardReplSetName if layout.configSrvReplSetName is my_cfgsrv_repl_set

## Logs

      config.systemLog ?= {}
      config.systemLog.destination ?= 'file'
      config.systemLog.logAppend ?= true
      config.systemLog.path ?= "/var/log/mongodb/mongod-router-server-#{@config.host}.log"

## Process

      config.processManagement ?= {}
      config.processManagement.fork ?= true
      config.processManagement.pidFilePath ?= "#{mongodb.router.pid_dir}/mongod-router-server-#{@config.host}.pid"

## Network

[Configuring][mongod-ssl] ssl for the mongod process.

By changing the default port, we can allow different mongo service to run on the same host

      config.net ?= {}
      config.net.port ?=  27018
      config.net.bindIp ?=  '0.0.0.0'
      config.net.unixDomainSocket ?= {}
      config.net.unixDomainSocket.pathPrefix ?= "#{mongodb.router.pid_dir}"

## Security

      # disables the apis
      config.net.http ?=  {}
      config.net.http.enabled ?= false
      config.security ?= {}
      config.security.clusterAuthMode ?= 'x509'

## SSL

      switch config.security.clusterAuthMode
        when 'x509'
          config.net.ssl ?= {}
          config.net.ssl.mode ?= 'preferSSL'
          config.net.ssl.PEMKeyFile ?= "#{mongodb.router.conf_dir}/key.pem"
          config.net.ssl.PEMKeyPassword ?= "mongodb123"
          # use PEMkeyfile by default for membership authentication
          # config.net.ssl.clusterFile ?= "#{mongodb.configsrv.conf_dir}/cluster.pem" # this is the mongodb version of java trustore
          # config.net.ssl.clusterPassword ?= "mongodb123"
          config.net.ssl.CAFile ?=  "#{mongodb.router.conf_dir}/cacert.pem"
          config.net.ssl.allowConnectionsWithoutCertificates ?= false
          config.net.ssl.allowInvalidCertificates ?= false
          config.net.ssl.allowInvalidHostnames ?= false
        when 'keyFile'
          mongodb.sharedsecret ?= 'sharedSecretForMongodbCluster'
        else
          throw Error ' unsupported cluster authentication Mode'

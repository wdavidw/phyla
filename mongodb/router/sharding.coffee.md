
# MongoDB Add Shards to the Cluster


 Connect to the mongos instance and Add each Shard to the cluster using the sh.addShard().
 In our case each Shard is a replicat set of sharding server (mongod instances).
 We add only the primary designated sharing mongod instance (called the seed) to the Cluster.
 It will automatically add the other (mongod intance) replica set members to the cluster.
 Once done, the Sharded Cluster will be available for the mongodb.
 available does not mean used, the db admin has to manually add a shard to a database

    module.exports =  header: 'MongoDB Router Servers Shard Init', handler: ({options}) ->
      mongos_port =  options.config.net.port

# Wait Shard to be available

Wait to connect to the shards

      @call 'ryba/mongodb/shard/wait', options.wait_shardsrv

# Add shard to the cluster

To add s shard to the cluster, the command `sh.addShard("shardsrvRepSet1/primary.ryba:27017")`
must be issued to mongos.
So the primary server must be retrieved before applying this command. Because the replica set has a not a dedicated primary server,
We must connect to each server of the replica set manually and check if it is the primary one.


      @call header: 'Add Shard Replica Set ', retry: 3, ->
        @each options.my_shards_repl_sets, (opts, next) ->
          name = opts.key
          shard = opts.value
          primary_host = null
          shard_hosts = shard.hosts
          shard_quorum = shard_hosts.map( (host) -> "#{host}:#{shard.port}").join(',')
          @call
            unless_exec: """
             mongo admin --host #{options.fqdn} --port #{mongos_port} \
               -u #{shard.root_name} --password '#{shard.root_password}' \
               --eval 'sh.status()' | grep '.*#{name}.*#{name}/#{shard_quorum}'
            """
          , ->
            @each shard.hosts, (ops) ->
              host = ops.key
              @system.execute
                code_skipped: 1
                cmd: """
                mongo admin --host #{host} \
                  --port #{shard.port} -u #{shard.root_name} --password '#{shard.root_password}' \
                  --eval 'db.isMaster().primary' | grep '#{host}:#{shard.port}' \
                  | grep -v 'MongoDB.*version' | grep -v 'connecting to:'
                """
              @call if: (-> @status -1), -> primary_host = host
            @call ->
              @system.execute
                if: -> primary_host
                cmd: """
                mongo admin --host #{options.fqdn} --port #{mongos_port} \
                  -u #{shard.root_name} --password '#{shard.root_password}' \
                  --eval 'sh.addShard(\"#{name}/#{primary_host}:#{shard.port}\")'
                """
          @next next

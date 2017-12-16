
# Atlas Hive Bridge Install

    module.exports = header: 'Atlas Hive Bride Plugin', handler: (options) ->

## Registry

      @registry.register 'hdp_select', 'ryba/lib/hdp_select'

## Packages

      @service 'atlas-metadata*hive-plugin*'
      @hdp_select 'atlas-client' #needed by hive server2 aux jars

## Oozie ShareLib
Populates the Oozie directory with the Atlas server JAR files.

          # Server: import certificates, private and public keys to hosts with a server
      @call
        if: options.oozie
      , ->
        sharelib = ''
        @system.execute
          header: 'Discover Oozie Sharelib latest version'
          cmd: mkcmd.hdfs @, """
          hdfs dfs -ls  '/user/oozie/share/lib' | awk '{ print $8 }' | tail -n1
          """
        , (err, executed, stdout, stderr) ->
          throw err if err
          sharelib = stdout.trim()
          throw Error 'No Oozie Sharelib installed' if (sharelib.length is 0)
          return 
        @call header: 'Upload Atlas Jars to Oozie ShareLib', (_, callback) ->
          fs.readdir options.ssh, '/usr/hdp/current/atlas-client/hook/hive/atlas-hive-plugin-impl/', (err, files) =>
            throw err if err
            @each files, (opt) =>
              @system.execute
                retry: 2
                cmd: mkcmd.hdfs @, """
                hdfs dfs -put /usr/hdp/current/atlas-client/hook/hive/atlas-hive-plugin-impl/#{opt.key} \
                #{sharelib}/hive/
                """
                unless_exec: mkcmd.hdfs @, "hdfs dfs -stat #{sharelib}/hive/#{opt.key}"
              @system.execute
                retry: 2
                if: -> @status -1
                cmd: mkcmd.hdfs @, """
                  hdfs dfs -chown #{options.oozie_user.name}:#{options.oozie_user.name} #{sharelib}/hive/#{opt.key}
                  hdfs dfs -chmod 755 #{sharelib}/hive/#{opt.key}
                  """
            @next callback

## Kafka Topics ACL

Wait for topics to exists.

          @system.execute
            header: 'KafKa Topic ACL Hive User (Simple)'
            if: options.hive_bridge_enabled
            cmd: mkcmd.kafka @, """
            /usr/hdp/current/kafka-broker/bin/kafka-acls.sh --authorizer-properties zookeeper.connect=#{zoo_connect} \
              --add --allow-principal User:#{hive_ctx.config.ryba.hive.user.name}  --group #{group_id} \
              --operation All --topic #{topic}
            """
            unless_exec: mkcmd.kafka @, """
            /usr/hdp/current/kafka-broker/bin/kafka-acls.sh  --list \
              --authorizer-properties zookeeper.connect=#{zoo_connect}  \
              --topic #{topic} | grep 'User:#{hive_ctx.config.ryba.hive.user.name} has Allow permission for operations: Write from hosts: *'
            """

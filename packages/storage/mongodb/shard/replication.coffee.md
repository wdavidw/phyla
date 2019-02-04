
# MongoDB Shard Server Replica Set Initialization

    module.exports =  header: 'MongoDB Shard Server Replicat Set', handler: ({options}) ->
      mongo_shell_exec =  "mongo admin --port #{options.config.net.port}"
      mongo_shell_admin_exec =  "#{mongo_shell_exec} -u #{options.admin.name} --password  '#{options.admin.password}'"
      mongo_shell_root_exec =  "#{mongo_shell_exec} -u #{options.root.name} --password  '#{options.root.password}'"

The userAdminAnyDatabase role is the first account created thanks to locahost exception
it used to manage every other user and their roles, for the root user
having the right to deal with privileges does not give it the role of root (ie  manage replica sets).

      mongodb_admin =
        user: "#{options.admin.name}"
        pwd: "#{options.admin.password}"
        roles:  [ { role: "userAdminAnyDatabase", db: "admin" }]
      mongodb_root =
        user: "#{options.root.name}"
        pwd: "#{options.root.password}"
        roles: [ { role: "root", db: "admin" } ]

## Wait

      @call once: true, '@rybajs/storage/mongodb/shard/wait'

# Admin Users

Create the admin user and root user as specified. It uses the LocalHost Exception to
bind to mongod instance in order to create user without authentication.
The admin user is need for account creation and has the role `userAdminAnyDatabase`.
The root user is needed for replication and has role `root`

      @call
        header: 'Roles Admin DB',
        if: -> options.is_master
        unless_exec: """
          echo exit | mongo admin \
            --port #{options.config.net.port} \
            --username #{options.admin.name} \
            --password  '#{options.admin.password}'
          echo exit | mongo admin \
            --port #{options.config.net.port} \
            --username #{options.root.name} \
            --password  '#{options.root.password}'
        """
      , ->
        @service.stop
          name: 'mongod-shard-server'
        @file.yaml
          target: "#{options.conf_dir}/mongod.conf"
          content:
            replication: null
          merge: true
          uid: options.user.name
          gid: options.group.name
          mode: 0o0750
          backup: true
        @service.start
          name: 'mongod-shard-server'
        @connection.wait options.wait.local
        @system.execute
          cmd: """
          #{mongo_shell_exec} --eval <<-EOF \
          'printjson( db.createUser( \
            { user: \"#{options.admin.name}\", pwd: \"#{options.admin.password}\", roles: [ { role: \"userAdminAnyDatabase\", db: \"admin\" }]} \
          ))'
          EOF
          """
          unless_exec: """
          echo exit | #{mongo_shell_admin_exec} -u #{options.admin.name} --password  '#{options.admin.password}'
          """
          code_skipped: 252
        @system.execute
          cmd: """
          #{mongo_shell_admin_exec} --eval <<-EOF \
          'printjson(db.createUser( \
            { user: \"#{options.root.name}\", pwd: \"#{options.root.password}\", roles: [ { role: \"root\", db: \"admin\" }]} \
          ))'
          EOF
          """
          unless_exec: "echo exit | #{mongo_shell_admin_exec} -u #{options.root.name} --password  '#{options.root.password}'"
          code_skipped: 252
        @file.yaml
          target: "#{options.conf_dir}/mongod.conf"
          content: options.config
          merge: true
          uid: options.user.name
          gid: options.group.name
          mode: 0o0750
          backup: true
        @service.stop
          if: -> @status -1
          name: 'mongod-shard-server'
        @service.start
          if: -> @status -1
          name: 'mongod-shard-server'
      @call '@rybajs/storage/mongodb/shard/wait', options.wait


# Replica Set Initialization

Initializes the replica set by connecting to the designated primary shard server
and launching the 'rs.initiate()' command.

      @call
        header: 'Replica Set Init Master'
        if: -> options.is_master
      , ->
        message = {}
        config =
          _id: options.config.replication.replSetName
          version: 1
          members: [_id:0, host: "#{options.fqdn}:#{options.config.net.port}"]
        @call (_, callback) ->
          @system.execute
            cmd: " #{mongo_shell_root_exec}  --eval 'rs.status().ok' | grep -v 'MongoDB.*version' | grep -v 'connecting to:'"
          , (err, _, stdout) ->
            return callback err if err
            status =  parseInt(stdout)
            return callback null, true if +status == 0
            callback null, false
        @system.execute
          if: -> @status -1
          cmd: "#{mongo_shell_root_exec}  --eval 'rs.initiate(#{JSON.stringify config})'"

# Replica Set Members

Adds the other shard servers members of the replica set.

      @call
        header: 'Set Members'
        if: -> options.is_master
      , ->
        @system.execute (
          cmd: """
          mongo admin \
            --port #{options.config.net.port} \
            --username #{options.root.name} \
            --password  '#{options.root.password}' \
            --eval 'rs.add(\"#{host}:#{options.config.net.port}\")'
          """
          unless_exec: """
          mongo admin \
            --port #{options.config.net.port} \
            --username #{options.root.name} \
            --password  '#{options.root.password}' \
            --eval 'rs.conf().members' | grep '#{host}:#{options.config.net.port}'
          """
        ) for host in options.replicasets[options.config.replication.replSetName].hosts

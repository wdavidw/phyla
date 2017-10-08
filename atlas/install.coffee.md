
# Apache Atlas Install

    module.exports = header: 'Atlas Install', handler: (options) ->
      {, kafka} = @config.ryba
      {ssl, ssl_server, ssl_client, hadoop_conf_dir, realm, hadoop_group} = @config.ryba
      krb5 = @config.krb5_client.admin[realm]
      protocol = if options.application.properties['atlas.enableTLS'] is 'true' then 'https' else 'http'
      [hive_ctx] = @contexts('ryba/hive/server2')
      [ranger_admin] = @contexts 'ryba/ranger/admin'
      credential_file = options.application.properties['cert.stores.credential.provider.path'].split('jceks://file')[1]
      credential_name = path.basename credential_file
      credential_dir = path.dirname credential_file

## Wait

      @call 'masson/core/krb5_client/wait'
      @call 'ryba/zookeeper/server/wait'
      @call 'ryba/hbase/master/wait'
      @call 'ryba/oozie/server/wait'
      @call 'ryba/hive/server2/wait'
      @call 'ryba/kafka/broker/wait'
      @call if: ranger_admin?, once: true, 'ryba/ranger/admin/wait'

## Dependencies

      @registry.register 'hdp_select', 'ryba/lib/hdp_select'
      @registry.register ['file', 'jaas'], 'ryba/lib/file_jaas'

## Identities

      @system.group header: 'Group',  options.group
      @system.user header: 'User', options.user

## IPTables

  | Service       | Port   | Proto        | Parameter |
  |---------------|--------|--------------|-----------|
  | Atlas Server  | 21000  | http         | port      |
  | Atlas Server  | 21443  | https        | port      |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @call header: 'IPTables', ->
        return unless @config.iptables.action is 'start'
        @tools.iptables
          rules: [
            { chain: 'INPUT', jump: 'ACCEPT', dport: options.application.properties["atlas.server.#{protocol}.port"], protocol: 'tcp', state: 'NEW', comment: "Atlas Server #{protocol}" }
          ]

## Package & Repository

Install Atlas packages

      @service
        header: 'Atlas Package'
        name: 'atlas-metadata'
      @hdp_select
        name: 'atlas-server'
      @hdp_select
        name: 'atlas-client'
      @service.init
        header: 'Init Script'
        target: '/etc/init.d/atlas-metadata-server'
        source: "#{__dirname}/resources/atlas-metadata-server.j2"
        local: true
        mode: 0o0755
        context: @config

## Layout && Directories

      @call header: 'Layout Directories', ->
        @system.mkdir
          target: options.log_dir
          uid: options.user.name
          gid: options.group.name
          mode: 0o0750
        @system.mkdir
          target: options.pid_dir
          uid: options.user.name
          gid: options.group.name
          mode: 0o0750
        @system.mkdir
          target: options.conf_dir
          uid: options.user.name
          gid: options.group.name
          mode: 0o0750
        @system.mkdir
          target: options.env['ATLAS_DATA_DIR']
          uid: options.user.name
          gid: options.group.name
          mode: 0o0750
        @system.mkdir
          target: options.env['ATLAS_EXPANDED_WEBAPP_DIR']
          uid: options.user.name
          gid: options.group.name
          mode: 0o0750
        @system.link
          target: options.conf_dir
          source: '/usr/hdp/current/atlas-server/conf'
        @system.tmpfs
          if_os: name: ['redhat','centos'], version: '7'
          mount: options.pid_dir
          uid: options.user.name
          gid: options.group.name
          perm: '0750'

## SSL 

      # Server: import certificates, private and public keys to hosts with a server
      @java.keystore_add
        keystore: options.application.properties['keystore.file']
        storepass: options.keystore_password
        caname: "hadoop_root_ca"
        cacert: "#{ssl.cacert}"
        key: "#{ssl.key}"
        cert: "#{ssl.cert}"
        keypass: options.serverkey_password
        name: @config.shortname
        local: true
      @java.keystore_add
        keystore: options.application.properties['truststore.file']
        storepass: options.truststore_password
        caname: "hadoop_root_ca"
        cacert: "#{ssl.cacert}"
        local: true
      @system.chown
        target: options.application.properties['keystore.file']
        uid: options.user.name
        gid: options.group.name
        mode: 0o0755
      @system.chown
        target: options.application.properties['truststore.file']
        uid: options.user.name
        gid: options.group.name
        mode: 0o0755
      @call
        if: -> @status(-3) or @status(-4)
        header: 'Generate Credentials SSL provider file'
      , (_, callback) ->
        @options.ssh.shell (err, stream) =>
          stream.write 'if /usr/hdp/current/atlas-client/bin/cputil.py ;then exit 0; else exit 1;fi\n'
          data = ''
          error = exit = null
          stream.on 'data', (data, extended) =>
            data = data.toString()
            switch
              when /Please enter the full path to the credential provider:/.test data
                options.log "prompt: #{data}"
                options.log "writing: #{options.application.properties['cert.stores.credential.provider.path'].split('jceks://file')[1]}\n"
                stream.write "#{options.application.properties['cert.stores.credential.provider.path'].split('jceks://file')[1]}\n"
                data = ''
              when /Please enter the password value for keystore.password:/.test data
                options.log "prompt: #{data}"
                options.log "write: #{options.keystore_password}"
                stream.write "#{options.keystore_password}\n"
                data = ''
              when /Please enter the password value for keystore.password again:/.test data
                options.log "prompt: #{data}"
                options.log "write: #{options.keystore_password}"
                stream.write "#{options.keystore_password}\n"
                data = ''
              when /Please enter the password value for truststore.password:/.test data
                options.log "prompt: #{data}"
                options.log "write: #{options.truststore_password}"
                stream.write "#{options.truststore_password}\n"
                data = ''
              when /Please enter the password value for truststore.password again:/.test data
                options.log "prompt: #{data}"
                options.log "write: #{options.truststore_password}"
                stream.write "#{options.truststore_password}\n"
                data = ''
              when /Please enter the password value for password:/.test data
                options.log "prompt: #{data}"
                options.log "write: #{options.serverkey_password}"
                stream.write "#{options.serverkey_password}\n"
                data = ''
              when /Please enter the password value for password again:/.test data
                options.log "prompt: #{data}"
                options.log "write: #{options.serverkey_password}"
                stream.write "#{options.serverkey_password}\n"
                data = ''
              when /Entry for keystore.password already exists/.test data
                stream.write "y\n"
                data = ''
              when /Entry for truststore.password already exists/.test data
                stream.write "y\n"
                data = ''
              when /Entry for password already exists/.test data
                stream.write "y\n"
                data = ''
              when /Exception in thread.*/.test data
                error = new Error data
                stream.end 'exit\n' unless exit
                exit = true
          stream.on 'exit', =>
            return callback error if error
            callback null, true
      @system.chown
        target: "#{credential_dir}/#{credential_name}"
        uid: options.user.name
        gid: options.group.name
        mode: 0o770
      @system.chown
        target: "#{credential_dir}/.#{credential_name}.crc"
        uid: options.user.name
        gid: options.group.name
        mode: 0o770

## Kerberos

Add The Kerberos Principal for atlas service and setup a JAAS configuration file
for atlas to able to open client connection to solr for its indexing backend.

      @krb5.addprinc krb5,
        header: 'Kerberos Atlas Service'
        randkey: true
        principal: options.application.properties['atlas.authentication.principal'].replace '_HOST', @config.host
        keytab: options.application.properties['atlas.authentication.keytab']
        uid: options.user.name
        gid: options.group.name
        mode: 0o660
      @system.execute
        header: 'SPNEGO'
        cmd: "su -l #{options.user.name} -c \'test -r #{options.application.properties['atlas.http.authentication.kerberos.keytab']}\'"
      @krb5.addprinc krb5,
        header: 'Kerberos Atlas Service'
        principal: options.application.properties['atlas.http.authentication.kerberos.principal'].replace '_HOST', @config.host
        randkey: true
        keytab: options.application.properties['atlas.http.authentication.kerberos.keytab']
        uid: 'root'
        gid: hadoop_group.name
        mode: 0o660
        unless: -> @status -1
      @file.jaas
        if: options.atlas_opts['java.security.auth.login.config']?
        header: 'Atlas Service JAAS'
        target: options.atlas_opts['java.security.auth.login.config']
        mode: 0o750
        uid: options.user.name
        gid: options.group.name
        content:
          KafkaClient:
            principal: options.application.properties['atlas.authentication.principal']
            keyTab: options.application.properties['atlas.authentication.keytab']
            useKeyTab: true
            storeKey: true
            serviceName: 'kafka'
            useTicketCache: true
          Client:
            useKeyTab: true
            storeKey: true
            useTicketCache: false
            doNotPrompt: false
            keyTab: options.application.properties['atlas.authentication.keytab']
            principal: options.application.properties['atlas.authentication.principal'].replace '_HOST', @config.host
      @krb5.addprinc krb5,
        header: 'Kerberos Atlas Service Admin Users'
        principal: options.admin_principal
        randkey: true
        password: options.admin_password

## Application Properties

Writes `atlas-application.properties` file.

      @file.properties
        header: 'Atlas Application Properties'
        target: "#{options.conf_dir}/atlas-application.properties"
        content: options.application.properties
        backup: true
        uid: options.user.name
        gid: options.group.name
        merge: false
        mode: 0o770

## Log4 Properties

      @file.download
        header: 'Atlas Log4j Properties'
        target: "#{options.conf_dir}/atlas-log4j.xml"
        source: "#{__dirname}/resources/atlas-log4j.xml"
        local: true
        uid: options.user.name
        gid: options.group.name
        mode: 0o770

## Environment

Render the Atlas Environment file

      @call ->
        options.env['METADATA_OPTS'] ?= ''
        options.env['METADATA_OPTS'] += " -D#{k}=#{v} "  for k, v of options.metadata_opts
        options.env['ATLAS_OPTS'] ?= ''
        options.env['ATLAS_OPTS'] += " -D#{k}=#{v} "  for k, v of options.atlas_opts
        writes = for k,v of options.env
          match: RegExp "^.*#{k}=.*$", 'mg'
          replace: "export #{k}=\"#{v}\" # RYBA DON'T OVERWRITE"
          append: true
        @file.render
          header: 'Atlas Env'
          target: "#{options.conf_dir}/atlas-env.sh"
          source: "#{__dirname}/resources/atlas-env.sh.j2"
          backup: true
          uid: options.user.name
          gid: options.group.name
          mode: 0o770
          local: true
          context: @config
          write: writes
          unlink: true
          eof: true

## Deploy Atlas War

Need to copy the atlas war file if `env['ATLAS_EXPANDED_WEBAPP_DIR']` is
set to other than the default

      @system.copy
        header: 'Atlas webapp war'
        source: '/usr/hdp/current/atlas-server/server/webapp/atlas.war'
        target: "#{options.env['ATLAS_EXPANDED_WEBAPP_DIR']}/atlas.war"

## HBase Layout

      @system.copy
        header: 'HBase Client Site'
        source: "#{@config.ryba.hbase.conf_dir}/hbase-site.xml"
        target: "#{options.conf_dir}/hbase/hbase-site.xml"
      # @system.copy
      #   header: 'HBase Client Env'
      #   source: "#{@config.ryba.hbase.conf_dir}/hbase-env.sh"
      #   target: "#{atlas.conf_dir}/hbase/hbase-env.sh"
      @file.render
        header: 'HBase Client Env'
        target: "#{options.conf_dir}/hbase/hbase-env.sh"
        source: "#{__dirname}/../hbase/resources/hbase-env.sh.j2"
        context: @config
        uid: options.user.name
        gid: options.group.name
        local: true
        eof: true
        # Fix mapreduce looking for "mapreduce.tar.gz"
        write: [
          match: /^export HBASE_OPTS=\"(.*)\$\{HBASE_OPTS\} -Djava.security.auth.login.config(.*)$/m
          replace: "export HBASE_OPTS=\"${HBASE_OPTS} -Dhdp.version=$HDP_VERSION -Djava.security.auth.login.config=#{options.conf_dir}/atlas-server.jaas\" # HDP VERSION FIX RYBA, HBASE CLIENT ONLY"
          append: true
        ]
      @system.copy
        header: 'HBase Client HDFS site'
        source: "/etc/hadoop/conf/hdfs-site.xml"
        target: "#{options.conf_dir}/hbase/hdfs-site.xml"
      @system.execute
        header: 'Create HBase Namespace'
        cmd: mkcmd.hbase @, """
        hbase shell 2>/dev/null <<-CMD
          create_namespace 'atlas'
        CMD
        """
        if_exec: mkcmd.hbase @, "hbase shell 2>/dev/null <<< \"list_namespace_tables 'atlas'\" | grep 'ERROR: Unknown namespace atlas!'"

## HBase Permission

Grant Permission to atlas for its titan' tables through ranger or from hbase shell.

      @call
        if: -> ranger_admin?
        header: 'HBase Atlas Permissions'
      , ->
        {install} = ranger_admin.config.ryba.ranger.hbase_plugin
        policy_name = "Atlas-Titan-to-HBase-policy"
        hbase_policy =
          "name": "#{policy_name}"
          "service": "#{install['REPOSITORY_NAME']}"
          "resources":
            "column":
              "values": ["*"]
              "isExcludes": false
              "isRecursive": false
            "column-family":
              "values": ["*"]
              "isExcludes": false
              "isRecursive": false
            "table":
              "values": [
                "#{options.application.properties['atlas.graph.storage.hbase.table']}",
                "#{options.application.properties['atlas.audit.hbase.tablename']}"
                ]
              "isExcludes": false
              "isRecursive": false
          "repositoryName": "#{install['REPOSITORY_NAME']}"
          "repositoryType": "hbase"
          "isEnabled": "true",
          "isAuditEnabled": true,
          'tableType': 'Inclusion',
          'columnType': 'Inclusion',
          'policyItems': [
          		"accesses": [
          			'type': 'read'
          			'isAllowed': true
              ,
          			'type': 'write'
          			'isAllowed': true
          		,
          			'type': 'create'
          			'isAllowed': true
          		,
          			'type': 'admin'
          			'isAllowed': true
          		],
          		'users': ["#{options.user.name}"]
          		'groups': []
          		'conditions': []
          		'delegateAdmin': true
            ]
        @call once: true, 'ryba/ranger/admin/wait'
        @wait.execute
          header: 'Wait HBase Ranger repository'
          cmd: """
          curl --fail -H \"Content-Type: application/json\" -k -X GET  \
          -u admin:#{ranger_admin.config.ryba.ranger.admin.password} \
          \"#{install['POLICY_MGR_URL']}/service/public/v2/api/service/name/#{install['REPOSITORY_NAME']}\"
          """
          code_skipped: 22
        @system.execute
          cmd: """
          curl --fail -H "Content-Type: application/json"   -k -X POST \ 
          -d '#{JSON.stringify options.ranger_user}' -u admin:#{ranger_admin.config.ryba.ranger.admin.password} \
          \"#{ranger_admin.config.ryba.ranger.admin.install['policymgr_external_url']}/service/xusers/secure/users\"
          """
          unless_exec: """
          curl --fail -H "Content-Type: application/json"   -k -X GET \ 
          -u admin:#{ranger_admin.config.ryba.ranger.admin.password} \
          \"#{ranger_admin.config.ryba.ranger.admin.install['policymgr_external_url']}/service/xusers/users/userName/#{options.ranger_user.name}\"
          """
        @system.execute
          header: 'Ranger Ryba Policy'
          cmd: """
          curl --fail -H "Content-Type: application/json" -k -X POST \
          -d '#{JSON.stringify hbase_policy}' \
          -u admin:#{ranger_admin.config.ryba.ranger.admin.password} \
          \"#{install['POLICY_MGR_URL']}/service/public/v2/api/policy\"
          """
          unless_exec: """
          curl --fail -H \"Content-Type: application/json\" -k -X GET  \ 
          -u admin:#{ranger_admin.config.ryba.ranger.admin.password} \
          \"#{install['POLICY_MGR_URL']}/service/public/v2/api/service/#{install['REPOSITORY_NAME']}/policy/#{policy_name}\"
          """
      @call
        unless: -> ranger_admin?
        header: 'HBase Atlas Permissions'
      , ->
        @system.execute
          header: 'Grant Permissions'
          unless_exec: mkcmd.hbase @, "hbase shell 2>/dev/null <<< \"user_permission '@#{options.application.namespace}'\" |  egrep \"^\\s(#{options.user.name})\\s*(#{options.user.name}).*\\[Permission: actions=(READ|EXEC|WRITE|CREATE|ADMIN|,){9}\\]$\""
          cmd: mkcmd.hbase @, """
          hbase shell 2>/dev/null <<-CMD
            grant '#{options.user.name}', 'RWCA', '@#{options.application.namespace}'
          CMD
          """
          trap: true

## Setup Credentials File

Convert the user_creds object into a file of credentials. See [how to generate][atlas-credential-file] atlas
credential based on file.

```cson
  user_creds
    'toto':
      name: 'toto'
      password: 'toto123'
      group: 'user'
    'juju':
      name: 'julie'
      password: 'juju123'
      group: 'user'
```

      @call
        if: options.application.properties['atlas.authentication.method.file'] is 'true'
        header: 'Render Credentials file'
      , ->
        old_lines = []
        new_lines = []
        content = ''
        @call header: 'Read Current Credential', (_, callback )  ->
          fs.readFile @options.ssh, options.application.properties['atlas.authentication.method.file.filename'], 'utf8', (err, content) ->
            return callback null, true if err and err.code is 'ENOENT'
            return callback err if err
            old_lines = string.lines content
            return if old_lines.length > 0 then callback null, true else callback null, false
        @call
          header: 'Merge user credentials'
          if: -> @status -1
        , ->
          for line in old_lines
            name = line.split(':')[0]
            new_lines.push unless name in Object.keys(options.user_creds)#keep track of old user if not present in current config
        @call header: 'Generate credential file', ->
          @each options.user_creds, (opt, callback) ->
            name = opt.key
            user = opt.value
            line = "#{user.name}=#{user.group}"
            @system.execute
              header: 'Generate new credential'
              cmd: "echo -n '#{user.password}' | sha256sum"
            ,(err, status, stdout) ->
              throw err if err
              [match] = /[a-zA-Z0-9]*/.exec stdout.trim()
              new_lines.push "#{line}::#{match}"
            @then callback
          @call ->
            @file
              content: new_lines.join "/n"
              target: options.application.properties['atlas.authentication.method.file.filename']
              mode: 0o740
              eof: true
              backup: true
              uid: options.user.name
              gid: options.user.name

## Kafka Layout

Create the kafka topics needed by Atlas, if the property `atlas.notification.create.topics`
is false. Ryba create the topic base on the channel chosen for atlas. See configure options.
kakfa client become an implicit dependance. Its properties can be used.

      @call
        header: "Kafka Topic Layout"
        retry: 3
        if: options.application.properties['atlas.notification.create.topics'] is 'false'
      , ->
        ks_ctxs = @contexts 'ryba/kafka/broker'
        zoo_connect = options.application.properties['atlas.kafka.zookeeper.connect']
        topics = options.application.properties['atlas.notification.topics'].split ','
        for topic in topics
          [ATLAS_HOOK_TOPIC,ATLAS_ENTITIES_TOPIC] = topics
          group_id = null
          switch topic
            when ATLAS_HOOK_TOPIC then group_id = options.application.properties['atlas.kafka.hook.group.id']
            when ATLAS_ENTITIES_TOPIC then group_id = options.application.properties['atlas.kafka.entities.group.id']
          @system.execute
            header: "Create #{topic} (Kerberos)"
            if: kafka.consumer.env['KAFKA_KERBEROS_PARAMS']?
            cmd: mkcmd.kafka @, """
            /usr/hdp/current/kafka-broker/bin/kafka-topics.sh --create \
              --zookeeper #{zoo_connect} --partitions #{ks_ctxs.length} --replication-factor #{ks_ctxs.length} \
              --topic #{topic}
            """
            unless_exec: mkcmd.kafka @, """
            /usr/hdp/current/kafka-broker/bin/kafka-topics.sh --list \
            --zookeeper #{zoo_connect} | grep #{topic}
            """
          @system.execute
            header: "Create #{topic} (Simple)"
            unless: kafka.consumer.env['KAFKA_KERBEROS_PARAMS']?
            cmd: """
            /usr/hdp/current/kafka-broker/bin/kafka-topics.sh --create \
              --zookeeper #{zoo_connect} --partitions #{ks_ctxs.length} --replication-factor #{ks_ctxs.length} \
              --topic #{topic}
            """
            unless_exec: """
            /usr/hdp/current/kafka-broker/bin/kafka-topics.sh --list \
            --zookeeper #{zoo_connect} | grep #{topic}
            """

### Add Ranger ACL

          @call header: 'KafKa Topic ACL (Ranger)', if: ranger_admin?, ->
            {install} = ranger_admin.config.ryba.ranger.kafka_plugin
            policy_name = "atlas-metadata-server-#{@config.host}"
            atlas_protocol = options.application.properties['atlas.kafka.security.protocol']
            hive_protocol = hive_ctx.config.ryba.hive.server2.atlas.application.properties['atlas.kafka.security.protocol']
            users = ["#{options.user.name}"]
            users.push "#{hive_ctx.config.ryba.hive.user.name}" if hive_protocol in ['SASL_PLAINTEXT','SASL_SSL'] and options.hive_bridge_enabled
            users.push 'ANONYMOUS' if (atlas_protocol in ['PLAINTEXT','SSL']) or (hive_protocol in ['PLAINTEXT','SSL'])
            kafka_policy =
              service: "#{install['REPOSITORY_NAME']}"
              name: policy_name
              description: "Atlas MetaData Server ACL"
              isAuditEnabled: true
              resources:
                topic:
                  values: topics
                  isExcludes: false
                  isRecursive: false
              'policyItems': [
                  "accesses": [
                    'type': 'publish'
                    'isAllowed': true
                  ,
                    'type': 'consume'
                    'isAllowed': true
                  ,
                    'type': 'configure'
                    'isAllowed': true
                  ,
                    'type': 'describe'
                    'isAllowed': true
                  ,
                    'type': 'create'
                    'isAllowed': true
                  ,
                    'type': 'delete'
                    'isAllowed': true
                  ,
                    'type': 'kafka_admin'
                    'isAllowed': true
                  ],
                  'users': users
                  'groups': []
                  'conditions': []
                  'delegateAdmin': true
                ]
            @wait.execute
              header: 'Wait Ranger Kafka Plugin'
              cmd: """
              curl --fail -H \"Content-Type: application/json\"   -k -X GET  \
              -u admin:#{ranger_admin.config.ryba.ranger.admin.password} \
              \"#{install['POLICY_MGR_URL']}/service/public/v2/api/service/name/#{install['REPOSITORY_NAME']}\"
              """
              code_skipped: [1,7,22] #22 is for 404 not found,7 is for not connected to host
            @system.execute
              header: 'Add policy request'
              cmd: """
              curl --fail -H "Content-Type: application/json" -k -X POST \
              -d '#{JSON.stringify kafka_policy}' \
              -u admin:#{ranger_admin.config.ryba.ranger.admin.password} \
              \"#{install['POLICY_MGR_URL']}/service/public/v2/api/policy\"
              """
              unless_exec: """
              curl --fail -H \"Content-Type: application/json\" -k -X GET  \ 
              -u admin:#{ranger_admin.config.ryba.ranger.admin.password} \
              \"#{install['POLICY_MGR_URL']}/service/public/v2/api/service/#{install['REPOSITORY_NAME']}/policy/#{policy_name}\"
              """
            @wait
              time: 10000
              if: -> @status -1

### Add Simple ACL

Need to put ACL, even when Ranger is not configured.
Atlas and Hive users needs Authorization to topics.
The commands a divided per user, as the hive bridge is not mandatory.

          @system.execute
            header: 'KafKa Topic ACL Atlas User (Simple)'
            cmd: mkcmd.kafka @, """
            /usr/hdp/current/kafka-broker/bin/kafka-acls.sh --authorizer-properties zookeeper.connect=#{zoo_connect} \
              --add --allow-principal User:#{options.user.name}  --group #{group_id} \
              --operation All --topic #{topic}
            """
            unless_exec: mkcmd.kafka @, """
            /usr/hdp/current/kafka-broker/bin/kafka-acls.sh  --list \
              --authorizer-properties zookeeper.connect=#{zoo_connect}  \
              --topic #{topic} | grep 'User:#{options.user.name} has Allow permission for operations: Write from hosts: *'
            """
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

### Add Ranger Solr ACL

      @call
        header: 'Titan Solr ACL (Ranger)'
        if: ranger_admin? and options.ranger_solr_plugin
      , ->
        {install} = ranger_admin.config.ryba.ranger.solr_plugins[options.solr_cluster_name]
        policy_name = "atlas-metadata-server-#{@config.host}"
        users = ["#{options.user.name}"]
        solr_policy =
          service: "#{options.solr_cluster_name}"
          name: policy_name
          description: "Atlas MetaData Server ACL"
          isAuditEnabled: true
          resources:
            collection:
              values: [
                'vertex_index'
                'edge_index'
                'fulltext_index'
              ]
          'policyItems': [
              "accesses": [
                'type': 'query'
                'isAllowed': true
              ,
                'type': 'update'
                'isAllowed': true
              ,
                'type': 'others'
                'isAllowed': true
              ,
                'type': 'solr_admin'
                'isAllowed': true
              ],
              'users': users
              'groups': []
              'conditions': []
              'delegateAdmin': true
            ]
        @wait.execute
          header: 'Wait Ranger Solr Plugin'
          cmd: """
          curl --fail -H \"Content-Type: application/json\"   -k -X GET  \
          -u admin:#{ranger_admin.config.ryba.ranger.admin.password} \
          \"#{install['POLICY_MGR_URL']}/service/public/v2/api/service/name/#{install['REPOSITORY_NAME']}\"
          """
          code_skipped: [1,7,22] #22 is for 404 not found,7 is for not connected to host
        @system.execute
          header: 'Add policy request'
          cmd: """
          curl --fail -H "Content-Type: application/json" -k -X POST \
          -d '#{JSON.stringify solr_policy}' \
          -u admin:#{ranger_admin.config.ryba.ranger.admin.password} \
          \"#{install['POLICY_MGR_URL']}/service/public/v2/api/policy\"
          """
          unless_exec: """
          curl --fail -H \"Content-Type: application/json\" -k -X GET  \
          -u admin:#{ranger_admin.config.ryba.ranger.admin.password} \
          \"#{install['POLICY_MGR_URL']}/service/public/v2/api/service/#{install['REPOSITORY_NAME']}/policy/#{policy_name}\"
          """
        @wait
          time: 10000
          if: -> @status -1

## Oozie Share Lib 

Populates the Oozie directory with the Atlas server JAR files.

      # Server: import certificates, private and public keys to hosts with a server
      @call
        if: (@contexts('ryba/oozie/server').length > 0) and (@contexts('ryba/hive/server2').length > 0)
      , ->
        user = @contexts('ryba/oozie/server')[0].config.ryba.oozie.user.name
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
                  hdfs dfs -chown #{user}:#{user} #{sharelib}/hive/#{opt.key}
                  hdfs dfs -chmod 755 #{sharelib}/hive/#{opt.key}
                  """
            @then callback

## Ranger Atlas Plugin Install

      @call
        if: -> @contexts('ryba/ranger/admin').length > 0
      , -> @call 'ryba/ranger/plugins/atlas/install'

## Dependencies

    mkcmd = require '../lib/mkcmd'
    string = require 'nikita/lib/misc/string'
    path = require 'path'
    fs = require 'ssh2-fs'
    {merge} = require 'nikita/lib/misc'

[atlas-credential-file]:(https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.5.0/bk_data-governance/content/ch_hdp_data_governance_install_atlas_ambari.html)

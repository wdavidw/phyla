
# Apache Atlas Install

    module.exports = header: 'Atlas Install', handler: (options) ->
      protocol = if options.application.properties['atlas.enableTLS'] is 'true' then 'https' else 'http'
      credential_file = options.application.properties['cert.stores.credential.provider.path'].split('jceks://file')[1]
      credential_name = path.basename credential_file
      credential_dir = path.dirname credential_file

## Registry

      @registry.register 'hdp_select', '@rybajs/metal/lib/hdp_select'
      @registry.register ['file', 'jaas'], '@rybajs/metal/lib/file_jaas'
      @registry.register 'ranger_service', '@rybajs/metal/ranger/actions/ranger_service'
      @registry.register 'ranger_policy', '@rybajs/metal/ranger/actions/ranger_policy'
      @registry.register 'ranger_service_wait', '@rybajs/metal/ranger/actions/ranger_service_wait'
      @registry.register 'ranger_user', '@rybajs/metal/ranger/actions/ranger_user'

## Wait

      # @call 'masson/core/krb5_client/wait', once: true, options.wait_krb5_client
      # @call '@rybajs/metal/zookeeper/server/wait', once: true, options.wait_zookeeper_server
      # @call '@rybajs/metal/hbase/master/wait', once: true, options.wait_hbase
      # @call '@rybajs/metal/kafka/broker/wait', once: true, options.wait_kafka
      # @call '@rybajs/metal/ranger/admin/wait', once: true, options.wait_ranger

## Identities

      @system.group header: 'Group',  options.group
      @system.user header: 'User', options.user

## IPTables
IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

| Service       | Port   | Proto        | Parameter |
|---------------|--------|--------------|-----------|
| Atlas Server  | 21000  | http         | port      |
| Atlas Server  | 21443  | https        | port      |


      @tools.iptables
        if: options.iptables
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
        context: options

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

Import certificates, private and public keys of the host.

      @java.keystore_add
        keystore: options.application.properties['keystore.file']
        storepass: options.ssl.keystore.password
        key: options.ssl.key.source
        cert: options.ssl.cert.source
        keypass: options.ssl.keystore.keypass
        name: options.ssl.key.name
        local: options.ssl.cert.local
        uid: options.user.name
        gid: options.group.name
        mode: 0o0640
      @java.keystore_add
        keystore: options.application.properties['keystore.file']
        storepass: options.ssl.keystore.password
        caname: "hadoop_root_ca"
        cacert: options.ssl.cacert.source
        local: options.ssl.cacert.local
      @java.keystore_add
        keystore: options.application.properties['truststore.file']
        storepass: options.ssl.truststore.password
        caname: "hadoop_root_ca"
        cacert: options.ssl.cacert.source
        local: options.ssl.cacert.local
        uid: options.user.name
        gid: options.group.name
        mode: 0o0644
      @call
        if: -> @status(-3) or @status(-2)
        header: 'Generate Credentials SSL provider file'
      , (_, callback) ->
        ssh = @ssh options.ssh
        ssh.shell (err, stream) =>
          stream.write 'if /usr/hdp/current/atlas-client/bin/cputil.py ;then exit 0; else exit 1;fi\n'
          data = ''
          error = exit = null
          stream.on 'data', (data, extended) =>
            data = data.toString()
            switch
              when /Please enter the full path to the credential provider:/.test data
                @log "prompt: #{data}"
                @log "writing: #{options.application.properties['cert.stores.credential.provider.path'].split('jceks://file')[1]}\n"
                stream.write "#{options.application.properties['cert.stores.credential.provider.path'].split('jceks://file')[1]}\n"
                data = ''
              when /Please enter the password value for keystore.password:/.test data
                @log "prompt: #{data}"
                @log "write: #{options.ssl.keystore.password}"
                stream.write "#{options.ssl.keystore.password}\n"
                data = ''
              when /Please enter the password value for keystore.password again:/.test data
                @log "prompt: #{data}"
                @log "write: #{options.ssl.keystore.password}"
                stream.write "#{options.ssl.keystore.password}\n"
                data = ''
              when /Please enter the password value for truststore.password:/.test data
                @log "prompt: #{data}"
                @log "write: #{options.ssl.truststore.password}"
                stream.write "#{options.ssl.truststore.password}\n"
                data = ''
              when /Please enter the password value for truststore.password again:/.test data
                @log "prompt: #{data}"
                @log "write: #{options.ssl.truststore.password}"
                stream.write "#{options.ssl.truststore.password}\n"
                data = ''
              when /Please enter the password value for password:/.test data
                @log "prompt: #{data}"
                @log "write: #{options.ssl.keystore.keypass}"
                stream.write "#{options.ssl.keystore.keypass}\n"
                data = ''
              when /Please enter the password value for password again:/.test data
                @log "prompt: #{data}"
                @log "write: #{options.ssl.keystore.keypass}"
                stream.write "#{options.ssl.keystore.keypass}\n"
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
        header: 'Ownership credential'
        target: "#{credential_dir}/#{credential_name}"
        uid: options.user.name
        gid: options.group.name
        mode: 0o770
      @system.chown
        header: 'Ownership crc'
        target: "#{credential_dir}/.#{credential_name}.crc"
        uid: options.user.name
        gid: options.group.name
        mode: 0o770

## Kerberos

Add The Kerberos Principal for atlas service and setup a JAAS configuration file
for atlas to able to open client connection to solr for its indexing backend.

      @krb5.addprinc options.krb5.admin,
        header: 'Kerberos Atlas Service'
        randkey: true
        principal: options.application.properties['atlas.authentication.principal'].replace '_HOST', options.fqdn
        keytab: options.application.properties['atlas.authentication.keytab']
        uid: options.user.name
        gid: options.group.name
        mode: 0o660
      @krb5.addprinc options.krb5.admin,
        header: 'Kerberos Atlas Service'
        principal: options.application.properties['atlas.http.authentication.kerberos.principal'].replace '_HOST', options.fqdn
        randkey: true
        keytab: options.application.properties['atlas.http.authentication.kerberos.keytab']
        uid: 'root'
        gid: options.hadoop_group.name
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
            principal: options.application.properties['atlas.authentication.principal'].replace '_HOST', options.fqdn
      @krb5.addprinc options.krb5.admin,
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
          context: options
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
        source: "#{options.hbase_conf_dir}/hbase-site.xml"
        target: "#{options.conf_dir}/hbase/hbase-site.xml"
      @system.copy
        header: 'HBase Client Env'
        target: "#{options.conf_dir}/hbase/hbase-env.sh"
        source: "#{options.hbase_conf_dir}/hbase-env.sh"
        uid: options.user.name
        gid: options.group.name
        context: options
        local: false
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
        cmd: mkcmd.hbase options.hbase_admin, """
        hbase shell 2>/dev/null <<-CMD
          create_namespace 'atlas'
        CMD
        """
        if_exec: mkcmd.hbase options.hbase_admin, "hbase shell 2>/dev/null <<< \"list_namespace_tables 'atlas'\" | grep 'ERROR: Unknown namespace atlas!'"

## HBase Permission

Grant Permission to atlas for its titan' tables through ranger or from hbase shell.

      @call
        if: -> options.ranger_hbase
        header: 'HBase Atlas Permissions'
      , ->
        @ranger_service_wait
          header: "HBase Plugin Wait"
          username: options.ranger_admin.options.admin.username
          password: options.ranger_admin.options.admin.password
          url: options.ranger_admin.options.install['policymgr_external_url']
          service: options.hbase_policy.service
        @ranger_user
          header: "Ranger admin atlas"
          username: options.ranger_admin.options.admin.username
          password: options.ranger_admin.options.admin.password
          url: options.ranger_admin.options.install['policymgr_external_url']
          user: options.ranger_user
        @ranger_policy
          header: 'HBase Plugin ACL'
          username: options.ranger_admin.options.admin.username
          password: options.ranger_admin.options.admin.password
          url: options.ranger_admin.options.install['policymgr_external_url']
          policy: options.hbase_policy
      @call
        unless: -> options.ranger_hbase
        header: 'HBase Atlas Permissions'
      , ->
        @system.execute
          header: 'Grant Permissions'
          unless_exec: mkcmd.hbase options.hbase_admin, "hbase shell 2>/dev/null <<< \"user_permission '@#{options.application.namespace}'\" |  egrep \"^\\s(#{options.user.name})\\s*(#{options.user.name}).*\\[Permission: actions=(READ|EXEC|WRITE|CREATE|ADMIN|,){9}\\]$\""
          cmd: mkcmd.hbase options.hbase_admin, """
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
          ssh = @ssh options.ssh
          fs.readFile ssh, options.application.properties['atlas.authentication.method.file.filename'], 'utf8', (err, content) ->
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
            @next callback
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
        topics = options.application.properties['atlas.notification.topics'].split ','
        for topic in topics
          [ATLAS_HOOK_TOPIC,ATLAS_ENTITIES_TOPIC] = topics
          group_id = null
          switch topic
            when ATLAS_HOOK_TOPIC then group_id = options.application.properties['atlas.kafka.hook.group.id']
            when ATLAS_ENTITIES_TOPIC then group_id = options.application.properties['atlas.kafka.entities.group.id']
          @system.execute
            header: "Create #{topic} (Kerberos)"
            if: options.application.properties['atlas.kafka.security.protocol'] in ['SASL_SSL','SASL_PLAINTEXT']
            cmd: mkcmd.kafka options.kafka_admin, """
            /usr/hdp/current/kafka-broker/bin/kafka-topics.sh --create \
              --zookeeper #{options.application.properties['atlas.kafka.zookeeper.connect']} \
              --partitions #{options.kafka_partitions} --replication-factor #{options.kafka_replication} \
              --topic #{topic}
            """
            unless_exec: mkcmd.kafka options.kafka_admin, """
            /usr/hdp/current/kafka-broker/bin/kafka-topics.sh --list \
            --zookeeper #{options.application.properties['atlas.kafka.zookeeper.connect']} | grep #{topic}
            """
          @system.execute
            header: "Create #{topic} (Simple)"
            unless: options.application.properties['atlas.kafka.security.protocol'] in ['SASL_SSL','SASL_PLAINTEXT']
            cmd: """
            /usr/hdp/current/kafka-broker/bin/kafka-topics.sh --create \
              --zookeeper #{options.application.properties['atlas.kafka.zookeeper.connect']} \
              --partitions #{options.kafka_partitions} \
              --replication-factor #{options.kafka_replication} \
              --topic #{topic}
            """
            unless_exec: """
            /usr/hdp/current/kafka-broker/bin/kafka-topics.sh --list \
            --zookeeper #{options.application.properties['atlas.kafka.zookeeper.connect']} | grep #{topic}
            """

### Add Ranger ACL

          @call header: 'KafKa Topic ACL (Ranger)', if: options.ranger_kafka_install?, ->
            @ranger_service_wait
              header: "Kafka Plugin Wait"
              username: options.ranger_admin.options.admin.username
              password: options.ranger_admin.options.admin.password
              url: options.ranger_admin.options.install['policymgr_external_url']
              service: options.kafka_policy.service
            @ranger_user
              header: "Ranger admin"
              username: options.ranger_admin.options.admin.username
              password: options.ranger_admin.options.admin.password
              url: options.ranger_admin.options.install['policymgr_external_url']
              user: options.ranger_user
            @ranger_policy
              header: 'Kafka Plugin ACL'
              username: options.ranger_admin.options.admin.username
              password: options.ranger_admin.options.admin.password
              url: options.ranger_admin.options.install['policymgr_external_url']
              policy: options.kafka_policy
            @wait
              time: 10000
              if: -> @status -1

### Add Simple ACL

Need to put ACL, even when Ranger is not configured.
Atlas and Hive users needs Authorization to topics.
The commands a divided per user, as the hive bridge is not mandatory.

          @system.execute
            header: 'KafKa Topic ACL Atlas User (Simple)'
            cmd: mkcmd.kafka options.kafka_admin, """
              /usr/hdp/current/kafka-broker/bin/kafka-acls.sh \
              --authorizer-properties zookeeper.connect=#{options.application.properties['atlas.kafka.zookeeper.connect']} \
              --add --allow-principal User:#{options.user.name}  --group #{group_id} \
              --operation All --topic #{topic}
            """
            unless_exec: mkcmd.kafka options.kafka_admin, """
              /usr/hdp/current/kafka-broker/bin/kafka-acls.sh  --list \
              --authorizer-properties \
              zookeeper.connect=#{options.application.properties['atlas.kafka.zookeeper.connect']}  \
              --topic #{topic} | grep 'User:#{options.user.name} has Allow permission for operations: Write from hosts: *'
            """

### Add Ranger Solr ACL

      # @call
      #   header: 'Titan Solr ACL (Ranger)'
      #   if: options.ranger_solr_install
      # , ->
      #   @ranger_service_wait
      #     header: "Solr Plugin Wait"
      #     username: options.admin.username
      #     password: options.admin.password
      #     url: options.ranger_admin.options.install['policymgr_external_url']
      #     service: options.solr_policy.service
      #   @ranger_user
      #     header: "Ranger admin"
      #     username: options.admin.username
      #     password: options.admin.password
      #     url: options.ranger_admin.options.install['policymgr_external_url']
      #     user: options.ranger_user
      #   @ranger_policy
      #     header: 'Solr Plugin ACL'
      #     username: options.ranger_admin.options.admin.username
      #     password: options.ranger_admin.options.admin.password
      #     url: options.ranger_admin.options.install['policymgr_external_url']
      #     policy: options.solr_policy
      #   @wait
      #     time: 10000
      #     if: -> @status -1

## Dependencies

    mkcmd = require '../lib/mkcmd'
    string = require '@nikitajs/core/lib/misc/string'
    path = require 'path'
    fs = require 'ssh2-fs'
    {merge} = require '@nikitajs/core/lib/misc'

[atlas-credential-file]:(https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.5.0/bk_data-governance/content/ch_hdp_data_governance_install_atlas_ambari.html)
[solr-rest-api-roles]:(https://lucene.apache.org/solr/guide/6_6/rule-based-authorization-plugin.html)

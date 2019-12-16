
# Ranger Kafka Plugin Install

    module.exports = header: 'Ranger Kafka Plugin', handler: ({options}) ->
      version= null

# Register

      @registry.register 'hdfs_mkdir', '@rybajs/metal/lib/hdfs_mkdir'
      @registry.register 'ranger_user', '@rybajs/metal/ranger/actions/ranger_user'
      @registry.register 'ranger_service', '@rybajs/metal/ranger/actions/ranger_service'
      @registry.register 'ranger_policy', '@rybajs/metal/ranger/actions/ranger_policy'

## Wait

      @call '@rybajs/metal/ranger/admin/wait', once: true, options.wait_ranger_admin

# Packages

      @call header: 'Packages', ->
        @system.execute
          header: 'Setup Execution'
          shy:true
          cmd: """
          hdp-select versions | tail -1
          """
         , (err, data) ->
            return  err if err or not data.status
            version = data.stdout.trim() if data.status
        @service
          name: "ranger-kafka-plugin"

## Ranger User

      @ranger_user
        header: 'Ranger User'
        username: options.ranger_admin.username
        password: options.ranger_admin.password
        url: options.install['POLICY_MGR_URL']
        user: options.plugin_user
      @ranger_user
        header: 'Ranger Anon User'
        if: !!options.plugin_user_anonymous
        username: options.ranger_admin.username
        password: options.ranger_admin.password
        url: options.install['POLICY_MGR_URL']
        user: options.plugin_user_anonymous

## Audit Layout

The value present in "XAAUDIT.HDFS.DESTINATION_DIRECTORY" contains variables
such as "%app-type% and %time:yyyyMMdd%".

      @call
        if: options.install['XAAUDIT.HDFS.IS_ENABLED'] is 'true'
        header: 'HDFS Audit'
      , ->
        @ranger_policy
          header: 'HDFS Audit'
          username: options.ranger_admin.username
          password: options.ranger_admin.password
          url: options.install['POLICY_MGR_URL']
          policy: options.policy_hdfs_audit
        @system.mkdir
          header: 'HDFS Spool Dir'
          if: options.install['XAAUDIT.HDFS.IS_ENABLED'] is 'true'
          target: options.install['XAAUDIT.HDFS.FILE_SPOOL_DIR']
          uid: options.kafka_user.name
          gid: options.kafka_group.name
          mode: 0o0750
        @call header: 'HDFS Paths', ->
          for target in options.policy_hdfs_audit.resources.path.values
            @hdfs_mkdir
              target: target
              mode: 0o0750
              parent:
                mode: 0o0711
                user: options.user.name
                group: options.group.name
              uid: options.kafka_user.name
              gid: options.kafka_group.name
              krb5_user: options.hdfs_krb5_user
      @system.mkdir
        header: 'Solr Spool Dir'
        if: options.install['XAAUDIT.SOLR.IS_ENABLED'] is 'true'
        target: options.install['XAAUDIT.SOLR.FILE_SPOOL_DIR']
        uid: options.kafka_user.name
        gid: options.kafka_group.name
        mode: 0o0750


## Service Repository creation

Matchs step 1 in [kafka plugin configuration][plugin]. Instead of using the web ui
we execute this task using the rest api.

      @ranger_service
        header: 'Ranger Repository'
        username: options.ranger_admin.username
        password: options.ranger_admin.password
        url: options.install['POLICY_MGR_URL']
        service: options.service_repo

Note, by default, we're are using the same Ranger principal for every
plugin and the principal is created by the Ranger Admin service. Chances
are that a customer user will need specific ACLs but this hasn't been
tested.

      @krb5.addprinc options.krb5.admin,
        header: 'Plugin Principal'
        principal: "#{options.service_repo.configs.username}"
        password: options.service_repo.configs.password

## Properties

      @call -> @file
        header: 'Properties'
        if: -> version?
        source: "#{__dirname}/../../resources/plugin-install.properties"
        target: "/usr/hdp/#{version}/ranger-kafka-plugin/install.properties"
        local: true
        eof: true
        backup: true
        write: for k, v of options.install
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true

# Plugin Scripts 

      @call ->
        @file
          header: 'Script Fix'
          target: "/usr/hdp/#{version}/ranger-kafka-plugin/enable-kafka-plugin.sh"
          write: [
              match: RegExp "^HCOMPONENT_CONF_DIR=.*$", 'mg'
              replace: "HCOMPONENT_CONF_DIR=#{options.conf_dir}"
            ,
              match: RegExp "^HCOMPONENT_INSTALL_DIR_NAME=.*$", 'mg'
              replace: "HCOMPONENT_INSTALL_DIR_NAME=/usr/hdp/current/kafka-broker"
            ,
              match: RegExp "^HCOMPONENT_LIB_DIR=.*$", 'mg'
              replace: "HCOMPONENT_LIB_DIR=/usr/hdp/current/kafka-broker/libs"
            ,
              match: RegExp "^HCOMPONENT_NAME=.*$", 'mg'
              replace: "HCOMPONENT_NAME=kafka-broker"

          ]
          backup: true
          mode: 0o750
        @file
          header: 'Fix Classpath'
          target: "#{options.conf_dir}/kafka-env.sh"
          write: [
            match: RegExp "^export CLASSPATH=\"$CLASSPATH.*", 'm'
            replace: "export CLASSPATH=\"$CLASSPATH:${script_dir}:/usr/hdp/#{version}/ranger-kafka-plugin/lib/ranger-kafka-plugin-impl:#{options.conf_dir}:/usr/hdp/current/hadoop-hdfs-client/*:/usr/hdp/current/hadoop-hdfs-client/lib/*:/etc/hadoop/conf\" # RYBA, DONT OVERWRITE"
            append: true
          ]
          backup: true
          eof: true
          mode:0o0750
          uid: options.kafka_user.name
          gid: options.kafka_group.name
        @system.execute
          header: 'Script Execution'
          cmd: """
          if /usr/hdp/#{version}/ranger-kafka-plugin/enable-kafka-plugin.sh ;
          then exit 0 ;
          else exit 1 ;
          fi;
          """
        @system.chmod
          header: "Fix Permission"
          target: options.conf_dir
          uid: options.user.name
          gid: options.group.name
          mode: 0o755
        @system.chmod
          header: "Fix Ranger Repo Permission"
          target: "/etc/ranger/#{options.install['REPOSITORY_NAME']}"
          uid: options.user.name
          gid: options.group.name
          mode: 0o750
        @file.types.hfile
          header: 'Fix ranger-kafka-security conf'
          target: "#{options.conf_dir}/ranger-kafka-security.xml"
          merge: true
          properties:
            'ranger.plugin.kafka.policy.rest.ssl.config.file': "#{options.conf_dir}/ranger-policymgr-ssl.xml"

## Dependencies

    quote = require 'regexp-quote'
    path = require 'path'
    mkcmd = require '../../../lib/mkcmd'
    fs = require 'ssh2-fs'

[plugin]: https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.4.0/bk_installing_manually_book/content/installing_ranger_plugins.html#installing_ranger_kafka_plugin

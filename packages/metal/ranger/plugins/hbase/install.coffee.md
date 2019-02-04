
# Ranger HBase Plugin Install

    module.exports = header: 'Ranger HBase Plugin', handler: ({options}) ->
      version = null

## Wait

      @call '@rybajs/metal/ranger/admin/wait', once: true, options.wait_ranger_admin

## Register

      @registry.register 'hconfigure', '@rybajs/metal/lib/hconfigure'
      @registry.register 'hdfs_mkdir', '@rybajs/metal/lib/hdfs_mkdir'
      @registry.register 'ranger_policy', '@rybajs/metal/ranger/actions/ranger_policy'
      @registry.register 'ranger_service', '@rybajs/metal/ranger/actions/ranger_service'
      @registry.register 'ranger_user', '@rybajs/metal/ranger/actions/ranger_user'

## Packages

      @call header: 'Packages', ->
        @system.execute
          header: 'Setup Execution'
          shy:true
          cmd: """
          hdp-select versions | tail -1
          """
         , (err, obj) ->
            throw  err if err
            version = obj.stdout.trim()
            options.install['COMPONENT_INSTALL_DIR_NAME'] ?= "/usr/hdp/#{version}/hbase"
        @service
          name: "ranger-hbase-plugin"

## Ranger User

      @ranger_user
        if: options.master_fqdn is options.fqdn
        header: 'Ranger User'
        username: options.ranger_admin.username
        password: options.ranger_admin.password
        url: options.install['POLICY_MGR_URL']
        user: options.plugin_user

## Audit Layout

Matchs step 1 in [hdfs plugin configuration][plugin]. Instead of using the web ui
we execute this task using the rest api.

      @call
        if: options.install['XAAUDIT.HDFS.IS_ENABLED'] is 'true'
        header: 'Audit HDFS Policy'
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
          uid: options.hbase_user.name
          gid: options.hadoop_group.name
          mode: 0o0750
        @call ->
          for target in options.policy_hdfs_audit.resources.path.values
            @hdfs_mkdir
              target: target
              mode: 0o0750
              parent:
                mode: 0o0711
                user: options.user.name
                group: options.group.name
              uid: options.hbase_user.name
              gid: options.hadoop_group.name
              krb5_user: options.hdfs_krb5_user
              # unless_exec: mkcmd.hdfs options.hdfs_krb5_user, "hdfs dfs -test -d #{target}"
      @system.mkdir
        header: 'Solr Spool Dir'
        if: options.install['XAAUDIT.SOLR.IS_ENABLED'] is 'true'
        target: options.install['XAAUDIT.SOLR.FILE_SPOOL_DIR']
        uid: options.hbase_user.name
        gid: options.hbase_group.name
        mode: 0o0750

## Service Repository creation

Matchs step 1 in [hbase plugin configuration][plugin]. Instead of using the web ui
we execute this task using the rest api.

      @ranger_service
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

## SSL

The Ranger Plugin does not use its truststore configuration when using solrJClient.
Must add certificate to JAVA Cacerts file manually.

TODO: remove CA from JAVA_HOME cacerts in a future version.

      @java.keystore_add
        keystore: "#{options.jre_home}/lib/security/cacerts"
        storepass: 'changeit'
        caname: "hadoop_root_ca"
        cacert: "#{options.ssl.cacert.source}"
        local: "#{options.ssl.cacert.local}"

## Properties

      @call -> @file
        header: 'Properties'
        if: -> version?
        source: "#{__dirname}/../../resources/plugin-install.properties"
        target: "/usr/hdp/#{version}/ranger-hbase-plugin/install.properties"
        local: true
        eof: true
        backup: true
        write: for k, v of options.install
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true

## Plugin Scripts 

Activate the plugin.

      @call header: 'Enable', ->
        diff = false
        {install} = options
        @each options.conf_dir, ({options}, cb) ->
          conf_dir = options.key
          files = ['ranger-hbase-audit.xml','ranger-hbase-security.xml','ranger-policymgr-ssl.xml']
          sources_props = {}
          current_props = {}
          files_exists = {}
          @system.execute
            cmd: """
            echo '' | keytool -list \
              -storetype jceks \
              -keystore /etc/ranger/#{install['REPOSITORY_NAME']}/cred.jceks \
            | egrep '.*ssltruststore|auditdbcred|sslkeystore'
            """
            code_skipped: 1
          @call
            if: -> @status -1 # do not need this if the cred.jceks file is not provisioned
          , ->
            @each files, ({options}, cb) ->
              file = options.key
              target = "#{conf_dir}/#{file}"
              ssh = @ssh options.ssh
              fs.exists ssh, target, (err, exists) ->
                return cb err if err
                return cb() unless exists
                files_exists[file] = exists
                properties.read ssh, target, (err, props) ->
                  return cb err if err
                  sources_props[file] = props
                  cb()
          @file
            header: 'Script Fix'
            target: "/usr/hdp/#{version}/ranger-hbase-plugin/enable-hbase-plugin.sh"
            write:[
                match: RegExp "^HCOMPONENT_CONF_DIR=.*$", 'mg'
                replace: "HCOMPONENT_CONF_DIR=#{conf_dir}"
              ,
                match: RegExp "\\^HCOMPONENT_LIB_DIR=.*$", 'mg'
                replace: "HCOMPONENT_LIB_DIR=/usr/hdp/current/hbase-client/lib"
              ]
            backup: true
            mode: 0o750
            shy: true
          @system.execute
            header: 'Script'
            cmd: "/usr/hdp/#{version}/ranger-hbase-plugin/enable-hbase-plugin.sh"
          @hconfigure
            header: 'Security Fix'
            target: "#{conf_dir}/ranger-hbase-security.xml"
            merge: true
            properties:
              'ranger.plugin.hbase.policy.rest.ssl.config.file': "#{conf_dir}/ranger-policymgr-ssl.xml"
          @each files, ({options}, cb) ->
            file = options.key
            target = "#{conf_dir}/#{file}"
            ssh = @ssh options.ssh
            fs.exists ssh, target, (err, exists) ->
              return cb err if err
              properties.read ssh, target , (err, props) ->
                return cb err if err
                current_props["#{file}"] = props
                cb()
          @call
            header: 'Diff'
            shy: true
          , (_, callback) ->
            for file in files
              #do not need to go further if the file did not exist
              return callback null,true unless sources_props["#{file}"]
              for prop, value of current_props["#{file}"]
                diff = true unless value is sources_props["#{file}"][prop]
              for prop, value of sources_props["#{file}"]
                diff =  true unless value is current_props["#{file}"][prop]
            callback null, diff
          @next cb


## Dependencies

    quote = require 'regexp-quote'
    path = require 'path'
    mkcmd = require '../../../lib/mkcmd'
    properties = require '../../../lib/properties'
    fs = require 'ssh2-fs'

[plugin]:(https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.4.0/bk_installing_manually_book/content/installing_ranger_plugins.html#installing_ranger_hbase_plugin)
[perms-fix]: https://community.hortonworks.com/questions/23717/ranger-solr-on-hdp-234-unable-to-refresh-policies.html

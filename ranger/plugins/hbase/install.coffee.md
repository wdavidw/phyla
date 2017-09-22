
# Ranger HBase Plugin Install

    module.exports = header: 'Ranger HBase Plugin', handler: (options) ->
      version = null

## Register

      @registry.register 'ranger_policy', 'ryba/ranger/actions/ranger_policy'
      @registry.register 'ranger_service', 'ryba/ranger/actions/ranger_service'

## Wait

      @call 'ryba/ranger/admin/wait', once: true, options.wait_ranger_admin

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdfs_mkdir', 'ryba/lib/hdfs_mkdir'
      @registry.register 'ranger_user', 'ryba/ranger/actions/ranger_user'

## Ranger User

      @ranger_user
        header: 'Ranger User'
        username: options.ranger_admin.username
        password: options.ranger_admin.password
        url: options.install['POLICY_MGR_URL']
        user: options.plugin_user

## Packages

      @call header: 'Packages', ->
        @system.execute
          header: 'Setup Execution'
          shy:true
          cmd: """
          hdp-select versions | tail -1
          """
         , (err, _, stdout) ->
            throw  err if err
            version = stdout.trim()
        @service
          name: "ranger-hbase-plugin"

## Audit Layout

Matchs step 1 in [hdfs plugin configuration][plugin]. Instead of using the web ui
we execute this task using the rest api.

      @call
        if: options.install['XAAUDIT.HDFS.IS_ENABLED'] is 'true'
        header: 'Audit HDFS Policy'
      , ->
        for target in options.policy_hdfs_audit.resources.path.values
          @hdfs_mkdir
            target: target
            mode: 0o0750
            parent:
              mode: 0o0711
              user: options.user.name
              group: options.group.name
            user: options.hbase_user.name
            group: options.hbase_user.name
            # unless_exec: mkcmd.hdfs @, "hdfs dfs -test -d #{target}"
        @ranger_policy
          username: options.ranger_admin.username
          password: options.ranger_admin.password
          url: options.install['POLICY_MGR_URL']
          policy: options.policy_hdfs_audit
      # @system.mkdir
      #   if: options.install['XAAUDIT.HDFS.IS_ENABLED'] is 'true'
      #   target: options.install['XAAUDIT.HDFS.FILE_SPOOL_DIR']
      #   uid: options.user.name
      #   gid: options.hadoop_group.name
      #   mode: 0o0750
      @system.mkdir
        header: 'Solr Spool Dir'
        if: options.install['XAAUDIT.SOLR.IS_ENABLED'] is 'true'
        target: options.install['XAAUDIT.SOLR.FILE_SPOOL_DIR']
        uid: options.user.name
        gid: options.hadoop_group.name
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
        principal: "#{options.service_repo.configs.username}@#{options.krb5.realm}"
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

## Plugin Scripts 

      @call ->
        # migration, wdavdiw 170918, this is not a j2 template so we should
        # just generate the file without relying on a template
        @file.render
          header: 'Properties'
          if: -> version?
          source: "#{__dirname}/../../resources/plugin-install.properties.j2"
          target: "/usr/hdp/#{version}/ranger-hbase-plugin/install.properties"
          local: true
          eof: true
          backup: true
          write: for k, v of options.install
            match: RegExp "^#{quote k}=.*$", 'mg'
            replace: "#{k}=#{v}"
            append: true
        @call header: 'Enable', (_, callback) ->
          @each options.conf_dir, (opt, cb) ->
            conf_dir = opt.key
            files = ['ranger-hbase-audit.xml','ranger-hbase-security.xml','ranger-policymgr-ssl.xml']
            sources_props = {}
            current_props = {}
            files_exists = {}
            @system.execute
              cmd: """
              echo '' | keytool -list \
                -storetype jceks \
                -keystore /etc/ranger/#{options.install['REPOSITORY_NAME']}/cred.jceks \
              | egrep '.*ssltruststore|auditdbcred|sslkeystore'
              """
              code_skipped: 1
            @call
              if: -> @status -1 # do not need this if the cred.jceks file is not provisioned
            , ->
              @each files, (opt, cb) ->
                file = opt.key
                target = "#{conf_dir}/#{file}"
                @fs.exists target, (err, exists) ->
                  return cb err if err
                  return cb() unless exists
                  files_exists[file] = exists
                  properties.read options.ssh, target, (err, props) ->
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
              header: 'Enable'
              cmd: "/usr/hdp/#{version}/ranger-hbase-plugin/enable-hbase-plugin.sh"
            # @system.execute
            #   header: "Fix Plugin repository permission"
            #   cmd: "chown -R #{options.user.name}:#{options.hadoop_group.name} /etc/ranger/#{options.install['REPOSITORY_NAME']}"
            @hconfigure
              header: 'Security Fix'
              target: "#{conf_dir}/ranger-hbase-security.xml"
              merge: true
              properties:
                'ranger.plugin.hbase.policy.rest.ssl.config.file': "#{conf_dir}/ranger-policymgr-ssl.xml"
            @each files, (opt, cb) ->
              file = opt.key
              target = "#{conf_dir}/#{file}"
              @fs.exists target, (err, exists) ->
                return callback err if err
                properties.read options.ssh, target , (err, props) ->
                  return cb err if err
                  current_props["#{file}"] = props
                  cb()
            @call
              header: 'Diff'
              shy: true
            , ->
              for file in files
                #do not need to go further if the file did not exist
                return callback null, true unless sources_props["#{file}"]?
                for prop, value of current_props["#{file}"]
                  return callback null, true unless value is sources_props["#{file}"][prop]
                for prop, value of sources_props["#{file}"]
                  return callback null, true unless value is current_props["#{file}"][prop]
                return callback null, false

## Dependencies

    quote = require 'regexp-quote'
    path = require 'path'
    mkcmd = require '../../../lib/mkcmd'
    properties = require '../../../lib/properties'

[plugin]:(https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.4.0/bk_installing_manually_book/content/installing_ranger_plugins.html#installing_ranger_hbase_plugin)
[perms-fix]: https://community.hortonworks.com/questions/23717/ranger-solr-on-hdp-234-unable-to-refresh-policies.html

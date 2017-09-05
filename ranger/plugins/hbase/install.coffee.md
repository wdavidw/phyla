
# Ranger HBase Plugin Install

    module.exports = header: 'Ranger HBase Plugin Install', handler: (options) ->
      version= null

## Wait

      @call once: true, 'ryba/ranger/admin/wait', options.wait_ranger_admin

## Register

      
      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdfs_mkdir', 'ryba/lib/hdfs_mkdir'

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

## Layout

      @system.mkdir
        target: options.install['XAAUDIT.HDFS.FILE_SPOOL_DIR']
        uid: options.user.name
        gid: options.hadoop_group.name
        mode: 0o0750
        if: options.install['XAAUDIT.HDFS.IS_ENABLED'] is 'true'
      @system.mkdir
        target: options.install['XAAUDIT.SOLR.FILE_SPOOL_DIR']
        uid: options.user.name
        gid: options.hadoop_group.name
        mode: 0o0750
        if: options.install['XAAUDIT.SOLR.IS_ENABLED'] is 'true'

## HBase Service Repository creation
Matchs step 1 in [hdfs plugin configuration][hbase-plugin]. Instead of using the web ui
we execute this task using the rest api.

      @call
        header: 'Policy'
      , ->
        hbase_policy =
          name: "hbase-ranger-plugin-audit"
          service: "#{options.hdfs_install['REPOSITORY_NAME']}"
          repositoryType:"hdfs"
          description: 'HBase Ranger Plugin audit log policy'
          isEnabled: true
          isAuditEnabled: true
          resources:
            path:
              isRecursive: 'true'
              values: ['/ranger/audit/hbaseRegional','/ranger/audit/hbaseMaster']
              isExcludes: false
          policyItems: [{
            users: ["#{options.user.name}"]
            groups: []
            delegateAdmin: true
            accesses:[
                "isAllowed": true
                "type": "read"
            ,
                "isAllowed": true
                "type": "write"
            ,
                "isAllowed": true
                "type": "execute"
            ]
            conditions: []
            }]
        @hdfs_mkdir
          header: 'HBase Master plugin HDFS audit dir'
          target: "/#{options.user.name}/audit/hbaseMaster"
          mode: 0o750
          user: options.user.name
          group: options.group.name
        @hdfs_mkdir
          header: 'HBase Regionserver plugin HDFS audit dir'
          target: "/#{options.user.name}/audit/hbaseRegional"
          mode: 0o750
          user: options.user.name
          group: options.group.name
        @system.execute
          header: 'Admin Policy'
          unless_exec: """
          curl --fail -H "Content-Type: application/json" -k -X GET  \
            -u #{options.ranger_admin.username}:#{options.ranger_admin.password} \
            "#{options.hdfs_install['POLICY_MGR_URL']}/service/public/v2/api/service/#{options.hdfs_install['REPOSITORY_NAME']}/policy/hbase-ranger-plugin-audit"
          """
          cmd: """
          curl --fail -H "Content-Type: application/json" -k -X POST \
            -d '#{JSON.stringify hbase_policy}' \
            -u #{options.ranger_admin.username}:#{options.ranger_admin.password} \
            "#{options.hdfs_install['POLICY_MGR_URL']}/service/public/v2/api/policy"
          """
        @system.execute
          header: 'Admin Repository'
          unless_exec: """
          curl --fail -H "Content-Type: application/json"   -k -X GET  \
            -u #{options.ranger_admin.username}:#{options.ranger_admin.password} \
            "#{options.install['POLICY_MGR_URL']}/service/public/v2/api/service/name/#{options.install['REPOSITORY_NAME']}"
          """
          cmd: """
          curl --fail -H "Content-Type: application/json" -k -X POST -d '#{JSON.stringify options.service_repo}' \
            -u #{options.ranger_admin.username}:#{options.ranger_admin.password} \
            "#{options.install['POLICY_MGR_URL']}/service/public/v2/api/service/"
          """

## HBase  Plugin Principal

      # migration: wdavidw, 170905, isnt the principal hbase/{fqdn}? If so, then
      # it should already be provisionned by HBase Master, no ?
      # @krb5.addprinc options.krb5.admin,
      #   if: options.principal
      #   header: 'Ranger HBase Principal'
      #   principal: ranger.hbase_plugin.principal
      #   randkey: true
      #   password: ranger.hbase_plugin.password

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
        @file.render
          header: 'Scripts rendering'
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
        @file
          header: 'Script Fix'
          target: "/usr/hdp/#{version}/ranger-hbase-plugin/enable-hbase-plugin.sh"
          write:[
              match: RegExp "^HCOMPONENT_CONF_DIR=.*$", 'mg'
              replace: "HCOMPONENT_CONF_DIR=#{options.conf_dir}"
            ,
              match: RegExp "\\^HCOMPONENT_LIB_DIR=.*$", 'mg'
              replace: "HCOMPONENT_LIB_DIR=/usr/hdp/current/hbase-client/lib"
          ]
          backup: true
          mode: 0o750
        @call header: 'Enable HBase Plugin', (options, callback) ->
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
            if: -> @status -1 #do not need this if the cred.jceks file is not provisioned
          , ->
            @each files, (options, cb) ->
              file = options.key
              target = "#{options.conf_dir}/#{file}"
              @fs.exists target, (err, exists) ->
                return cb err if err
                return cb() unless exists
                files_exists["#{file}"] = exists
                properties.read options.ssh, target , (err, props) ->
                  return cb err if err
                  sources_props["#{file}"] = props
                  cb()
          @system.execute
            header: 'Script Execution'
            cmd: """
            if /usr/hdp/#{version}/ranger-hbase-plugin/enable-hbase-plugin.sh ;
            then exit 0 ;
            else exit 1 ;
            fi;
            """
          @system.execute
            header: "Fix Plugin repository permission"
            cmd: "chown -R #{options.user.name}:#{options.hadoop_group.name} /etc/ranger/#{options.install['REPOSITORY_NAME']}"
          @hconfigure
            header: 'Fix Plugin security conf'
            target: "#{options.conf_dir}/ranger-hbase-security.xml"
            merge: true
            properties:
              'ranger.plugin.hbase.policy.rest.ssl.config.file': "#{options.conf_dir}/ranger-policymgr-ssl.xml"
          @each files, (options, cb) ->
            file = options.key
            target = "#{options.conf_dir}/#{file}"
            @fs.exists target, (err, exists) ->
              return callback err if err
              properties.read options.ssh, target , (err, props) ->
                return cb err if err
                current_props["#{file}"] = props
                cb()
          @call
            header: 'Compare Current Config Files'
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

[hbase-plugin]:(https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.4.0/bk_installing_manually_book/content/installing_ranger_plugins.html#installing_ranger_hbase_plugin)
[perms-fix]https://community.hortonworks.com/questions/23717/ranger-solr-on-hdp-234-unable-to-refresh-policies.html

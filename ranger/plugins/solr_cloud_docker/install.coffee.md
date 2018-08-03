
# Ranger Solr Cloud on Docker Ranger Plugin Install

    module.exports = header: 'Ranger Solr Plugin install', handler: (options) ->
      version = null

## Registry

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdfs_mkdir', 'ryba/lib/hdfs_mkdir'
      @registry.register 'ranger_service', 'ryba/ranger/actions/ranger_service'
      @registry.register 'ranger_policy', 'ryba/ranger/actions/ranger_policy'

## Wait

      @call once: true, 'ryba/ranger/admin/wait', options.wait_ranger_admin

## Packages

      @call header: 'Packages', ->
        @system.execute
          header: 'Setup Execution Version'
          shy:true
          cmd: """
          hdp-select versions | tail -1
          """
         , (err, data) ->
            return  err if err or not data.status
            version = data.stdout.trim() if data.status
            
        @service
          name: "ranger-solr-plugin"

## Service Repositories

      @each options.service_repos, (opts, callback) ->
        {key, value} = opts
        #Ranger Repository
        @ranger_service
          username: options.ranger_admin.options.admin.username
          password: options.ranger_admin.options.admin.password
          url: options.solr_plugins[key].install['POLICY_MGR_URL']
          service: value
        @next callback
      
## Service Layout
        
      @each options.solr_plugins, (opts, callback) ->
        {key, value} = opts
        @call
          if: value.install['XAAUDIT.HDFS.IS_ENABLED'] is 'true'
          header: 'Audit HDFS Policy'
        , ->
          @ranger_policy
            header: 'HDFS Audit'
            username: options.ranger_admin.options.admin.username
            password: options.ranger_admin.options.admin.password
            url: value.install['POLICY_MGR_URL']
            policy: value.policy_hdfs_audit
          @system.mkdir
            header: 'HDFS Spool Dir'
            if: value.install['XAAUDIT.HDFS.IS_ENABLED'] is 'true'
            target: value.install['XAAUDIT.HDFS.FILE_SPOOL_DIR']
            uid: options.solr_user.name
            gid: options.solr_user.name
            mode: 0o0750
          @call ->
            for target in value.policy_hdfs_audit
              @hdfs_mkdir
                target: target
                mode: 0o0750
                parent:
                  mode: 0o0711
                  user: options.user.name
                  group: options.group.name
                uid: options.solr_user.name
                gid: options.solr_user.name
                krb5_user: options.hdfs_krb5_user
          @system.mkdir
            header: 'Solr Spool Dir'
            if: value.install['XAAUDIT.SOLR.IS_ENABLED'] is 'true'
            target: value.install['XAAUDIT.SOLR.FILE_SPOOL_DIR']
            uid: options.solr_user.name
            gid: options.solr_user.name
            mode: 0o0750

                      
                      
      # solr_plugin.hdp_current_version = null
      # context.system.execute
      #   cmd:  "hdp-select versions | tail -1"
      #   header: 'configure mounts'
      # , (err, data) ->
      #   return callback err if err
      #   solr_plugin.hdp_current_version = data.stdout.trim() if data.status
      # "/usr/hdp/#{solr_plugin.hdp_current_version}/ranger-solr-plugin:/usr/hdp/#{solr_plugin.hdp_current_version}/ranger-solr-plugin"
      # context.call 'ryba/ranger/plugins/solr_cloud_docker/install', solr_cluster: {config: cluster_config, name: name, host_config: host_config}

# Plugin Scripts 
The execution of the ranger-solr-plugin-enable script,  slightly differs from other plugins.
Indeed the ranger' lib dir needs to be added to solr's classpath. By default solr
loads the lib directory found in the `SOLR_HOME`.

        @call ->
          @file
            header: 'Scripts rendering'
            if: -> version?
            source: "#{__dirname}/../../resources/plugin-install.properties"
            target: "/usr/hdp/#{version}/ranger-solr-plugin/install.properties"
            local: true
            eof: true
            backup: true
            write: for k, v of options.solr_plugins[key].install
              match: RegExp "^#{quote k}=.*$", 'mg'
              replace: "#{k}=#{v}"
              append: true
        @system.mkdir
          target: "#{options.conf_dir}/clusters/#{key}/server/solr-webapp/webapp/WEB-INF/classes"
          uid: options.solr_user.name
          gid: options.solr_group.name
          mode: 0o0750
        @system.mkdir
          target: "#{options.conf_dir}/clusters/#{key}/server/solr-webapp/webapp/WEB-INF/lib"
          uid: options.solr_user.name
          gid: options.solr_group.name
          mode: 0o0750
        @file
          header: 'Script Fix'
          target: "/usr/hdp/#{version}/ranger-solr-plugin/enable-solr-plugin.sh"
          write: [
              match: RegExp "^HCOMPONENT_INSTALL_DIR=.*$", 'mg'
              replace: "HCOMPONENT_INSTALL_DIR=#{options.conf_dir}/clusters/#{key}/server"
            ,
              match: RegExp "^HCOMPONENT_CONF_DIR=.*$", 'mg'
              replace: "HCOMPONENT_CONF_DIR=#{options.conf_dir}/clusters/#{key}/server/solr-webapp/webapp/WEB-INF/classes"
            ,
              match: RegExp "^HCOMPONENT_LIB_DIR=.*$", 'mg'
              replace: "HCOMPONENT_LIB_DIR=#{options.conf_dir}/clusters/#{key}/server/solr-webapp/webapp/WEB-INF/lib"
            
          ]
          backup: true
          mode: 0o750
        @call
          header: 'Enable Solr Plugin'
        , (_, callback) ->
          files = ['ranger-solr-audit.xml','ranger-solr-security.xml','ranger-policymgr-ssl.xml']
          sources_props = {}
          current_props = {}
          files_exists = {}
          @system.execute
            cmd: """
            echo '' | keytool -list \
              -storetype jceks \
              -keystore /etc/ranger/#{options.solr_plugins[key].install['REPOSITORY_NAME']}/cred.jceks | egrep '.*ssltruststore|auditdbcred|sslkeystore'
            """
            code_skipped: 1
          @call
            if: -> @status -1 #do not need this if the cred.jceks file is not provisioned
          , ->
            @each files, (opts, cb) ->
              file = opts.key
              target = "#{options.conf_dir}/clusters/#{key}/server/solr-webapp/webapp/WEB-INF/classes/#{file}"
              ssh = @ssh options.ssh
              fs.exists ssh, target, (err, exists) ->
                return cb err if err
                return cb() unless exists
                files_exists["#{file}"] = exists
                properties.read ssh, target , (err, props) ->
                  return cb err if err
                  sources_props["#{file}"] = props
                  cb()
          @system.execute
            header: 'Script Execution'
            cmd: """
            if /usr/hdp/#{version}/ranger-solr-plugin/enable-solr-plugin.sh ;
            then exit 0 ;
            else exit 1 ;
            fi;
            """
          @hconfigure
            header: 'Fix ranger-solr-security conf'
            target: "#{options.conf_dir}/clusters/#{key}/server/solr-webapp/webapp/WEB-INF/classes/ranger-solr-security.xml"
            merge: true
            properties:
              'ranger.plugin.solr.policy.rest.ssl.config.file': "/usr/solr-cloud/current/server/solr-webapp/webapp/WEB-INF/classes/ranger-policymgr-ssl.xml"
          @chown
            header: 'Fix Permissions'
            target: "/etc/ranger/#{value.install['REPOSITORY_NAME']}/.cred.jceks.crc"
            uid: options.solr_user.name
            gid: options.solr_group.name
          @hconfigure
            header: 'JAAS Properties for solr'
            target: "#{options.conf_dir}/clusters/#{key}/server/solr-webapp/webapp/WEB-INF/classes/ranger-solr-audit.xml"
            merge: true
            properties: value.audit
          @each files, (opts, cb) ->
            file = opts.key
            target = "#{options.conf_dir}/clusters/#{key}/server/solr-webapp/webapp/WEB-INF/classes/#{file}"
            ssh = @ssh options.ssh
            fs.exists ssh, target, (err, exists) ->
              return callback err if err
              properties.read ssh, target , (err, props) ->
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
        @system.copy
          source: '/etc/hadoop/conf/core-site.xml'
          target: "#{options.conf_dir}/clusters/#{key}/server/solr-webapp/webapp/WEB-INF/classes/core-site.xml"
        @system.copy
          source: '/etc/hadoop/conf/hdfs-site.xml'
          target: "#{options.conf_dir}/clusters/#{key}/server/solr-webapp/webapp/WEB-INF/classes/hdfs-site.xml"
        @next callback


## Dependencies

    quote = require 'regexp-quote'
    path = require 'path'
    mkcmd = require '../../../lib/mkcmd'
    properties = require '../../../lib/properties'
    fs = require 'ssh2-fs'

[solr-plugin]:(https://community.hortonworks.com/articles/15159/securing-solr-collections-with-ranger-kerberos.html)

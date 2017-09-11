
# Ranger HDFS Plugin Install

    module.exports = header: 'Ranger HDFS Plugin', handler: (options) ->

## HDFS Dependencies

      @call 'ryba/ranger/admin/wait', once: true, options.wait_ranger_admin
      # @call 'ryba/hadoop/hdfs_client/install' #migation solved it with implicy hdfs_client requirement
      @registry.register 'hconfigure', 'ryba/lib/hconfigure'

## HDP version

      version = null
      @system.execute
        header: 'HDP Version'
        shy: true
        cmd: """
        hdp-select versions | tail -1
        """
       , (err, executed,stdout, stderr) ->
          return  err if err or not executed
          version = stdout.trim() if executed

## Package

      @service
        header: 'Package'
        name: "ranger-hdfs-plugin"

## Layout

      @system.mkdir
        header: 'HDFS Spool Dir'
        if: options.install['XAAUDIT.HDFS.IS_ENABLED'] is 'true'
        target: options.install['XAAUDIT.HDFS.FILE_SPOOL_DIR']
        uid: options.hdfs_user.name
        gid: options.hadoop_group.name
        mode: 0o0750
      @system.mkdir
        header: 'SOLR Spool Dir'
        if: options.install['XAAUDIT.SOLR.IS_ENABLED'] is 'true'
        target: options.install['XAAUDIT.SOLR.FILE_SPOOL_DIR']
        uid: options.hdfs_user.name
        gid: options.hadoop_group.name
        mode: 0o0750

## Plugin Scripts

From HDP 2.5 (Ranger 0.6) hdfs plugin need a Client JAAS configuration file to
talk with kerberized component.
The JAAS configuration can be donne with a jaas file and the Namenonde Env property
auth.to.login.conf or can be set by properties in ranger-hdfs-audit.xml file.
Not documented be taken from [github-source][hdfs-plugin-source]

      @call
        header: 'HDFS Plugin'
      , (_, callback) ->
        files = ['ranger-hdfs-audit.xml','ranger-hdfs-security.xml','ranger-policymgr-ssl.xml', 'hdfs-site.xml']
        sources_props = {}
        current_props = {}
        files_exists = {}
        # wrap into call for version to be not null
        @file.render
          header: 'Configuration'
          if: -> version?
          source: "#{__dirname}/../../resources/plugin-install.properties.j2"
          target: "/usr/hdp/#{version}/ranger-hdfs-plugin/install.properties"
          local: true
          eof: true
          backup: true
          write: for k, v of options.install
            match: RegExp "^#{quote k}=.*$", 'mg'
            replace: "#{k}=#{v}"
            append: true
        @system.execute
          cmd: """
          echo '' | keytool -list \
            -storetype jceks \
            -keystore /etc/ranger/#{options.install['REPOSITORY_NAME']}/cred.jceks | egrep '.*ssltruststore|auditdbcred|sslkeystore'
          """
          code_skipped: 1
        @call
          if: -> @status -1 #do not need this if the cred.jceks file is not provisioned
        , ->
          @each files, (file, cb) ->
            file = file.key
            target = "#{options.hdfs_conf_dir}/#{file}"
            @fs.exists target, (err, exists) ->
              return cb err if err
              return cb() unless exists
              files_exists["#{file}"] = exists
              properties.read options.ssh, target , (err, props) ->
                return cb err if err
                sources_props["#{file}"] = props
                cb()
        @file
          header: 'Fix'
          target: "/usr/hdp/#{version}/ranger-hdfs-plugin/enable-hdfs-plugin.sh"
          write: [
              match: RegExp "^HCOMPONENT_CONF_DIR=.*$", 'mg'
              replace: "HCOMPONENT_CONF_DIR=#{options.hdfs_conf_dir}"
            ,
              match: RegExp "^HCOMPONENT_INSTALL_DIR_NAME=.*$", 'mg'
              replace: "HCOMPONENT_INSTALL_DIR_NAME=/usr/hdp/current/hadoop-hdfs-namenode"
            ,
              match: RegExp "^HCOMPONENT_LIB_DIR=.*$", 'mg'
              replace: "HCOMPONENT_LIB_DIR=/usr/hdp/current/hadoop-hdfs-namenode/lib"
          ]
          backup: true
          mode: 0o750
        @system.execute
          header: 'Execution'
          shy: true
          cmd: """
          export HADOOP_LIBEXEC_DIR=/usr/hdp/current/hadoop-client/libexec
          if /usr/hdp/#{version}/ranger-hdfs-plugin/enable-hdfs-plugin.sh ;
          then exit 0 ;
          else exit 1 ;
          fi;
          """
        @hconfigure
          header: 'Fix Conf'
          target: "#{options.hdfs_conf_dir}/ranger-hdfs-security.xml"
          merge: true
          properties:
            'ranger.plugin.hdfs.policy.rest.ssl.config.file': "#{options.hdfs_conf_dir}/ranger-policymgr-ssl.xml"
        @hconfigure
          header: 'Solr JAAS'
          target: "#{options.hdfs_conf_dir}/ranger-hdfs-audit.xml"
          merge: true
          properties: options.audit
        @each files, (file, cb) ->
          file = file.key
          target = "#{options.hdfs_conf_dir}/#{file}"
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


## Service Repository

Based on step 1 in [hdfs plugin configuration][hdfs-plugin]. Instead of using the web ui
we execute this task using the rest api.

      @call 'ryba/ranger/admin/wait', once: true, options.wait_ranger_admin
      @system.execute
        header: 'Ranger HDFS Repository'
        if: options.repo_create
        unless_exec: """
        curl --fail -H "Content-Type: application/json" -k -X GET  \
          -u #{options.ranger_admin.username}:#{options.ranger_admin.password} "#{options.install['POLICY_MGR_URL']}/service/public/v2/api/service/name/#{options.install['REPOSITORY_NAME']}"
        """
        cmd: """
        curl --fail -H "Content-Type: application/json" -k -X POST -d '#{JSON.stringify options.service_repo}' \
          -u #{options.ranger_admin.username}:#{options.ranger_admin.password} "#{options.install['POLICY_MGR_URL']}/service/public/v2/api/service/"
        """
      # See [#96](https://github.com/ryba-io/ryba/issues/95): Ranger HDFS: should we use a dedicated principal
      @krb5.addprinc options.krb5.admin,
        header: 'Ranger HDFS Principal'
        # if: options.plugins.principal
        principal: "#{options.service_repo.configs.principal}@#{options.krb5.realm}"
        password: options.service_repo.configs.password

## Dependencies

    quote = require 'regexp-quote'
    properties = require '../../../lib/properties'

[hdfs-plugin]: https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.4.0/bk_installing_manually_book/content/installing_ranger_plugins.html#installing_ranger_hdfs_plugin
[hdfs-plugin-source]: https://github.com/apache/incubator-ranger/blob/ranger-0.6/agents-audit/src/main/java/org/apache/ranger/audit/utils/InMemoryJAASConfiguration.java

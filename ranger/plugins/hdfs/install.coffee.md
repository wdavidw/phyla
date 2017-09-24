
# Ranger HDFS Plugin Install

    module.exports = header: 'Ranger HDFS Plugin', handler: (options) ->

## Wait

      @call 'ryba/ranger/admin/wait', once: true, options.wait_ranger_admin

## HDFS Dependencies

      # @call 'ryba/hadoop/hdfs_client/install' #migation solved it with implicy hdfs_client requirement
      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdfs_mkdir', 'ryba/lib/hdfs_mkdir'
      @registry.register 'ranger_service', 'ryba/ranger/actions/ranger_service'

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

The value present in "XAAUDIT.HDFS.DESTINATION_DIRECTORY" contains variables
such as "%app-type% and %time:yyyyMMdd%".

migration: wdavidw 170918, NameNodes are not yet started.

      # @hdfs_mkdir
      #   header: 'HDFS Audit'
      #   # target: options.install['XAAUDIT.HDFS.DESTINATION_DIRECTORY']
      #   target: "/#{options.user.name}/audit/#{options.service_repo.type}"
      #   mode: 0o0750
      #   parent:
      #     mode: 0o0711
      #     user: options.user.name
      #     group: options.group.name
      #   user: options.hdfs_user.name
      #   group: options.hdfs_group.name
      @system.mkdir
        header: 'SOLR Spool Dir'
        if: options.install['XAAUDIT.SOLR.IS_ENABLED'] is 'true'
        target: options.install['XAAUDIT.SOLR.FILE_SPOOL_DIR']
        uid: options.hdfs_user.name
        gid: options.hadoop_group.name
        mode: 0o0750


## Service Repository

Based on step 1 in [hdfs plugin configuration][plugin]. Instead of using the web ui
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

## Plugin Scripts

From HDP 2.5 (Ranger 0.6) hdfs plugin need a Client JAAS configuration file to
talk with kerberized component.
The JAAS configuration can be donne with a jaas file and the Namenonde Env property
auth.to.login.conf or can be set by properties in ranger-hdfs-audit.xml file.
Not documented be taken from [github-source][plugin-source]

      @call
        header: 'HDFS Plugin'
      , (_, callback) ->
        files = ['ranger-hdfs-audit.xml','ranger-hdfs-security.xml','ranger-policymgr-ssl.xml', 'hdfs-site.xml']
        sources_props = {}
        current_props = {}
        files_exists = {}
        # wrap into call for version to be not null
        @file
          header: 'Configuration'
          if: -> version?
          source: "#{__dirname}/../../resources/plugin-install.properties"
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

## Dependencies

    quote = require 'regexp-quote'
    properties = require '../../../lib/properties'

[plugin]: https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.4.0/bk_installing_manually_book/content/installing_ranger_plugins.html#installing_ranger_hdfs_plugin
[plugin-source]: https://github.com/apache/incubator-ranger/blob/ranger-0.6/agents-audit/src/main/java/org/apache/ranger/audit/utils/InMemoryJAASConfiguration.java

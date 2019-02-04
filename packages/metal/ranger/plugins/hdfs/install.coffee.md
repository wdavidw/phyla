
# Ranger HDFS Plugin Install

    module.exports = header: 'Ranger HDFS Plugin', handler: ({options}) ->
      {hdfs_conf_dir} = options

## Wait

      @call '@rybajs/metal/ranger/admin/wait', once: true, options.wait_ranger_admin

## HDFS Dependencies

      # @call '@rybajs/metal/hadoop/hdfs_client/install' #migation solved it with implicy hdfs_client requirement
      @registry.register 'hconfigure', '@rybajs/metal/lib/hconfigure'
      @registry.register 'hdfs_mkdir', '@rybajs/metal/lib/hdfs_mkdir'
      @registry.register 'ranger_service', '@rybajs/metal/ranger/actions/ranger_service'
      @registry.register 'ranger_policy', '@rybajs/metal/ranger/actions/ranger_policy'
      @registry.register 'ranger_user', '@rybajs/metal/ranger/actions/ranger_user'

## HDP version

      version = null
      @system.execute
        header: 'HDP Version'
        shy: true
        cmd: """
        hdp-select versions | tail -1
        """
       , (err, {status, stdout}) ->
          throw err if err
          version = stdout.trim()

## Package

      @service
        header: 'Package'
        name: "ranger-hdfs-plugin"

## Layout

The value present in "XAAUDIT.HDFS.DESTINATION_DIRECTORY" contains variables
such as "%app-type% and %time:yyyyMMdd%".

migration: wdavidw 170918, NameNodes are not yet started.

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


## Ranger User

      @ranger_user
        if: options.master_fqdn is options.fqdn
        header: 'Ranger User'
        username: options.ranger_admin.username
        password: options.ranger_admin.password
        url: options.install['POLICY_MGR_URL']
        user: options.plugin_user

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

      # See [#96](https://github.com/ryba-io/@rybajs/metal/issues/95): Ranger HDFS: should we use a dedicated principal
      @krb5.addprinc options.krb5.admin,
        header: 'Plugin Principal'
        principal: "#{options.service_repo.configs.username}"
        password: options.service_repo.configs.password

## Properties

      @call -> @file
        header: 'Properties'
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

## Plugin Scripts

From HDP 2.5 (Ranger 0.6) hdfs plugin need a Client JAAS configuration file to
talk with kerberized component.
The JAAS configuration can be donne with a jaas file and the Namenonde Env property
auth.to.login.conf or can be set by properties in ranger-hdfs-audit.xml file.
Not documented be taken from [github-source][plugin-source]

      @call (_, callback) ->
        files = ['ranger-hdfs-audit.xml','ranger-hdfs-security.xml','ranger-policymgr-ssl.xml', 'hdfs-site.xml']
        sources_props = {}
        current_props = {}
        files_exists = {}
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
          @each files, ({options}, cb) ->
            file = options.key
            target = "#{hdfs_conf_dir}/#{file}"
            ssh = @ssh options.ssh
            fs.exists ssh, target, (err, exists) ->
              return cb err if err
              return cb() unless exists
              files_exists["#{file}"] = exists
              properties.read ssh, target , (err, props) ->
                return cb err if err
                sources_props["#{file}"] = props
                cb()
        @system.link
          source: hdfs_conf_dir
          target: '/usr/hdp/current/hadoop-hdfs-namenode/etc/hadoop'
        @file
          header: 'Fix'
          target: "/usr/hdp/#{version}/ranger-hdfs-plugin/enable-hdfs-plugin.sh"
          write: [
              match: RegExp "^HCOMPONENT_CONF_DIR=.*$", 'mg'
              replace: "HCOMPONENT_CONF_DIR=#{hdfs_conf_dir}"
            ,
              match: RegExp "^HCOMPONENT_INSTALL_DIR_NAME=.*$", 'mg'
              replace: "HCOMPONENT_INSTALL_DIR_NAME=/usr/hdp/current/hadoop-hdfs-namenode"
            ,
              match: RegExp "^HCOMPONENT_LIB_DIR=.*$", 'mg'
              replace: "HCOMPONENT_LIB_DIR=/usr/hdp/current/hadoop-hdfs-namenode/lib"
            ,
              match: RegExp "^HCOMPONENT_ARCHIVE_CONF_DIR==.*$", 'mg'
              replace: "HCOMPONENT_LIB_DIR=#{hdfs_conf_dir}/.archive"
            ,
              match: RegExp "^HCOMPONENT_INSTALL_DIR==.*$", 'mg'
              replace: "HCOMPONENT_INSTALL_DIR=/usr/hdp/current/hadoop-hdfs-namenode"
              
          ]
          backup: true
          mode: 0o750
        @system.execute
          header: 'Execution'
          shy: true
          cmd: """
          export HADOOP_LIBEXEC_DIR=/usr/hdp/current/hadoop-client/libexec
          /usr/hdp/#{version}/ranger-hdfs-plugin/enable-hdfs-plugin.sh
          """
        @hconfigure
          header: 'Fix Conf'
          target: "#{hdfs_conf_dir}/ranger-hdfs-security.xml"
          merge: true
          properties:
            'ranger.plugin.hdfs.policy.rest.ssl.config.file': "#{hdfs_conf_dir}/ranger-policymgr-ssl.xml"
        @hconfigure
          header: 'Solr JAAS'
          target: "#{hdfs_conf_dir}/ranger-hdfs-audit.xml"
          merge: true
          properties: options.audit
        @each files, ({options}, cb) ->
          file = options.key
          target = "#{hdfs_conf_dir}/#{file}"
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

## Dependencies

    quote = require 'regexp-quote'
    properties = require '../../../lib/properties'
    fs = require 'ssh2-fs'

[plugin]: https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.4.0/bk_installing_manually_book/content/installing_ranger_plugins.html#installing_ranger_hdfs_plugin
[plugin-source]: https://github.com/apache/incubator-ranger/blob/ranger-0.6/agents-audit/src/main/java/org/apache/ranger/audit/utils/InMemoryJAASConfiguration.java

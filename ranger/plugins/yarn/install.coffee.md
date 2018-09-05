
    module.exports = header: 'Ranger YARN Plugin install', handler: ({options}) ->
      version = null

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdfs_mkdir', 'ryba/lib/hdfs_mkdir'
      @registry.register 'ranger_policy', 'ryba/ranger/actions/ranger_policy'
      @registry.register 'ranger_service', 'ryba/ranger/actions/ranger_service'


## Wait

      @call 'ryba/ranger/admin/wait', once: true, options.wait_ranger_admin


## Packages

      @call header: 'Packages', ->
        @system.execute
          header: 'Setup Execution'
          shy: true
          cmd: """
          hdp-select versions | tail -1
          """
         , (err, {status, stdout}) ->
            throw err if err
            version = stdout.trim()
        @service
          name: "ranger-yarn-plugin"

## Layout


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
          uid: options.yarn_user.name
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
              uid: options.yarn_user.name
              gid: options.hadoop_group.name
              krb5_user: options.hdfs_krb5_user
      @system.mkdir
        target: options.install['XAAUDIT.SOLR.FILE_SPOOL_DIR']
        uid: options.yarn_user.name
        gid: options.hadoop_group.name
        mode: 0o0750
        if: options.install['XAAUDIT.SOLR.IS_ENABLED'] is 'true'

## YARN Service Repository creation

Matchs step 1 in [hdfs plugin configuration][yarn-plugin]. Instead of using the web ui
we execute this task using the rest api.

      @ranger_service
        if: options.exec_repo
        header: 'Yarn Repo'
        username: options.ranger_admin.username
        password: options.ranger_admin.password
        url: options.install['POLICY_MGR_URL']
        service: options.service_repo

Note, by default, we're are using the same Ranger principal for every
plugin and the principal is created by the Ranger Admin service. Chances
are that a customer user will need specific ACLs but this hasn't been
tested.

      # See [#96](https://github.com/ryba-io/ryba/issues/95): Ranger HDFS: should we use a dedicated principal
      @krb5.addprinc
        header: 'Ranger YARN Principal'
        # if: options.plugins.principal
        principal: "#{options.service_repo.configs.username}"
        password: options.service_repo.configs.password
      , options.krb5.admin

## HDFS Audit Layout

        # @system.execute
        #   header: 'HDFS Audit Layout'
        #   cmd: mkcmd.hdfs options.hdfs_krb5_user, """
        #   hdfs --config #{options.conf_dir} dfs -mkdir -p /#{options.user.name}/audit/yarn
        #   hdfs --config #{options.conf_dir} dfs -chown -R #{options.yarn_user.name}:#{options.yarn_user.name} /#{options.user.name}/audit/yarn
        #   hdfs --config #{options.conf_dir} dfs -chmod 750 /#{options.user.name}/audit/yarn
        #   """
      @hdfs_mkdir
        target: "/#{options.user.name}/audit/yarn"
        user: options.yarn_user.name
        mode: 0o0750
        conf_dir: options.conf_dir
        krb5_user: options.hdfs_krb5_user

## Properties

      @call -> @file
        header: 'Properties'
        if: -> version?
        source: "#{__dirname}/../../resources/plugin-install.properties"
        target: "/usr/hdp/#{version}/ranger-yarn-plugin/install.properties"
        local: true
        eof: true
        backup: true
        write: for k, v of options.install
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true

## Activation

      @call
        header: 'Activation'
      , ->
        @file.render
          header: 'Env'
          target: "/usr/hdp/#{version}/ranger-yarn-plugin/enable-yarn-plugin.sh"
          source: "#{__dirname}/../../resources/enable-yarn-plugin.sh.j2"
          local: true
          mode: 0o755
          eof: true
          context:
            conf_dir: options.conf_dir
            install_dir: '/usr/hdp/current/hadoop-yarn-resourcemanager'
            lib_dir: '/usr/hdp/current/hadoop-yarn-resourcemanager/lib'
        @system.execute
          header: 'Script Execution'
          cmd: """
          export HADOOP_LIBEXEC_DIR=/usr/hdp/current/hadoop-client/libexec
          cd /usr/hdp/#{version}/ranger-yarn-plugin/
          ./enable-yarn-plugin.sh
          """
        @system.execute
          header: 'Fix repository'
          cmd: "chown -R #{options.yarn_user.name}:#{options.hadoop_group.name} /etc/ranger/#{options.install['REPOSITORY_NAME']}"
        @hconfigure
          header: 'Fix ranger-yarn-security conf'
          target: "#{options.conf_dir}/ranger-yarn-security.xml"
          merge: true
          properties:
            'ranger.plugin.yarn.policy.rest.ssl.config.file': "#{options.conf_dir}/ranger-policymgr-ssl.xml"
        # @hconfigure
        #   header: 'plugin properties site'
        #   target: "#{options.conf_dir}/ranger-yarn-audit.xml"
        #   properties: options.configurations['ranger-yarn-audit']
        #   backup: true
        # @hconfigure
        #   header: 'policymgr ssl site'
        #   target: "#{options.conf_dir}/ranger-policymgr-ssl.xml"
        #   properties: options.configurations['ranger-yarn-policymgr-ssl']
        #   backup: true
        # @hconfigure
        #   header: 'yarn security site'
        #   target: "#{options.conf_dir}/ranger-yarn-security.xml"
        #   properties: options.configurations['ranger-yarn-security']
        #   backup: true
        @file
          header: 'Fix Ranger YARN Plugin Env'
          target: "#{options.conf_dir}/yarn-env.sh"
          write: [
            match: RegExp "^export YARN_OPTS=.*", 'mg'
            replace: "export YARN_OPTS=\"-Dhdp.version=$HDP_VERSION $YARN_OPTS -Djavax.net.ssl.trustStore=#{options.install['SSL_TRUSTSTORE_FILE_PATH']} -Djavax.net.ssl.trustStorePassword=#{options.install['SSL_TRUSTSTORE_PASSWORD']} \" # RYBA, DONT OVERWRITE"
            append: true
          ]

## Dependencies

    quote = require 'regexp-quote'
    path = require 'path'
    mkcmd = require '../../../lib/mkcmd'
    fs = require 'ssh2-fs'

[yarn-plugin]:(https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.4.0/bk_installing_manually_book/content/installing_ranger_plugins.html#installing_ranger_yarn_plugin)

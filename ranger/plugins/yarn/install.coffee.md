
    module.exports = header: 'Ranger YARN Plugin install', handler: (options) ->
      version = null

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'

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
         , (err, executed,stdout, stderr) ->
            return  err if err or not executed
            version = stdout.trim() if executed
        @service
          name: "ranger-yarn-plugin"

## Layout

      @system.mkdir
        target: options.install['XAAUDIT.HDFS.FILE_SPOOL_DIR']
        uid: options.yarn_user.name
        gid: options.hadoop_group.name
        mode: 0o0750
        if: options.install['XAAUDIT.HDFS.IS_ENABLED'] is 'true'
      @system.mkdir
        target: options.install['XAAUDIT.SOLR.FILE_SPOOL_DIR']
        uid: options.yarn_user.name
        gid: options.hadoop_group.name
        mode: 0o0750
        if: options.install['XAAUDIT.SOLR.IS_ENABLED'] is 'true'

## YARN Service Repository creation
Matchs step 1 in [hdfs plugin configuration][yarn-plugin]. Instead of using the web ui
we execute this task using the rest api.

      @call
        if: @contexts('ryba/hadoop/yarn_rm')[0].config.host is @config.host
        header: 'Ranger YARN Repository'
      , ->
        @system.execute
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
          header: 'Ranger YARN Principal'
          # if: options.plugins.principal
          principal: "#{options.service_repo.configs.principal}@#{options.krb5.realm}"
          password: options.service_repo.configs.password

## HDFS Audit Layout

        @system.execute
          header: 'HDFS Audit Layout'
          cmd: mkcmd.hdfs @, """
          hdfs --config #{options.conf_dir} dfs -mkdir -p /#{options.user.name}/audit/yarn
          hdfs --config #{options.conf_dir} dfs -chown -R #{options.yarn_user.name}:#{options.yarn_user.name} /#{options.user.name}/audit/yarn
          hdfs --config #{options.conf_dir} dfs -chmod 750 /#{options.user.name}/audit/yarn
          """

## Activation

      @call
        header: 'Activation'
      , ->
        @file
          header: 'Scripts Rendering'
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
        @file
          header: 'Script Fix'
          target: "/usr/hdp/#{version}/ranger-yarn-plugin/enable-yarn-plugin.sh"
          write:[
              match: RegExp "^HCOMPONENT_CONF_DIR=.*$", 'mg'
              replace: "HCOMPONENT_CONF_DIR=#{options.conf_dir}"
            ,
              match: RegExp "\\^HCOMPONENT_LIB_DIR=.*$", 'mg'
              replace: "HCOMPONENT_LIB_DIR=/usr/hdp/current/hadoop-yarn-resourcemanager/lib"
          ]
          backup: true
          mode: 0o750
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

[yarn-plugin]:(https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.4.0/bk_installing_manually_book/content/installing_ranger_plugins.html#installing_ranger_yarn_plugin)

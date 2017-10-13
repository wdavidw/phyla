
## Ranger YARN Plugin

## Configure

This modules configures every hadoop plugin needed to enable Ranger. It configures
variables but also inject some function to be executed.

    module.exports = ->
      service = migration.call @, service, 'ryba/ranger/plugins/yarn', ['ryba', 'ranger', 'yarn'], require('nikita/lib/misc').merge require('.').use,
        krb5_client: key: ['krb5_client']
        hadoop_core: key: ['ryba']
        hdfs_client: key: ['ryba', 'hdfs_client']
        yarn_rm: key: ['ryba', 'yarn', 'rm']
        ranger_admin: key: ['ryba', 'ranger', 'admin']
      @config.ryba.ranger ?= {}
      options = @config.ryba.ranger.yarn = service.options

## Plugin User

migration: wdavidw 170828, please explain its usage.It is an admin user here 
for conveniency or an internal application user to communicate with between the 
plugin and the server ?

migration: wdavidw 170828, access for the user need to be tested through a HTTP
REST request.

      service.use.ranger_admin.options.users['yarn'] ?=
        "name": 'yarn'
        "firstName": 'yarn'
        "lastName": 'hadoop'
        "emailAddress": 'yarn@hadoop.ryba'
        "password": 'yarn123'
        'userSource': 1
        'userRoleList': ['ROLE_USER']
        'groups': []
        'status': 1

## Identities

      options.group = merge {}, service.use.ranger_admin.options.group, options.group or {}
      options.user = merge {}, service.use.ranger_admin.options.user, options.user or {}
      options.yarn_user = service.use.yarn_rm.options.user
      options.hadoop_group = service.use.yarn_rm.options.hadoop_group

## Kerberos

      options.krb5 ?= {}
      options.krb5.enabled ?= service.use.hadoop_core.options.core_site['hadoop.security.authentication'] is 'kerberos'
      options.krb5.realm ?= service.use.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      # Admin Information
      options.krb5.admin = service.use.krb5_client.options.admin[options.krb5.realm]

## Access`

      options.ranger_admin ?= service.use.ranger_admin.options.admin
      # Wait for [#95](https://github.com/ryba-io/ryba/issues/95) to be answered
      # options.plugins ?= {}
      # options.plugins.principal ?= service.use.ranger_admin.options.plugins.principal
      # options.plugins.password ?= service.use.ranger_admin.options.plugins.password

## Environment

      # migration: wdavidw 1708829, where is expected the plugin to be installed ? 
      # for now only on RM but this suggest on NM as well:
      # conf_dir = if @config.ryba.yarn_plugin_is_master then yarn.rm.conf_dir else yarn.nm.conf_dir
      options.conf_dir ?= service.use.yarn_rm.options.conf_dir
      options.log_dir ?= service.use.yarn_rm.options.log_dir
      # migration: should we really need this? noone is gonna use it, isnt it?
      # log_dir = if @config.ryba.yarn_plugin_is_master
      # then @config.ryba.yarn.rm.log_dir
      # else @config.ryba.yarn.nm.log_dir

## Configuration

      options.install ?= {}
      options.install['PYTHON_COMMAND_INVOKER'] ?= 'python'

## YARN Policy Admin Tool

The repository name should match the reposity name in web ui.

      yarn_url = if service.use.yarn_rm.options.yarn_site['yarn.http.policy'] is 'HTTP_ONLY'
      then "http://#{service.use.yarn_rm.options.yarn_site["yarn.resourcemanager.webapp.http.address.#{service.use.yarn_rm.node.fqdn}"]}"
      else "https://#{service.use.yarn_rm.options.yarn_site["yarn.resourcemanager.webapp.https.address.#{service.use.yarn_rm.node.fqdn}"]}"
      options.install['POLICY_MGR_URL'] ?= service.use.ranger_admin.options.install['policymgr_external_url']
      options.install['REPOSITORY_NAME'] ?= 'hadoop-ryba-yarn'
      options.service_repo ?=
        'configs':
          'password': 'ranger_plugin_yarn'
          'username': 'RangerPluginYARN123!'
          'yarn.url': yarn_url
          'policy.download.auth.users': "#{service.use.yarn_rm.options.user.name}" #from ranger 0.6
          'tag.download.auth.users': "#{service.use.yarn_rm.options.user.name}"
        'description': 'YARN Repo'
        'isEnabled': true
        'name': options.install['REPOSITORY_NAME']
        'type': 'yarn'

## Audit to HDFS

      options.install['XAAUDIT.HDFS.IS_ENABLED'] ?= 'true'
      if options.install['XAAUDIT.HDFS.IS_ENABLED'] is 'true'
        # migration: lucasbak 11102017
        # honored but not used by plugin
        # options.install['XAAUDIT.HDFS.LOCAL_BUFFER_DIRECTORY'] ?= "#{service.use.ranger_admin.options.conf_dir}/%app-type%/audit"
        # options.install['XAAUDIT.HDFS.LOCAL_ARCHIVE_DIRECTORY'] ?= "#{service.use.ranger_admin.options.conf_dir}/%app-type%/archive"
        options.install['XAAUDIT.HDFS.ENABLE'] ?= 'true'
        options.install['XAAUDIT.HDFS.DESTINATION_DIRECTORY'] ?= "#{service.use.hdfs_client.options.core_site['fs.defaultFS']}/#{options.user.name}/audit/%app-type%/%time:yyyyMMdd%"
        options.install['XAAUDIT.HDFS.FILE_SPOOL_DIR'] ?= "#{service.use.yarn_rm.options.log_dir}/audit/hdfs/spool"
        options.install['XAAUDIT.HDFS.DESTINATION_FILE'] ?= '%hostname%-audit.log'
        options.install['XAAUDIT.HDFS.DESTINATION_FLUSH_INTERVAL_SECONDS'] ?= '900'
        options.install['XAAUDIT.HDFS.DESTINATION_ROLLOVER_INTERVAL_SECONDS'] ?= '86400'
        options.install['XAAUDIT.HDFS.DESTINATION _OPEN_RETRY_INTERVAL_SECONDS'] ?= '60'
        options.install['XAAUDIT.HDFS.LOCAL_BUFFER_FILE'] ?= '%time:yyyyMMdd-HHmm.ss%.log'
        options.install['XAAUDIT.HDFS.LOCAL_BUFFER_FLUSH_INTERVAL_SECONDS'] ?= '60'
        options.install['XAAUDIT.HDFS.LOCAL_BUFFER_ROLLOVER_INTERVAL_SECONDS'] ?= '600'
        options.install['XAAUDIT.HDFS.LOCAL_ARCHIVE _MAX_FILE_COUNT'] ?= '5'
      options.policy_hdfs_audit ?=
        'name': "yarn-ranger-plugin-audit"
        'service': "#{options.install['REPOSITORY_NAME']}"
        'repositoryType':"hdfs"
        'description': 'Kafka Ranger Plugin audit log policy'
        'isEnabled': true
        'isAuditEnabled': true
        'resources':
          'path':
            'isRecursive': 'true'
            'values': ['/ranger/audit/yarn']
            'isExcludes': false
        'policyItems': [
          'users': ["#{options.yarn_user.name}"]
          'groups': []
          'delegateAdmin': true
          'accesses': [
              "isAllowed": true
              "type": "read"
          ,
              "isAllowed": true
              "type": "write"
          ,
              "isAllowed": true
              "type": "execute"
          ]
          'conditions': []
        ]

## Audit to database storage

      #Deprecated
      options.install['XAAUDIT.DB.IS_ENABLED'] ?= 'false'
      if options.install['XAAUDIT.DB.IS_ENABLED'] is 'true'
        options.install['XAAUDIT.DB.FLAVOUR'] ?= 'MYSQL'
        switch options.install['XAAUDIT.DB.FLAVOUR']
          when 'MYSQL'
            options.install['SQL_CONNECTOR_JAR'] ?= '/usr/share/java/mysql-connector-java.jar'
            options.install['XAAUDIT.DB.HOSTNAME'] ?= service.use.ranger_admin.options.install['db_host']
            options.install['XAAUDIT.DB.DATABASE_NAME'] ?= service.use.ranger_admin.options.install['audit_db_name']
            options.install['XAAUDIT.DB.USER_NAME'] ?= service.use.ranger_admin.options.install['audit_db_user']
            options.install['XAAUDIT.DB.PASSWORD'] ?= service.use.ranger_admin.options.install['audit_db_password']
          when 'ORACLE'
            throw Error 'Ryba does not support ORACLE Based Ranger Installation'
          else
            throw Error "Apache Ranger does not support chosen DB FLAVOUR"
      else
          options.install['XAAUDIT.DB.HOSTNAME'] ?= 'NONE'
          options.install['XAAUDIT.DB.DATABASE_NAME'] ?= 'NONE'
          options.install['XAAUDIT.DB.USER_NAME'] ?= 'NONE'
          options.install['XAAUDIT.DB.PASSWORD'] ?= 'NONE'

## Audit to SOLR

      if service.use.ranger_admin.options.install['audit_store'] is 'solr'
        options.install['XAAUDIT.SOLR.IS_ENABLED'] ?= 'true'
        options.install['XAAUDIT.SOLR.ENABLE'] ?= 'true'
        options.install['XAAUDIT.SOLR.URL'] ?= service.use.ranger_admin.options.install['audit_solr_urls']
        options.install['XAAUDIT.SOLR.USER'] ?= service.use.ranger_admin.options.install['audit_solr_user']
        options.install['XAAUDIT.SOLR.ZOOKEEPER'] ?= service.use.ranger_admin.options.install['audit_solr_zookeepers']
        options.install['XAAUDIT.SOLR.PASSWORD'] ?= service.use.ranger_admin.options.install['audit_solr_password']
        options.install['XAAUDIT.SOLR.FILE_SPOOL_DIR'] ?= "#{options.log_dir}/audit/solr/spool"

## SSL

SSL can be configured to use SSL if ranger admin has SSL enabled.

      if service.use.ranger_admin.options.site['ranger.service.https.attrib.ssl.enabled'] is 'true'
        options.install['SSL_KEYSTORE_FILE_PATH'] ?= service.use.yarn_rm.options.ssl_server['ssl.server.keystore.location']
        options.install['SSL_KEYSTORE_PASSWORD'] ?= service.use.yarn_rm.options.ssl_server['ssl.server.keystore.password']
        options.install['SSL_TRUSTSTORE_FILE_PATH'] ?= service.use.yarn_rm.options.ssl_server['ssl.server.truststore.location']
        options.install['SSL_TRUSTSTORE_PASSWORD'] ?= service.use.yarn_rm.options.ssl_server['ssl.server.truststore.password']

## Merge yarn_plugin conf to ranger admin

      # migration: should we really need this? noone is gonna use it, isnt it?
      # ranger_admin_ctx.config.ryba.ranger.yarn_plugin = merge yarn_plugin

## Wait

      options.wait_ranger_admin = service.use.ranger_admin.options.wait

## Dependencies

    {merge} = require 'nikita/lib/misc'
    migration = require 'masson/lib/migration'

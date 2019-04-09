
## Ranger YARN Plugin

## Configure

This modules configures every hadoop plugin needed to enable Ranger. It configures
variables but also inject some function to be executed.

    module.exports = (service) ->
      options = service.options

## Identities

      options.group = merge service.deps.ranger_admin.options.group, options.group or {}
      options.user = merge service.deps.ranger_admin.options.user, options.user or {}
      options.yarn_user = if service.deps.yarn_rm_local then service.deps.yarn_rm_local.options.user else service.deps.yarn_nm.options.user
      options.hadoop_group = if service.deps.yarn_rm_local then service.deps.yarn_rm_local.options.hadoop_group else service.deps.yarn_nm.options.hadoop_group## Kerberos

      options.krb5 ?= {}
      options.krb5.enabled ?= service.deps.hadoop_core.options.core_site['hadoop.security.authentication'] is 'kerberos'
      options.krb5.realm ?= service.deps.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      # Admin Information
      options.krb5.admin = service.deps.krb5_client.options.admin[options.krb5.realm]
      # Kerberos HDFS Admin
      options.hdfs_krb5_user = service.deps.hadoop_core.options.hdfs.krb5_user

## Plugin User

migration: wdavidw 170828, please explain its usage.It is an admin user here
for conveniency or an internal application user to communicate with between the
plugin and the server ?

migration: wdavidw 170828, access for the user need to be tested through a HTTP
REST request.

      service.deps.ranger_admin.options.users['yarn'] ?=
        "name": 'yarn'
        "firstName": 'yarn'
        "lastName": 'hadoop'
        "emailAddress": 'yarn@hadoop.ryba'
        "password": 'yarn1234-'
        'userSource': 1
        'userRoleList': ['ROLE_USER']
        'groups': []
        'status': 1
## Kerberos

      options.krb5 ?= {}
      options.krb5.enabled ?= service.deps.hadoop_core.options.core_site['hadoop.security.authentication'] is 'kerberos'
      options.krb5.realm ?= service.deps.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      # Admin Information
      options.krb5.admin = service.deps.krb5_client.options.admin[options.krb5.realm]

## Access`

      options.ranger_admin ?= service.deps.ranger_admin.options.admin
      options.hdfs_install ?= service.deps.ranger_hdfs[0].options.install
      options.exec_repo ?= service.deps.yarn_rm[0].node.fqdn is service.node.fqdn
      # Wait for [#95](https://github.com/ryba-io/@rybajs/metal/issues/95) to be answered
      # options.plugins ?= {}
      # options.plugins.principal ?= service.deps.ranger_admin.options.plugins.principal
      # options.plugins.password ?= service.deps.ranger_admin.options.plugins.password

## Environment

      # migration: wdavidw 1708829, where is expected the plugin to be installed ?
      # for now only on RM but this suggest on NM as well:
      # conf_dir = if @config.ryba.yarn_plugin_is_master then yarn.rm.conf_dir else yarn.nm.conf_dir
      # migration: lucasbak 171010 put back ranger plugin on yarn nodemanager
      service.deps.yarn_rm_local.options.yarn_site['yarn.authorization-provider'] ?= 'org.apache.ranger.authorization.yarn.authorizer.RangerYarnAuthorizer' if service.deps.yarn_rm_local
      service.deps.yarn_nm.options.yarn_site['yarn.authorization-provider'] ?= 'org.apache.ranger.authorization.yarn.authorizer.RangerYarnAuthorizer' if service.deps.yarn_nm
      options.conf_dir ?= if service.deps.yarn_rm_local then service.deps.yarn_rm_local.options.conf_dir else service.deps.yarn_nm.options.conf_dir
      options.log_dir ?= if service.deps.yarn_rm_local then service.deps.yarn_rm_local.options.log_dir else service.deps.yarn_nm.options.conf_dir
      options.ssl_server ?= if service.deps.yarn_rm_local then service.deps.yarn_rm_local.options.ssl_server else service.deps.yarn_nm.options.ssl_server
      # migration: should we really need this? noone is gonna use it, isnt it?
      # log_dir = if @config.ryba.yarn_plugin_is_master
      # then @config.ryba.yarn.rm.log_dir
      # else @config.ryba.yarn.nm.log_dir

## Configuration

      options.install ?= {}
      options.install['PYTHON_COMMAND_INVOKER'] ?= 'python'

## YARN Policy Admin Tool

The repository name should match the reposity name in web ui.

      yarn_url = if service.deps.yarn_rm[0].options.yarn_site['yarn.http.policy'] is 'HTTP_ONLY'
      then "http://#{service.deps.yarn_rm[0].options.yarn_site["yarn.resourcemanager.webapp.http.address.#{service.deps.yarn_rm[0].node.fqdn}"]}"
      else "https://#{service.deps.yarn_rm[0].options.yarn_site["yarn.resourcemanager.webapp.https.address.#{service.deps.yarn_rm[0].node.fqdn}"]}"
      options.install['POLICY_MGR_URL'] ?= service.deps.ranger_admin.options.install['policymgr_external_url']
      options.install['REPOSITORY_NAME'] ?= 'hadoop-ryba-yarn'
      options.service_repo ?=
        'configs':
          'username': 'ranger_plugin_yarn'
          'password': 'RangerPluginYARN123!'
          'yarn.url': yarn_url
          'policy.download.auth.users': "#{options.yarn_user.name}" #from ranger 0.6
          'tag.download.auth.users': "#{options.yarn_user.name}"
        'description': 'YARN Repo'
        'isEnabled': true
        'name': options.install['REPOSITORY_NAME']
        'type': 'yarn'

## Audit to HDFS

      options.install['XAAUDIT.HDFS.IS_ENABLED'] ?= 'true'
      if options.install['XAAUDIT.HDFS.IS_ENABLED'] is 'true'
        # migration: lucasbak 11102017
        # honored but not used by plugin
        # options.install['XAAUDIT.HDFS.LOCAL_BUFFER_DIRECTORY'] ?= "#{service.deps.ranger_admin.options.conf_dir}/%app-type%/audit"
        # options.install['XAAUDIT.HDFS.LOCAL_ARCHIVE_DIRECTORY'] ?= "#{service.deps.ranger_admin.options.conf_dir}/%app-type%/archive"
        options.install['XAAUDIT.HDFS.HDFS_DIR'] ?= "#{service.deps.hdfs_client.options.core_site['fs.defaultFS']}/#{options.user.name}/audit"
        options.install['XAAUDIT.HDFS.ENABLE'] ?= 'true'
        options.install['XAAUDIT.HDFS.DESTINATION_DIRECTORY'] ?= "#{service.deps.hdfs_client.options.core_site['fs.defaultFS']}/#{options.user.name}/audit/%app-type%/%time:yyyyMMdd%"
        options.install['XAAUDIT.HDFS.FILE_SPOOL_DIR'] ?= "#{options.log_dir}/audit/hdfs/spool"
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
        'service': "#{options.hdfs_install['REPOSITORY_NAME']}"
        'repositoryType':"hdfs"
        'description': 'Yarn Ranger Plugin audit log policy'
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
            options.install['XAAUDIT.DB.HOSTNAME'] ?= service.deps.ranger_admin.options.install['db_host']
            options.install['XAAUDIT.DB.DATABASE_NAME'] ?= service.deps.ranger_admin.options.install['audit_db_name']
            options.install['XAAUDIT.DB.USER_NAME'] ?= service.deps.ranger_admin.options.install['audit_db_user']
            options.install['XAAUDIT.DB.PASSWORD'] ?= service.deps.ranger_admin.options.install['audit_db_password']
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

      if service.deps.ranger_admin.options.install['audit_store'] is 'solr'
        options.install['XAAUDIT.SOLR.IS_ENABLED'] ?= 'true'
        options.install['XAAUDIT.SOLR.ENABLE'] ?= 'true'
        options.install['XAAUDIT.SOLR.URL'] ?= service.deps.ranger_admin.options.install['audit_solr_urls']
        options.install['XAAUDIT.SOLR.USER'] ?= service.deps.ranger_admin.options.install['audit_solr_user']
        options.install['XAAUDIT.SOLR.ZOOKEEPER'] ?= service.deps.ranger_admin.options.install['audit_solr_zookeepers']
        options.install['XAAUDIT.SOLR.PASSWORD'] ?= service.deps.ranger_admin.options.install['audit_solr_password']
        options.install['XAAUDIT.SOLR.FILE_SPOOL_DIR'] ?= "#{options.log_dir}/audit/solr/spool"

## SSL

SSL can be configured to use SSL if ranger admin has SSL enabled.

      if service.deps.ranger_admin.options.site['ranger.service.https.attrib.ssl.enabled'] is 'true'
        options.install['SSL_KEYSTORE_FILE_PATH'] ?= options.ssl_server['ssl.server.keystore.location']
        options.install['SSL_KEYSTORE_PASSWORD'] ?= options.ssl_server['ssl.server.keystore.password']
        options.install['SSL_TRUSTSTORE_FILE_PATH'] ?= options.ssl_server['ssl.server.truststore.location']
        options.install['SSL_TRUSTSTORE_PASSWORD'] ?= options.ssl_server['ssl.server.truststore.password']

## Ambari Config  - YARN Plugin Audit

        options.configurations ?= {}
        options.configurations['ranger-yarn-audit'] ?= {}
        options.configurations['ranger-yarn-audit']['xasecure.audit.is.enabled'] ?= 'true'
        # audit to hdfs
        options.configurations['ranger-yarn-audit']['xasecure.audit.destination.hdfs'] ?= options.install['XAAUDIT.HDFS.IS_ENABLED']
        options.configurations['ranger-yarn-audit']['xasecure.audit.destination.hdfs.batch.filespool.dir'] ?= options.install['XAAUDIT.HDFS.FILE_SPOOL_DIR']
        options.configurations['ranger-yarn-audit']['xasecure.audit.destination.hdfs.dir'] ?= options.install['XAAUDIT.HDFS.HDFS_DIR']
        # audit to solr
        options.configurations['ranger-yarn-audit']['xasecure.audit.destination.solr'] ?= options.install['XAAUDIT.SOLR.IS_ENABLED']
        options.configurations['ranger-yarn-audit']['xasecure.audit.destination.solr.batch.filespool.dir'] ?= options.install['XAAUDIT.SOLR.FILE_SPOOL_DIR']
        options.configurations['ranger-yarn-audit']['xasecure.audit.destination.solr.zookeepers'] ?= options.install['XAAUDIT.SOLR.ZOOKEEPER']
        options.configurations['ranger-yarn-audit']['xasecure.audit.solr.solr_url'] ?= options.install['XAAUDIT.SOLR.URL']
        options.configurations['ranger-yarn-audit']['xasecure.audit.jaas.inmemory.loginModuleName'] ?= 'com.sun.security.auth.module.Krb5LoginModule'
        options.configurations['ranger-yarn-audit']['xasecure.audit.jaas.inmemory.loginModuleControlFlag'] ?= 'required'
        options.configurations['ranger-yarn-audit']['xasecure.audit.jaas.inmemory.Client.option.useKeyTab'] ?= 'true'
        options.configurations['ranger-yarn-audit']['xasecure.audit.jaas.inmemory.Client.option.debug'] ?= 'true'
        options.configurations['ranger-yarn-audit']['xasecure.audit.jaas.inmemory.Client.option.doNotPrompt'] ?= 'yes'
        options.configurations['ranger-yarn-audit']['xasecure.audit.jaas.inmemory.Client.option.storeKey'] ?= 'yes'
        options.configurations['ranger-yarn-audit']['xasecure.audit.jaas.inmemory.Client.option.serviceName'] ?= 'solr'
        options.configurations['ranger-yarn-audit']['xasecure.audit.jaas.inmemory.Client.option.keyTab'] ?= service.deps.yarn_rm[0].options.yarn_site['yarn.resourcemanager.keytab']
        options.configurations['ranger-yarn-audit']['xasecure.audit.jaas.inmemory.Client.option.principal'] ?= service.deps.yarn_rm[0].options.yarn_site['yarn.resourcemanager.principal']

## Ambari Config - YARN Plugin SSL
SSL can be configured to use SSL if ranger admin has SSL enabled.

        options.configurations['ranger-yarn-policymgr-ssl'] ?= {}
        if service.deps.ranger_admin.options.site['ranger.service.https.attrib.ssl.enabled'] is 'true'
          options.configurations['ranger-yarn-policymgr-ssl']['xasecure.policymgr.clientssl.keystore'] ?= options.ssl_server['ssl.server.keystore.location']
          options.configurations['ranger-yarn-policymgr-ssl']['xasecure.policymgr.clientssl.keystore.password'] ?= options.ssl_server['ssl.server.keystore.password']
          options.configurations['ranger-yarn-policymgr-ssl']['xasecure.policymgr.clientssl.truststore'] ?= options.ssl_server['ssl.server.truststore.location']
          options.configurations['ranger-yarn-policymgr-ssl']['xasecure.policymgr.clientssl.truststore.password'] ?= options.ssl_server['ssl.server.truststore.password']
          options.configurations['ranger-yarn-policymgr-ssl']['xasecure.policymgr.clientssl.keystore.credential.file'] ?= "jceks://file/etc/ranger/#{options.service_repo.name}/cred.jceks"
          options.configurations['ranger-yarn-policymgr-ssl']['xasecure.policymgr.clientssl.truststore.credential.file'] ?=  "jceks://file/etc/ranger/#{options.service_repo.name}/cred.jceks"

## Ambari Config - YARN Plugin Properties

        options.configurations['ranger-yarn-plugin-properties'] ?= {}
        options.configurations['ranger-yarn-plugin-properties']['ranger-yarn-plugin-enabled'] ?= 'Yes' 
        options.configurations['ranger-yarn-plugin-properties']['REPOSITORY_CONFIG_USERNAME'] ?= options.service_repo.configs.username
        options.configurations['ranger-yarn-plugin-properties']['REPOSITORY_CONFIG_PASSWORD'] ?= options.service_repo.configs.password
        options.configurations['ranger-yarn-plugin-properties']['common.name.for.certificate'] ?= options.service_repo.configs['commonNameForCertificate']
        options.configurations['ranger-yarn-plugin-properties']['hadoop.rpc.protection'] ?= options.service_repo.configs['hadoop.rpc.protection']
        options.configurations['ranger-yarn-plugin-properties']['policy_user'] ?= options.service_repo.configs['policy.download.auth.users']
        for k, v of options.install
          if k.indexOf('XAAUDIT') isnt -1
            options.configurations['ranger-yarn-plugin-properties'][k] ?= v

## Ambari Config - YARN Plugin Security

        options.configurations['ranger-yarn-security'] ?= {}
        options.configurations['ranger-yarn-security']['ranger.plugin.yarn.service.name'] ?= options.service_repo.name
        options.configurations['ranger-yarn-security']['ranger.plugin.yarn.policy.rest.url'] ?= options.install['POLICY_MGR_URL']
        options.configurations['ranger-yarn-security']['ranger.plugin.yarn.policy.cache.dir'] ?= "/etc/ranger/#{options.service_repo.name}/policycache"
        options.configurations['ranger-yarn-security']['ranger.plugin.yarn.policy.pollIntervalMs'] ?= "30000"
        options.configurations['ranger-yarn-security']['ranger.plugin.yarn.policy.rest.ssl.config.file'] ?= "#{options.conf_dir}/ranger-policymgr-ssl.xml"
        options.configurations['ranger-yarn-security']['ranger.plugin.yarn.policy.source.impl'] ?= 'org.apache.ranger.admin.client.RangerAdminRESTClient'
        options.configurations['ranger-yarn-security']['xasecure.add-hadoop-authorization'] ?= 'true'

## Wait

      options.wait_ranger_admin = service.deps.ranger_admin.options.wait

## Dependencies

    {merge} = require 'mixme'

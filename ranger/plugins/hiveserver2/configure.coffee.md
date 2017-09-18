
# Ranger HIVE Plugin Configure

Ranger Hive plugin runs inside Hiveserver2's JVM

    module.exports = ->
      service = migration.call @, service, 'ryba/ranger/plugins/hive', ['ryba', 'ranger', 'hive'], require('nikita/lib/misc').merge require('.').use,
        krb5_client: key: ['krb5_client']
        java: key: ['java']
        hadoop_core: key: ['ryba']
        hive_hcatalog: key: ['ryba', 'hive', 'hcatalog']
        hive_server2: key: ['ryba', 'hive', 'server2']
        ranger_admin: key: ['ryba', 'ranger', 'admin']
        ranger_hdfs: key: ['ryba', 'ranger', 'hdfs']
        ranger_hive: key: ['ryba', 'ranger', 'hive']
      @config.ryba.ranger ?= {}
      options = @config.ryba.ranger.hive = service.options

## Kerberos

      options.krb5 ?= {}
      options.krb5.enabled ?= service.use.hadoop_core.options.core_site['hadoop.security.authentication'] is 'kerberos'
      options.krb5.realm ?= service.use.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      # Admin Information
      options.krb5.admin = service.use.krb5_client.options.admin[options.krb5.realm]

## Identities

      options.group = merge {}, service.use.ranger_admin.options.group, options.group or {}
      options.user = merge {}, service.use.ranger_admin.options.user, options.user or {}
      options.hive_user = service.use.hive_server2.options.user
      options.hive_group = service.use.hive_server2.options.group

## Access

      options.ranger_admin ?= service.use.ranger_admin.options.admin
      options.hdfs_install ?= service.use.ranger_hdfs.options.install

## Plugin User

      options.plugin_user =
        "name": options.hive_user.name
        "firstName": ''
        "lastName": ''
        "emailAddress": ''
        'userSource': 1
        'userRoleList': ['ROLE_USER']
        'groups': []
        'status': 1

## Environment

      # Layout
      options.conf_dir ?= service.use.hive_server2.options.conf_dir

## Configuration

      options.install ?= {}
      options.install['PYTHON_COMMAND_INVOKER'] ?= 'python'
      # Should Hive GRANT/REVOKE update XA policies?
      options.install['UPDATE_XAPOLICIES_ON_GRANT_REVOKE'] ?= 'true'
      options.install['CUSTOM_USER'] ?= "#{options.user.name}"
      options.install['CUSTOM_GROUP'] ?= "#{options.group.name}"

## SSL

Used only if SSL is enabled between Policy Admin Tool and Plugin. The path to
keystore is derived from Hive Server2. The path to the truststore is derived
from Hadoop Core.
    
      if service.use.ranger_admin.options.site['ranger.service.https.attrib.ssl.enabled'] is 'true'
        options.install['SSL_KEYSTORE_FILE_PATH'] ?= service.use.hive_server2.options.hive_site['hive.server2.keystore.path']
        options.install['SSL_KEYSTORE_PASSWORD'] ?= service.use.hive_server2.options.hive_site['hive.server2.keystore.password']
        options.install['SSL_TRUSTSTORE_FILE_PATH'] ?= service.use.hadoop_core.options.ssl_client['ssl.client.truststore.location']
        options.install['SSL_TRUSTSTORE_PASSWORD'] ?= service.use.hadoop_core.options.ssl_client['ssl.client.truststore.password']

##Policy Admin Tool

The repository name should match the reposity name in web ui.

      # Build Hive Server2 URL
      
      port = if service.use.hive_server2.options.hive_site['hive.server2.transport.mode'] is 'http'
      then service.use.hive_server2.options.hive_site['hive.server2.thrift.http.port']
      else service.use.hive_server2.options.hive_site['hive.server2.thrift.port']
      httpPath = service.use.hive_server2.options.hive_site['hive.server2.thrift.http.path']
      hive_url = 'jdbc:hive2://'
      hive_url += "#{service.node.fqdn}:#{port}/"
      if service.use.hive_server2.options.hive_site['hive.server2.authentication'] is 'KERBEROS'
        hive_url += ";principal=#{service.use.hive_server2.options.hive_site['hive.server2.authentication.kerberos.principal']}"
      if service.use.hive_server2.options.hive_site['hive.server2.use.SSL'] is 'true'
        hive_url += ";ssl=true"
        hive_url += ";sslTrustStore=#{service.use.hadoop_core.options.ssl_client['ssl.client.truststore.location']}"
        hive_url += ";trustStorePassword=#{service.use.hadoop_core.options.ssl_client['ssl.client.truststore.password']}"
      if service.use.hive_server2.options.hive_site['hive.server2.transport.mode'] is 'http'
        hive_url += ";transportMode=#{service.use.hive_server2.options.hive_site['hive.server2.transport.mode']}"
        hive_url += ";httpPath=#{httpPath}"

## Admin properties

      options.install['POLICY_MGR_URL'] ?= service.use.ranger_admin.options.install['policymgr_external_url']
      options.install['REPOSITORY_NAME'] ?= 'hadoop-ryba-hive'

## Service Definition

      options.service_repo ?=
        'name': options.install['REPOSITORY_NAME']
        'description': 'Hive Repo'
        'type': 'hive'
        'isEnabled': true
        'configs':
          # 'username': 'ranger_plugin_hbase'
          # 'password': 'RangerPluginHive123!'
          'username': service.use.ranger_admin.options.plugins.principal
          'password': service.use.ranger_admin.options.plugins.password
          'jdbc.driverClassName': 'org.apache.hive.jdbc.HiveDriver'
          'jdbc.url': "#{hive_url}"
          "commonNameForCertificate": ''
          'policy.download.auth.users': "#{service.use.hive_server2.options.user.name}" #from ranger 0.6
          'tag.download.auth.users': "#{service.use.hive_server2.options.user.name}"

## Audit

### HDFS storage

      # options.install['XAAUDIT.HDFS.ENABLE'] ?= 'true'
      # options.install['XAAUDIT.HDFS.HDFS_DIR'] ?= "#{service.use.hadoop_core.options.core_site['fs.defaultFS']}/#{options.user.name}/audit"
      # options.install['XAAUDIT.HDFS.FILE_SPOO
      options.install['XAAUDIT.HDFS.IS_ENABLED'] ?= 'true'
      if options.install['XAAUDIT.HDFS.IS_ENABLED'] is 'true'
        options.install['XAAUDIT.HDFS.DESTINATION_DIRECTORY'] ?= "#{service.use.hadoop_core.options.core_site['fs.defaultFS']}/#{options.user.name}/audit/%app-type%/%time:yyyyMMdd%"
        options.install['XAAUDIT.HDFS.LOCAL_BUFFER_DIRECTORY'] ?= '/var/log/ranger/%app-type%/audit'
        options.install['XAAUDIT.HDFS.LOCAL_ARCHIVE_DIRECTORY'] ?= '/var/log/ranger/%app-type%/archive'
        options.install['XAAUDIT.HDFS.DESTINATION_FILE'] ?= '%hostname%-audit.log'
        options.install['XAAUDIT.HDFS.DESTINATION_FLUSH_INTERVAL_SECONDS'] ?= '900'
        options.install['XAAUDIT.HDFS.DESTINATION_ROLLOVER_INTERVAL_SECONDS'] ?= '86400'
        options.install['XAAUDIT.HDFS.DESTINATION _OPEN_RETRY_INTERVAL_SECONDS'] ?= '60'
        options.install['XAAUDIT.HDFS.LOCAL_BUFFER_FILE'] ?= '%time:yyyyMMdd-HHmm.ss%.log'
        options.install['XAAUDIT.HDFS.LOCAL_BUFFER_FLUSH_INTERVAL_SECONDS'] ?= '60'
        options.install['XAAUDIT.HDFS.LOCAL_BUFFER_ROLLOVER_INTERVAL_SECONDS'] ?= '600'
        options.install['XAAUDIT.HDFS.LOCAL_ARCHIVE _MAX_FILE_COUNT'] ?= '5'

## HDFS Policy

      if options.install['XAAUDIT.HDFS.IS_ENABLED'] is 'true'
        options.policy_hdfs_audit ?=
          'name': "hive-ranger-plugin-audit"
          'service': "#{options.hdfs_install['REPOSITORY_NAME']}"
          'repositoryType':"hdfs"
          'description': 'Hive Ranger Plugin audit log policy'
          'isEnabled': true
          'isAuditEnabled': true
          'resources':
            'path':
              'isRecursive': 'true'
              'values': ['/ranger/audit/hiveServer2']
              'isExcludes': false
          'policyItems': [
            'users': ["#{options.hive_user.name}"]
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

### Solr storage

      if service.use.ranger_admin.options.install['audit_store'] is 'solr'
        options.audit ?= {}
        options.install['XAAUDIT.SOLR.IS_ENABLED'] ?= 'true'
        options.install['XAAUDIT.SOLR.ENABLE'] ?= 'true'
        options.install['XAAUDIT.SOLR.URL'] ?= service.use.ranger_admin.options.install['audit_solr_urls']
        options.install['XAAUDIT.SOLR.USER'] ?= service.use.ranger_admin.options.install['audit_solr_user']
        options.install['XAAUDIT.SOLR.ZOOKEEPER'] ?= service.use.ranger_admin.options.install['audit_solr_zookeepers']
        options.install['XAAUDIT.SOLR.PASSWORD'] ?= service.use.ranger_admin.options.install['audit_solr_password']
        options.install['XAAUDIT.SOLR.FILE_SPOOL_DIR'] ?= "#{service.use.hive_server2.options.log_dir}/audit/solr/spool"
        options.audit['xasecure.audit.destination.solr.force.use.inmemory.jaas.config'] ?= 'true'
        options.audit['xasecure.audit.jaas.inmemory.loginModuleName'] ?= 'com.sun.security.auth.module.Krb5LoginModule'
        options.audit['xasecure.audit.jaas.inmemory.loginModuleControlFlag'] ?= 'required'
        options.audit['xasecure.audit.jaas.inmemory.Client.option.useKeyTab'] ?= 'true'
        options.audit['xasecure.audit.jaas.inmemory.Client.option.debug'] ?= 'true'
        options.audit['xasecure.audit.jaas.inmemory.Client.option.doNotPrompt'] ?= 'yes'
        options.audit['xasecure.audit.jaas.inmemory.Client.option.storeKey'] ?= 'yes'
        options.audit['xasecure.audit.jaas.inmemory.Client.option.serviceName'] ?= 'solr'
        options.audit['xasecure.audit.jaas.inmemory.Client.option.principal'] = service.use.hive_server2.options.hive_site['hive.server2.authentication.kerberos.principal'].replace '_HOST', service.node.fqdn
        options.audit['xasecure.audit.jaas.inmemory.Client.option.keyTab'] ?= service.use.hive_server2.options.hive_site['hive.server2.authentication.kerberos.keytab']

### Database storage

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

## Wait

      options.wait_ranger_admin = service.use.ranger_admin.options.wait

## Enrich configuration

      # Hive HCatalog
      for srv in service.use.hive_hcatalog
        srv.options.warehouse_mode = '0000'
      # Hive Server2
      service.use.hive_server2.options.hive_site['hive.security.authorization.manager'] = 'org.apache.ranger.authorization.hive.authorizer.RangerHiveAuthorizerFactory'
      service.use.hive_server2.options.hive_site['hive.security.authenticator.manager'] = 'org.apache.hadoop.hive.ql.security.SessionStateUserAuthenticator'
      service.use.hive_server2.options.opts ?= ''
      service.use.hive_server2.options.opts += " -Djavax.net.ssl.trustStore=#{service.use.hadoop_core.options.ssl_client['ssl.client.truststore.location']} "
      service.use.hive_server2.options.opts += " -Djavax.net.ssl.trustStorePassword=#{service.use.hadoop_core.options.ssl_client['ssl.client.truststore.password']}"

## Dependencies

    {merge} = require 'nikita/lib/misc'
    migration = require 'masson/lib/migration'


# Ranger Atlas Plugin Configure
Ranger Atlas plugin runs inside Atlas Metadata server's JVM


    module.exports = ->
      service = migration.call @, service, 'ryba/ranger/plugins/atlas', ['ryba', 'ranger', 'atlas'], require('nikita/lib/misc').merge require('.').use,
        krb5_client: key: ['krb5_client']
        java: key: ['java']
        hadoop_core: key: ['ryba']
        # hdfs_client: key: ['ryba', 'hdfs_client']
        atlas: key: ['ryba', 'atlas']
        ranger_admin: key: ['ryba', 'ranger', 'admin']
        ranger_hdfs: key: ['ryba', 'ranger', 'hdfs']
      @config.ryba.ranger ?= {}
      options = @config.ryba.ranger.atlas = service.options

## Kerberos

      options.krb5 ?= {}
      options.krb5.enabled ?= service.use.hadoop_core.options.core_site['hadoop.security.authentication'] is 'kerberos'
      options.krb5.realm ?= service.use.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      # Admin Information
      options.krb5.admin = service.use.krb5_client.options.admin[options.krb5.realm]

      [ranger_admin_ctx] = @contexts 'ryba/ranger/admin'

      {ryba} = @config
      {realm, ssl, core_site, hdfs, hadoop_group, hadoop_conf_dir} = ryba
      ranger = ranger_admin_ctx.config.ryba.ranger.admin ?= {}

## Identities

      options.group = merge {}, service.use.ranger_admin.options.group, options.group or {}
      options.user = merge {}, service.use.ranger_admin.options.user, options.user or {}

## Access

      options.ranger_admin ?= service.use.ranger_admin.options.admin
      options.hdfs_install ?= service.use.ranger_hdfs.options.install
      options.atlas_user = service.use.atlas.options.user
      options.atlas_group = service.use.atlas.options.group
      options.hdfs_krb5_user = service.use.hadoop_core.options.hdfs.krb5_user

## Plugin User

      options.plugin_user = 
        "name": options.atlas_user.name
        "firstName": ''
        "lastName": ''
        "emailAddress": ''
        "password": ''
        'userSource': 1
        'userRoleList': ['ROLE_USER']
        'groups': []
        'status': 1
        
## Configuration

      options.install ?= {}
      options.install['PYTHON_COMMAND_INVOKER'] ?= 'python'
      # Should Atlas GRANT/REVOKE update XA policies?
      options.install['UPDATE_XAPOLICIES_ON_GRANT_REVOKE'] ?= 'true'
      options.install['CUSTOM_USER'] ?= "#{@config.ryba.atlas.user.name}"
      options.install['CUSTOM_GROUP'] ?= "#{hadoop_group.name}"

## Admin properties

      options.install['POLICY_MGR_URL'] ?= service.use.ranger_admin.options.install['policymgr_external_url']
      options.install['REPOSITORY_NAME'] ?= 'hadoop-ryba-atlas'

## Service Definition

      options.service_repo ?=
        'name': options.install['REPOSITORY_NAME']
        'description': 'Atlas Repo'
        'type': 'atlas'
        'isEnabled': true
        'configs':
          # 'username': 'ranger_plugin_atlas'
          # 'password': 'RangerPluginAtlas123!'
          'username': service.use.ranger_admin.options.plugins.principal
          'password': service.use.ranger_admin.options.plugins.password
          'atlas.rest.address': @config.ryba.atlas.application.properties['atlas.rest.address']
          'policy.download.auth.users': "#{@config.ryba.atlas.user.name}" #from ranger 0.6
          'tag.download.auth.users': "#{@config.ryba.atlas.user.name}"

### Atlas Plugin audit

      options.install['XAAUDIT.HDFS.IS_ENABLED'] ?= 'true'
      if options.install['XAAUDIT.HDFS.IS_ENABLED'] is 'true'
        options.install['XAAUDIT.HDFS.DESTINATION_DIRECTORY'] ?= "#{core_site['fs.defaultFS']}/#{options.user.name}/audit/%app-type%/%time:yyyyMMdd%"
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
        # AUDIT TO HDFS
        # atlas_plugin.install['XAAUDIT.HDFS.ENABLE'] ?= 'true'
        # atlas_plugin.install['XAAUDIT.HDFS.HDFS_DIR'] ?= "#{core_site['fs.defaultFS']}/#{ranger.user.name}/audit"
        # atlas_plugin.install['XAAUDIT.HDFS.FILE_SPOOL_DIR'] ?= "#{@config.ryba.atlas.log_dir}/audit/hdfs/spool"

## HDFS Policy

      if options.install['XAAUDIT.HDFS.IS_ENABLED'] is 'true'
        throw Error 'HDFS Ranger Plugin required' unless options.hdfs_install
        options.policy_hdfs_audit ?=
          'name': "atlas-ranger-plugin-audit"
          'service': "#{options.hdfs_install['REPOSITORY_NAME']}"
          'repositoryType':"hdfs"
          'description': 'Atlas Ranger Plugin audit log policy'
          'isEnabled': true
          'isAuditEnabled': true
          'resources':
            'path':
              'isRecursive': 'true'
              'values': ['/ranger/audit/atlas']
              'isExcludes': false
          'policyItems': [
            'users': ["#{options.atlas_user.name}"]
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
        

### Atlas Audit (HDFS Storage)

      # AUDIT TO HDFS
      options.install['XAAUDIT.HDFS.ENABLE'] ?= 'true'
      options.install['XAAUDIT.HDFS.HDFS_DIR'] ?= "#{core_site['fs.defaultFS']}/#{options.user.name}/audit"
      options.install['XAAUDIT.HDFS.FILE_SPOOL_DIR'] ?= "#{service.use.atlas.options.log_dir}/audit/hdfs/spool"

### Atlas Audit (database storage)

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

### Atlas Audit (to SOLR)

      if service.use.ranger_admin.options.install['audit_store'] is 'solr'
        options.audit ?= {}
        options.install['XAAUDIT.SOLR.IS_ENABLED'] ?= 'true'
        options.install['XAAUDIT.SOLR.ENABLE'] ?= 'true'
        options.install['XAAUDIT.SOLR.URL'] ?= service.use.ranger_admin.options.install['audit_solr_urls']
        options.install['XAAUDIT.SOLR.USER'] ?= service.use.ranger_admin.options.install['audit_solr_user']
        options.install['XAAUDIT.SOLR.ZOOKEEPER'] ?= service.use.ranger_admin.options.install['audit_solr_zookeepers']
        options.install['XAAUDIT.SOLR.PASSWORD'] ?= service.use.ranger_admin.options.install['audit_solr_password']
        options.install['XAAUDIT.SOLR.FILE_SPOOL_DIR'] ?= "#{service.use.atlas.options.log_dir}/audit/solr/spool"
        options.audit['xasecure.audit.destination.solr.force.use.inmemory.jaas.config'] ?= 'true'
        options.audit['xasecure.audit.jaas.inmemory.loginModuleName'] ?= 'com.sun.security.auth.module.Krb5LoginModule'
        options.audit['xasecure.audit.jaas.inmemory.loginModuleControlFlag'] ?= 'required'
        options.audit['xasecure.audit.jaas.inmemory.Client.option.useKeyTab'] ?= 'true'
        options.audit['xasecure.audit.jaas.inmemory.Client.option.debug'] ?= 'true'
        options.audit['xasecure.audit.jaas.inmemory.Client.option.doNotPrompt'] ?= 'yes'
        options.audit['xasecure.audit.jaas.inmemory.Client.option.storeKey'] ?= 'yes'
        options.audit['xasecure.audit.jaas.inmemory.Client.option.serviceName'] ?= 'solr'
        atlas_princ = @config.ryba.atlas.application.properties['atlas.authentication.principal'].replace '_HOST', service.use.atlas.node.fqdn
        options.audit['xasecure.audit.jaas.inmemory.Client.option.principal'] ?= atlas_princ
        options.audit['xasecure.audit.jaas.inmemory.Client.option.keyTab'] ?= service.use.atlas.options.application.properties['atlas.authentication.keytab']

### Plugin Execution

Used only if SSL is enabled between Policy Admin Tool and Plugin

      if service.use.ranger_admin.options.site['ranger.service.https.attrib.ssl.enabled'] is 'true'
        options.ssl = merge {}, service.use.hadoop_core.options.ssl, options.ssl
        options.install['SSL_KEYSTORE_FILE_PATH'] ?= service.use.hadoop_core.options.ssl_server['ssl.server.keystore.location']
        options.install['SSL_KEYSTORE_PASSWORD'] ?= service.use.hadoop_core.options.ssl_server['ssl.server.keystore.password']
        options.install['SSL_TRUSTSTORE_FILE_PATH'] ?= service.use.hadoop_core.options.ssl_server['ssl.server.truststore.location']
        options.install['SSL_TRUSTSTORE_PASSWORD'] ?= service.use.hadoop_core.options.ssl_server['ssl.server.truststore.password']

## Wait

      options.wait_ranger_admin = service.use.ranger_admin.options.wait

## Dependencies

    {merge} = require 'nikita/lib/misc'
    migration = require 'masson/lib/migration'

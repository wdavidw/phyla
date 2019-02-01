
# Ranger HDFS Plugin Configure

For the HDFS plugin, the executed script already create the hdfs user to ranger admin
as external.

    module.exports = (service) ->
      options = service.options

## Identities

      options.group = merge {}, service.deps.ranger_admin.options.group, options.group or {}
      options.user = merge {}, service.deps.ranger_admin.options.user, options.user or {}
      options.hdfs_user = service.deps.hdfs_nn.options.user
      options.hdfs_group = service.deps.hdfs_nn.options.group
      options.hadoop_group = service.deps.hdfs_nn.options.hadoop_group

## Environment

      service.deps.hdfs_nn.options.hdfs_site['dfs.namenode.inode.attributes.provider.class'] ?= 'org.apache.ranger.authorization.hadoop.RangerHdfsAuthorizer'
      options.hdfs_conf_dir = service.deps.hdfs_nn.options.conf_dir

## Kerberos

      options.krb5 ?= {}
      options.krb5.enabled ?= service.deps.hadoop_core.options.core_site['hadoop.security.authentication'] is 'kerberos'
      options.krb5.realm ?= service.deps.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      # Admin Information
      options.krb5.admin = service.deps.krb5_client.options.admin[options.krb5.realm]

## Access

      options.ranger_admin ?= service.deps.ranger_admin.options.admin
      # Wait for [#95](https://github.com/ryba-io/ryba/issues/95) to be answered
      # options.plugins ?= {}
      # options.plugins.principal ?= service.deps.ranger_admin.options.plugins.principal
      # options.plugins.password ?= service.deps.ranger_admin.options.plugins.password

## Setup

Repository creating is only executed from one NameNode.

      options.repo_create = service.deps.hdfs_nn.options.active_nn_host is service.node.fqdn

## Configuration

      options.install ?= {}
      options.install['PYTHON_COMMAND_INVOKER'] ?= 'python'

## Admin properties

      options.install['POLICY_MGR_URL'] ?= service.deps.ranger_admin.options.install['policymgr_external_url']
      options.install['REPOSITORY_NAME'] ?= 'hadoop-ryba-hdfs'

## Plugin User

      options.plugin_user =
        "name": options.hdfs_user.name
        "firstName": ''
        "lastName": ''
        "emailAddress": ''
        "password": 'hdfs1234-'
        'userSource': 1
        'userRoleList': ['ROLE_USER']
        'groups': []
        'status': 1

## Service Definition

      options.service_repo ?=
        'name': options.install['REPOSITORY_NAME']
        'description': 'HDFS Repo'
        'type': 'hdfs'
        'isEnabled': true
        'configs':
          # 'username': 'ranger_plugin_hdfs'
          # 'password': 'RangerPluginHDFS123!'
          'username': service.deps.ranger_admin.options.plugins.principal
          'password': service.deps.ranger_admin.options.plugins.password
          'fs.default.name': service.deps.hdfs_nn.options.core_site['fs.defaultFS']
          'hadoop.security.authentication': service.deps.hdfs_nn.options.core_site['hadoop.security.authentication']
          'dfs.namenode.kerberos.principal': service.deps.hdfs_nn.options.hdfs_site['dfs.namenode.kerberos.principal']
          'dfs.datanode.kerberos.principal': service.deps.hdfs_dn[0].options.hdfs_site['dfs.datanode.kerberos.principal']
          'hadoop.rpc.protection': service.deps.hdfs_nn.options.core_site['hadoop.rpc.protection']
          'hadoop.security.authorization': service.deps.hdfs_nn.options.core_site['hadoop.security.authorization']
          'hadoop.security.auth_to_local': service.deps.hdfs_nn.options.core_site['hadoop.security.auth_to_local']
          'commonNameForCertificate': ''
          'policy.download.auth.users': "#{service.deps.hdfs_nn.options.user.name}" #from ranger 0.6
          'tag.download.auth.users': "#{service.deps.hdfs_nn.options.user.name}"

## SSL

      if service.deps.ranger_admin.options.site['ranger.service.https.attrib.ssl.enabled'] is 'true'
        options.install['SSL_KEYSTORE_FILE_PATH'] ?= service.deps.hdfs_nn.options.ssl_server['ssl.server.keystore.location']
        options.install['SSL_KEYSTORE_PASSWORD'] ?= service.deps.hdfs_nn.options.ssl_server['ssl.server.keystore.password']
        options.install['SSL_TRUSTSTORE_FILE_PATH'] ?= service.deps.hdfs_nn.options.ssl_server['ssl.server.truststore.location']
        options.install['SSL_TRUSTSTORE_PASSWORD'] ?= service.deps.hdfs_nn.options.ssl_server['ssl.server.truststore.password']

## Audit Storage

      options.audit ?= {}

### Database Storage

      #Deprecated
      options.install['XAAUDIT.DB.IS_ENABLED'] ?= 'false'
      options.install['SQL_CONNECTOR_JAR'] ?= '/usr/share/java/mysql-connector-java.jar'
      if options.install['XAAUDIT.DB.IS_ENABLED'] is 'true'
        options.install['XAAUDIT.DB.FLAVOUR'] ?= 'MYSQL'
        switch options.install['XAAUDIT.DB.FLAVOUR']
          when 'MYSQL'
            options.install['XAAUDIT.DB.HOSTNAME'] ?= service.deps.ranger_admin.options.install['db_host']
            options.install['XAAUDIT.DB.DATABASE_NAME'] ?= service.deps.ranger_admin.options.install['audit_db_name']
            options.install['XAAUDIT.DB.USER_NAME'] ?= service.deps.ranger_admin.options.install['audit_db_user']
            options.install['XAAUDIT.DB.PASSWORD'] ?= service.deps.ranger_admin.options.install['audit_db_password']
          when 'ORACLE'
            throw Error 'Ryba does not support ORACLE Based Ranger Installation'
          else
            throw Error "Apache Ranger does not support chosen DB FLAVOUR"
      else
          # This properties are needed even if they are not user
          # We set it to NONE to let the script execute
          options.install['XAAUDIT.DB.HOSTNAME'] ?= 'NONE'
          options.install['XAAUDIT.DB.DATABASE_NAME'] ?= 'NONE'
          options.install['XAAUDIT.DB.USER_NAME'] ?= 'NONE'
          options.install['XAAUDIT.DB.PASSWORD'] ?= 'NONE'

### HDFS Storage

      options.install['XAAUDIT.HDFS.IS_ENABLED'] ?= 'true'
      if options.install['XAAUDIT.HDFS.IS_ENABLED'] is 'true'
        # migration: lucasbak 11102017
        # honored but not used by plugin
        # options.install['XAAUDIT.HDFS.LOCAL_BUFFER_DIRECTORY'] ?= "#{service.deps.ranger_admin.options.conf_dir}/%app-type%/audit"
        # options.install['XAAUDIT.HDFS.LOCAL_ARCHIVE_DIRECTORY'] ?= "#{service.deps.ranger_admin.options.conf_dir}/%app-type%/archive"
        options.install['XAAUDIT.HDFS.ENABLE'] ?= 'true'
        options.install['XAAUDIT.HDFS.DESTINATION_DIRECTORY'] ?= "#{service.deps.hdfs_nn.options.core_site['fs.defaultFS']}/#{service.deps.ranger_admin.options.user.name}/audit/%app-type%/%time:yyyyMMdd%"
        options.install['XAAUDIT.HDFS.HDFS_DIR'] ?= "#{service.deps.hdfs_nn.options.core_site['fs.defaultFS']}/#{service.deps.ranger_admin.options.user.name}/audit"
        options.install['XAAUDIT.HDFS.FILE_SPOOL_DIR'] ?= "#{service.deps.hdfs_nn.options.log_dir}/audit/hdfs/spool"
        options.install['XAAUDIT.HDFS.DESTINATION_FILE'] ?= '%hostname%-audit.log'
        options.install['XAAUDIT.HDFS.DESTINATION_FLUSH_INTERVAL_SECONDS'] ?= '900'
        options.install['XAAUDIT.HDFS.DESTINATION_ROLLOVER_INTERVAL_SECONDS'] ?= '86400'
        options.install['XAAUDIT.HDFS.DESTINATION _OPEN_RETRY_INTERVAL_SECONDS'] ?= '60'
        options.install['XAAUDIT.HDFS.LOCAL_BUFFER_FILE'] ?= '%time:yyyyMMdd-HHmm.ss%.log'
        options.install['XAAUDIT.HDFS.LOCAL_BUFFER_FLUSH_INTERVAL_SECONDS'] ?= '60'
        options.install['XAAUDIT.HDFS.LOCAL_BUFFER_ROLLOVER_INTERVAL_SECONDS'] ?= '600'
        options.install['XAAUDIT.HDFS.LOCAL_ARCHIVE _MAX_FILE_COUNT'] ?= '5'
        options.policy_hdfs_audit ?=
          'name': "hdfs-ranger-plugin-audit"
          'service': "#{options.install['REPOSITORY_NAME']}"
          'repositoryType':"hdfs"
          'description': 'HDFS Ranger Plugin audit log policy'
          'isEnabled': true
          'isAuditEnabled': true
          'resources':
            'path':
              'isRecursive': 'true'
              'values': [options.install['XAAUDIT.HDFS.HDFS_DIR']]
              'isExcludes': false
          'policyItems': [
            'users': ["#{options.hdfs_user.name}"]
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

### Solr Storage

      if service.deps.ranger_admin.options.install['audit_store'] is 'solr'
        options.install['XAAUDIT.SOLR.IS_ENABLED'] ?= 'true'
        options.install['XAAUDIT.SOLR.ENABLE'] ?= 'true'
        options.install['XAAUDIT.SOLR.URL'] ?= service.deps.ranger_admin.options.install['audit_solr_urls']
        options.install['XAAUDIT.SOLR.USER'] ?= service.deps.ranger_admin.options.install['audit_solr_user']
        options.install['XAAUDIT.SOLR.ZOOKEEPER'] ?= service.deps.ranger_admin.options.install['audit_solr_zookeepers']
        options.install['XAAUDIT.SOLR.PASSWORD'] ?= service.deps.ranger_admin.options.install['audit_solr_password']
        options.install['XAAUDIT.SOLR.FILE_SPOOL_DIR'] ?= "#{service.deps.hdfs_nn.options.log_dir}/audit/solr/spool"
        options.audit['xasecure.audit.destination.solr.force.use.inmemory.jaas.config'] ?= 'true'
        options.audit['xasecure.audit.jaas.inmemory.loginModuleName'] ?= 'com.sun.security.auth.module.Krb5LoginModule'
        options.audit['xasecure.audit.jaas.inmemory.loginModuleControlFlag'] ?= 'required'
        options.audit['xasecure.audit.jaas.inmemory.Client.option.useKeyTab'] ?= 'true'
        options.audit['xasecure.audit.jaas.inmemory.Client.option.debug'] ?= 'true'
        options.audit['xasecure.audit.jaas.inmemory.Client.option.doNotPrompt'] ?= 'yes'
        options.audit['xasecure.audit.jaas.inmemory.Client.option.storeKey'] ?= 'yes'
        options.audit['xasecure.audit.jaas.inmemory.Client.option.serviceName'] ?= 'solr'
        options.audit['xasecure.audit.jaas.inmemory.Client.option.keyTab'] ?= service.deps.hdfs_nn.options.hdfs_site['dfs.namenode.keytab.file']
        nn_princ = service.deps.hdfs_nn.options.hdfs_site['dfs.namenode.kerberos.principal'].replace '_HOST', service.node.fqdn
        options.audit['xasecure.audit.jaas.inmemory.Client.option.principal'] ?= nn_princ

## Wait

      options.wait_ranger_admin = service.deps.ranger_admin.options.wait

## Dependencies

    {merge} = require '@nikita/core/lib/misc'

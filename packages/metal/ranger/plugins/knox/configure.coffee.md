
## Ranger Knox Plugin Configure

    module.exports = (service) ->
      options = service.options

## Environment

      # Layout
      options.conf_dir ?= service.deps.knox.options.conf_dir

## Kerberos

      options.krb5 ?= {}
      options.krb5.enabled ?= service.deps.hadoop_core.options.core_site['hadoop.security.authentication'] is 'kerberos'
      options.krb5.realm ?= service.deps.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      # Admin Information
      options.krb5.admin = service.deps.krb5_client.options.admin[options.krb5.realm]

## Identities

      options.group = merge service.deps.ranger_admin.options.group, options.group or {}
      options.user = merge service.deps.ranger_admin.options.user, options.user or {}
      options.knox_user = service.deps.knox.options.user
      options.knox_group = service.deps.knox.options.group
      options.hadoop_group = service.deps.hadoop_core.options.hadoop_group
      options.hdfs_krb5_user = service.deps.hadoop_core.options.hdfs.krb5_user

## Access

      options.ranger_admin ?= service.deps.ranger_admin.options.admin

## Configuration

      # Knox Plugin configuration
      options.install ?= {}
      options.install['PYTHON_COMMAND_INVOKER'] ?= 'python'
      options.install['CUSTOM_USER'] ?= "#{options.knox_user.name}"
      options.install['CUSTOM_GROUP'] ?= "#{options.knox_group.name}"
      options.install['KNOX_HOME'] ?= '/usr/hdp/current/knox-server'

## Admin properties

      options.install['POLICY_MGR_URL'] ?= service.deps.ranger_admin.options.install['policymgr_external_url']
      options.install['REPOSITORY_NAME'] ?= 'hadoop-ryba-knox'
        
## Plugin User

      options.plugin_user ?=
        'name': options.knox_user.name
        'firstName': ''
        'lastName': ''
        'emailAddress': ''
        'userSource': 1
        'userRoleList': ['ROLE_USER']
        'groups': []
        'status': 1

## Service Definition

      knox_protocol = if service.deps.knox.options.ssl then 'https' else 'http'
      knox_url = "#{knox_protocol}://#{service.deps.knox.node.fqdn}"
      knox_url += ":#{service.deps.knox.options.gateway_site['gateway.port']}/#{service.deps.knox.options.gateway_site['gateway.path']}"
      knox_url += '/admin/api/v1/topologies'
      options.service_repo ?=
        'name': options.install['REPOSITORY_NAME']
        'description': 'Knox Repository'
        'type': 'knox'
        'isEnabled': true
        'configs':
          'username': service.deps.ranger_admin.options.plugins.principal
          'password': service.deps.ranger_admin.options.plugins.password
          'knox.url': "#{knox_url}"
          'commonNameForCertificate': ''
          'policy.download.auth.users': "#{options.user.name}" #from ranger 0.6
          'tag.download.auth.users': "#{options.user.name}"

## Knox Plugin SSL

      if service.deps.ranger_admin.options.site['ranger.service.https.attrib.ssl.enabled'] is 'true'
        options.ssl = merge service.deps.hadoop_core.options.ssl, options.ssl
        options.install['SSL_KEYSTORE_FILE_PATH'] ?= service.deps.knox.options.ssl.keystore.target
        options.install['SSL_KEYSTORE_PASSWORD'] ?= service.deps.knox.options.ssl.keystore.password
        options.install['SSL_TRUSTSTORE_FILE_PATH'] ?= service.deps.hadoop_core.options.ssl_client['ssl.client.truststore.location']
        options.install['SSL_TRUSTSTORE_PASSWORD'] ?= service.deps.hadoop_core.options.ssl_client['ssl.client.truststore.password']

## HDFS Storage

      options.install['XAAUDIT.HDFS.IS_ENABLED'] ?= 'true'
      if options.install['XAAUDIT.HDFS.IS_ENABLED'] is 'true'
        # migration: lucasbak 11102017
        # honored but not used by plugin
        # options.install['XAAUDIT.HDFS.LOCAL_BUFFER_DIRECTORY'] ?= "#{service.deps.ranger_admin.options.conf_dir}/%app-type%/audit"
        # options.install['XAAUDIT.HDFS.LOCAL_ARCHIVE_DIRECTORY'] ?= "#{service.deps.ranger_admin.options.conf_dir}/%app-type%/archive"
        options.install['XAAUDIT.HDFS.ENABLE'] ?= 'true'
        options.install['XAAUDIT.HDFS.HDFS_DIR'] ?= "#{service.deps.hdfs_client.options.core_site['fs.defaultFS']}/#{options.user.name}/audit"
        options.install['XAAUDIT.HDFS.DESTINATION_DIRECTORY'] ?= "#{service.deps.hdfs_client.options.core_site['fs.defaultFS']}/#{options.user.name}/audit/%app-type%/%time:yyyyMMdd%"
        options.install['XAAUDIT.HDFS.DESTINATION_FILE'] ?= '%hostname%-audit.log'
        options.install['XAAUDIT.HDFS.FILE_SPOOL_DIR'] ?= "#{service.deps.knox.options.log_dir}/audit/hdfs/spool"
        options.install['XAAUDIT.HDFS.DESTINATION_FILE'] ?= '%hostname%-audit.log'
        options.install['XAAUDIT.HDFS.DESTINATION_FLUSH_INTERVAL_SECONDS'] ?= '900'
        options.install['XAAUDIT.HDFS.DESTINATION_ROLLOVER_INTERVAL_SECONDS'] ?= '86400'
        options.install['XAAUDIT.HDFS.DESTINATION _OPEN_RETRY_INTERVAL_SECONDS'] ?= '60'
        options.install['XAAUDIT.HDFS.LOCAL_BUFFER_FILE'] ?= '%time:yyyyMMdd-HHmm.ss%.log'
        options.install['XAAUDIT.HDFS.LOCAL_BUFFER_FLUSH_INTERVAL_SECONDS'] ?= '60'
        options.install['XAAUDIT.HDFS.LOCAL_BUFFER_ROLLOVER_INTERVAL_SECONDS'] ?= '600'
        options.install['XAAUDIT.HDFS.LOCAL_ARCHIVE _MAX_FILE_COUNT'] ?= '5'

## Solr Storage

      if service.deps.ranger_admin.options.install['audit_store'] is 'solr'
        options.install['XAAUDIT.SOLR.IS_ENABLED'] ?= 'true'
        options.install['XAAUDIT.SOLR.ENABLE'] ?= 'true'
        options.install['XAAUDIT.SOLR.URL'] ?= service.deps.ranger_admin.options.install['audit_solr_urls']
        options.install['XAAUDIT.SOLR.USER'] ?= service.deps.ranger_admin.options.install['audit_solr_user']
        options.install['XAAUDIT.SOLR.ZOOKEEPER'] ?= service.deps.ranger_admin.options.install['audit_solr_zookeepers']
        options.install['XAAUDIT.SOLR.PASSWORD'] ?= service.deps.ranger_admin.options.install['audit_solr_password']
        options.install['XAAUDIT.SOLR.FILE_SPOOL_DIR'] ?= "#{service.deps.knox.options.log_dir}/audit/solr/spool"

## Database Storage

      # Deprecated
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
        options.install['XAAUDIT.DB.HOSTNAME'] ?= 'NONE'
        options.install['XAAUDIT.DB.DATABASE_NAME'] ?= 'NONE'
        options.install['XAAUDIT.DB.USER_NAME'] ?= 'NONE'
        options.install['XAAUDIT.DB.PASSWORD'] ?= 'NONE'

## Wait

      options.wait_ranger_admin = service.deps.ranger_admin.options.wait

## Dependencies

    {merge} = require 'mixme'

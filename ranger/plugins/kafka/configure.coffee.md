
# Ranger Kafka Plugin Configure

    module.exports = (service) ->
      options = service.options

## Identities

      options.group = merge {}, service.deps.ranger_admin.options.group, options.group or {}
      options.user = merge {}, service.deps.ranger_admin.options.user, options.user or {}
      options.kafka_user = service.deps.kafka_broker.options.user
      options.kafka_group = service.deps.kafka_broker.options.group
      options.hadoop_group = service.deps.hadoop_core.options.hadoop_group
      options.hdfs_krb5_user = service.deps.hadoop_core.options.hdfs.krb5_user

## Kerberos

      options.krb5 ?= {}
      options.krb5.enabled ?= service.deps.hadoop_core.options.core_site['hadoop.security.authentication'] is 'kerberos'
      options.krb5.realm ?= service.deps.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      # Admin Information
      options.krb5.admin = service.deps.krb5_client.options.admin[options.krb5.realm]

## Environment

      # Layout
      options.conf_dir ?= service.deps.kafka_broker.options.conf_dir

## Access

      options.ranger_admin ?= service.deps.ranger_admin.options.admin

## Register Authentication

      service.deps.kafka_broker.options.config['authorizer.class.name'] = 'org.apache.ranger.authorization.kafka.authorizer.RangerKafkaAuthorizer'

## Plugin User

      options.plugin_user ?=
        'name': options.kafka_user.name
        'firstName': ''
        'lastName': ''
        'emailAddress': ''
        'userSource': 1
        'userRoleList': ['ROLE_USER']
        'groups': []
        'status': 1
      if 'PLAINTEXT' in service.deps.kafka_broker.options.protocols or 'SSL' in service.deps.kafka_broker.options.protocols
        options.plugin_user_anonymous ?=
          name: "ANONYMOUS"
          firstName: ''
          lastName: ''
          emailAddress: ''
          userSource: 1
          userRoleList: ['ROLE_USER']
          groups: []
          status: 1

## Configuration

      options.install ?= {}
      options.install['PYTHON_COMMAND_INVOKER'] ?= 'python'
      options.install['CUSTOM_USER'] ?= "#{service.deps.kafka_broker.options.user.name}"

## Ranger admin properties

The repository name should match the reposity name in web ui.
The properties can be found [here][kafka-repository]

      options.install['POLICY_MGR_URL'] ?= service.deps.ranger_admin.options.install['policymgr_external_url']
      options.install['REPOSITORY_NAME'] ?= 'hadoop-ryba-kafka'

## Service Definition

      options.service_repo ?=
        'name': options.install['REPOSITORY_NAME']
        'description': 'Kafka Repository'
        'type': 'kafka'
        'isEnabled': true
        'configs':
          'username': service.deps.ranger_admin.options.plugins.principal
          'password': service.deps.ranger_admin.options.plugins.password
          'hadoop.security.authentication': service.deps.hadoop_core.options.core_site['hadoop.security.authentication']
          'zookeeper.connect': service.deps.kafka_broker.options.config['zookeeper.connect'].join(',')
          'policy.download.auth.users': "#{service.deps.kafka_broker.options.user.name}" #from ranger 0.6
          'commonNameForCertificate': ''

## SSL

Used only if SSL is enabled between Policy Admin Tool and Plugin. The path to
keystore is derived from Kafka server. The path to the truststore is derived
from Hadoop Core.

      if service.deps.ranger_admin.options.site['ranger.service.https.attrib.ssl.enabled'] is 'true'
        options.install['SSL_KEYSTORE_FILE_PATH'] ?= service.deps.kafka_broker.options.config['ssl.keystore.location']
        options.install['SSL_KEYSTORE_PASSWORD'] ?= service.deps.kafka_broker.options.config['ssl.keystore.password']
        options.install['SSL_KEY_PASSWORD'] ?= service.deps.kafka_broker.options.config['ssl.key.password']
        options.install['SSL_TRUSTSTORE_FILE_PATH'] ?= service.deps.kafka_broker.options.config['ssl.truststore.location']
        options.install['SSL_TRUSTSTORE_PASSWORD'] ?= service.deps.kafka_broker.options.config['ssl.truststore.password']

## Audit

      options.install['XAAUDIT.SUMMARY.ENABLE'] ?= 'true'

## HDFS storage

      options.install['XAAUDIT.HDFS.IS_ENABLED'] ?= 'true'
      if options.install['XAAUDIT.HDFS.IS_ENABLED'] is 'true'
        # migration: lucasbak 11102017
        # honored but not used by plugin
        # options.install['XAAUDIT.HDFS.LOCAL_BUFFER_DIRECTORY'] ?= "#{service.deps.ranger_admin.options.conf_dir}/%app-type%/audit"
        # options.install['XAAUDIT.HDFS.LOCAL_ARCHIVE_DIRECTORY'] ?= "#{service.deps.ranger_admin.options.conf_dir}/%app-type%/archive"
        options.install['XAAUDIT.HDFS.ENABLE'] ?= 'true'
        options.install['XAAUDIT.HDFS.DESTINATION_DIRECTORY'] ?= "#{service.deps.hdfs_client.options.core_site['fs.defaultFS']}/#{options.user.name}/audit/%app-type%/%time:yyyyMMdd%"
        options.install['XAAUDIT.HDFS.DESTINATION_FILE'] ?= '%hostname%-audit.log'
        options.install['XAAUDIT.HDFS.FILE_SPOOL_DIR'] ?= "#{service.deps.kafka_broker.options.log_dir}/audit/hdfs/spool"
        options.install['XAAUDIT.HDFS.DESTINATION_FILE'] ?= '%hostname%-audit.log'
        options.install['XAAUDIT.HDFS.DESTINATION_FLUSH_INTERVAL_SECONDS'] ?= '900'
        options.install['XAAUDIT.HDFS.DESTINATION_ROLLOVER_INTERVAL_SECONDS'] ?= '86400'
        options.install['XAAUDIT.HDFS.DESTINATION _OPEN_RETRY_INTERVAL_SECONDS'] ?= '60'
        options.install['XAAUDIT.HDFS.LOCAL_BUFFER_FILE'] ?= '%time:yyyyMMdd-HHmm.ss%.log'
        options.install['XAAUDIT.HDFS.LOCAL_BUFFER_FLUSH_INTERVAL_SECONDS'] ?= '60'
        options.install['XAAUDIT.HDFS.LOCAL_BUFFER_ROLLOVER_INTERVAL_SECONDS'] ?= '600'
        options.install['XAAUDIT.HDFS.LOCAL_ARCHIVE _MAX_FILE_COUNT'] ?= '5'
        options.policy_hdfs_audit ?=
          'name': "kafka-ranger-plugin-audit"
          'service': "#{options.install['REPOSITORY_NAME']}"
          'repositoryType':"hdfs"
          'description': 'Kafka Ranger Plugin audit log policy'
          'isEnabled': true
          'isAuditEnabled': true
          'resources':
            'path':
              'isRecursive': 'true'
              'values': ['/ranger/audit/kafka']
              'isExcludes': false
          'policyItems': [
            'users': ["#{options.kafka_user.name}"]
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

## Solr storage

      if options.install['audit_store'] is 'solr'
        options.install['XAAUDIT.SOLR.IS_ENABLED'] ?= 'true'
        options.install['XAAUDIT.SOLR.ENABLE'] ?= 'true'
        options.install['XAAUDIT.SOLR.URL'] ?= service.deps.ranger_admin.options.install['audit_solr_urls']
        options.install['XAAUDIT.SOLR.USER'] ?= service.deps.ranger_admin.options.install['audit_solr_user']
        options.install['XAAUDIT.SOLR.ZOOKEEPER'] ?= service.deps.ranger_admin.options.install['audit_solr_zookeepers']
        options.install['XAAUDIT.SOLR.PASSWORD'] ?= service.deps.ranger_admin.options.install['audit_solr_password']
        options.install['XAAUDIT.SOLR.FILE_SPOOL_DIR'] ?= "#{service.deps.kafka_broker.options.log_dir}/audit/solr/spool"

## Database storage

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
          options.install['XAAUDIT.DB.HOSTNAME'] ?= 'NONE'
          options.install['XAAUDIT.DB.DATABASE_NAME'] ?= 'NONE'
          options.install['XAAUDIT.DB.USER_NAME'] ?= 'NONE'
          options.install['XAAUDIT.DB.PASSWORD'] ?= 'NONE'

## Wait

      options.wait_ranger_admin = service.deps.ranger_admin.options.wait

## Dependencies

    {merge} = require 'nikita/lib/misc'

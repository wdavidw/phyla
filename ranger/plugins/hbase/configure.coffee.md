
## Ranger HBase Plugin Configure

    module.exports = ->
      service = migration.call @, service, 'ryba/ranger/plugins/hbase', ['ryba', 'ranger', 'hbase'], require('nikita/lib/misc').merge require('.').use,
        krb5_client: key: ['krb5_client']
        java: key: ['java']
        hadoop_core: key: ['ryba']
        hbase_master: key: ['ryba', 'hbase', 'master']
        ranger_admin: key: ['ryba', 'ranger', 'admin']
        ranger_hdfs: key: ['ryba', 'ranger', 'hdfs']
      @config.ryba.ranger ?= {}
      options = @config.ryba.ranger.hbase = service.options

## Kerberos

      options.krb5 ?= {}
      options.krb5.enabled ?= service.use.hadoop_core.options.core_site['hadoop.security.authentication'] is 'kerberos'
      options.krb5.realm ?= service.use.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      # Admin Information
      options.krb5.admin = service.use.krb5_client.options.admin[options.krb5.realm]

## Identities

      options.group = merge {}, service.use.ranger_admin.options.group, options.group or {}
      options.user = merge {}, service.use.ranger_admin.options.user, options.user or {}
      options.hbase_user = service.use.hbase_master.options.user
      options.hadoop_group = service.use.hbase_master.options.hadoop_group

## Access

      options.ranger_admin ?= service.use.ranger_admin.options.admin
      options.hdfs_install ?= service.use.ranger_hdfs.options.install

## Environment

      # Layout
      options.conf_dir ?= service.use.hbase_master.options.conf_dir
      options.log_dir ?= service.use.hbase_master.options.log_dir
      # Java
      # Java
      options.jre_home ?= service.use.java.options.jre_home

## Plugin User

migration: wdavidw 170828, please explain its usage.It is an admin user here 
for conveniency or an internal application user to communicate with between the 
plugin and the server ?

migration: wdavidw 170828, access for the user need to be tested through a HTTP
REST request.

      options.plugin_user = 
        "name": 'hbase'
        "firstName": ''
        "lastName": 'hadoop'
        "emailAddress": 'hbase@hadoop.ryba'
        "password": 'hbase123'
        'userSource': 1
        'userRoleList': ['ROLE_USER']
        'groups': []
        'status': 1
      # service.use.ranger_admin.options.users['hbase'] ?= options.ranger_user

## Configuration

      options.install ?= {}
      # migration: wdavidw 170902, used in hbase/rest/check, should be moved
      # options.policy_name ?= "Ranger-Ryba-HBase-Policy"
      options.install ?= {}
      options.install['PYTHON_COMMAND_INVOKER'] ?= 'python'
      options.install['CUSTOM_USER'] ?= "#{options.hbase_user.name}"

### HBase regionserver env

Some ranger plugins needs to have the configuration file on their classpath to 
make configuration effective.

      # migration: wdavidw 170902, code is ready but commented for now, maybe
      # it should apply to hbase master as well.
      # for srv in service.use.hbase_regionserver
      #   core_site_path = "#{srv.options.conf_dir}/core-site.xml"
      #   unless srv.options.env['HBASE_CLASSPATH']
      #     srv.options.env['HBASE_CLASSPATH'] = "$HBASE_CLASSPATH:#{core_site_path}"
      #   else if (srv.options.env['HBASE_CLASSPATH'].indexOf(":#{core_site_path}") is -1)
      #     srv.options.env['HBASE_CLASSPATH'] += ":#{core_site_path}"

### HBase Policy Admin Tool
The repository name should match the reposity name in web ui.

      options.install['POLICY_MGR_URL'] ?= service.use.ranger_admin.options.install['policymgr_external_url']
      options.install['REPOSITORY_NAME'] ?= 'hadoop-ryba-hbase'
      options.service_repo ?=
        'configs':
          'username': 'ranger_plugin_hbase'
          'password': 'RangerPluginHBase123!'
          'hadoop.security.authorization': service.use.hadoop_core.options.core_site['hadoop.security.authorization']
          'hbase.master.kerberos.principal': service.use.hbase_master.options.hbase_site['hbase.master.kerberos.principal']
          'hadoop.security.authentication': service.use.hadoop_core.options.core_site['hadoop.security.authentication']
          'hbase.security.authentication': service.use.hbase_master.options.hbase_site['hbase.security.authentication']
          'hbase.zookeeper.property.clientPort': service.use.hbase_master.options.hbase_site['hbase.zookeeper.property.clientPort']
          'hbase.zookeeper.quorum': service.use.hbase_master.options.hbase_site['hbase.zookeeper.quorum']
          'zookeeper.znode.parent': service.use.hbase_master.options.hbase_site['zookeeper.znode.parent']
          'policy.download.auth.users': "#{options.hbase_user.name}" #from ranger 0.6
          'tag.download.auth.users': "#{options.hbase_user.name}"
          'policy.grantrevoke.auth.users': "#{options.hbase_user.name}"
        'description': 'HBase Repo'
        'isEnabled': true
        'name': options.install['REPOSITORY_NAME']
        'type': 'hbase'
      options.install['XAAUDIT.SUMMARY.ENABLE'] ?= 'true'
      options.install['UPDATE_XAPOLICIES_ON_GRANT_REVOKE'] ?= 'true'

### HBase Audit (HDFS V3 properties)

      # V3 Configuration
      options.install['XAAUDIT.HDFS.IS_ENABLED'] ?= 'true'
      if options.install['XAAUDIT.HDFS.IS_ENABLED'] is 'true'
        options.install['XAAUDIT.HDFS.DESTINATION_DIRECTORY'] ?= "#{service.use.hadoop_core.options.core_site['fs.defaultFS']}/#{service.use.ranger_admin.options.user.name}/audit/%app-type%/%time:yyyyMMdd%"
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

### HBase Audit (HDFS Storage)

      # AUDIT TO HDFS
      options.install['XAAUDIT.HDFS.ENABLE'] ?= 'true'
      options.install['XAAUDIT.HDFS.HDFS_DIR'] ?= "#{service.use.hadoop_core.options.core_site['fs.defaultFS']}/#{service.use.ranger_admin.options.user.name}/audit"
      options.install['XAAUDIT.HDFS.FILE_SPOOL_DIR'] ?= "#{options.log_dir}/audit/hdfs/spool"

### HBase Audit (database storage)

      # Deprecated
      # migration: wdavidw 170902, in favor of what ?
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


### HBase Audit (to SOLR)

      if service.use.ranger_admin.options.install['audit_store'] is 'solr'
        options.install['XAAUDIT.SOLR.IS_ENABLED'] ?= 'true'
        options.install['XAAUDIT.SOLR.ENABLE'] ?= 'true'
        options.install['XAAUDIT.SOLR.URL'] ?= service.use.ranger_admin.options.install['audit_solr_urls']
        options.install['XAAUDIT.SOLR.USER'] ?= service.use.ranger_admin.options.install['audit_solr_user']
        options.install['XAAUDIT.SOLR.ZOOKEEPER'] ?= service.use.ranger_admin.options.install['audit_solr_zookeepers']
        options.install['XAAUDIT.SOLR.PASSWORD'] ?= service.use.ranger_admin.options.install['audit_solr_password']
        options.install['XAAUDIT.SOLR.FILE_SPOOL_DIR'] ?= "#{options.log_dir}/audit/solr/spool"

### HBase Plugin Execution

      if service.use.ranger_admin.options.site['ranger.service.https.attrib.ssl.enabled'] is 'true'
        options.ssl = merge {}, service.use.hadoop_core.options.ssl, options.ssl or {}
        options.install['SSL_KEYSTORE_FILE_PATH'] ?= service.use.hadoop_core.options.ssl_server['ssl.server.keystore.location']
        options.install['SSL_KEYSTORE_PASSWORD'] ?= service.use.hadoop_core.options.ssl_server['ssl.server.keystore.password']
        options.install['SSL_TRUSTSTORE_FILE_PATH'] ?= service.use.hadoop_core.options.ssl_server['ssl.server.truststore.location']
        options.install['SSL_TRUSTSTORE_PASSWORD'] ?= service.use.hadoop_core.options.ssl_server['ssl.server.truststore.password']

## Merge hive_plugin conf to ranger admin

        # ranger_admin_ctx.config.ryba.ranger.hbase_plugin = merge hbase_plugin

## Wait

      options.wait_ranger_admin = service.use.ranger_admin.options.wait

## Dependencies

    {merge} = require 'nikita/lib/misc'
    migration = require 'masson/lib/migration'

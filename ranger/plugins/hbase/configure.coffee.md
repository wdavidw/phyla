
## Ranger HBase Plugin Configure

    module.exports = (service) ->
      options = service.options

## Identities

      options.group = merge {}, service.deps.ranger_admin.options.group, options.group or {}
      options.user = merge {}, service.deps.ranger_admin.options.user, options.user or {}
      options.hbase_user = service.deps.hbase_master[0].options.user
      options.hbase_group = service.deps.hbase_master[0].options.group
      options.hadoop_group = service.deps.hbase_master[0].options.hadoop_group
      options.hdfs_krb5_user = service.deps.hadoop_core.options.hdfs.krb5_user

## Kerberos

      options.krb5 ?= {}
      options.krb5.enabled ?= service.deps.hadoop_core.options.core_site['hadoop.security.authentication'] is 'kerberos'
      options.krb5.realm ?= service.deps.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      # Admin Information
      options.krb5.admin = service.deps.krb5_client.options.admin[options.krb5.realm]

## Access

      options.ranger_admin ?= service.deps.ranger_admin.options.admin
      options.hdfs_install ?= service.deps.ranger_hdfs[0].options.install

## Environment

      # Layout
      options.conf_dir ?= []
      options.conf_dir.push service.deps.hbase_master[0].options.conf_dir if service.deps.hbase_master.some (srv) -> srv.node.fqdn is service.node.fqdn
      options.conf_dir.push service.deps.hbase_regionserver.options.conf_dir if service.deps.hbase_regionserver
      # Java
      options.jre_home ?= service.deps.java.options.jre_home

## Plugin User

migration: wdavidw 170828, please explain its usage.It is an admin user here 
for conveniency or an internal application user to communicate with between the 
plugin and the server ?

migration: wdavidw 170828, access for the user need to be tested through a HTTP
REST request.

      options.plugin_user = 
        "name": options.hbase_user.name
        "firstName": ''
        "lastName": ''
        "emailAddress": ''
        "password": ''
        'userSource': 1
        'userRoleList': ['ROLE_USER']
        'groups': []
        'status': 1
      # service.deps.ranger_admin.options.users['hbase'] ?= options.ranger_user

## Configuration

      #misc
      options.master_fqdn = service.deps.hbase_master[0].node.fqdn
      options.fqdn = service.node.fqdn
      options.install ?= {}
      # migration: wdavidw 170902, used in hbase/rest/check, should be moved
      # options.policy_name ?= "Ranger-Ryba-HBase-Policy"
      options.install ?= {}
      options.install['PYTHON_COMMAND_INVOKER'] ?= 'python'
      options.install['CUSTOM_USER'] ?= "#{options.hbase_user.name}"

## RAnger Coprocessor

      # Master Hbase site
      index = service.deps.hbase_master[0].options.hbase_site['hbase.coprocessor.master.classes'].indexOf('org.apache.hadoop.hbase.security.access.AccessController')
      if index >= 0
        service.deps.hbase_master[0].options.hbase_site['hbase.coprocessor.master.classes'].splice(index, 1)
      index = service.deps.hbase_master[0].options.hbase_site['hbase.coprocessor.region.classes'].indexOf 'org.apache.hadoop.hbase.security.access.AccessController'
      if index >= 0
        service.deps.hbase_master[0].options.hbase_site['hbase.coprocessor.region.classes'].splice(index, 1)
      service.deps.hbase_master[0].options.hbase_site['hbase.coprocessor.master.classes'].push 'org.apache.ranger.authorization.hbase.RangerAuthorizationCoprocessor' unless 'org.apache.ranger.authorization.hbase.RangerAuthorizationCoprocessor' in   service.deps.hbase_master[0].options.hbase_site['hbase.coprocessor.master.classes']

      # RS Hbase site
      if service.deps.hbase_regionserver
        index = service.deps.hbase_regionserver.options.hbase_site['hbase.coprocessor.region.classes'].indexOf 'org.apache.hadoop.hbase.security.access.AccessController'
        if index >= 0
          service.deps.hbase_regionserver.options.hbase_site['hbase.coprocessor.region.classes'].splice(index, 1)
        service.deps.hbase_regionserver.options.hbase_site['hbase.coprocessor.region.classes'].push 'org.apache.ranger.authorization.hbase.RangerAuthorizationCoprocessor' unless 'org.apache.ranger.authorization.hbase.RangerAuthorizationCoprocessor' in   service.deps.hbase_regionserver.options.hbase_site['hbase.coprocessor.region.classes']

## HBase regionserver env

Some ranger plugins needs to have the configuration file on their classpath to 
make configuration effective.

      # migration: wdavidw 170902, code is ready but commented for now, maybe
      # it should apply to hbase master as well.
      # for srv in service.deps.hbase_regionserver
      #   core_site_path = "#{srv.options.conf_dir}/core-site.xml"
      #   unless srv.options.env['HBASE_CLASSPATH']
      #     srv.options.env['HBASE_CLASSPATH'] = "$HBASE_CLASSPATH:#{core_site_path}"
      #   else if (srv.options.env['HBASE_CLASSPATH'].indexOf(":#{core_site_path}") is -1)
      #     srv.options.env['HBASE_CLASSPATH'] += ":#{core_site_path}"

## Admin properties

      options.install['POLICY_MGR_URL'] ?= service.deps.ranger_admin.options.install['policymgr_external_url']
      options.install['REPOSITORY_NAME'] ?= 'hadoop-ryba-hbase'

## Service Definition

      options.service_repo ?=
        'name': options.install['REPOSITORY_NAME']
        'description': 'HBase Repo'
        'type': 'hbase'
        'isEnabled': true
        'configs':
          # 'username': 'ranger_plugin_hbase'
          # 'password': 'RangerPluginHBase123!'
          'username': service.deps.ranger_admin.options.plugins.principal
          'password': service.deps.ranger_admin.options.plugins.password
          'hadoop.security.authorization': service.deps.hadoop_core.options.core_site['hadoop.security.authorization']
          'hbase.master.kerberos.principal': service.deps.hbase_master[0].options.hbase_site['hbase.master.kerberos.principal']
          'hadoop.security.authentication': service.deps.hadoop_core.options.core_site['hadoop.security.authentication']
          'hbase.security.authentication': service.deps.hbase_master[0].options.hbase_site['hbase.security.authentication']
          'hbase.zookeeper.property.clientPort': service.deps.hbase_master[0].options.hbase_site['hbase.zookeeper.property.clientPort']
          'hbase.zookeeper.quorum': service.deps.hbase_master[0].options.hbase_site['hbase.zookeeper.quorum']
          'zookeeper.znode.parent': service.deps.hbase_master[0].options.hbase_site['zookeeper.znode.parent']
          'policy.download.auth.users': "#{options.hbase_user.name}" #from ranger 0.6
          'tag.download.auth.users': "#{options.hbase_user.name}"
          'policy.grantrevoke.auth.users': "#{options.hbase_user.name}"
      options.install['XAAUDIT.SUMMARY.ENABLE'] ?= 'true'
      options.install['UPDATE_XAPOLICIES_ON_GRANT_REVOKE'] ?= 'true'

## Audit

### HDFS Storage

      options.install['XAAUDIT.HDFS.IS_ENABLED'] ?= 'true'
      if options.install['XAAUDIT.HDFS.IS_ENABLED'] is 'true'
        # migration: lucasbak 11102017
        # honored but not used by plugin
        # options.install['XAAUDIT.HDFS.LOCAL_BUFFER_DIRECTORY'] ?= "#{service.deps.ranger_admin.options.conf_dir}/%app-type%/audit"
        # options.install['XAAUDIT.HDFS.LOCAL_ARCHIVE_DIRECTORY'] ?= "#{service.deps.ranger_admin.options.conf_dir}/%app-type%/archive"
        options.install['XAAUDIT.HDFS.ENABLE'] ?= 'true'
        options.install['XAAUDIT.HDFS.HDFS_DIR'] ?= "#{service.deps.hdfs_client.options.core_site['fs.defaultFS']}/#{options.user.name}/audit"
        options.install['XAAUDIT.HDFS.DESTINATION_DIRECTORY'] ?= "#{service.deps.hdfs_client.options.core_site['fs.defaultFS']}/#{options.user.name}/audit/%app-type%/%time:yyyyMMdd%"
        options.install['XAAUDIT.HDFS.FILE_SPOOL_DIR'] ?= "#{service.deps.hbase_master[0].options.log_dir}/audit/hdfs/spool"
        options.install['XAAUDIT.HDFS.LOCAL_ARCHIVE_DIRECTORY'] ?= '/var/log/ranger/%app-type%/archive'
        options.install['XAAUDIT.HDFS.DESTINATION_FILE'] ?= '%hostname%-audit.log'
        options.install['XAAUDIT.HDFS.DESTINATION_FLUSH_INTERVAL_SECONDS'] ?= '900'
        options.install['XAAUDIT.HDFS.DESTINATION_ROLLOVER_INTERVAL_SECONDS'] ?= '86400'
        options.install['XAAUDIT.HDFS.DESTINATION _OPEN_RETRY_INTERVAL_SECONDS'] ?= '60'
        options.install['XAAUDIT.HDFS.LOCAL_BUFFER_FILE'] ?= '%time:yyyyMMdd-HHmm.ss%.log'
        options.install['XAAUDIT.HDFS.LOCAL_BUFFER_FLUSH_INTERVAL_SECONDS'] ?= '60'
        options.install['XAAUDIT.HDFS.LOCAL_BUFFER_ROLLOVER_INTERVAL_SECONDS'] ?= '600'
        options.install['XAAUDIT.HDFS.LOCAL_ARCHIVE _MAX_FILE_COUNT'] ?= '5'

## Audit Policy

      if options.install['XAAUDIT.HDFS.IS_ENABLED'] is 'true'
        options.policy_hdfs_audit =
          name: "hbase-ranger-plugin-audit"
          service: "#{options.hdfs_install['REPOSITORY_NAME']}"
          repositoryType: 'hdfs'
          description: 'HBase Ranger Plugin audit log policy'
          isEnabled: true
          isAuditEnabled: true
          resources:
            path:
              isRecursive: 'true'
              values: ['/ranger/audit/hbaseRegional','/ranger/audit/hbaseMaster']
              isExcludes: false
          policyItems: [{
            users: ["#{options.hbase_user.name}"]
            groups: []
            delegateAdmin: true
            accesses:[
                "isAllowed": true
                "type": "read"
            ,
                "isAllowed": true
                "type": "write"
            ,
                "isAllowed": true
                "type": "execute"
            ]
            conditions: []
            }]

### Solr Storage

      if service.deps.ranger_admin.options.install['audit_store'] is 'solr'
        options.install['XAAUDIT.SOLR.IS_ENABLED'] ?= 'true'
        options.install['XAAUDIT.SOLR.ENABLE'] ?= 'true'
        options.install['XAAUDIT.SOLR.URL'] ?= service.deps.ranger_admin.options.install['audit_solr_urls']
        options.install['XAAUDIT.SOLR.USER'] ?= service.deps.ranger_admin.options.install['audit_solr_user']
        options.install['XAAUDIT.SOLR.ZOOKEEPER'] ?= service.deps.ranger_admin.options.install['audit_solr_zookeepers']
        options.install['XAAUDIT.SOLR.PASSWORD'] ?= service.deps.ranger_admin.options.install['audit_solr_password']
        options.install['XAAUDIT.SOLR.FILE_SPOOL_DIR'] ?= "#{service.deps.hbase_master[0].options.log_dir}/audit/solr/spool"

### Plugin Execution

      if service.deps.ranger_admin.options.site['ranger.service.https.attrib.ssl.enabled'] is 'true'
        options.ssl = merge {}, service.deps.hadoop_core.options.ssl, options.ssl
        options.install['SSL_KEYSTORE_FILE_PATH'] ?= service.deps.hadoop_core.options.ssl_server['ssl.server.keystore.location']
        options.install['SSL_KEYSTORE_PASSWORD'] ?= service.deps.hadoop_core.options.ssl_server['ssl.server.keystore.password']
        options.install['SSL_TRUSTSTORE_FILE_PATH'] ?= service.deps.hadoop_core.options.ssl_server['ssl.server.truststore.location']
        options.install['SSL_TRUSTSTORE_PASSWORD'] ?= service.deps.hadoop_core.options.ssl_server['ssl.server.truststore.password']

### Database Storage

      # Deprecated
      # migration: wdavidw 170902, in favor of what ?
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

## Merge hive_plugin conf to ranger admin

        # ranger_admin_ctx.config.ryba.ranger.hbase_plugin = merge hbase_plugin

## Wait

      options.wait_ranger_admin = service.deps.ranger_admin.options.wait

## Dependencies

    {merge} = require 'nikita/lib/misc'

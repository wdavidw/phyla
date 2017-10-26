
# Rangerize Solr Cluster
The configuration slightly differs for Solr in camparison to the other ranger plugins.
The need is to configure the differents solr clusters which are configured by Ryba
As a consequence, the configuration is hold in the `ryba.ranger.solr_plugins` property and
contains as the key the cluster name and configuration the `solr_plugin` config.

This modules injects installation actions in the `ryba/solr/cloud_docker` contexts.
As a consequence, `ryba/ranger/admin` and `ryba/solr/cloud_docker` must not be installed on
the same machine.

    module.exports = ->
      service = migration.call @, service, 'ryba/ranger/plugins/solr_cloud_docker', ['ryba', 'ranger', 'solr_cloud_docker'], require('nikita/lib/misc').merge require('.').use,
        krb5_client: key: ['krb5_client']
        java: key: ['java']
        hadoop_core: key: ['ryba']
        hdfs_client: key: ['ryba', 'hdfs_client']
        solr_cloud_docker: key: ['ryba', 'solr', 'cloud_docker']
        atlas: key: ['ryba', 'atlas']
        ranger_admin: key: ['ryba', 'ranger', 'admin']
        ranger_hdfs: key: ['ryba', 'ranger', 'hdfs']
        ranger_solr_cloud_docker: key: ['ryba', 'ranger','solr_cloud_docker']
      @config.ryba.ranger ?= {}
      options = @config.ryba.ranger.solr_cloud_docker = service.options

## Kerberos

      options.krb5 ?= {}
      options.krb5.enabled ?= service.use.hadoop_core.options.core_site['hadoop.security.authentication'] is 'kerberos'
      options.krb5.realm ?= service.use.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      # Admin Information
      options.krb5.admin = service.use.krb5_client.options.admin[options.krb5.realm]

## Environment

      # Layout
      options.conf_dir ?= service.use.solr_cloud_docker.options.conf_dir
      
## Identities

      options.group = merge {}, service.use.ranger_admin.options.group, options.group or {}
      options.user = merge {}, service.use.ranger_admin.options.user, options.user or {}
      options.solr_user = service.use.solr_cloud_docker.options.user
      options.solr_group = service.use.solr_cloud_docker.options.group
      options.hadoop_group = service.use.hadoop_core.options.hadoop_group
      options.hdfs_krb5_user = service.use.hadoop_core.options.hdfs.krb5_user

## Access

      options.ranger_admin ?= service.use.ranger_admin
      options.hdfs_install ?= service.use.ranger_hdfs[0].options.install

## Plugin User

      options.plugin_user ?=
        "name": 'solr'
        "firstName": 'solr'
        "lastName": 'hadoop'
        "emailAddress": 'solr@hadoop.ryba'
        'userSource': 1
        'userRoleList': ['ROLE_USER']
        'groups': []
        'status': 1

## Configure Ranger Enabled Solr Cloud Docker Cluster
The ranger plugin is installed on the docker host machine.
A Ranger Service Repo is created for each cluster.
The configuration of the plugin is specific for each cluster.
The configuration of each cluster is enriched with mount volumes to make Ranger
lib file available to solr process inside the container.

      options.service_repos ?= {}
      options.solr_plugins ?= {}
      for name, cluster_config of service.use.solr_cloud_docker.options.clusters
        for host, config of cluster_config.config_hosts
          config.security["authorization"] ?= {}
          config.security["authorization"]['class'] = 'org.apache.ranger.authorization.solr.authorizer.RangerSolrAuthorizer'
        # Service Repo Definition
        options.service_repos[name] ?=
            'description': "Ranger plugin #{name} cluster"
            'isEnabled': true
            'name': name
            'type': 'solr'
            'configs':
              'solr.url': cluster_config.solr_urls
              # should match the name mapped after the solr admin principal
              'policy.download.auth.users': "#{options.solr_user.name}" #from ranger 0.6
              'tag.download.auth.users': "#{options.solr_user.name}"
        if cluster_config.authentication_class isnt 'org.apache.solr.security.KerberosPlugin'
        then throw Error 'Ranger Solr Plugin does only support Kerberized solr cluster'
        #cluster_config.admin_principal
        #cluster_config.admin_password
        options.service_repos[name]['configs']['username'] ?= options.solr_user.name
        options.service_repos[name]['configs']['password'] ?= options.solr_user.name

## Service Repo Configuration

        options.solr_plugins[name] ?= {}
        options.solr_plugins[name].audit ?= {}
        options.solr_plugins[name].install ?= {}
        options.solr_plugins[name].install['REPOSITORY_NAME'] ?= name
        options.solr_plugins[name].install['PYTHON_COMMAND_INVOKER'] ?= 'python'
        options.solr_plugins[name].install['CUSTOM_USER'] ?= "#{options.solr_user.name}"
        options.solr_plugins[name].install['POLICY_MGR_URL'] ?= service.use.ranger_admin.options.install['policymgr_external_url']
        options.solr_plugins[name].install['COMPONENT_INSTALL_DIR_NAME'] ?= "#{options.conf_dir}/clusters/#{name}/server"
        options.solr_plugins[name].data_dir ?= cluster_config.data_dir

## HDFs Audit

        options.solr_plugins[name].install['XAAUDIT.HDFS.IS_ENABLED'] ?= 'true'
        if options.solr_plugins[name].install['XAAUDIT.HDFS.IS_ENABLED'] is 'true'
          # migration: lucasbak 11102017
          # honored but not used by plugin
          # options.solr_plugins[name].install['XAAUDIT.HDFS.LOCAL_BUFFER_DIRECTORY'] ?= "#{service.use.ranger_admin.options.conf_dir}/%app-type%/audit"
          # options.solr_plugins[name].install['XAAUDIT.HDFS.LOCAL_ARCHIVE_DIRECTORY'] ?= "#{service.use.ranger_admin.options.conf_dir}/%app-type%/archive"
          options.solr_plugins[name].install['XAAUDIT.SUMMARY.ENABLE'] ?= 'true'
          # AUDIT TO HDFS
          options.solr_plugins[name].install['XAAUDIT.HDFS.ENABLE'] ?= 'true'
          options.solr_plugins[name].install['XAAUDIT.HDFS.HDFS_DIR'] ?= "#{service.use.hdfs_client.options.core_site['fs.defaultFS']}/#{options.user.name}/audit/#{name}/"
          options.solr_plugins[name].install['XAAUDIT.HDFS.FILE_SPOOL_DIR'] ?= "#{cluster_config.log_dir}/audit/hdfs/spool"
          options.solr_plugins[name].install['XAAUDIT.HDFS.DESTINATION_DIRECTORY'] ?= "#{service.use.hdfs_client.options.core_site['fs.defaultFS']}/#{options.user.name}/audit/%app-type%/%time:yyyyMMdd%"
          options.solr_plugins[name].install['XAAUDIT.HDFS.DESTINATION_FILE'] ?= '%hostname%-audit.log'
          options.solr_plugins[name].install['XAAUDIT.HDFS.FILE_SPOOL_DIR'] ?= "#{cluster_config.log_dir}/audit/hdfs/spool"
          options.solr_plugins[name].install['XAAUDIT.HDFS.LOCAL_BUFFER_DIRECTORY'] ?= "#{cluster_config.log_dir}/ranger/%app-type%/audit"
          options.solr_plugins[name].install['XAAUDIT.HDFS.LOCAL_ARCHIVE_DIRECTORY'] ?= "#{cluster_config.log_dir}/ranger/%app-type%/archive"
          options.solr_plugins[name].install['XAAUDIT.HDFS.DESTINATION_FILE'] ?= '%hostname%-audit.log'
          options.solr_plugins[name].install['XAAUDIT.HDFS.DESTINATION_FLUSH_INTERVAL_SECONDS'] ?= '900'
          options.solr_plugins[name].install['XAAUDIT.HDFS.DESTINATION_ROLLOVER_INTERVAL_SECONDS'] ?= '86400'
          options.solr_plugins[name].install['XAAUDIT.HDFS.DESTINATION _OPEN_RETRY_INTERVAL_SECONDS'] ?= '60'
          options.solr_plugins[name].install['XAAUDIT.HDFS.LOCAL_BUFFER_FILE'] ?= '%time:yyyyMMdd-HHmm.ss%.log'
          options.solr_plugins[name].install['XAAUDIT.HDFS.LOCAL_BUFFER_FLUSH_INTERVAL_SECONDS'] ?= '60'
          options.solr_plugins[name].install['XAAUDIT.HDFS.LOCAL_BUFFER_ROLLOVER_INTERVAL_SECONDS'] ?= '600'
          options.solr_plugins[name].install['XAAUDIT.HDFS.LOCAL_ARCHIVE _MAX_FILE_COUNT'] ?= '5'
          options.solr_plugins[name].policy_hdfs_audit =
            name: "solr-ranger-plugin-audit-#{name}"
            service: "#{options.hdfs_install['REPOSITORY_NAME']}"
            repositoryType: 'hdfs'
            description: "Solr Plugin cluster #{name}"
            isEnabled: true
            isAuditEnabled: true
            resources:
              path:
                isRecursive: 'true'
                values: [options.solr_plugins[name].install['XAAUDIT.HDFS.HDFS_DIR']]
                isExcludes: false
            policyItems: [{
              users: ["#{options.solr_user.name}"]
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

### Solr Audit (database storage)

        #Deprecated
        options.solr_plugins[name].install['XAAUDIT.DB.IS_ENABLED'] ?= 'false'
        if options.solr_plugins[name].install['XAAUDIT.DB.IS_ENABLED'] is 'true'
          options.solr_plugins[name].install['XAAUDIT.DB.FLAVOUR'] ?= 'MYSQL'
          switch options.solr_plugins[name].install['XAAUDIT.DB.FLAVOUR']
            when 'MYSQL'
              options.solr_plugins[name].install['SQL_CONNECTOR_JAR'] ?= '/usr/share/java/mysql-connector-java.jar'
              options.solr_plugins[name].install['XAAUDIT.DB.HOSTNAME'] ?= options.ranger_admin.options.install['db_host']
              options.solr_plugins[name].install['XAAUDIT.DB.DATABASE_NAME'] ?= options.ranger_admin.options.install['audit_db_name']
              options.solr_plugins[name].install['XAAUDIT.DB.USER_NAME'] ?= options.ranger_admin.options.install['audit_db_user']
              options.solr_plugins[name].install['XAAUDIT.DB.PASSWORD'] ?= options.ranger_admin.options.install['audit_db_password']
            when 'ORACLE'
              throw Error 'Ryba does not support ORACLE Based Ranger Installation'
            else
              throw Error "Apache Ranger does not support chosen DB FLAVOUR"
        else
          options.solr_plugins[name].install['XAAUDIT.DB.HOSTNAME'] ?= 'NONE'
          options.solr_plugins[name].install['XAAUDIT.DB.DATABASE_NAME'] ?= 'NONE'
          options.solr_plugins[name].install['XAAUDIT.DB.USER_NAME'] ?= 'NONE'
          options.solr_plugins[name].install['XAAUDIT.DB.PASSWORD'] ?= 'NONE'

### Solr Audit (to SOLR)
Note, when using `ryba/solr/cloud_docker` with version > 6.0.0, the ranger-solr-plugin
doest not work properly, because the plugin load 6+ version class when instantiating
its utility class.
Inded until now (hdp 2.5.3.0), ranger plugin is base on HDP' solr version which is
5.5.0

        if options.ranger_admin.options.install['audit_store'] is 'solr'
          options.solr_plugins[name].audit ?= {}
          options.solr_plugins[name].install['XAAUDIT.SOLR.IS_ENABLED'] ?= 'false'
          options.solr_plugins[name].install['XAAUDIT.SOLR.ENABLE'] ?= 'false'
          options.solr_plugins[name].install['XAAUDIT.SOLR.URL'] ?= options.ranger_admin.options.install['audit_solr_urls']
          options.solr_plugins[name].install['XAAUDIT.SOLR.USER'] ?= options.ranger_admin.options.install['audit_solr_user']
          options.solr_plugins[name].install['XAAUDIT.SOLR.ZOOKEEPER'] ?= options.ranger_admin.options.install['audit_solr_zookeepers']
          options.solr_plugins[name].install['XAAUDIT.SOLR.PASSWORD'] ?= options.ranger_admin.options.install['audit_solr_password']
          options.solr_plugins[name].install['XAAUDIT.SOLR.FILE_SPOOL_DIR'] ?= "#{cluster_config.log_dir}/ranger/audit/solr/spool"
          options.solr_plugins[name].audit['xasecure.audit.destination.solr.force.use.inmemory.jaas.config'] ?= 'true'
          options.solr_plugins[name].audit['xasecure.audit.jaas.inmemory.loginModuleName'] ?= 'com.sun.security.auth.module.Krb5LoginModule'
          options.solr_plugins[name].audit['xasecure.audit.jaas.inmemory.loginModuleControlFlag'] ?= 'required'
          options.solr_plugins[name].audit['xasecure.audit.jaas.inmemory.Client.option.useKeyTab'] ?= 'true'
          options.solr_plugins[name].audit['xasecure.audit.jaas.inmemory.Client.option.debug'] ?= 'true'
          options.solr_plugins[name].audit['xasecure.audit.jaas.inmemory.Client.option.doNotPrompt'] ?= 'yes'
          options.solr_plugins[name].audit['xasecure.audit.jaas.inmemory.Client.option.storeKey'] ?= 'yes'
          options.solr_plugins[name].audit['xasecure.audit.jaas.inmemory.Client.option.serviceName'] ?= 'solr'
          solr_princ = cluster_config.config_hosts[service.node.fqdn].auth_opts['solr.kerberos.principal'].replace '_HOST', service.node.fqdn
          options.solr_plugins[name].audit['xasecure.audit.jaas.inmemory.Client.option.principal'] ?= solr_princ
          options.solr_plugins[name].audit['xasecure.audit.jaas.inmemory.Client.option.keyTab'] ?= cluster_config.config_hosts[service.node.fqdn].auth_opts['solr.kerberos.keytab']

### Solr Plugin SSL
Used only if SSL is enabled between Policy Admin Tool and Plugin

        
        if options.ranger_admin.options.site['ranger.service.https.attrib.ssl.enabled'] is 'true'
          options.solr_plugins[name].install['SSL_KEYSTORE_FILE_PATH'] ?= service.use.hadoop_core.options.ssl_server['ssl.server.keystore.location']
          options.solr_plugins[name].install['SSL_KEYSTORE_PASSWORD'] ?= service.use.hadoop_core.options.ssl_server['ssl.server.keystore.password']
          options.solr_plugins[name].install['SSL_TRUSTSTORE_FILE_PATH'] ?= service.use.hadoop_core.options.ssl_client['ssl.client.truststore.location']
          options.solr_plugins[name].install['SSL_TRUSTSTORE_PASSWORD'] ?= service.use.hadoop_core.options.ssl_client['ssl.client.truststore.password']
          # migration: lucasbak 25102017
          # use solr cluster config
          # options.solr_plugins[name].install['SSL_KEYSTORE_FILE_PATH'] ?= cluster_config.env['SOLR_SSL_KEY_STORE']
          # options.solr_plugins[name].install['SSL_KEYSTORE_PASSWORD'] ?= cluster_config.env['SOLR_SSL_KEY_STORE_PASSWORD']
          # options.solr_plugins[name].install['SSL_TRUSTSTORE_FILE_PATH'] ?= cluster_config.env['SOLR_SSL_TRUST_STORE']
          # options.solr_plugins[name].install['SSL_TRUSTSTORE_PASSWORD'] ?= cluster_config.env['SOLR_SSL_TRUST_STORE_PASSWORD']

## Docker Specific Configuration
The ranger-solr-plugin is installed on the host machine, and mounted by containers
which does need it.

        mounts = [
          "/etc/ranger/#{options.solr_plugins[name].install['REPOSITORY_NAME']}:/etc/ranger/#{options.solr_plugins[name].install['REPOSITORY_NAME']}"
          '/etc/hadoop/conf:/etc/hadoop/conf'
          "#{cluster_config.conf_dir}/server/solr-webapp/webapp/WEB-INF/classes:/usr/solr-cloud/current/server/solr-webapp/webapp/WEB-INF/classes"
          '/usr/hdp:/usr/hdp'
          ]
        for name, srv of cluster_config.service_def
          for mount in mounts
            srv.volumes.push mount unless srv.volumes.indexOf(mount) isnt -1

## Wait

      options.wait_ranger_admin = service.use.ranger_admin.options.wait

## Dependencies

    {merge} = require 'nikita/lib/misc'
    migration = require 'masson/lib/migration'

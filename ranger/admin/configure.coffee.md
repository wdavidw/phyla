
## Configure
This modules configures every hadoop plugin needed to enable Ranger. It configures
variables but also inject some function to be executed.

    module.exports = ->
      service = migration.call @, service, 'ryba/hadoop/hdfs_jn', ['ryba', 'hdfs', 'jn'], require('nikita/lib/misc').merge require('.').use,
        iptables: key: ['iptables']
        krb5_client: key: ['krb5_client']
        java: key: ['java']
        mysql_client: key: ['mysql']
        db_admin: key: ['ryba', 'db_admin']
        hadoop_core: key: ['ryba']
        solr_cloud_docker: key: ['ryba', 'solr', 'cloud_docker']
        solr_cloud: key: ['ryba', 'solr', 'cloud']
        solr_standalone: key: ['ryba', 'solr', 'single']    
      @config.ryba.ranger ?= {}
      options = @config.ryba.ranger.admin ?= service.options

# Ranger user & group

      # Group
      options.group ?= {}
      options.group = name: options.group if typeof options.group is 'string'
      options.group.name ?= 'ranger'
      options.group.system ?= true
      # User
      options.user ?= {}
      options.user = name: options.user if typeof options.user is 'string'
      options.user.name ?= 'ranger'
      options.user.system ?= true
      options.user.comment ?= 'Ranger User'
      options.user.home ?= "/var/lib/#{options.user.name}"
      options.user.gid ?= options.group.name
      options.user.groups ?= 'hadoop'
      
## Environment
      
      # Layout
      options.conf_dir ?= '/etc/ranger/admin/conf'
      options.pid_dir ?= '/var/run/ranger/admin'
      options.log_dir ?= '/var/log/ranger/admin'
      # Misc
      options.clean_logs ?= false
      options.iptables ?= service.use.iptables and service.use.iptables.options.action is 'start'

## Kerberos

      options.krb5 ?= {}
      options.krb5.enabled ?= service.use.hadoop_core.options.core_site['hadoop.security.authentication'] is 'kerberos'
      options.krb5.realm ?= service.use.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      # Admin Information
      options.krb5.admin = service.use.krb5_client.options.admin[options.krb5.realm]

## SSL

      options.ssl = merge options.ssl or {}, service.use.hadoop_core.options.ssl

## Log4j

      options.log4j ?= {}
      options.log4j['log4j.logger.xaaudit.org.apache.ranger.audit.provider.Log4jAuditProvider'] = 'INFO, hdfsAppender'
      options.log4j['log4j.appender.hdfsAppender'] = 'org.apache.log4j.HdfsRollingFileAppender'
      options.log4j['log4j.appender.hdfsAppender.hdfsDestinationDirectory'] = 'hdfs://%hostname%:8020/logs/application/%file-open-time:yyyyMMdd%'
      options.log4j['log4j.appender.hdfsAppender.hdfsDestinationFile'] = '%hostname%-audit.log'
      options.log4j['log4j.appender.hdfsAppender.hdfsDestinationRolloverIntervalSeconds'] = '86400'
      options.log4j['log4j.appender.hdfsAppender.localFileBufferDirectory'] = '/tmp/logs/application/%hostname%'
      options.log4j['log4j.appender.hdfsAppender.localFileBufferFile'] = '%file-open-time:yyyyMMdd-HHmm.ss%.log'
      options.log4j['log4j.appender.hdfsAppender.localFileBufferRolloverIntervalSeconds'] = '15'
      options.log4j['log4j.appender.hdfsAppender.localFileBufferArchiveDirectory'] = '/tmp/logs/archive/application/%hostname%'
      options.log4j['log4j.appender.hdfsAppender.localFileBufferArchiveFileCount'] = '12'
      options.log4j['log4j.appender.hdfsAppender.layout'] = 'org.apache.log4j.PatternLayout'
      options.log4j['log4j.appender.hdfsAppender.layout.ConversionPattern'] = '%d{yy/MM/dd HH:mm:ss} [%t]: %p %c{2}: %m%n'
      options.log4j['log4j.appender.hdfsAppender.encoding'] = 'UTF-8'

# Ranger xusers
Ranger eanble to create users with its REST API. Required user can be specified in the
ranger config and ryba will create them.
User can be External and Internal. Only Internal users can be created from the ranger webui.

      # Ranger Manager Users
      # Dictionnary containing as a key the name of the ranger admin webui users
      # and value and user properties.
      options.users ?= {}
      options.users['ryba'] ?=
        "name": 'ryba'
        "firstName": 'ryba'
        "lastName": 'hadoop'
        "emailAddress": 'ryba@hadoop.ryba'
        "password": 'ryba123'
        'userSource': 1
        'userRoleList': ['ROLE_USER']
        'groups': []
        'status': 1
      options.lock = "/etc/ranger/#{Date.now()}"
      # Ranger Admin configuration
      options.current_password ?= 'admin'
      options.password ?= 'rangerAdmin123'
      if not (/^.*[a-zA-Z]/.test(options.password) and /^.*[0-9]/.test(options.password) and options.password.length > 8)
       throw Error "new passord's length must be > 8, must contain one alpha and numerical character at lest"
      options.conf_dir ?= '/etc/ranger/admin'
      options.site ?= {}
      options.site['ranger.service.http.port'] ?= '6080'
      options.site['ranger.service.https.port'] ?= '6182'
      options.install ?= {}
      options.install['PYTHON_COMMAND_INVOKER'] ?= 'python'
      # Needed starting from 2.5 version to not have problem during setup execution
      options.install['hadoop_conf'] ?= "#{service.use.hadoop_core.options.hadoop_conf_dir}"
      options.install['RANGER_ADMIN_LOG_DIR'] ?= "#{options.log_dir}"

# Kerberos
[Starting from 2.5][ranger-upgrade-24-25], Ranger supports Kerberos Authentication for secured cluster

      if options.krb5.enabled
        options.install['spnego_principal'] ?= "HTTP/#{service.node.fqdn}@#{options.krb5.realm}"
        options.install['spnego_keytab'] ?= '/etc/security/keytabs/spnego.service.keytab'
        options.install['token_valid'] ?= '30'
        options.install['cookie_domain'] ?= "#{service.node.fqdn}"
        options.install['cookie_path'] ?= '/'
        options.install['admin_principal'] ?= "rangeradmin/#{service.node.fqdn}@#{options.krb5.realm}"
        options.install['admin_keytab'] ?= '/etc/security/keytabs/ranger.admin.service.keytab'
        options.install['lookup_principal'] ?= "rangerlookup/#{service.node.fqdn}@#{options.krb5.realm}"
        options.install['lookup_keytab'] ?= "/etc/security/keytabs/ranger.lookup.service.keytab"
        if options.solr_type in ['cloud','cloud_docker']
          #Configuring in memory jaas property for ranger to sol
          options.site['xasecure.audit.destination.solr.force.use.inmemory.jaas.config'] ?= 'true'
          options.site['xasecure.audit.jaas.inmemory.loginModuleName'] ?= 'com.sun.security.auth.module.Krb5LoginModule'
          options.site['xasecure.audit.jaas.inmemory.loginModuleControlFlag'] ?= 'required'
          options.site['xasecure.audit.jaas.inmemory.Client.option.useKeyTab'] ?= 'true'
          options.site['xasecure.audit.jaas.inmemory.Client.option.debug'] ?= 'true'
          options.site['xasecure.audit.jaas.inmemory.Client.option.doNotPrompt'] ?= 'yes'
          options.site['xasecure.audit.jaas.inmemory.Client.option.storeKey'] ?= 'yes'
          options.site['xasecure.audit.jaas.inmemory.Client.option.serviceName'] ?= 'solr'
          options.site['xasecure.audit.jaas.inmemory.Client.option.keyTab'] ?= options.install['admin_keytab']
          options.site['xasecure.audit.jaas.inmemory.Client.option.principal'] ?= options.install['admin_principal']

# Audit Storage
Ranger can store  audit to different storage type.
- HDFS ( Long term and scalable storage)
- SOLR ( short term storage & Ranger WEBUi)
- DB Flavor ( mid term storage & Ranger WEBUi)
We do not advice to use DB Storage as it is not efficient to query when it grows up.
Hortonworks recommandations are to enable SOLR and HDFS Storage.

      options.install['audit_store'] ?= 'solr'

## Solr Audit Configuration
Here SOLR configuration is discovered and ranger admin is set up.

Ryba support both Solr Cloud mode and Solr Standalone installation. 

The `solr_type` option designates the type of solr service (ie standalone, embedded, cloud, cloud indocker)
used for Ranger.
The type requires differents instructions/configuration for ranger plugin audit to work.
- Solr Standalone `ryba/solr/standalone`
  Ryba default. You need to set `ryba/solr/standalone` on one host.
- Solr Standalone embedded
  No need to have `ryba/solr/standalone` on one host, Solr will be installed on the same host as Ranger Admin.
  Change property `solr_type` to `embedded` to use it.
- Solr Cloud `ryba/solr/cloud`
  Changes  property `solr_type` to `cloud` and deploy `ryba/solr/cloud`
  module on at least one host.
- Solr Cloud on docker `ryba/solr/cloud_docker`
  Changes  property `solr_type` to `cloud_docker`.
  Important:
    For this to work you need to deploy `ryba/solr/cloud_docker` module on at least on host.
    AND you also need to setup a solr cluster in your configuration, for ryba being able to configure
      ranger with this cluster. 
    Ryba configures Ranger by using one of the cluster available
    You can configure it by using `config.ryba.solr.cloud_docker.clusters` property.
    Ryba will search by default for an instance named `ranger_cluster` which is set
    by the property `cluster_name`.
    An example is available in [the ryba-cluster config file][ryba-cluster-conf].

Note July 2016:
The previous properties works only with (HDP 2.4) `solr.BasicAuthPlugin` (in solr cluster config).
And it is configured by Ryba only in ryba/solr/cloud_docker installation.

If no `ryba/solr/*` is configured Ranger admin deploys a `ryba/solr/standalone` 
on the same host than `ryba/ranger/admin` module.

## Example

To use the embedded Solr mode, configure ranger-admin as follows:

```json
{ "ranger": {
    "admin": {
      "solr_type": "embedded"
    }
} }
```

If you have configured a Solr Cloud Docker in your cluster, you can configure like this:

```json
{ "ranger": {
    "admin": {
      "solr_type": "cloud_docker"
    }
} }
```

      options.solr_type ?= 'embedded'
      # solr = {}
      solrs_urls = ''
      # solr_ctx = {}
      # Retention period in day to keep audit logs
      options.audit_retention_period ?= '1095' #value in days. default to 3 years.
      options.retention ?=  "+#{options.audit_retention_period}"
      switch options.solr_type
        when 'single'
          throw Error 'No Solr Standalone Server configured' unless service.use.solr_standalone
          options.install['audit_solr_port'] ?= service.use.solr_standalone[0].options.port
          options.install['audit_solr_zookeepers'] ?= 'NONE'
          solrs_urls = service.use.solr_standalone.map( (srv) -> 
           "#{if srv.options.ssl.enabled then 'https://' else 'http://'}#{srv.node.fqdn}:#{srv.options.port}")
          .map (url) -> "#{url}/solr/ranger_audits"
          .join ','
          # TODO: migration can't handle this for now
          if @params.command is 'install'
            st_ctxs = @contexts 'ryba/solr/standalone'
            st_ctxs[0]
            .after
              type: ['java','keystore_add']
              keystore: solr_ctx[0].config.ryba.solr["#{options.solr_type}"]['ssl_trustore_path']
              storepass: solr_ctx[0].config.ryba.solr["#{options.solr_type}"]['ssl_keystore_pwd']
              caname: "hadoop_root_ca"
            , -> @call 'ryba/ranger/admin/solr_bootstrap'
          break;
        when 'embedded'
          options.solr ?= {}
          options.solr.group ?= {}
          options.solr.group = name: options.solr.group if typeof options.solr.group is 'string'
          options.solr.group.name ?= 'solr'
          options.solr.group.system ?= true
          options.solr.user ?= {}
          options.solr.user = name: options.solr.user if typeof options.solr.user is 'string'
          options.solr.user.name ?= 'solr'
          options.solr.user.gid ?= options.solr.group.name
          options.solr.user.home ?= "/var/lib/#{options.solr.user.name}"
          options.solr.user.system ?= true
          options.solr.user.comment ?= 'Solr User'
          options.solr.user.groups ?= 'hadoop'
          options.solr.fqdn = service.node.fqdn
          options.solr.version ?= '5.5.2'
          options.solr.root_dir ?= '/usr'
          options.solr.install_dir ?= "#{options.solr.root_dir}/solr/#{options.solr.version}"
          options.solr.latest_dir = '/opt/lucidworks-hdpsearch/solr'
          options.solr.pid_dir ?= '/var/run/solr'
          options.solr.log_dir ?= '/var/log/solr'
          options.solr.conf_dir ?= '/etc/solr/conf'
          options.solr.env ?= {}
          options.solr.dir_factory ?= "${solr.directoryFactory:solr.NRTCachingDirectoryFactory}"
          options.solr.lock_type = 'native'
          options.solr.conf_source = "#{__dirname}/../resources/solr/solr_5.xml.j2"
          if options.krb5.enabled
            options.solr.principal ?= "#{options.solr.user.name}/#{service.node.fqdn}@#{options.krb5.realm}"
            options.solr.keytab ?= '/etc/security/keytabs/solr.service.keytab'
          options.solr.ssl = merge options.solr.ssl or {}, service.use.hadoop_core.options.ssl
          options.solr.port ?= if options.solr.ssl.enabled then 9983 else 8983
          options.solr.ssl_trustore_path ?= "#{options.solr.conf_dir}/trustore"
          options.solr.ssl_trustore_pwd ?= 'solr123'
          options.solr.ssl_keystore_path ?= "#{options.solr.conf_dir}/keystore"
          options.solr.ssl_keystore_pwd ?= 'solr123'
          options.solr.env['SOLR_JAVA_HOME'] ?= service.use.java.options.java_home
          options.solr.env['SOLR_HOST'] ?= service.node.fqdn
          options.solr.env['SOLR_HEAP'] ?= "512m"
          options.solr.env['SOLR_PORT'] ?= "#{options.solr.port}"
          options.solr.env['ENABLE_REMOTE_JMX_OPTS'] ?= 'false'
          if options.solr.ssl.enabled
            options.solr.env['SOLR_SSL_KEY_STORE'] ?= options.solr.ssl_keystore_path
            options.solr.env['SOLR_SSL_KEY_STORE_PASSWORD'] ?= options.solr.ssl_keystore_pwd
            options.solr.env['SOLR_SSL_TRUST_STORE'] ?= options.solr.ssl_trustore_path
            options.solr.env['SOLR_SSL_TRUST_STORE_PASSWORD'] ?= options.solr.ssl_trustore_pwd
            options.solr.env['SOLR_SSL_NEED_CLIENT_AUTH'] ?= 'false'
          options.solr.jre_home ?= service.use.java.options.jre_home
          solrs_urls = "#{if options.solr.ssl.enabled then 'https://' else 'http://'}#{service.node.fqdn}:#{options.solr.port}/solr/ranger_audits"
          options.install['audit_solr_zookeepers'] ?= 'NONE'
        when 'cloud'
          throw Error 'No Solr Docker Server configured' unless service.use.solr_cloud
          solr = sc_ctxs[0].config.ryba.solr
          options.install['audit_solr_port'] ?= service.use.solr_cloud[0].options.port
          solrs_urls = service.use.solr_cloud.map( (srv) ->
            "#{if srv.options.ssl.enabled then 'https://' else 'http://'}#{srv.node.fqdn}:#{srv.options.port}")
          # .map( (url) -> if options.solr_type is 'single' then "#{url}/solr/ranger_audits" else "#{url}")
          .join(',')
          options.install['audit_solr_zookeepers'] ?= service.use.solr_cloud[0].options.zkhosts
          # TODO: migration can't handle this for now
          if @params.command is 'install'
            sc_ctxs = @contexts 'ryba/solr/cloud'
            solr_ctx[0]
            .after
              type: ['service','start']
              name: 'solr'
            , -> @call 'ryba/ranger/admin/solr_bootstrap'
          break;
        when 'cloud_docker'
          throw Error 'No Solr Cloud Docker Server configured' unless service.use.solr_cloud_docker or options.cluster_name
          # scd_ctxs = @contexts 'ryba/solr/cloud_docker'
          # options.cluster_name ?= 'ranger_cluster'
          # options.solr_admin_user ?= 'solr'
          # options.solr_admin_password ?= 'SolrRocks' #Default
          # options.solr_users ?= [
          #   name: 'ranger'
          #   secret: 'ranger123'
          # ]
          # # Get Solr Method Configuration
          # solr_clusterize = require '../../solr/cloud_docker/clusterize'
          # # {solr} = scd_ctxs[0].config.ryba
          # # solr.cloud_docker.clusters ?= {}
          # {solr} = @config.ryba ?= {}
          # solr.cloud_docker ?= {}
          # solr.cloud_docker.clusters ?= {}
          # cluster_config = options.cluster_config = solr.cloud_docker.clusters[options.cluster_name] ?= {}
          # cluster_config.rangerEnabled = false
          # for solr_ctx in scd_ctxs
          #   solr = solr_ctx.config.ryba.solr ?= {}
          #   # By default Ryba search for a solr cloud cluster named ranger_cluster in config
          #   # Configures one cluster if not in config
          #   solr.cloud_docker.clusters ?= {}
          #   cluster_config  = solr.cloud_docker.clusters[options.cluster_name] ?= {}
          #   cluster_config.rangerEnabled = false
          #   cluster_config.volumes ?= []
          #   cluster_config.volumes.push '/tmp/ranger_audits:/ranger_audits'
          #   cluster_config['containers'] ?= scd_ctxs.length
          #   cluster_config['master'] ?= scd_ctxs[0].config.host
          #   cluster_config['heap_size'] ?= '256m'
          #   cluster_config['port'] ?= 10000
          #   cluster_config.zk_opts ?= {}
          #   cluster_config['hosts'] ?= scd_ctxs.map (ctx) -> ctx.config.host
          #   solr_clusterize solr_ctx , options.cluster_name, cluster_config
          # # Search for a cloud_docker cluster find in solr.cloud_docker.clusters
          # options.cluster_config = scd_ctxs.filter( (ctx) -> 
          #   ctx.config.host is cluster_config['master']
          # ).pop().config.ryba.solr.cloud_docker.clusters[options.cluster_name]
          # if @params.command is 'install'
          #   for ctx in scd_ctxs
          #     if cluster_config['master'] is ctx.config.host
          #       ctx
          #       .after
          #         type: ['docker','compose','up']
          #         target: "#{solr.cloud_docker.conf_dir}/clusters/#{options.cluster_name}/docker-compose.yml"
          #       , -> @call 'ryba/ranger/admin/solr_bootstrap'
          # options.install['audit_solr_port'] ?= options.cluster_config.port
          # options.cluster_config['ranger'] ?= {}
          # if scd_ctxs.length > 0
          #   options.install['audit_solr_zookeepers'] ?= "#{scd_ctxs[0].config.ryba.solr.cloud_docker.zk_connect}/solr_#{options.cluster_name}"
          # else
          #   options.install['audit_solr_zookeepers'] ?= 'NONE'
          # solrs_urls = options.cluster_config.hosts.map( (host) ->
          #  "#{if cluster_config.is_ssl_enabled  then 'https://' else 'http://'}#{host}:#{options.cluster_config.port}/solr/ranger_audits").join(',')
          break;

## Solr Audit Database Bootstrap
Create the `ranger_audits` collection('cloud')/core('standalone').

      if options.install['audit_store'] is 'solr'
        options.install['audit_solr_urls'] ?= solrs_urls
        options.install['audit_solr_user'] ?= 'ranger'
        options.install['audit_solr_password'] ?= 'ranger123'
        # options.install['audit_solr_zookeepers'] = 'NONE'

When Basic authentication is used, the following property can be set to add 
users to solr `cluster_config.ranger.solr_users`:
  -  An object describing all the users used by the different plugins which will
  write audit to solr.
  - By default if no user are provided, Ryba configure only one user named ranger
  to audit to solr.

Example:

```cson
ranger.admin.cluster_config.ranger.solr_users =
  name: 'my_plugin_user'
  secret: 'my_plugin_password'
```

        options.solr_users ?= []
        if options.solr_users.length is 0
          options.solr_users.push {
            name: "#{options.install['audit_solr_user']}"
            secret:"#{options.install['audit_solr_password']}"
          }

## Ranger Admin SSL
Configure SSL for Ranger policymanager (webui).

      options.site['ranger.service.https.attrib.ssl.enabled'] ?= 'true'
      options.site['ranger.service.https.attrib.clientAuth'] ?= 'false'
      options.site['ranger.service.https.attrib.keystore.file'] ?= '/etc/ranger/admin/conf/keystore'
      options.site['ranger.service.https.attrib.keystore.pass'] ?= 'ryba123'
      options.site['ranger.service.https.attrib.keystore.keyalias'] ?= @config.shortname

# Ranger Admin Databases
Configures the Ranger WEBUi (policymanager) database. For now only mysql is supported.

      options.install['DB_FLAVOR'] ?= 'MYSQL' # we support only mysql for now
      switch options.install['DB_FLAVOR'].toLowerCase()
        when 'mysql'
          provider = service.use.db_admin.options.mysql
          throw Error "DB Provider Not Available: mysql" unless provider
          options.install['SQL_CONNECTOR_JAR'] ?= '/usr/hdp/current/ranger-admin/lib/mysql-connector-java.jar'
          # not setting these properties on purpose, we manage manually databases inside mysql
          options.install['db_root_user'] = provider.admin_username
          options.install['db_root_password'] ?= provider.admin_password
          if not options.install['db_root_user'] and not options.install['db_root_password']
          then throw Error "account with privileges for creating database schemas and users is required"
          options.install['db_host'] ?=  provider.host
          #Ranger Policy Database
          throw Error "mysql host not specified" unless options.install['db_host']
          options.install['db_name'] ?= 'ranger'
          options.install['db_user'] ?= 'rangeradmin'
          options.install['db_password'] ?= 'rangeradmin123'
          options.install['audit_db_name'] ?= 'ranger_audit'
          options.install['audit_db_user'] ?= 'rangerlogger'
          options.install['audit_db_password'] ?= 'rangerlogger123'
        else throw Error 'For now only mysql engine is supported'


# Ranger Admin Policymanager Access
Defined how Ranger authenticates users (the xusers)  to the webui. By default
only users created within the webui are allowed.

      protocol = if options.site['ranger.service.https.attrib.ssl.enabled'] == 'true' then 'https' else 'http'
      port = options.site["ranger.service.#{protocol}.port"]
      options.install['policymgr_external_url'] ?= "#{protocol}://#{service.node.fqdn}:#{port}"
      options.install['policymgr_http_enabled'] ?= 'true'
      options.install['unix_user'] ?= options.user.name
      options.install['unix_group'] ?= options.group.name
      #Policy Admin Tool Authentication
      # NONE enables only users created within the Policy Admin Tool 
      options.install['authentication_method'] ?= 'NONE'
      unix_props = ['remoteLoginEnabled','authServiceHostName','authServicePort']
      ldap_props = ['xa_ldap_url','xa_ldap_userDNpattern','xa_ldap_groupSearchBase',
      'xa_ldap_groupSearchFilter','xa_ldap_groupRoleAttribute']
      active_dir_props = ['xa_ldap_ad_domain','xa_ldap_ad_url']
      switch options.install['authentication_method']
        when 'UNIX'
          throw Error "missing property: #{prop}" unless options.install[prop] for prop in unix_props
        when 'LDAP'
          if !options.install['xa_ldap_url']
            [opldp_srv_ctx] = @contexts 'masson/core/openldap_server'
            throw Error 'no openldap server configured' unless opldp_srv_ctx?
            {openldap_server} = opldp_srv_ctx.config
            options.install['xa_ldap_url'] ?= "#{openldap_server.uri}"
            options.install['xa_ldap_userDNpattern'] ?= "cn={0},ou=users,#{openldap_server.suffix}"
            options.install['xa_ldap_groupSearchBase'] ?=  "ou=groups,#{openldap_server.suffix}"
            options.install['xa_ldap_groupSearchFilter'] ?= "(uid={0},ou=groups,#{openldap_server.suffix})"
            options.install['xa_ldap_groupRoleAttribute'] ?= 'cn'
            options.install['xa_ldap_userSearchFilter'] ?= '(uid={0})'
            options.install['xa_ldap_base_dn'] ?= "#{openldap_server.suffix}"
            options.install['xa_ldap_bind_dn'] ?= "#{openldap_server.root_dn}"
            options.install['xa_ldap_bind_password'] ?= "#{openldap_server.root_password}"
          throw Error "missing property: #{prop}" unless options.install[prop] for prop in ldap_props
        when 'ACTIVE_DIRECTORY'
          throw Error "missing property: #{prop}" unless options.install[prop] for prop in active_dir_props
        when 'NONE'
          break;
        else
          throw Error 'selected authentication_method is not supported by Ranger'

## Ranger Environment

      options.heap_size ?= '256m'
      options.opts ?= {}
      # options.opts['javax.net.ssl.trustStore'] ?= '/etc/hadoop/conf/truststore'
      # options.opts['javax.net.ssl.trustStorePassword'] ?= 'ryba123'

## Ranger PLUGINS

Plugins are HDP Packages which once enabled, allow Ranger to manage ACL for services.
For now Ranger support policy management for:

- HDFS
- YARN
- HBASE
- KAFKA
- Hive 
- SOLR 

Plugins should be configured before the service is started and/or configured.
Ryba injects function to the different contexts.

      options.plugins ?= {}
      options.plugins.principal ?= "#{options.user.name}@#{options.krb5.realm}"
      options.plugins.password ?= 'ranger123'

## Wait

      options.wait_krb5_client = service.use.krb5_client.options.wait
      options.wait = {}
      options.wait.http = {}
      options.wait.http.username = 'admin'
      options.wait.http.password = options.password
      options.wait.http.url = "#{options.install['policymgr_external_url']}/service/users/1"

## Dependencies

    quote = require 'regexp-quote'
    migration = require 'masson/lib/migration'
    {merge} = require 'nikita/lib/misc'

[ranger-2.4.0]:(http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.4.0/bk_installing_manually_book/content/configure-the-ranger-policy-administration-authentication-moades.html)
[ranger-ssl]:(https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.4.0/bk_Security_Guide/content/configure_non_ambari_ranger_ssl.html) 
[ranger-ldap]:(https://community.hortonworks.com/articles/16696/ranger-ldap-integration.html)
[ranger-api-object]:(https://community.hortonworks.com/questions/10826/rest-api-url-to-configure-ranger-objects.html)
[ranger-solr]:(https://community.hortonworks.com/articles/15159/securing-solr-collections-with-ranger-kerberos.html)
[hdfs-repository]: (http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.4.0/bk_Ranger_User_Guide/content/hdfs_repository.html)
[hdfs-repository-0.4.1]:(https://cwiki.apache.org/confluence/display/RANGER/REST+APIs+for+Policy+Management?src=contextnavpagetreemode)
[user-guide-0.5]:(https://cwiki.apache.org/confluence/display/RANGER/Apache+Ranger+0.5+-+User+Guide)
[ryba-cluster-conf]: https://github.com/ryba-io/ryba-cluster/blob/master/conf/config.coffee
[ranger-upgrade-24-25]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.5.0/bk_command-line-upgrade/content/upgrade-ranger_24.html

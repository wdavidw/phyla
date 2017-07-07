
# Ambari Standalone Configuration

## Minimal Example

```json
{ "config": {
  "admin_password": "MySecret"
  "db": {
    "password": "MySecret"
  }
} }
```

## Database Encryption

```json
{ "config": {
  "master_key": "MySecret",
} }
```

## LDAP Connection

```json
{ "config": {
  "client.security": "ldap",
  "authentication.ldap.useSSL": true,
  "authentication.ldap.primaryUrl": "master3.ryba:636",
  "authentication.ldap.baseDn": "ou=users,dc=ryba",
  "authentication.ldap.bindAnonymously": false,
  "authentication.ldap.managerDn": "cn=admin,ou=users,dc=ryba",
  "authentication.ldap.managerPassword": "XXX",
  "authentication.ldap.usernameAttribute": "cn"
} }
```

    module.exports = ->
      # Dependencies
      [java_ctx] = @contexts('masson/commons/java').filter (ctx) => ctx.config.host is @config.host
      [pg_ctx] = @contexts 'masson/commons/postgres/server'
      [my_ctx] = @contexts 'masson/commons/mysql/server'
      [maria_ctx] = @contexts 'masson/commons/mariadb/server'
      [krb5_ctx] = @contexts 'masson/core/krb5_server'
      [hadoop_ctx] = @contexts 'ryba/hadoop/core'
      [o_ctx] = @contexts 'ryba/oozie/server'
      nn_ctxs = @contexts 'ryba/hadoop/hdfs_nn'
      yarn_ts_ctxs = @contexts 'ryba/hadoop/yarn_ts'
      yarn_rm_ctxs = @contexts 'ryba/hadoop/yarn_rm'
      hive_server2_ctxs = @contexts 'ryba/hive/server2'
      [ranger_ctx] = @contexts 'ryba/ranger/admin'
      @config.ryba ?= {}
      {host, ssl} = @config
      {db_admin} = @config.ryba
      # Init
      options = @config.ryba.ambari_standalone ?= {}
      throw Error "Required Option: db.password" unless options.db?.password

## Environnment

      options.fqdn = @config.host
      options.http ?= '/var/www/html'
      options.conf_dir ?= '/etc/ambari-server/conf'
      # options.database ?= {}
      # options.database.engine ?= @config.ryba.db_admin.engine
      # options.database.password ?= null
      options.sudo ?= false
      options.java_home ?= java_ctx.config.java.java_home
      options.master_key ?= null
      options.admin ?= {}
      options.current_admin_password ?= 'admin'
      throw Error "Required Option: admin_password" unless options.admin_password

## Identities

Note, there are no identities created by the Ambari package. Identities are only
used in case the server and its agents run as sudoers.

The non-root user you choose to run the Ambari Server should be part of the 
Hadoop group. The default group name is "hadoop".

      # Group
      options.group = name: options.group if typeof options.group is 'string'
      options.group ?= {}
      options.group.name ?= 'ambari'
      options.group.system ?= true
      options.hadoop_group ?= hadoop_ctx?.config.ryba.hadoop_group
      options.hadoop_group = name: options.group if typeof options.group is 'string'
      options.hadoop_group ?= {}
      options.hadoop_group.name ?= 'hadoop'
      options.hadoop_group.system ?= true
      options.hadoop_group.comment ?= 'Hadoop Group'
      # User
      options.user = name: options.user if typeof options.user is 'string'
      options.user ?= {}
      options.user.name ?= 'ambari'
      options.user.system ?= true
      options.user.comment ?= 'Ambari User'
      options.user.home ?= "/var/lib/#{options.user.name}"
      options.user.groups ?= ['hadoop']
      options.user.gid = options.group.name

## Ambari TLS and Truststore

      options.ssl ?= ssl
      options.truststore ?= {}
      if options.ssl
        throw Error "Required Option: ssl.cert" if  not options.ssl.cert
        throw Error "Required Option: ssl.key" if not options.ssl.key
        throw Error "Required Option: ssl.cacert" if not options.ssl.cacert
        options.truststore.target ?= "#{options.conf_dir}/truststore"
        throw Error "Required Property: truststore.password" if not options.truststore.password
        options.truststore.caname ?= 'hadoop_root_ca'
        options.truststore.type ?= 'jks'
        throw Error "Invalid Truststore Type: #{truststore.type}" unless options.truststore.type in ['jks', 'jceks', 'pkcs12']

## JAAS

Multiple ambari instance on a same server involve a different principal or the principal must point to the same keytab.

`auth=KERBEROS;proxyuser=ambari`

      options.jaas ?= {}
      options.jaas.enabled ?= false
      if options.jaas.enabled
        options.jaas.realm ?= hadoop_ctx?.config.ryba.realm
        options.jaas.realm ?= options.jaas.principal.split('@')[1] if options.jaas.principal
        throw Error "Require Property: jaas.realm or jaas.principal" unless options.jaas.realm
        # Masson 2 will require some adjustment in the way we discover the kerberos admin information
        krb5 = krb5_ctx.config.krb5_server.admin[options.jaas.realm]
        options.jaas.kadmin_principal ?= krb5.kadmin_principal
        throw Error "Require Property: jaas.kadmin_principal" unless options.jaas.kadmin_principal
        options.jaas.kadmin_password ?= krb5.kadmin_password
        throw Error "Require Property: jaas.kadmin_password" unless options.jaas.kadmin_password
        options.jaas.admin_server ?= krb5.admin_server
        throw Error "Require Property: jaas.admin_server" unless options.jaas.admin_server
        options.jaas.keytab ?= '/etc/ambari-server/conf/ambari.service.keytab'
        options.jaas.principal ?= "ambari/_HOST@#{hadoop_ctx?.config.ryba.realm}" if hadoop_ctx?.config.ryba.realm
        options.jaas.principal = options.jaas.principal.replace '_HOST', @config.host

## Configuration

      options.config ?= {}
      options.config['server.url_port'] ?= "8440"
      options.config['server.secured_url_port'] ?= "8441"
      options.config['api.ssl'] ?= unless options.ssl then 'false' else 'true'
      options.config['client.api.port'] ?= "8080"
      # Be Carefull, collision in HDP 2.5.3 on port 8443 between Ambari and Knox
      options.config['client.api.ssl.port'] ?= "8442"

## Database

Ambari DB password is stash into "/etc/ambari-server/conf/password.dat".

      options.supported_db_engines ?= ['mysql', 'mariadb', 'postgres']
      if pg_ctx then options.db.engine ?= 'postgres'
      else if maria_ctx then options.db.engine ?= 'mariadb'
      else if my_ctx then options.db.engine ?= 'mysql'
      else options.db.engine ?= 'derby'
      Error 'Unsupported database engine' unless options.db.engine in options.supported_db_engines
      options.db[k] ?= v for k, v of db_admin[options.db.engine]
      options.db.database ?= 'ambari'
      options.db.username ?= 'ambari'

## Ranger provisionning

      options.db_ranger ?= false
      options.db_ranger = password: options.db_ranger if typeof options.db_ranger is 'string'
      if options.db_ranger
        options.db_ranger.engine ?= options.db.engine
        options.db_ranger[k] ?= v for k, v of db_admin[options.db_ranger.engine]
        options.db_ranger.database ?= 'ranger'
        options.db_ranger.username ?= 'ranger'
        throw Error "Required Option: db_ranger.password" unless options.db_ranger.password

## Views

Configures Views to be used on the ambari server.
Note: The Install scripts are separated for clarity purposes.

### Files View Configuration
the files view correspond to the view of HDFS. For now Ryba does only configure HA enabled Namenodes
Note: Ambari hardcodes the masters's name, ie for example `master01` must be named `nn1`
        
      options.views ?= {}
      # variable used for changing install instruction for ambari/standalone
      options.views.enabled ?= false
      if options.views.enabled
        options.views.files ?= {}
        options.views.files.enabled ?= if nn_ctxs.length > 0 then true else false
        if options.views.files.enabled or options.views.hive.enabled
          options.views.enabled = true
          options.views.files.version ?= '1.0.0'
          throw Error 'Need Kerberos For ambari' if (@config.ryba.security is 'kerberos') and not options.jaas.enabled
          throw Error 'Need two namenodes' unless nn_ctxs.length is 2
          options.views.files.configuration ?= {}
          nn_site = nn_ctxs[0].config.ryba.hdfs.nn.site
          # Global configuration
          options.views.files.configuration['description'] ?=  "Files API"
          options.views.files.configuration['label'] ?=  "FILES View"
          # View Instance Properties
          props = options.views.files.configuration.properties ?= {}
          props['webhdfs.nameservices'] ?= nn_site['dfs.nameservices']
          props['webhdfs.ha.namenodes.list'] ?= 'nn1,nn2'
          nn_protocol = if nn_site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
          [nn1,nn2] = nn_site["dfs.ha.namenodes.#{props['webhdfs.nameservices']}"].split(',')
          props["webhdfs.ha.namenode.#{nn_protocol}-address.nn1"] ?= nn_site["dfs.namenode.#{nn_protocol}-address.#{props['webhdfs.nameservices']}.#{nn1}"]
          props["webhdfs.ha.namenode.#{nn_protocol}-address.nn2"] ?= nn_site["dfs.namenode.#{nn_protocol}-address.#{props['webhdfs.nameservices']}.#{nn2}"]
          props["webhdfs.ha.namenode.rpc-address.nn1"] ?= nn_site["dfs.namenode.rpc-address.#{props['webhdfs.nameservices']}.#{nn1}"]
          props["webhdfs.ha.namenode.rpc-address.nn2"] ?= nn_site["dfs.namenode.rpc-address.#{props['webhdfs.nameservices']}.#{nn2}"]
          # set class as ha automatic failover
          props['webhdfs.client.failover.proxy.provider'] ?= 'org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider'
          props['webhdfs.url'] ?= "hdfs://#{props['webhdfs.nameservices']}"
          props['hdfs.auth_to_local'] ?= hadoop_ctx.config.ryba.core_site['hadoop.security.auth_to_local']
          # authentication
          props['webhdfs.auth'] ?= if options.jaas.enabled then 'auth=KERBEROS;proxyuser=ambari' else 'auth=SIMPLE'
          props['webhdfs.username'] ?= '${username}'#doAs for proxy user for HDFS. By default, uses the currently logged-in Ambari user

### Hive View Configuration
the hive view enable to user to use hive, like Hue's database module.
Configuration inherits properties from Files Views. It adds the Hive'server2 jdbc
It has only been tested with HIVe VIEW version 1.5.0 and 2.0.0

        options.views.hive ?= {}
        options.views.hive.enabled ?= if hive_server2_ctxs.length > 0 then true else false
        if options.views.hive.enabled
          options.views.hive.version ?= '2.0.0'
          options.views.enabled = true
          throw Error 'HIVE View version not supported by ryba' unless options.views.hive.version in ['1.5.0','2.0.0']
          options.views.hive.configuration ?= {}
          options.views.hive.configuration['description'] ?=  "HIVE API"
          options.views.hive.configuration['label'] ?=  "HIVE View"
          properties = options.views.hive.configuration.properties ?= {}
          #Hive server2 connection
          quorum = hive_server2_ctxs[0].config.ryba.hive.server2.site['hive.zookeeper.quorum']
          namespace = hive_server2_ctxs[0].config.ryba.hive.server2.site['hive.server2.zookeeper.namespace']
          principal = hive_server2_ctxs[0].config.ryba.hive.server2.site['hive.server2.authentication.kerberos.principal']
          url = "jdbc:hive2://#{quorum}/;principal=#{principal};serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=#{namespace}"
          if hive_server2_ctxs[0].config.ryba.hive.server2.site['hive.server2.use.SSL'] is 'true'
            url += ";ssl=true"
            url += ";sslTrustStore=#{options.truststore.target}"
            url += ";trustStorePassword=#{options.truststore.password}"
          properties['hive.session.params'] ?= ''
          # if hive_server2_ctxs[0].config.ryba.hive.server2.site['hive.server2.transport.mode'] is 'http'
          #   properties['hive.session.params'] += ";transportMode=#{hive_server2_ctxs[0].config.ryba.hive.server2.site['hive.server2.transport.mode']}"
          #   properties['hive.session.params'] += ";httpPath=#{hive_server2_ctxs[0].config.ryba.hive.server2.site['hive.server2.thrift.http.path']}"
          if hive_server2_ctxs[0].config.ryba.hive.server2.site['hive.server2.transport.mode'] is 'http'
            url += ";transportMode=#{hive_server2_ctxs[0].config.ryba.hive.server2.site['hive.server2.transport.mode']}"
            url += ";httpPath=#{hive_server2_ctxs[0].config.ryba.hive.server2.site['hive.server2.thrift.http.path']}"
          properties['hive.session.params'] = 'hive.server2.proxy.user=${username}'
          properties['hive.jdbc.url'] ?= url
          properties['hive.metastore.warehouse.dir'] ?= '/apps/hive/warehouse'
          properties['scripts.dir'] ?= '/user/${username}/hive/scripts'
          properties['jobs.dir'] ?= '/user/${username}/hive/jobs'
          options.views.files.configuration.properties = merge properties, options.views.files.configuration.properties

#### HIVE View to Yarn ATS

          throw Error 'Cannot install HIVE View without Yarn TS' unless yarn_ts_ctxs.length
          throw Error 'Cannot install HIVE View without YARN RM' unless yarn_rm_ctxs.length
          ats_ctx = yarn_ts_ctxs[0]
          rm_ctx = yarn_rm_ctxs[0]
          id = if rm_ctx.config.ryba.yarn.rm.site['yarn.resourcemanager.ha.enabled'] is 'true' then ".#{rm_ctx.config.ryba.yarn.rm.site['yarn.resourcemanager.ha.id']}" else ''
          properties['yarn.ats.url'] ?= if ats_ctx.config.ryba.yarn.site['yarn.http.policy'] is 'HTTP_ONLY'
          then "http://" + ats_ctx.config.ryba.yarn.site['yarn.timeline-service.webapp.address']
          else "https://"+ ats_ctx.config.ryba.yarn.site['yarn.timeline-service.webapp.https.address']
          properties['yarn.resourcemanager.url'] ?= if rm_ctx.config.ryba.yarn.site['yarn.http.policy'] is 'HTTP_ONLY'
          then "http://" + rm_ctx.config.ryba.yarn.rm.site["yarn.resourcemanager.webapp.address#{id}"]
          else "https://"+ rm_ctx.config.ryba.yarn.rm.site["yarn.resourcemanager.webapp.https.address#{id}"]
          
#### HIVE View to Ranger

          if options.views.hive.version in ['2.0.0']
            if hive_server2_ctxs[0].config.ryba.ranger?.hive_plugin?
              options.views.hive.configuration.properties['hive.ranger.servicename'] ?= hive_server2_ctxs[0].config.ryba.ranger.hive_plugin['REPOSITORY_NAME']
              options.views.hive.configuration.properties['hive.ranger.username'] ?= 'admin'
              options.views.hive.configuration.properties['hive.ranger.password'] ?= ranger_ctx.config.ryba.ranger.admin.password
              options.views.hive.configuration.properties['hive.ranger.url'] ?= hive_server2_ctxs[0].config.ryba.ranger.hive_plugin['POLICY_MGR_URL']

### Tez View
Note: Only test with TEZ VIEW 0.7.0.2.6.1.0-118

          options.views.tez ?= {}
          options.views.tez.enabled ?= if @contexts('ryba/tez').length > 0 then true else false
          if options.views.tez.enabled
            options.views.enabled = true
            options.views.tez.version ?= '0.7.0.2.6.1.0-118'
            options.views.tez.configuration ?= {}
            options.views.tez.configuration['description'] ?=  "TEZ API"
            options.views.tez.configuration['label'] ?=  "TEZ View"
            properties = options.views.tez.configuration.properties ?= {}
            throw Error 'Cannot install TEZ View without Yarn TS' unless yarn_ts_ctxs.length
            throw Error 'Cannot install TEZ View without YARN RM' unless yarn_rm_ctxs.length
            ats_ctx = yarn_ts_ctxs[0]
            rm_ctx = yarn_rm_ctxs[0]
            id = if rm_ctx.config.ryba.yarn.rm.site['yarn.resourcemanager.ha.enabled'] is 'true' then ".#{rm_ctx.config.ryba.yarn.rm.site['yarn.resourcemanager.ha.id']}" else ''
            properties['yarn.ats.url'] ?= if ats_ctx.config.ryba.yarn.site['yarn.http.policy'] is 'HTTP_ONLY'
            then "http://" + ats_ctx.config.ryba.yarn.site['yarn.timeline-service.webapp.address']
            else "https://"+ ats_ctx.config.ryba.yarn.site['yarn.timeline-service.webapp.https.address']
            properties['yarn.resourcemanager.url'] ?= if rm_ctx.config.ryba.yarn.site['yarn.http.policy'] is 'HTTP_ONLY'
            then "http://" + rm_ctx.config.ryba.yarn.rm.site["yarn.resourcemanager.webapp.address#{id}"]
            else "https://"+ rm_ctx.config.ryba.yarn.rm.site["yarn.resourcemanager.webapp.https.address#{id}"]
            properties['hdfs.auth_to_local'] ?= hadoop_ctx.config.ryba.core_site['hadoop.security.auth_to_local']
            properties['timeline.http.auth.type'] ?= ats_ctx.config.ryba.yarn.site['yarn.timeline-service.http-authentication.type']
            properties['hadoop.http.auth.type'] ?= hadoop_ctx.config.ryba.core_site['hadoop.http.authentication.type']

## Workflow Manager
The workflow manager correspond to the oozie view. It needs HDFS'properties and oozie base url. it does not support oozie High Availability.

          options.views.wfmanager ?= {}
          options.views.wfmanager.enabled ?= if o_ctxs? then true else false
          if options.views.wfmanager.enabled
            options.views.wfmanager.version ?= '1.0.0'
            options.views.enabled = true
            throw Error 'Workflow Manager View version not supported by ryba' unless options.views.wfmanager.version in ['1.0.0']
            throw Error 'Need oozie server to enable Workflow Manager view' unless o_ctx?
            options.views.wfmanager.configuration ?= {}
            options.views.wfmanager.configuration['description'] ?=  "OOZIE API"
            options.views.wfmanager.configuration['label'] ?=  "OOZIE View"
            properties = options.views.wfmanager.configuration.properties ?= {}
            properties['hadoop.security.authentication'] ?= hadoop_ctx.config.ryba.core_site['hadoop.security.authentication']
            properties['oozie.service.uri'] = o_ctx.config.ryba.oozie.site['oozie.base.url']
            options.views.wfmanager.configuration.properties = merge properties, options.views.files.configuration.properties

## Workflow Manager YARN

          throw Error 'Cannot install Workflow Manager View without YARN RM' unless yarn_rm_ctxs.length
          rm_ctx = yarn_rm_ctxs[0]
          id = if rm_ctx.config.ryba.yarn.rm.site['yarn.resourcemanager.ha.enabled'] is 'true' then ".#{rm_ctx.config.ryba.yarn.rm.site['yarn.resourcemanager.ha.id']}" else ''
          properties['yarn.resourcemanager.address'] ?= if rm_ctx.config.ryba.yarn.site['yarn.http.policy'] is 'HTTP_ONLY'
          then "http://" + rm_ctx.config.ryba.yarn.rm.site["yarn.resourcemanager.webapp.address#{id}"]
          else "https://"+ rm_ctx.config.ryba.yarn.rm.site["yarn.resourcemanager.webapp.https.address#{id}"]

### Views Proxyusers
        
        hadoop_ctxs = @contexts ['ryba/hadoop/hdfs_nn', 'ryba/hadoop/hdfs_dn', 'ryba/hadoop/yarn_rm', 'ryba/hadoop/yarn_nm', 'ryba/hadoop/core']
        for hadoop_ctx in hadoop_ctxs
          hadoop_ctx.config.ryba ?= {}
          hadoop_ctx.config.ryba.core_site ?= {}
          hadoop_ctx.config.ryba.core_site["hadoop.proxyuser.ambari.groups"] ?= '*'
          hadoop_ctx.config.ryba.core_site["hadoop.proxyuser.ambari.hosts"] ?= "#{@contexts('ryba/ambari/standalone').map( (c)->c.config.host)}"

### Oozie Proxyusers

        oozie_ctxs = @contexts 'ryba/oozie/server'
        for oozie_ctx in oozie_ctxs
          oozie_ctx.config.ryba ?= {}
          oozie_ctx.config.ryba.oozie ?= {}
          oozie_ctx.config.ryba.oozie.site ?= {}
          oozie_ctx.config.ryba.oozie.site["oozie.service.ProxyUserService.proxyuser.ambari.groups"] ?= '*'
          oozie_ctx.config.ryba.oozie.site["oozie.service.ProxyUserService.proxyuser.ambari.hosts"] ?= "#{@contexts('ryba/ambari/standalone').map( (c)->c.config.host)}"

[files-view]:(https://github.com/apache/ambari/blob/branch-2.5/contrib/views/files/src/main/resources/view.xml)
[files-view-custom]:(https://docs.hortonworks.com/HDPDocuments/Ambari-2.4.1.0/bk_ambari-views/content/Cluster_Configuration_Custom.html)
[hive-view]:(https://github.com/apache/ambari/blob/79cca1c7184f1661236971dac70d85a83fab6c11/contrib/views/hive-next/src/main/resources/view.xml)
[tez-view-resources]:(https://github.com/apache/ambari/blob/79cca1c7184f1661236971dac70d85a83fab6c11/contrib/views/tez/src/main/resources/view.xml)

## Dependencies
      
    {merge} = require 'nikita/lib/misc'

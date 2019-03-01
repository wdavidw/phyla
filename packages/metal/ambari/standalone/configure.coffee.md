
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

    module.exports = (service) ->
      options = service.options

## Environment

      options.fqdn = service.node.fqdn
      # options.http ?= '/var/www/html'
      options.conf_dir ?= '/etc/ambari-server/conf'
      # options.database ?= {}
      options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'
      options.sudo ?= false
      options.java_home ?= service.deps.java.options.java_home
      options.master_key ?= null
      options.admin ?= {}
      options.current_admin_password ?= 'admin'
      throw Error "Required Option: admin_password" unless options.admin_password

## Identities

Note, there are no identities created by the Ambari package. Identities are only
used in case the server and its agents run as sudoers.

The non-root user you choose to run the Ambari Server should be part of the 
Hadoop group. The default group name is "hadoop".

      # Hadoop Group
      options.hadoop_group ?= service.deps.hadoop_core.options.hadoop_group if service.deps.hadoop_core
      options.hadoop_group = name: options.group if typeof options.group is 'string'
      options.hadoop_group ?= {}
      options.hadoop_group.name ?= 'hadoop'
      options.hadoop_group.system ?= true
      options.hadoop_group.comment ?= 'Hadoop Group'
      # Group
      options.group = name: options.group if typeof options.group is 'string'
      options.group ?= {}
      options.group.name ?= 'ambari'
      options.group.system ?= true
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

      options.ssl = mixme service.deps.ssl?.options, options.ssl
      options.ssl.enabled ?= !!service.deps.ssl
      if options.ssl.enabled
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


      options.krb5_enabled ?= !!service.deps.krb5_client
      # Krb5 Import
      options.krb5 ?= {}
      options.krb5.realm ?= service.deps.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      throw Error 'Required Options: "realm"' unless options.krb5.realm
      options.krb5.admin ?= service.deps.krb5_client.options.admin[options.krb5.realm]
      # Krb5 Validation
      throw Error "Require Property: krb5.admin.kadmin_principal" unless options.krb5.admin.kadmin_principal
      throw Error "Require Property: krb5.admin.kadmin_password" unless options.krb5.admin.kadmin_password
      throw Error "Require Property: krb5.admin.admin_server" unless options.krb5.admin.admin_server
      # JAAS
      options.jaas ?= {}
      options.jaas.enabled ?= false
      if options.jaas.enabled
        options.jaas.keytab ?= '/etc/ambari-server/conf/ambari.service.keytab'
        options.jaas.principal ?= "ambari/_HOST@#{options.jaas.realm}"
        options.jaas.principal = options.jaas.principal.replace '_HOST', service.node.fqdn

## Configuration

      options.config ?= {}
      options.config['server.url_port'] ?= "8440"
      options.config['server.secured_url_port'] ?= "8441"
      options.config['api.ssl'] ?= if options.ssl.enabled then 'true' else 'false'
      options.config['client.api.port'] ?= "8080"
      # Be Carefull, collision in HDP 2.5.3 on port 8443 between Ambari and Knox
      options.config['client.api.ssl.port'] ?= "8442"

## Database

Ambari DB password is stash into "/etc/ambari-server/conf/password.dat".

      options.supported_db_engines ?= ['mysql', 'mariadb', 'postgresql']
      options.db ?= {}
      options.db.engine ?= service.deps.db_admin.options.engine
      Error 'Unsupported database engine' unless options.db.engine in options.supported_db_engines
      options.db = mixme service.deps.db_admin.options[options.db.engine], options.db
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
        options.views.files.enabled ?= if service.deps.hdfs_nn then true else false
        if options.views.files.enabled or options.views.hive.enabled
          options.views.enabled = true
          options.views.files.version ?= '1.0.0'
          throw Error 'Need Kerberos For ambari' if (options.krb5_enabled) and not options.jaas.enabled
          throw Error 'Need two namenodes' unless service.deps.hdfs_nn.length is 2
          options.views.files.configuration ?= {}
          nn_site = service.deps.hdfs_nn[0].options.hdfs_site
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
          props['hdfs.auth_to_local'] ?= service.deps.hadoop_core.options.core_site['hadoop.security.auth_to_local']
          # authentication
          props['webhdfs.auth'] ?= if options.jaas.enabled then 'auth=KERBEROS;proxyuser=ambari' else 'auth=SIMPLE'
          props['webhdfs.username'] ?= '${username}'#doAs for proxy user for HDFS. By default, uses the currently logged-in Ambari user

### Hive View Configuration
the hive view enable to user to use hive, like Hue's database module.
Configuration inherits properties from Files Views. It adds the Hive'server2 jdbc
It has only been tested with HIVe VIEW version 1.5.0 and 2.0.0

        options.views.hive ?= {}
        options.views.hive.enabled ?= if service.deps.hive_server2 then true else false
        if options.views.hive.enabled
          options.views.hive.version ?= '2.0.0'
          options.views.enabled = true
          throw Error 'HIVE View version not supported by ryba' unless options.views.hive.version in ['1.5.0','2.0.0']
          options.views.hive.configuration ?= {}
          options.views.hive.configuration['description'] ?=  "HIVE API"
          options.views.hive.configuration['label'] ?=  "HIVE View"
          properties = options.views.hive.configuration.properties ?= {}
          #Hive server2 connection
          quorum = service.deps.hive_server2[0].options.hive_site['hive.zookeeper.quorum']
          namespace = service.deps.hive_server2[0].options.hive_site['hive.server2.zookeeper.namespace']
          principal = service.deps.hive_server2[0].options.hive_site['hive.server2.authentication.kerberos.principal']
          jdbc_url = "jdbc:hive2://#{quorum}/;principal=#{principal};serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=#{namespace}"
          if service.deps.hive_server2[0].options.hive_site['hive.server2.use.SSL'] is 'true'
            jdbc_url += ";ssl=true"
            jdbc_url += ";sslTrustStore=#{options.truststore.target}"
            jdbc_url += ";trustStorePassword=#{options.truststore.password}"
          properties['hive.session.params'] ?= ''
          # if service.deps.hive_server2[0].options.hive_site['hive.server2.transport.mode'] is 'http'
          #   properties['hive.session.params'] += ";transportMode=#{service.deps.hive_server2[0].options.hive_site['hive.server2.transport.mode']}"
          #   properties['hive.session.params'] += ";httpPath=#{service.deps.hive_server2[0].options.hive_site['hive.server2.thrift.http.path']}"
          if service.deps.hive_server2[0].options.hive_site['hive.server2.transport.mode'] is 'http'
            jdbc_url += ";transportMode=#{service.deps.hive_server2[0].options.hive_site['hive.server2.transport.mode']}"
            jdbc_url += ";httpPath=#{service.deps.hive_server2[0].options.hive_site['hive.server2.thrift.http.path']}"
          properties['hive.session.params'] = 'hive.server2.proxy.user=${username}'
          properties['hive.jdbc.url'] ?= jdbc_url
          properties['hive.metastore.warehouse.dir'] ?= '/apps/hive/warehouse'
          properties['scripts.dir'] ?= '/user/${username}/hive/scripts'
          properties['jobs.dir'] ?= '/user/${username}/hive/jobs'
          options.views.files.configuration.properties = mixme properties, options.views.files.configuration.properties

#### HIVE View to Yarn ATS

          throw Error 'Cannot install HIVE View without Yarn TS' unless service.deps.yarn_ts
          throw Error 'Cannot install HIVE View without YARN RM' unless service.deps.yarn_rm
          id = if service.deps.yarn_rm[0].options.yarn_site['yarn.resourcemanager.ha.enabled'] is 'true' then ".#{service.deps.yarn_rm[0].options.yarn_site['yarn.resourcemanager.ha.id']}" else ''
          properties['yarn.ats.url'] ?= if service.deps.yarn_ts[0].options.yarn_site['yarn.http.policy'] is 'HTTP_ONLY'
          then "http://" + service.deps.yarn_ts[0].options.yarn_site['yarn.timeline-service.webapp.address']
          else "https://"+ service.deps.yarn_ts[0].options.yarn_site['yarn.timeline-service.webapp.https.address']
          properties['yarn.resourcemanager.url'] ?= if service.deps.yarn_rm[0].options.yarn_site['yarn.http.policy'] is 'HTTP_ONLY'
          then "http://" + service.deps.yarn_rm[0].options.yarn_site["yarn.resourcemanager.webapp.address#{id}"]
          else "https://"+ service.deps.yarn_rm[0].options.yarn_site["yarn.resourcemanager.webapp.https.address#{id}"]

#### HIVE View to Ranger

          if options.views.hive.version in ['2.0.0']
            if service.deps.ranger_hive
              options.views.hive.configuration.properties['hive.ranger.servicename'] ?= service.deps.ranger_hive[0].options.install['REPOSITORY_NAME']
              options.views.hive.configuration.properties['hive.ranger.username'] ?= service.deps.ranger_hive[0].options.ranger_admin.username
              options.views.hive.configuration.properties['hive.ranger.password'] ?= service.deps.ranger_hive[0].options.ranger_admin.password
              options.views.hive.configuration.properties['hive.ranger.url'] ?= service.deps.ranger_hive[0].options.install['POLICY_MGR_URL']

### Tez View
Note: Only test with TEZ VIEW 0.7.0.2.6.1.0-118

          options.views.tez ?= {}
          options.views.tez.enabled ?= if @contexts('@rybajs/metal/tez').length > 0 then true else false
          if options.views.tez.enabled
            options.views.enabled = true
            options.views.tez.version ?= '0.7.0.2.6.1.0-118'
            options.views.tez.configuration ?= {}
            options.views.tez.configuration['description'] ?=  "TEZ API"
            options.views.tez.configuration['label'] ?=  "TEZ View"
            properties = options.views.tez.configuration.properties ?= {}
            throw Error 'Cannot install TEZ View without Yarn TS' unless service.deps.yarn_ts
            throw Error 'Cannot install TEZ View without YARN RM' unless service.deps.yarn_rm
            id = if service.deps.yarn_rm[0].options.yarn_site['yarn.resourcemanager.ha.enabled'] is 'true' then ".#{service.deps.yarn_rm[0].options.yarn_site['yarn.resourcemanager.ha.id']}" else ''
            properties['yarn.ats.url'] ?= if service.deps.yarn_ts[0].options.yarn_site['yarn.http.policy'] is 'HTTP_ONLY'
            then "http://" + service.deps.yarn_ts[0].options.yarn_site['yarn.timeline-service.webapp.address']
            else "https://"+ service.deps.yarn_ts[0].options.yarn_site['yarn.timeline-service.webapp.https.address']
            properties['yarn.resourcemanager.url'] ?= if service.deps.yarn_rm[0].options.yarn_site['yarn.http.policy'] is 'HTTP_ONLY'
            then "http://" + service.deps.yarn_rm[0].options.yarn_site["yarn.resourcemanager.webapp.address#{id}"]
            else "https://"+ service.deps.yarn_rm[0].options.yarn_site["yarn.resourcemanager.webapp.https.address#{id}"]
            properties['hdfs.auth_to_local'] ?= hadoop_service.deps.hadoop_core.options.core_site['hadoop.security.auth_to_local']
            properties['timeline.http.auth.type'] ?= service.deps.yarn_ts[0].options.yarn_site['yarn.timeline-service.http-authentication.type']
            properties['hadoop.http.auth.type'] ?= hadoop_service.deps.hadoop_core.options.core_site['hadoop.http.authentication.type']

## Workflow Manager
The workflow manager correspond to the oozie view. It needs HDFS'properties and oozie base url. it does not support oozie High Availability.

          options.views.wfmanager ?= {}
          options.views.wfmanager.enabled ?= if service.oozie_server then true else false
          if options.views.wfmanager.enabled
            options.views.wfmanager.version ?= '1.0.0'
            options.views.enabled = true
            throw Error 'Workflow Manager View version not supported by ryba' unless options.views.wfmanager.version in ['1.0.0']
            throw Error 'Need oozie server to enable Workflow Manager view' unless service.oozie_server
            options.views.wfmanager.configuration ?= {}
            options.views.wfmanager.configuration['description'] ?=  "OOZIE API"
            options.views.wfmanager.configuration['label'] ?=  "OOZIE View"
            properties = options.views.wfmanager.configuration.properties ?= {}
            properties['hadoop.security.authentication'] ?= hadoop_service.deps.hadoop_core.options.core_site['hadoop.security.authentication']
            properties['oozie.service.uri'] = service.oozie_server[0].oozie_site['oozie.base.url']
            options.views.wfmanager.configuration.properties = mixme properties, options.views.files.configuration.properties

## Workflow Manager YARN

          throw Error 'Cannot install Workflow Manager View without YARN RM' unless service.deps.yarn_rm
          id = if service.deps.yarn_rm[0].options.yarn_site['yarn.resourcemanager.ha.enabled'] is 'true' then ".#{service.deps.yarn_rm[0].options.yarn_site['yarn.resourcemanager.ha.id']}" else ''
          properties['yarn.resourcemanager.address'] ?= if service.deps.yarn_rm[0].options.yarn_site['yarn.http.policy'] is 'HTTP_ONLY'
          then "http://" + service.deps.yarn_rm[0].options.yarn_site["yarn.resourcemanager.webapp.address#{id}"]
          else "https://"+ service.deps.yarn_rm[0].options.yarn_site["yarn.resourcemanager.webapp.https.address#{id}"]

### Views Proxyusers

        enrich_proxy_user (srv) ->
          srv.options.core_site["hadoop.proxyuser.#{options.user.name}.groups"] ?= '*'
          hosts = srv.options.core_site["hadoop.proxyuser.#{options.user.name}.hosts"] or []
          hosts = hosts.split ',' unless Array.isArray hosts
          for fqdn in service.instances.map( (instance) -> instance.node.fqdn)
            hosts.push fqdn unless fqdn in hosts
          hosts = hosts.join ' '
          srv.options.core_site["hadoop.proxyuser.#{options.user.name}.hosts"] ?= hosts
        enrich_proxy_user srv for srv in service.deps.hadoop_core
        enrich_proxy_user srv for srv in service.deps.hdfs_nn
        enrich_proxy_user srv for srv in service.deps.hdfs_dn
        enrich_proxy_user srv for srv in service.deps.yarn_rm
        enrich_proxy_user srv for srv in service.deps.yarn_nm

### Oozie Proxyusers

        for srv in service.deps.oozie_server
          srv.options.oozie_site["oozie.service.ProxyUserService.proxyuser.#{options.user.name}.groups"] ?= '*'
          hosts = srv.options.oozie_site["oozie.service.ProxyUserService.proxyuser.#{options.user.name}.hosts"] or []
          hosts = hosts.split ','  unless Array.isArray hosts
          for fqdn in service.instances.map( (instance) -> instance.node.fqdn)
            hosts.push fqdn unless fqdn in hosts
          hosts = hosts.join ' '
          srv.options.oozie_site["oozie.service.ProxyUserService.proxyuser.#{options.user.name}.hosts"] ?= hosts

[files-view]:(https://github.com/apache/ambari/blob/branch-2.5/contrib/views/files/src/main/resources/view.xml)
[files-view-custom]:(https://docs.hortonworks.com/HDPDocuments/Ambari-2.4.1.0/bk_ambari-views/content/Cluster_Configuration_Custom.html)
[hive-view]:(https://github.com/apache/ambari/blob/79cca1c7184f1661236971dac70d85a83fab6c11/contrib/views/hive-next/src/main/resources/view.xml)
[tez-view-resources]:(https://github.com/apache/ambari/blob/79cca1c7184f1661236971dac70d85a83fab6c11/contrib/views/tez/src/main/resources/view.xml)

## Wait

      # options.wait_ambari_server = service.deps.ambari_server
      options.wait = {}
      options.wait.rest = for srv in service.deps.ambari_standalone
        clusters_url: url.format
          protocol: unless srv.options.config['api.ssl'] is 'true'
          then 'http'
          else 'https'
          hostname: srv.options.fqdn
          port: unless srv.options.config['api.ssl'] is 'true'
          then srv.options.config['client.api.port']
          else srv.options.config['client.api.ssl.port']
          pathname: '/api/v1/clusters'
        oldcred: "admin:#{srv.options.current_admin_password}"
        newcred: "admin:#{srv.options.admin_password}"

## Dependencies

    url = require 'url'
    mixme = require 'mixme'

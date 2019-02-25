
# Ambari Server Configuration

## Options

* `db_hive.database` (string)   
  Name of the database storing the Hive database.
* `db_hive.enabled` (boolean)   
  Prepare the Hive database.
* `db_hive.engine` (boolean)   
  Type of database; one of "mariadb", "mysql" or "postgresql".
* `db_hive.password` (boolean)   
  Password associated with the database administrator user.
* `db_hive.username` (boolean)   
  Hive database administrator user.

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
      options.sudo ?= false
      options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'
      options.java_home ?= service.deps.java and service.deps.java.options.java_home
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

      # test User
      options.test_group = name: options.test_group if typeof options.test_group is 'string'
      options.test_group ?= {}
      options.test_group.name ?= 'ambari-qa'
      options.test_group.system ?= true
      options.test_user = name: options.test_user if typeof options.v is 'string'
      options.test_user ?= {}
      options.test_user.name ?= 'ambari-qa'
      options.test_user.system ?= true
      options.test_user.comment ?= 'Ambari Test User'
      options.test_user.home ?= "/var/lib/#{options.test_user.name}"
      options.test_user.groups ?= ['hadoop']
      options.test_user.gid = options.test_group.name

      # test User
      # options.explorer_group = name: options.explorer_group if typeof options.explorer_group is 'string'
      # options.explorer_group ?= {}
      # options.explorer_group.name ?= 'activity_explorer'
      # options.explorer_group.system ?= true
      # options.explorer_user = name: options.explorer_user if typeof options.v is 'string'
      # options.explorer_user ?= {}
      # options.explorer_user.name ?= 'activity_explorer'
      # options.explorer_user.system ?= true
      # options.explorer_user.comment ?= 'Ambari Activity Explorer User'
      # options.explorer_user.home ?= "/var/lib/#{options.explorer_user.name}"
      # options.explorer_user.groups ?= ['hadoop']
      # options.explorer_user.gid = options.explorer_group.name

      # test User
      # options.analyzer_group = name: options.analyzer_group if typeof options.analyzer_group is 'string'
      # options.analyzer_group ?= {}
      # options.analyzer_group.name ?= 'activity_analyzer'
      # options.analyzer_group.system ?= true
      # options.analyzer_user = name: options.analyzer_user if typeof options.v is 'string'
      # options.analyzer_user ?= {}
      # options.analyzer_user.name ?= 'activity_analyzer'
      # options.analyzer_user.system ?= true
      # options.analyzer_user.comment ?= 'Ambari Activity Analyzer User'
      # options.analyzer_user.home ?= "/var/lib/#{options.analyzer_user.name}"
      # options.analyzer_user.groups ?= ['hadoop']
      # options.analyzer_user.gid = options.analyzer_group.name

## Ambari TLS and Truststore

      options.ssl = mixme service.deps.ssl?.options, options.ssl
      options.ssl.enabled ?= !!service.deps.ssl
      options.truststore ?= {}
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

      # Krb5 Import
      options.krb5 ?= {}
      # Krb5 Client adapter
      if service.deps.krb5_client
        options.krb5.realm ?= service.deps.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
        options.krb5.admin ?= service.deps.krb5_client.options.admin[options.krb5.realm]
      if options.krb5.enabled
        throw Error 'Required Options: "realm"' unless options.krb5.realm
        # Krb5 Validation
        throw Error "Require Property: krb5.admin.kadmin_principal" unless options.krb5.admin.kadmin_principal
        throw Error "Require Property: krb5.admin.kadmin_password" unless options.krb5.admin.kadmin_password
        throw Error "Require Property: krb5.admin.admin_server" unless options.krb5.admin.admin_server
      # JAAS
      options.jaas ?= {}
      options.jaas.enabled ?= options.krb5.enabled
      options.jaas.keytab ?= '/etc/security/keytabs/ambari.service.keytab'
      if options.jaas.enabled
        throw Error 'jaas.enabled required krb5.enabled' unless options.krb5.enabled
        options.jaas.principal ?= "ambari/_HOST@#{options.krb5.realm}"
        options.jaas.principal = options.jaas.principal.replace '_HOST', service.node.fqdn

        # options.analyzer_user.principal ?= "#{options.analyzer_user.name}/_HOST@#{options.krb5.realm}"
        # options.analyzer_user.keytab ?= "/etc/security/keytabs/activity-analyzer.headless.keytab"
        # options.explorer_user.principal ?= "#{options.explorer_user.name}/_HOST@#{options.krb5.realm}"
        # options.explorer_user.keytab ?=  "/etc/security/keytabs/activity-explorer.headless.keytab"

## Configuration

      options.config ?= {}
      options.config['server.url_port'] ?= "8440"
      options.config['server.secured_url_port'] ?= "8441"
      options.config['api.ssl'] ?= if options.ssl.enabled then 'true' else 'false'
      options.config['client.api.port'] ?= "8080"
      # Be Carefull, collision in HDP 2.5.3 on port 8443 between Ambari and Knox
      options.config['client.api.ssl.port'] ?= "8442"

## MPack

A management pack (MPack) bundles service definitions, stack definitions, and stack add-
on service definitions so they do not need to be included with the Ambari core functionality
and can be updated in between major releases.

The only MPack file to be registered in the configuration is the one for HDF. It is desactivated by default.

      options.mpacks ?= {}
      options.mpacks.hdf = mixme
        enabled: false
        arch: 'centos'
        version: '7'
        source: 'https://public-repo-1.hortonworks.com/HDF/centos7/2.x/updates/2.1.3.0/tars/hdf_ambari_mp/hdf-ambari-mpack-2.1.3.0-6.tar.gz'
      , options.mpacks.hdf or {}

## Database

Ambari DB password is stash into "/etc/ambari-server/conf/password.dat".

      options.supported_db_engines ?= ['mysql', 'mariadb', 'postgresql']
      options.db ?= {}
      options.db.engine ?= service.deps.db_admin.options.engine
      Error "Unsupported Database Engine: got #{options.db.engine}" unless options.db.engine in options.supported_db_engines
      options.db = mixme service.deps.db_admin.options[options.db.engine], options.db
      options.db.database ?= 'ambari'
      options.db.username ?= 'ambari'
      options.db.jdbc += "/#{options.db.database}?createDatabaseIfNotExist=true"
      throw Error "Required Option: db.password" unless options.db?.password

## Hive provisionning

      options.db_hive ?= {}
      options.db_hive.enabled ?= false
      if options.db_hive.enabled
        options.db_hive.engine ?= options.db.engine
        options.db_hive = mixme service.deps.db_admin.options[options.db_hive.engine], options.db_hive
        options.db_hive.database ?= 'hive'
        options.db_hive.username ?= 'hive'
        throw Error "Required Option: db_hive.password" unless options.db_hive.password

## Oozie provisionning

      options.db_oozie ?= {}
      options.db_oozie.enabled ?= false
      if options.db_oozie.enabled
        options.db_oozie.engine ?= options.db.engine
        options.db_oozie = mixme service.deps.db_admin.options[options.db_oozie.engine], options.db_oozie
        options.db_oozie.database ?= 'oozie'
        options.db_oozie.username ?= 'oozie'
        throw Error "Required Option: db_oozie.password" unless options.db_oozie.password

## Ranger provisionning

      options.db_ranger ?= {}
      options.db_ranger.enabled ?= false
      if options.db_ranger.enabled
        options.db_ranger.engine ?= options.db.engine
        options.db_ranger = mixme service.deps.db_admin.options[options.db_ranger.engine], options.db_ranger
        options.db_ranger.database ?= 'ranger'
        options.db_ranger.username ?= 'ranger'
        throw Error "Required Option: db_ranger.password" unless options.db_ranger.password

## Ranger provisionning

      options.db_rangerkms ?= {}
      options.db_rangerkms.enabled ?= false
      if options.db_rangerkms.enabled
        options.db_rangerkms.engine ?= options.db.engine
        options.db_rangerkms = mixme service.deps.db_admin.options[options.db_rangerkms.engine], options.db_rangerkms
        options.db_rangerkms.database ?= 'rangerkms'
        options.db_rangerkms.username ?= 'rangerkms'
        throw Error "Required Option: db_rangerkms.password" unless options.db_rangerkms.password

## Client Rest API Url

      options.ambari_url ?= if options.config['api.ssl'] is 'false'
      then "http://#{service.node.fqdn}:#{options.config['client.api.port']}"
      else "https://#{service.node.fqdn}:#{options.config['client.api.ssl.port']}"
      options.ambari_admin_password ?= options.admin_password
      #options.cluster_name ?= options.cluster_name

## Wait

      options.wait_db_admin = service.deps.db_admin.options.wait
      options.wait = {}
      options.wait.rest = for srv in service.deps.ambari_server
        clusters_url: url.format
          protocol: if srv.options.config['api.ssl'] is 'true'
          then 'https'
          else 'http'
          hostname: srv.options.fqdn
          port: if srv.options.config['api.ssl'] is 'true'
          then srv.options.config['client.api.ssl.port']
          else srv.options.config['client.api.port']
          pathname: '/api/v1/clusters'
        oldcred: "admin:#{srv.options.current_admin_password}"
        newcred: "admin:#{srv.options.admin_password}"

## Dependencies

    url = require 'url'
    mixme = require 'mixme'

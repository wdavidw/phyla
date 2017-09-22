
# Ambari Server Configuration

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
      service = migration.call @, service, 'ryba/ambari/hdfserver', ['ryba', 'ambari', 'hdfserver'], require('nikita/lib/misc').merge require('.').use,
        ssl: key: ['ssl']
        krb5_client: key: ['krb5_client']
        java: key: ['java']
        db_admin: key: ['ryba', 'db_admin']
        hadoop_core: key: ['ryba']
        ambari_repo: key: ['ryba', 'ambari', 'repo']
      @config.ryba ?= {}
      @config.ryba.ambari ?= {}
      options = @config.ryba.ambari.hdfserver = service.options

## Environnment

      options.fqdn = service.node.fqdn
      # options.http ?= '/var/www/html'
      options.conf_dir ?= '/etc/ambari-server/conf'
      options.sudo ?= false
      options.java_home ?= service.use.java.options.java_home
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
      options.hadoop_group ?= service.use.hadoop_core.options.hadoop_group if service.use.hadoop_core
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

      options.ssl = merge {}, service.use.ssl?.options, options.ssl
      options.ssl.enabled = !!service.use.ssl
      # options.truststore ?= {}
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
      options.krb5.realm ?= service.use.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      throw Error 'Required Options: "realm"' unless options.krb5.realm
      options.krb5.admin ?= service.use.krb5_client.options.admin[options.krb5.realm]
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
      options.config['api.ssl'] ?= unless options.ssl then 'false' else 'true'
      options.config['client.api.port'] ?= "8080"
      # Be Carefull, collision in HDP 2.5.3 on port 8443 between Ambari and Knox
      options.config['client.api.ssl.port'] ?= "8442"

## MPack

A management pack (MPack) bundles service definitions, stack definitions, and stack add-
on service definitions so they do not need to be included with the Ambari core functionality
and can be updated in between major releases.

The only MPack file to be registered in the configuration is the one for HDF. It is desactivated by default.

      options.mpacks ?= {}
      options.mpacks.hdf = merge
        enabled: false
        arch: 'centos'
        version: '7'
        source: 'https://public-repo-1.hortonworks.com/HDF/centos7/2.x/updates/2.1.3.0/tars/hdf_ambari_mp/hdf-ambari-mpack-2.1.3.0-6.tar.gz'
      , options.mpacks.hdf or {}

## Database

Ambari DB password is stash into "/etc/ambari-server/conf/password.dat".

      options.supported_db_engines ?= ['mysql', 'mariadb', 'postgres']
      options.db ?= {}
      options.db.engine ?= service.use.db_admin.options.engine
      Error 'Unsupported database engine' unless options.db.engine in options.supported_db_engines
      options.db = merge {}, service.use.db_admin.options[options.db.engine], options.db
      options.db.database ?= 'ambari'
      options.db.username ?= 'ambari'
      options.db.jdbc += "/#{options.db.database}?createDatabaseIfNotExist=true"
      throw Error "Required Option: db.password" unless options.db?.password

## Hive provisionning

      options.db_hive ?= false
      options.db_hive = password: options.db_hive if typeof options.db_hive is 'string'
      if options.db_hive
        options.db_hive.engine ?= options.db.engine
        options.db_hive = merge {}, service.use.db_admin.options[options.db_hive.engine], options.db_hive
        options.db_hive.database ?= 'hive'
        options.db_hive.username ?= 'hive'
        throw Error "Required Option: db_hive.password" unless options.db_hive.password

## Oozie provisionning

      options.db_oozie ?= false
      options.db_oozie = password: options.db_oozie if typeof options.db_oozie is 'string'
      if options.db_oozie
        options.db_oozie.engine ?= options.db.engine
        options.db_oozie = merge {}, service.use.db_admin.options[options.db_oozie.engine], options.db_oozie
        options.db_oozie.database ?= 'oozie'
        options.db_oozie.username ?= 'oozie'
        throw Error "Required Option: db_oozie.password" unless options.db_oozie.password

## Ranger provisionning

      options.db_ranger ?= false
      options.db_ranger = password: options.db_ranger if typeof options.db_ranger is 'string'
      if options.db_ranger
        options.db_ranger.engine ?= options.db.engine
        options.db_ranger = merge {}, service.use.db_admin.options[options.db_ranger.engine], options.db_ranger
        options.db_ranger.database ?= 'ranger'
        options.db_ranger.username ?= 'ranger'
        throw Error "Required Option: db_ranger.password" unless options.db_ranger.password

## Wait

      options.wait_db_admin = service.use.db_admin.options.wait

## Dependencies

    {merge} = require 'nikita/lib/misc'
    migration = require 'masson/lib/migration'

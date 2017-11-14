
# Druid Configure

Example:

```json
{
  "version": "0.9.1.1"
}
```

    module.exports = (service) ->
      options = service.options

## Environment

      # Layout
      options.dir ?= '/opt/druid'
      options.conf_dir ?= '/etc/druid/conf'
      options.log_dir ?= '/var/log/druid'
      options.pid_dir ?= '/var/run/druid'
      options.hadoop_conf_dir = service.deps.hdfs_client.options.conf_dir
      # Java
      options.server_opts ?= ''
      options.server_heap ?= ''
      # Package
      options.version ?= '0.10.0'
      options.source ?= "http://static.druid.io/artifacts/releases/druid-#{options.version}-bin.tar.gz"
      options.source_mysql_extension ?= "http://static.druid.io/artifacts/releases/mysql-metadata-storage-#{options.version}.tar.gz"

## Identities

      # Group
      options.group = name: options.group if typeof options.group is 'string'
      options.group ?= {}
      options.group.name ?= 'druid'
      options.group.system ?= true
      # User
      options.user = name: options.user if typeof options.user is 'string'
      options.user ?= {}
      options.user.name ?= 'druid'
      options.user.system ?= true
      options.user.comment ?= 'Druid User'
      options.user.home ?= "/var/lib/#{options.user.name}"
      options.user.groups ?= ['hadoop']
      options.user.gid = options.group.name

## Kerberos

      options.krb5 ?= {}
      options.krb5.realm ?= service.deps.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      throw Error 'Required Options: "realm"' unless options.krb5.realm
      options.krb5.admin ?= service.deps.krb5_client.options.admin[options.krb5.realm]
      # Kerberos Druid Admin
      options.krb5_user ?= {}
      options.krb5_user.principal ?= "druid@#{options.krb5.realm}"
      options.krb5_user.password ?= "druid123"
      # Kerberos Druid Service
      options.krb5_service ?= {}
      options.krb5_service.principal ?= "druid/#{service.node.fqdn}@#{options.krb5.realm}"
      options.krb5_service.keytab ?= "#{options.dir}/conf/druid/_common/druid.keytab"
      # Kerberos HDFS Admin
      options.hdfs_krb5_user = service.deps.hdfs_client.options.krb5_user

## Configuration

      options.timezone ?= 'UTC'
      options.common_runtime ?= {}
      # Extensions
      # Note, Mysql extension isnt natively supported due to licensing issues
      # Seems like it is either postgresql or mysql extension ("postgresql-metadata-storage", "mysql-metadata-storage")
      # "druid-s3-extensions",
      options.common_runtime['druid.extensions.loadList'] = JSON.parse options.common_runtime['druid.extensions.loadList'] if options.common_runtime['druid.extensions.loadList']
      options.common_runtime['druid.extensions.loadList'] ?= ["druid-kafka-eight", "druid-histogram", "druid-datasketches", "druid-lookups-cached-global", "druid-hdfs-storage"]
      # Logging
      options.common_runtime['druid.startup.logging.logProperties'] ?= 'true'
      # Zookeeper
      zookeeper_quorum = for srv in service.deps.zookeeper_server
        continue unless srv.options.config['peerType'] is 'participant'
        "#{srv.node.fqdn}:#{srv.options.config['clientPort']}"
      options.common_runtime['druid.zk.service.host'] ?= "#{zookeeper_quorum.join ','}"
      options.common_runtime['druid.zk.paths.base'] ?= '/druid'

## Metadata storage

      options.supported_db_engines ?= ['mysql', 'mariadb', 'postgresql']
      options.db ?= {}
      options.db.engine ?= service.deps.db_admin.options.engine
      Error 'Unsupported database engine' unless options.db.engine in options.supported_db_engines
      options.db = merge {}, service.deps.db_admin.options[options.db.engine], options.db
      options.db.database ?= 'druid'
      options.db.username ?= 'druid'
      throw Error "Require Options: db.password" unless options.db.password
      switch options.db.engine
        when 'postgresql'
          options.common_runtime['druid.metadata.storage.type'] ?= 'postgresql'
          options.common_runtime['druid.metadata.storage.connector.connectURI'] ?= "jdbc:postgresql://#{options.db.host}:#{options.db.port}/#{options.db.database}"
          options.common_runtime['druid.metadata.storage.connector.host'] ?= "#{options.db.host}"
          options.common_runtime['druid.metadata.storage.connector.port'] ?= "#{options.db.port}"
          options.common_runtime['druid.extensions.loadList'].push "postgresql-metadata-storage"
        when 'mysql', 'mariadb'
          options.common_runtime['druid.metadata.storage.type'] ?= 'mysql'
          options.common_runtime['druid.metadata.storage.connector.connectURI'] ?= "jdbc:mysql://#{options.db.host}:#{options.db.port}/#{options.db.database}"
          options.common_runtime['druid.metadata.storage.connector.host'] ?= "#{options.db.host}"
          options.common_runtime['druid.metadata.storage.connector.port'] ?= "#{options.db.port}"
          options.common_runtime['druid.extensions.loadList'].push "mysql-metadata-storage"
        when 'derby'
          options.common_runtime['druid.metadata.storage.type'] ?= 'derby'
          options.common_runtime['druid.metadata.storage.connector.connectURI'] ?= "jdbc:derby://#{service.node.fqdn}:1527/var/druid/metadata.db;create=true"
          options.common_runtime['druid.metadata.storage.connector.host'] ?= "#{service.node.fqdn}"
          options.common_runtime['druid.metadata.storage.connector.port'] ?= '1527'
      options.common_runtime['druid.metadata.storage.connector.user'] ?= "#{options.db.username}"
      options.common_runtime['druid.metadata.storage.connector.password'] ?= "#{options.db.password}"
      # Deep storage
      # Extension "druid-hdfs-storage" added to "loadList"
      options.common_runtime['druid.storage.type'] ?= 'hdfs'
      options.common_runtime['druid.storage.storageDirectory'] ?= '/apps/druid/segments'
      # Indexing service logs
      options.common_runtime['druid.indexer.logs.type'] ?= 'hdfs'
      options.common_runtime['druid.indexer.logs.directory'] ?= '/apps/druid/indexing-logs'
      # Service discovery
      options.common_runtime['druid.selectors.indexing.serviceName'] ?= 'druid/overlord'
      options.common_runtime['druid.selectors.coordinator.serviceName'] ?= 'druid/coordinator'
      # Monitoring
      options.common_runtime['druid.monitoring.monitors'] ?= '["com.metamx.metrics.JvmMonitor"]'
      options.common_runtime['druid.emitter'] ?= 'logging'
      options.common_runtime['druid.emitter.logging.logLevel'] ?= 'info'
      options.common_runtime['druid.extensions.loadList'] = JSON.stringify options.common_runtime['druid.extensions.loadList']

## Dependencies

    {merge} = require 'nikita/lib/misc'

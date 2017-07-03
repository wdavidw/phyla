
# Schema Registry Configure

    module.exports = ->
      {db_admin, realm} = @config.ryba
      registry = @config.ryba.registry ?= {}

# Environment

      registry.conf_dir ?= '/etc/registry/conf'
      registry.pid_dir ?= '/var/run/registry'
      registry.log_dir ?= '/var/log/registry'

## Identities

      # Group
      registry.group = name: registry.group if typeof registry.group is 'string'
      registry.group ?= {}
      registry.group.name ?= 'registry'
      registry.group.system ?= true
      # User
      registry.user = name: registry.user if typeof registry.user is 'string'
      registry.user ?= {}
      registry.user.name ?= 'registry'
      registry.user.gid = registry.group.name
      registry.user.system ?= true
      registry.user.comment ?= 'Registry User'
      registry.user.home ?= '/var/lib/registry'
      registry.user.limits ?= {}
      registry.user.limits.nofile ?= 64000
      registry.user.limits.nproc ?= 10000
      registry.db ?= {}

## Configuration

      registry.config ?= {}
      registry.config['modules'] ?= [
        name: 'schema-registry'
        className: 'com.hortonworks.registries.schemaregistry.webservice.SchemaRegistryModule'
        config:
          schemaProviders: [
            providerClass: 'com.hortonworks.registries.schemaregistry.avro.AvroSchemaProvider'
            defaultSerializerClass: 'com.hortonworks.registries.schemaregistry.serdes.avro.AvroSnapshotSerializer'
            defaultDeserializerClass: 'com.hortonworks.registries.schemaregistry.serdes.avro.AvroSnapshotDeserializer'
          ]
          schemaCacheSize: 10000
          schemaCacheExpiryInterval: 3600
      ]
      registry.config['fileStorageConfiguration'] ?= {}
      registry.config['fileStorageConfiguration']['className'] ?= 'com.hortonworks.registries.common.util.LocalFileSystemStorage'
      registry.config['fileStorageConfiguration']['properties'] ?= {}
      registry.config['fileStorageConfiguration']['properties']['directory'] ?= "#{registry.user.home}/jars"
      registry.config['storageProviderConfiguration'] ?= {}
      registry.config['storageProviderConfiguration']['providerClass'] ?= 'com.hortonworks.registries.storage.impl.jdbc.JdbcStorageManager'
      registry.config['storageProviderConfiguration']['properties'] ?= {}
      registry.config['storageProviderConfiguration']['properties']['queryTimeoutInSecs'] ?= 30
      registry.config['storageProviderConfiguration']['properties']['db.type'] ?= 'mysql'
      registry.db[k] ?= v for k, v of db_admin[registry.config['storageProviderConfiguration']['properties']['db.type']]
      registry.db.database ?= 'schema_registry'
      registry.db.username ?= 'registry'
      registry.db.password ?= 'registry123'
      registry.config['storageProviderConfiguration']['properties']['db.properties'] ?= {}
      registry.config['storageProviderConfiguration']['properties']['db.properties']['dataSourceClassName'] ?= 'org.mariadb.jdbc.MariaDbDataSource'
      registry.config['storageProviderConfiguration']['properties']['db.properties']['dataSource.url'] ?= "#{registry.db.jdbc}/#{registry.db.database}"
      registry.config['storageProviderConfiguration']['properties']['db.properties']['dataSource.user'] ?= registry.db.username
      registry.config['storageProviderConfiguration']['properties']['db.properties']['dataSource.password'] ?= registry.db.password
      registry.config['swagger'] ?= {}
      registry.config['swagger']['resourcePackage'] ?= 'com.hortonworks.registries.schemaregistry.webservice'
      registry.config['enableCors'] ?= true
      registry.config['server'] ?= {}
      registry.config['server']['rootPath'] ?= '/api/*'
      registry.config['server']['applicationConnectors'] ?= [{}]
      for con, i in registry.config['server']['applicationConnectors']
        con.type ?= 'http'
        con.port ?= 9080+i
      registry.config['server']['adminConnectors'] ?= [{}]
      for con, i in registry.config['server']['adminConnectors']
        con.type ?= 'http'
        con.port ?= 9090+i
      registry.config['logging'] ?= {}
      registry.config['logging']['level'] ?= 'INFO'
      registry.config['logging']['loggers'] ?= 'com.hortonworks.registries': 'DEBUG'
      registry.config['logging']['appenders'] ?= [{}]
      for appender in registry.config['logging']['appenders']
        appender.type ?= 'file'
        appender.threshold ?= 'DEBUG'
        appender.logFormat ?= "%-6level [%d{HH:mm:ss.SSS}] [%t] %logger{5} - %X{code} %msg %n"
        appender.currentLogFilename ?= "#{registry.log_dir}/registry.log"
        appender.maxFileSize ?= '100MB'
        appender.archivedLogFilenamePattern ?= "#{registry.log_dir}/registry-%d{yyyy-MM-dd}-%i.log.gz"
        appender.archivedFileCount ?= 20

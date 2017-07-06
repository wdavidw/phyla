
# Schema Registry Configure

    module.exports = ->
      {db_admin, realm} = @config.ryba
      options = @config.ryba.registry ?= {}

# Environment

      options.conf_dir ?= '/etc/registry/conf'
      options.pid_dir ?= '/var/run/registry'
      options.log_dir ?= '/var/log/registry'

## Identities

      # Group
      options.group = name: options.group if typeof options.group is 'string'
      options.group ?= {}
      options.group.name ?= 'registry'
      options.group.system ?= true
      # User
      options.user = name: options.user if typeof options.user is 'string'
      options.user ?= {}
      options.user.name ?= 'registry'
      options.user.gid = options.group.name
      options.user.system ?= true
      options.user.comment ?= 'Registry User'
      options.user.home ?= '/var/lib/registry'
      options.user.limits ?= {}
      options.user.limits.nofile ?= 64000
      options.user.limits.nproc ?= 10000
      options.db ?= {}

## Configuration

      options.config ?= {}
      options.config['modules'] ?= [
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
      options.config['fileStorageConfiguration'] ?= {}
      options.config['fileStorageConfiguration']['className'] ?= 'com.hortonworks.registries.common.util.LocalFileSystemStorage'
      options.config['fileStorageConfiguration']['properties'] ?= {}
      options.config['fileStorageConfiguration']['properties']['directory'] ?= "#{options.user.home}/jars"
      options.config['storageProviderConfiguration'] ?= {}
      options.config['storageProviderConfiguration']['providerClass'] ?= 'com.hortonworks.registries.storage.impl.jdbc.JdbcStorageManager'
      options.config['storageProviderConfiguration']['properties'] ?= {}
      options.config['storageProviderConfiguration']['properties']['queryTimeoutInSecs'] ?= 30
      options.config['storageProviderConfiguration']['properties']['db.type'] ?= 'mysql'
      options.db[k] ?= v for k, v of db_admin[options.config['storageProviderConfiguration']['properties']['db.type']]
      options.db.database ?= 'schema_registry'
      options.db.username ?= 'registry'
      options.db.password ?= 'registry123'
      options.config['storageProviderConfiguration']['properties']['db.properties'] ?= {}
      options.config['storageProviderConfiguration']['properties']['db.properties']['dataSourceClassName'] ?= 'org.mariadb.jdbc.MariaDbDataSource'
      options.config['storageProviderConfiguration']['properties']['db.properties']['dataSource.url'] ?= "#{options.db.jdbc}/#{options.db.database}"
      options.config['storageProviderConfiguration']['properties']['db.properties']['dataSource.user'] ?= options.db.username
      options.config['storageProviderConfiguration']['properties']['db.properties']['dataSource.password'] ?= options.db.password
      options.config['swagger'] ?= {}
      options.config['swagger']['resourcePackage'] ?= 'com.hortonworks.registries.schemaregistry.webservice'
      options.config['enableCors'] ?= true
      options.config['server'] ?= {}
      options.config['server']['rootPath'] ?= '/api/*'
      options.config['server']['applicationConnectors'] ?= [{}]
      for con, i in options.config['server']['applicationConnectors']
        con.type ?= 'http'
        con.port ?= 9080+i
      options.config['server']['adminConnectors'] ?= [{}]
      for con, i in options.config['server']['adminConnectors']
        con.type ?= 'http'
        con.port ?= 9090+i
      options.config['logging'] ?= {}
      options.config['logging']['level'] ?= 'INFO'
      options.config['logging']['loggers'] ?= 'com.hortonworks.registries': 'DEBUG'
      options.config['logging']['appenders'] ?= [{}]
      for appender in options.config['logging']['appenders']
        appender.type ?= 'file'
        appender.threshold ?= 'DEBUG'
        appender.logFormat ?= "%-6level [%d{HH:mm:ss.SSS}] [%t] %logger{5} - %X{code} %msg %n"
        appender.currentLogFilename ?= "#{options.log_dir}/registry.log"
        appender.maxFileSize ?= '100MB'
        appender.archivedLogFilenamePattern ?= "#{options.log_dir}/registry-%d{yyyy-MM-dd}-%i.log.gz"
        appender.archivedFileCount ?= 20

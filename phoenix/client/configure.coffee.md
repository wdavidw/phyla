
# Phoenix Configuration

    module.exports = (service) ->
      service = migration.call @, service, 'ryba/phoenix/client', ['ryba', 'phoenix', 'client'], require('nikita/lib/misc').merge require('.').use,
        java: key: ['java']
        test_user: key: ['ryba', 'test_user']
        hbase_master: key: ['ryba', 'hbase', 'master']
        hbase_regionserver: key: ['ryba', 'hbase', 'regionserver']
        hbase_client: key: ['ryba', 'hbase', 'client']
      @config.ryba ?= {}
      options = @config.ryba.phoenix_client = service.options
      options.site = merge service.use.hbase_master[0].options.hbase_site, options.site
      options.admin = merge service.use.hbase_master[0].options.admin, options.admin
      for srv in service.use.hbase_client
        srv.options.hbase_site['phoenix.schema.isNamespaceMappingEnabled'] = 'true'
        srv.options.hbase_site['phoenix.schema.mapSystemTablesToNamespace'] = 'true'
      for srv in service.use.hbase_master
        srv.options.hbase_site['hbase.defaults.for.version.skip'] = 'true'
        srv.options.hbase_site['hbase.regionserver.wal.codec'] = 'org.apache.hadoop.hbase.regionserver.wal.IndexedWALEditCodec'
        srv.options.hbase_site['hbase.table.sanity.checks'] = 'true'
        srv.options.hbase_site['hbase.region.server.rpc.scheduler.factory.class'] = 'org.apache.hadoop.hbase.ipc.PhoenixRpcSchedulerFactory'
        srv.options.hbase_site['hbase.rpc.controllerfactory.class'] = 'org.apache.hadoop.hbase.ipc.controller.ServerRpcControllerFactory'
        srv.options.hbase_site['phoenix.schema.isNamespaceMappingEnabled'] = 'true'
        srv.options.hbase_site['phoenix.schema.mapSystemTablesToNamespace'] = 'true'
      for srv in service.use.hbase_regionserver
        srv.options.hbase_site['hbase.defaults.for.version.skip'] = 'true'
        srv.options.hbase_site['hbase.regionserver.wal.codec'] = 'org.apache.hadoop.hbase.regionserver.wal.IndexedWALEditCodec'
        srv.options.hbase_site['hbase.table.sanity.checks'] = 'true'
        srv.options.hbase_site['hbase.region.server.rpc.scheduler.factory.class'] = 'org.apache.hadoop.hbase.ipc.PhoenixRpcSchedulerFactory'
        srv.options.hbase_site['hbase.rpc.controllerfactory.class'] = 'org.apache.hadoop.hbase.ipc.controller.ServerRpcControllerFactory'
        srv.options.hbase_site['phoenix.schema.isNamespaceMappingEnabled'] = 'true'
        srv.options.hbase_site['phoenix.schema.mapSystemTablesToNamespace'] = 'true'
        
## Test

      options.test = merge {}, service.use.test_user.options, options.test
      options.test.namespace ?= "ryba_check_client_#{service.node.hostname}"
      options.test.table ?= 'a_table'

## Dependencies

    string = require 'nikita/lib/misc/string'
    {merge} = require 'nikita/lib/misc'
    appender = require '../../lib/appender'
    migration = require 'masson/lib/migration'

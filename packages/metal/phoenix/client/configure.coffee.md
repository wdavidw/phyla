
# Phoenix Configuration

    module.exports = (service) ->
      {options, deps, nodes} = service

A Phoenix Client must have one of instance HBase Master, HBase RegionServer or
HBase Client.

      has_hbase = deps.hbase_master_local or deps.hbase_regionserver_local or deps.hbase_client_local
      throw Error "Invalid Configuration: Phoenix Client without HBase on node #{service.node.id}" unless has_hbase

## Kerberos

      # Kerberos Test Principal
      options.test_krb5_user ?= deps.test_user.options.krb5.user

## Environment

      options.hbase_conf_dir ?= switch
        when deps.hbase_client_local then deps.hbase_client_local.options.conf_dir
        when deps.hbase_master_local then deps.hbase_master_local.options.conf_dir
        when deps.hbase_regionserver_local then deps.hbase_regionserver_local.options.conf_dir
        else throw Error 'Undetermined Option: hbase_conf_dir'
      # Misc
      options.hostname = service.node.hostname

## Configuration

      options.site = merge deps.hbase_master[0].options.hbase_site, options.site
      options.admin = merge deps.hbase_master[0].options.admin, options.admin
      for srv in deps.hbase_client
        srv.options.hbase_site['phoenix.schema.isNamespaceMappingEnabled'] = 'true'
        srv.options.hbase_site['phoenix.schema.mapSystemTablesToNamespace'] = 'true'
      for srv in deps.hbase_master
        srv.options.hbase_site['hbase.defaults.for.version.skip'] = 'true'
        srv.options.hbase_site['hbase.regionserver.wal.codec'] = 'org.apache.hadoop.hbase.regionserver.wal.IndexedWALEditCodec'
        srv.options.hbase_site['hbase.table.sanity.checks'] = 'true'
        srv.options.hbase_site['hbase.region.server.rpc.scheduler.factory.class'] = 'org.apache.hadoop.hbase.ipc.PhoenixRpcSchedulerFactory'
        srv.options.hbase_site['hbase.rpc.controllerfactory.class'] = 'org.apache.hadoop.hbase.ipc.controller.ServerRpcControllerFactory'
        srv.options.hbase_site['phoenix.schema.isNamespaceMappingEnabled'] = 'true'
        srv.options.hbase_site['phoenix.schema.mapSystemTablesToNamespace'] = 'true'
      for srv in deps.hbase_regionserver
        srv.options.hbase_site['hbase.defaults.for.version.skip'] = 'true'
        srv.options.hbase_site['hbase.regionserver.wal.codec'] = 'org.apache.hadoop.hbase.regionserver.wal.IndexedWALEditCodec'
        srv.options.hbase_site['hbase.table.sanity.checks'] = 'true'
        srv.options.hbase_site['hbase.region.server.rpc.scheduler.factory.class'] = 'org.apache.hadoop.hbase.ipc.PhoenixRpcSchedulerFactory'
        srv.options.hbase_site['hbase.rpc.controllerfactory.class'] = 'org.apache.hadoop.hbase.ipc.controller.ServerRpcControllerFactory'
        srv.options.hbase_site['phoenix.schema.isNamespaceMappingEnabled'] = 'true'
        srv.options.hbase_site['phoenix.schema.mapSystemTablesToNamespace'] = 'true'
        
## Test

      options.test = merge deps.test_user.options, options.test
      options.test.namespace ?= "ryba_check_client_#{service.node.hostname}"
      options.test.table ?= 'a_table'
      options.hostname = service.node.hostname
      
## Wait

      options.wait_hbase_master = service.deps.hbase_master[0].options.wait
      options.wait_hbase_regionserver = service.deps.hbase_regionserver[0].options.wait

## Dependencies

    string = require '@nikitajs/core/lib/misc/string'
    {merge} = require 'mixme'
    appender = require '../../lib/appender'

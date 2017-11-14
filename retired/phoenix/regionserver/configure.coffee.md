## Configuration

    module.exports = (service) ->
      
      service.deps.hbase_regionserver.options.hbase_site['hbase.defaults.for.version.skip'] = 'true'
      service.deps.hbase_regionserver.options.hbase_site['phoenix.functions.allowUserDefinedFunctions'] = 'true'
      service.deps.hbase_regionserver.options.hbase_site['hbase.regionserver.wal.codec'] = 'org.apache.hadoop.hbase.regionserver.wal.IndexedWALEditCodec'
      service.deps.hbase_regionserver.options.hbase_site['hbase.rpc.controllerfactory.class'] = 'org.apache.hadoop.hbase.ipc.controller.ServerRpcControllerFactory'
      # Factory to create the Phoenix RPC Scheduler that knows to put index updates into index queues:
      # In [HDP 2.3.2 doc](http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.3.2/bk_installing_manually_book/content/configuring-hbase-for-phoenix.html)
      # hbase.site['hbase.region.server.rpc.scheduler.factory.class'] ?= 'org.apache.hadoop.hbase.ipc.PhoenixRpcSchedulerFactory'
      # Historically (and worked)
      service.deps.hbase_regionserver.options.hbase_site['hbase.regionserver.rpc.scheduler.factory.class'] = 'org.apache.hadoop.hbase.ipc.PhoenixRpcSchedulerFactory'
      # [Local Indexing](http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.3.2/bk_installing_manually_book/content/configuring-hbase-for-phoenix.html)
      # The local indexing feature is a technical preview and considered under development.
      # As of dec 2015, dont activate or it will prevent permission from working, displaying a message like
      # "ERROR: DISABLED: Security features are not available" after a grant 
      # hbase.site['hbase.coprocessor.regionserver.classes'] = 'org.apache.hadoop.hbase.regionserver.LocalIndexMerger'


# Phoenix Configuration

    module.exports = ->
      {hbase} = @config.ryba
      hc_ctxs = @contexts 'ryba/hbase/client'
      hm_ctxs = @contexts 'ryba/hbase/master'
      rs_ctxs = @contexts 'ryba/hbase/regionserver'
      # Avoid message "Class org.apache.hadoop.hbase.regionserver.LocalIndexSplitter
      # cannot be loaded Set hbase.table.sanity.checks to false at conf or table
      # descriptor if you want to bypass sanity checks"
      for hc_ctx in hc_ctxs
        hc_ctx.config.ryba.hbase.client.hbase_site['phoenix.schema.isNamespaceMappingEnabled'] = 'true'
        hc_ctx.config.ryba.hbase.client.hbase_site['phoenix.schema.mapSystemTablesToNamespace'] = 'true'
      for hm_ctx in hm_ctxs
        hm_ctx.config.ryba.hbase.master.hbase_site['hbase.defaults.for.version.skip'] = 'true'
        hm_ctx.config.ryba.hbase.master.hbase_site['hbase.regionserver.wal.codec'] = 'org.apache.hadoop.hbase.regionserver.wal.IndexedWALEditCodec'
        hm_ctx.config.ryba.hbase.master.hbase_site['hbase.table.sanity.checks'] = 'true'
        hm_ctx.config.ryba.hbase.master.hbase_site['hbase.region.server.rpc.scheduler.factory.class'] = 'org.apache.hadoop.hbase.ipc.PhoenixRpcSchedulerFactory'
        hm_ctx.config.ryba.hbase.master.hbase_site['hbase.rpc.controllerfactory.class'] = 'org.apache.hadoop.hbase.ipc.controller.ServerRpcControllerFactory'
        hm_ctx.config.ryba.hbase.master.hbase_site['phoenix.schema.isNamespaceMappingEnabled'] = 'true'
        hm_ctx.config.ryba.hbase.master.hbase_site['phoenix.schema.mapSystemTablesToNamespace'] = 'true'
        hm_ctx.after
          type: 'service'
          name: 'hbase-master'
        , ->
          @service
            header: 'Install Phoenix'
            name: 'phoenix'
      for rs_ctx in rs_ctxs
        rs_ctx.config.ryba.hbase.regionserver.hbase_site['hbase.defaults.for.version.skip'] = 'true'
        rs_ctx.config.ryba.hbase.regionserver.hbase_site['hbase.regionserver.wal.codec'] = 'org.apache.hadoop.hbase.regionserver.wal.IndexedWALEditCodec'
        rs_ctx.config.ryba.hbase.regionserver.hbase_site['hbase.table.sanity.checks'] = 'true'
        rs_ctx.config.ryba.hbase.regionserver.hbase_site['hbase.region.server.rpc.scheduler.factory.class'] = 'org.apache.hadoop.hbase.ipc.PhoenixRpcSchedulerFactory'
        rs_ctx.config.ryba.hbase.regionserver.hbase_site['hbase.rpc.controllerfactory.class'] = 'org.apache.hadoop.hbase.ipc.controller.ServerRpcControllerFactory'
        rs_ctx.config.ryba.hbase.regionserver.hbase_site['phoenix.schema.isNamespaceMappingEnabled'] = 'true'
        rs_ctx.config.ryba.hbase.regionserver.hbase_site['phoenix.schema.mapSystemTablesToNamespace'] = 'true'
        rs_ctx.after
          type: 'service'
          name: 'hbase-regionserver'
        , ->
          @service
            header: 'Install Phoenix'
            name: 'phoenix'

## Optimisation

Set "hbase.bucketcache.ioengine" to "offheap".

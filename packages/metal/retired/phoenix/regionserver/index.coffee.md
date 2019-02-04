
# Phoenix

Apache Phoenix is a relational database layer over HBase delivered as a client-embedded
JDBC driver targeting low latency queries over HBase data. Apache Phoenix takes
your SQL query, compiles it into a series of HBase scans, and orchestrates the
running of those scans to produce regular JDBC result sets.

    module.exports =
      deps:
        java: module: 'masson/commons/java', local:true, implicit: true
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        hbase_regionserver: module: '@rybajs/metal/hbase/regionserver', local: true, required: true
      configure:
        '@rybajs/metal/phoenix/regionserver/configure'
      plugin: (options) ->
        @after
          # TODO: add header support to aspect in nikita
          action: 'service'
          name: 'hbase-regionserver'
        , ->
          @service.install name: 'phoenix'
          @registry.register 'hdp_select', '@rybajs/metal/lib/hdp_select'
          @hdp_select name: 'phoenix-client'
          @call require '../lib/hbase_restart'

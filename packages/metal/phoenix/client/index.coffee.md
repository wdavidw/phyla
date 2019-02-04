
# Phoenix

Apache Phoenix is a relational database layer over HBase delivered as a client-embedded
JDBC driver targeting low latency queries over HBase data. Apache Phoenix takes
your SQL query, compiles it into a series of HBase scans, and orchestrates the
running of those scans to produce regular JDBC result sets.

    module.exports =
      deps:
        java: module: 'masson/commons/java', local:true, implicit: true
        test_user: module: '@rybajs/metal/commons/test_user', local: true, auto: true
        hbase_master: module: '@rybajs/metal/hbase/master'
        hbase_master_local: module: '@rybajs/metal/hbase/master', local: true
        hbase_regionserver: module: '@rybajs/metal/hbase/regionserver'
        hbase_regionserver_local: module: '@rybajs/metal/hbase/regionserver', local: true
        hbase_client: module: '@rybajs/metal/hbase/client'
        hbase_client_local: module: '@rybajs/metal/hbase/client', local: true
      configure:
        '@rybajs/metal/phoenix/client/configure'
      plugin: ({options}) ->
        @before
          action: ['service', 'start']
          name: 'hbase-master'
        , ->
          @call '@rybajs/metal/phoenix/client/install'
        @before
          action: ['service', 'start']
          name: 'hbase-regionserver'
        , ->
          @call '@rybajs/metal/phoenix/client/install', options
      commands:
        'install': [
          '@rybajs/metal/phoenix/client/install'
          '@rybajs/metal/phoenix/client/init'
          '@rybajs/metal/phoenix/client/check'
        ]

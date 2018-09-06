
# Phoenix

Apache Phoenix is a relational database layer over HBase delivered as a client-embedded
JDBC driver targeting low latency queries over HBase data. Apache Phoenix takes
your SQL query, compiles it into a series of HBase scans, and orchestrates the
running of those scans to produce regular JDBC result sets.

    module.exports =
      deps:
        java: module: 'masson/commons/java', local:true, implicit: true
        test_user: module: 'ryba/commons/test_user', local: true, auto: true
        hbase_master: module: 'ryba/hbase/master'
        hbase_master_local: module: 'ryba/hbase/master', local: true
        hbase_regionserver: module: 'ryba/hbase/regionserver'
        hbase_regionserver_local: module: 'ryba/hbase/regionserver', local: true
        hbase_client: module: 'ryba/hbase/client'
        hbase_client_local: module: 'ryba/hbase/client', local: true
      configure:
        'ryba/phoenix/client/configure'
      plugin: ({options}) ->
        @before
          action: ['service', 'start']
          name: 'hbase-master'
        , ->
          @call 'ryba/phoenix/client/install'
        @before
          action: ['service', 'start']
          name: 'hbase-regionserver'
        , ->
          @call 'ryba/phoenix/client/install', options
      commands:
        'install': [
          'ryba/phoenix/client/install'
          'ryba/phoenix/client/init'
          'ryba/phoenix/client/check'
        ]

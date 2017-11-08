
# Phoenix

Apache Phoenix is a relational database layer over HBase delivered as a client-embedded
JDBC driver targeting low latency queries over HBase data. Apache Phoenix takes
your SQL query, compiles it into a series of HBase scans, and orchestrates the
running of those scans to produce regular JDBC result sets.

    module.exports =
      use:
        java: module: 'masson/commons/java', local:true, implicit: true
        test_user: module: 'ryba/commons/test_user', local: true, auto: true, implicit: true
        hbase_master: module: 'ryba/hbase/master'
        hbase_regionserver: module: 'ryba/hbase/regionserver'
        hbase_client: module: 'ryba/hbase/client', implicit: true
      configure:
        'ryba/phoenix/client/configure'
      plugin: ->
        options = @config.ryba.hbase
        @after
          type: ['service', 'install']
          name: 'hbase-master'
        , ->
          @call 'ryba/phoenix/client/install', options
        @after
          type: ['service', 'install']
          name: 'hbase-regionserver'
        , ->
          @call 'ryba/phoenix/client/install', options
      commands:
        'install': ->
          options = @config.ryba.phoenix_client
          @call 'ryba/phoenix/client/install', options
          @call 'ryba/phoenix/client/init', options
          @call 'ryba/phoenix/client/check', options

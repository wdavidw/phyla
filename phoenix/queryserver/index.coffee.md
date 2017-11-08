
# Phoenix

Apache Phoenix is a relational database layer over HBase delivered as a client-embedded
JDBC driver targeting low latency queries over HBase data. Apache Phoenix takes
your SQL query, compiles it into a series of HBase scans, and orchestrates the
running of those scans to produce regular JDBC result sets.

    module.exports =
      use:
        java: module: 'masson/commons/java', local:true, implicit: true
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        hadoop_core: module: 'ryba/hadoop/core', local: true, auto: true, implicit: true
        hbase_client: module: 'ryba/hbase/client'
        phoenix_client: module: 'ryba/phoenix/client'
      configure:
        'ryba/phoenix/queryserver/configure'
      commands:
        install: ->
          options = @config.ryba.phoenix_queryserver
          @call 'ryba/phoenix/queryserver/install', options
          @call 'ryba/phoenix/queryserver/start', options
          @call 'ryba/phoenix/queryserver/check', options
        check: ->
          options = @config.ryba.phoenix_queryserver
          @call 'ryba/phoenix/queryserver/check', options
        status: ->
          options = @config.ryba.phoenix_queryserver
          @call 'ryba/phoenix/queryserver/status', options
        start: ->
          options = @config.ryba.phoenix_queryserver
          @call 'ryba/phoenix/queryserver/start', options
        stop: ->
          options = @config.ryba.phoenix_queryserver
          @call 'ryba/phoenix/queryserver/stop', options

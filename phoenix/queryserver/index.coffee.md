
# Phoenix

Apache Phoenix is a relational database layer over HBase delivered as a client-embedded
JDBC driver targeting low latency queries over HBase data. Apache Phoenix takes
your SQL query, compiles it into a series of HBase scans, and orchestrates the
running of those scans to produce regular JDBC result sets.

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        java: module: 'masson/commons/java', local:true, implicit: true
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        hadoop_core: module: 'ryba/hadoop/core', local: true, auto: true, implicit: true
        hbase_client: module: 'ryba/hbase/client'
        phoenix_client: module: 'ryba/phoenix/client'
      configure:
        'ryba/phoenix/queryserver/configure'
      commands:
        install: [
          'ryba/phoenix/queryserver/install'
          'ryba/phoenix/queryserver/start'
          'ryba/phoenix/queryserver/check'
        ]
        check:
          'ryba/phoenix/queryserver/check'
        status:
          'ryba/phoenix/queryserver/status'
        start:
          'ryba/phoenix/queryserver/start'
        stop:
          'ryba/phoenix/queryserver/stop'

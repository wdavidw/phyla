
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
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true, auto: true, implicit: true
        hbase_client: module: '@rybajs/metal/hbase/client'
        phoenix_client: module: '@rybajs/metal/phoenix/client'
      configure:
        '@rybajs/metal/phoenix/queryserver/configure'
      commands:
        install: [
          '@rybajs/metal/phoenix/queryserver/install'
          '@rybajs/metal/phoenix/queryserver/start'
          '@rybajs/metal/phoenix/queryserver/check'
        ]
        check:
          '@rybajs/metal/phoenix/queryserver/check'
        status:
          '@rybajs/metal/phoenix/queryserver/status'
        start:
          '@rybajs/metal/phoenix/queryserver/start'
        stop:
          '@rybajs/metal/phoenix/queryserver/stop'

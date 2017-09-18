
# HBase Rest Gateway
Stargate is the name of the REST server bundled with HBase.
The [REST Server](http://wiki.apache.org/hadoop/Hbase/Stargate) is a daemon which enables other application to request HBASE database via http.
Of course we deploy the secured version of the configuration of this API.

    module.exports =
      use:
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        test_user: module: 'ryba/commons/test_user', local: true, auto: true, implicit: true
        hadoop_core: module: 'ryba/hadoop/core', local: true, auto: true, implicit: true
        hdfs_dn: module: 'ryba/hadoop/core', required: true
        hdfs_client: module: 'ryba/hadoop/hdfs_client', local: true, required: true
        hbase_master: module: 'ryba/hbase/master', required: true
        hbase_regionserver: module: 'ryba/hbase/regionserver', required: true
        hbase_client: module: 'ryba/hbase/client', local: true
        hbase_rest: module: 'ryba/hbase/thrift'
        ranger_admin: module: 'ryba/ranger/admin', single: true
        ranger_hbase: module: 'ryba/ranger/plugins/hbase'
      configure:
        'ryba/hbase/rest/configure'
      commands:
        'check': ->
          options = @config.ryba.hbase.rest
          @call 'ryba/hbase/rest/check', options
        'install': ->
          options = @config.ryba.hbase.rest
          @call 'ryba/hbase/rest/install', options
          @call 'ryba/hbase/rest/start', options
          @call 'ryba/hbase/rest/check', options
        'start': ->
          options = @config.ryba.hbase.rest
          @call 'ryba/hbase/rest/start', options
        'status':
          'ryba/hbase/rest/status'
        'stop': ->
          options = @config.ryba.hbase.rest
          @call 'ryba/hbase/rest/stop', options

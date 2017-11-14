
# OpenTSDB

[OpenTSDB][website] is a distributed, scalable Time Series Database (TSDB) written on
top of HBase.  OpenTSDB was written to address a common need: store, index
and serve metrics collected from computer systems (network gear, operating
systems, applications) at a large scale, and make this data easily accessible
and graphable.
OpenTSDB does not seem to work without the hbase rights

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        test_user: module: 'ryba/commons/test_user', local: true, auto: true
        zookeeper_server: module: 'ryba/zookeeper/server', required: true
        hadoop_core: module: 'ryba/hadoop/core', local: true, required: true
        hbase_client: module: 'ryba/hbase/client', local: true, auto: true
        hbase_master: module: 'ryba/hbase/master', required: true
        hbase_regionserver: module: 'ryba/hbase/regionserver', required: true
        ranger_admin: module: 'ryba/ranger/admin', single: true
        ranger_plugin_hbase: module: 'ryba/ranger/plugin/hbase'
      configure:
        'ryba/opentsdb/configure'
      commands:
        'install': [
          'ryba/opentsdb/install'
          'ryba/opentsdb/start'
          'ryba/opentsdb/check'
        ]
        'prepare':
          'ryba/opentsdb/prepare'
        'start':
          'ryba/opentsdb/start'
        'check':
          'ryba/opentsdb/check'
        'status':
          'ryba/opentsdb/status'
        'stop':
          'ryba/opentsdb/stop'
        'wait':
          'ryba/opentsdb/wait'

## Resources

*   [OpentTSDB: Configuration](http://opentsdb.net/docs/build/html/user_guide/configuration.html)

[website]: http://opentsdb.net/


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
        test_user: module: '@rybajs/metal/commons/test_user', local: true, auto: true
        zookeeper_server: module: '@rybajs/metal/zookeeper/server', required: true
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true, required: true
        hbase_client: module: '@rybajs/metal/hbase/client', local: true, auto: true
        hbase_master: module: '@rybajs/metal/hbase/master', required: true
        hbase_regionserver: module: '@rybajs/metal/hbase/regionserver', required: true
        ranger_admin: module: '@rybajs/metal/ranger/admin', single: true
        ranger_plugin_hbase: module: '@rybajs/metal/ranger/plugin/hbase'
      configure:
        '@rybajs/metal/opentsdb/configure'
      commands:
        'install': [
          '@rybajs/metal/opentsdb/install'
          '@rybajs/metal/opentsdb/start'
          '@rybajs/metal/opentsdb/check'
        ]
        'prepare':
          '@rybajs/metal/opentsdb/prepare'
        'start':
          '@rybajs/metal/opentsdb/start'
        'check':
          '@rybajs/metal/opentsdb/check'
        'status':
          '@rybajs/metal/opentsdb/status'
        'stop':
          '@rybajs/metal/opentsdb/stop'
        'wait':
          '@rybajs/metal/opentsdb/wait'

## Resources

*   [OpentTSDB: Configuration](http://opentsdb.net/docs/build/html/user_guide/configuration.html)

[website]: http://opentsdb.net/

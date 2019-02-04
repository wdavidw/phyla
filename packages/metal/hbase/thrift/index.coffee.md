
# HBase ThriftServer

[Apache Thrift](http://wiki.apache.org/hadoop/Hbase/ThriftApi) is a
cross-platform, cross-language development framework. HBase includes a Thrift 
API and filter language. The Thrift API relies on client and server processes.
Thrift is both cross-platform and more lightweight than REST for many operations.

From 1.0 thrift can enable impersonation for other service 
[like hue][hue-hbase-impersonation].

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true, auto: true, implicit: true
        hdfs_dn: module: '@rybajs/metal/hadoop/hdfs_dn', required: true
        hdfs_client: module: '@rybajs/metal/hadoop/hdfs_client', local: true, required: true
        hbase_master: module: '@rybajs/metal/hbase/master', required: true
        hbase_regionserver: module: '@rybajs/metal/hbase/regionserver', required: true
        hbase_client: module: '@rybajs/metal/hbase/client', local: true
        hbase_thrift: module: '@rybajs/metal/hbase/thrift'
      configure:
        '@rybajs/metal/hbase/thrift/configure'
      commands:
        'check':
          '@rybajs/metal/hbase/thrift/check'
        'install': [
          '@rybajs/metal/hbase/thrift/install'
          '@rybajs/metal/hbase/thrift/start'
          '@rybajs/metal/hbase/thrift/check'
        ]
        'start':
          '@rybajs/metal/hbase/thrift/start'
        'status':
          '@rybajs/metal/hbase/thrift/status'
        'stop':
          '@rybajs/metal/hbase/thrift/stop'

[hue-hbase-impersonation]:(http://gethue.com/hbase-browsing-with-doas-impersonation-and-kerberos/)
[hbase-configuration]:(http://www.cloudera.com/content/www/en-us/documentation/enterprise/latest/topics/cdh_sg_hbase_authentication.html/)

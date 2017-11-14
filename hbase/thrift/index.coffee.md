
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
        hadoop_core: module: 'ryba/hadoop/core', local: true, auto: true, implicit: true
        hdfs_dn: module: 'ryba/hadoop/hdfs_dn', required: true
        hdfs_client: module: 'ryba/hadoop/hdfs_client', local: true, required: true
        hbase_master: module: 'ryba/hbase/master', required: true
        hbase_regionserver: module: 'ryba/hbase/regionserver', required: true
        hbase_client: module: 'ryba/hbase/client', local: true
        hbase_thrift: module: 'ryba/hbase/thrift'
      configure:
        'ryba/hbase/thrift/configure'
      commands:
        'check':
          'ryba/hbase/thrift/check'
        'install': [
          'ryba/hbase/thrift/install'
          'ryba/hbase/thrift/start'
          'ryba/hbase/thrift/check'
        ]
        'start':
          'ryba/hbase/thrift/start'
        'status':
          'ryba/hbase/thrift/status'
        'stop':
          'ryba/hbase/thrift/stop'

[hue-hbase-impersonation]:(http://gethue.com/hbase-browsing-with-doas-impersonation-and-kerberos/)
[hbase-configuration]:(http://www.cloudera.com/content/www/en-us/documentation/enterprise/latest/topics/cdh_sg_hbase_authentication.html/)

# HBase Thrift Server Start

Start the Thrift server. You can also start the server manually with one of the
following two commands:

```
service hbase-thrift start
su -l hbase -c "/usr/hdp/current/hbase-client/bin/hbase-daemon.sh --config /etc/hbase/conf start thrift"
```

    module.exports =  header: 'HBase Thrift Start', handler: ({options}) ->

Wait for Kerberos, ZooKeeper, HDFS and Hbase Master to be started.

      @call 'masson/core/krb5_client/wait', once: true, options.wait_krb5_client
      @call 'ryba/hbase/master/wait', once: true, options.wait_hbase_master

Start the service.

      @service.start
        header: 'Service'
        name: 'hbase-thrift'

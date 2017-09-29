
# Hive Server2 Start

The Hive HCatalog require the database server to be started. The Hive Server2
require the HDFS Namenode to be started. Both of them will need to functionnal
HDFS server to answer queries.

    module.exports = header: 'Hive Server2 Start', handler: (options) ->

## Wait

Wait for Kerberos, Zookeeper, Hadoop and Hive HCatalog.

      @call 'masson/core/krb5_client/wait', once: true, options.wait_krb5_client
      @call 'ryba/zookeeper/server/wait', once: true, options.wait_zookeeper_server
      @call 'ryba/hive/hcatalog/wait', once: true, options.wait_hive_hcatalog

## Service

Start the Hive Server2. You can also start the server manually with one of the
following two commands:

```
service hive-server2 start
systemctl start hive-server2
su -l hive -c 'nohup /usr/hdp/current/hive-server2/bin/hiveserver2 >/var/log/hive/hiveserver2.out 2>/var/log/hive/hiveserver2.log & echo $! >/var/run/hive-server2/hive-server2.pid'
```

      @service.start
        name: 'hive-server2'

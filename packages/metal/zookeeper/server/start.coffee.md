
# Zookeeper Server Start

Start the ZooKeeper server. You can also start the server manually with the
following two commands:

```
service zookeeper-server start
su - zookeeper -c "export ZOOCFGDIR=/usr/hdp/current/zookeeper-server/conf; export ZOOCFG=/etc/zookeeper/conf/zoo.cfg; source /usr/hdp/current/zookeeper-server/conf/zookeeper-env.sh; /usr/hdp/current/zookeeper-server/bin/zkServer.sh start"
```

    module.exports = header: 'ZooKeeper Server Start', handler: ({options}) ->
      
Wait for Kerberos to be started.
      
      @call 'masson/core/krb5_client/wait', once:true, options.wait_krb5_client

Start the service.

      @service.start name: 'zookeeper-server'

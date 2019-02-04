
# Kafka Broker Start

Start the Kafka Broker.

    module.exports = header: 'Kafka Broker Start', handler: ({options}) ->

## Wait

Wait for Kerberos and ZooKeeper.

      @call 'masson/core/krb5_client/wait', once: true, options.wait_krb5_client
      @call '@rybajs/metal/zookeeper/server/wait', once: true, options.wait_zookeeper_server

## service.

You can also start the server manually with the following commands:

```
service kafka-broker start
systemctl start kafka-broker
su - kafka -c '/usr/hdp/current/kafka-broker/bin/kafka start'
```

      @service.start
        header: 'Service'
        name: 'kafka-broker'

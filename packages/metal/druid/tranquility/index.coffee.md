
# Tranquility Server

[Tranquility] helps you send real-time event streams to Druid and handles 
partitioning, replication, service discovery, and schema rollover, seamlessly 
and without downtime.  You only have to define your Druid schema.

If you have a program that generates a stream, then you can push that stream 
directly into Druid in real-time. With this approach, Tranquility is embedded 
in your data-producing application. Tranquility comes with bindings for the 
Storm and Samza stream processors. It also has a direct API that can be used 
from any JVM-based program, such as Spark Streaming or a Kafka consumer.

For examples and more information, please see the [Tranquility README][readme].

The documentation [suggest](http://druid.io/docs/0.10.1/ingestion/stream-push.html) 
to colocate the Transquility servers with the Druid middleManagers and historical processes.

[Tranquility]: http://druid.io/docs/0.9.1.1/ingestion/stream-ingestion.html#server
[readme]: https://github.com/druid-io/tranquility

    module.exports =
      deps:
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true, recommanded: true
        iptables: module: 'masson/core/iptables', local: true
        druid: module: '@rybajs/metal/druid/base', local: true, auto: true, implicit: true
        druid_tranquility: module: '@rybajs/metal/druid/tranquility'
      configure:
        '@rybajs/metal/druid/tranquility/configure'
      commands:
        'prepare':
          '@rybajs/metal/druid/tranquility/prepare'
        'install': [
          '@rybajs/metal/druid/tranquility/install'
          '@rybajs/metal/druid/tranquility/start'
        ]
        # 'start':
        #   '@rybajs/metal/druid/tranquility/start'
        # 'status':
        #   '@rybajs/metal/druid/tranquility/status'
        # 'stop':
        #   '@rybajs/metal/druid/tranquility/stop'

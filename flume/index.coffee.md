
# Flume

[Flume](https://flume.apache.org/) is a distributed, reliable, and available service for efficiently
collecting, aggregating, and moving large amounts of log data. It has a simple
and flexible architecture based on streaming data flows. It is robust and fault
tolerant with tunable reliability mechanisms and many failover and recovery
mechanisms.

    module.exports =
      use:
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        hadoop_core: module: 'ryba/hadoop/core', local: true, auto: true, implicit: true
      configure:
        'ryba/flume/configure'
      commands:
        'install': ->
          options = @config.ryba.flume
          @call 'ryba/flume/install', options

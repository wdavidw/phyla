
# Kafka Client Install

    module.exports = header: 'Kafka Client Install', handler: ({options}) ->

## Register

      @registry.register 'hdp_select', '@rybajs/metal/lib/hdp_select'
      @registry.register ['file', 'jaas'], '@rybajs/metal/lib/file_jaas'

## Identities

By default, the "kafka" package create the following entries:

```bash
cat /etc/passwd | grep kafka
kafka:x:496:496:KAFKA:/home/kafka:/bin/bash
cat /etc/group | grep kafka
kafka:x:496:kafka
```

      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user

## Package

Install the Kafka producer package and set it to the latest version. Note, we
select the "kafka-broker" HDP directory. There is no "kafka-producer"
directories.

      @service
        name: 'kafka'
      @system.mkdir
        target: '/var/lib/kafka'
        uid: options.user.name
        gid: options.user.name
      @hdp_select
        name: 'kafka-broker'

## Configure

Update the file "server.properties" with the properties defined by the
"ryba.kafka.server" configuration.

      @file
        header: 'Producer Properties'
        target: "#{options.conf_dir}/producer.properties"
        write: for k, v of options.producer.config
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true
      @file
        header: 'Consumer Properties'
        target: "#{options.conf_dir}/consumer.properties"
        write: for k, v of options.consumer.config
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true

## Logging

      @file
        header: 'Tools Log4j'
        target: "#{options.conf_dir}/tools-log4j.properties"
        write: for k, v of options.log4j
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true
      @file
        header: 'Log4j'
        target: "#{options.conf_dir}/log4j.properties"
        write: for k, v of options.log4j
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true
      @file
        header: 'Test Log4j'
        target: "#{options.conf_dir}/test-log4j.properties"
        write: for k, v of options.log4j
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true

## Kerberos

      @file.jaas
        header: 'Client JAAS'
        if: -> options.env['KAFKA_KERBEROS_PARAMS']?
        target: "#{options.conf_dir}/kafka-client.jaas"
        mode: 0o644
        content:
          KafkaClient:
            useTicketCache: true
            serviceName: options.user.name
          Client:
            useTicketCache: true
            serviceName: options.user.name
        uid: options.user.name
        gid: options.group.name

## Environment

Exports JAAS configuration to producer JVM properties.

      @file
        header: 'Environment'
        target: "#{options.conf_dir}/kafka-env.sh"
        write: for k, v of options.env
          match: RegExp "export #{k}=.*", 'm'
          replace: "export #{k}=\"#{v}\" # RYBA, DONT OVERWRITE"
          append: true
        backup: true
        eof: true

## SSL

Imports broker's CA to truststore.

      @java.keystore_add
        header: 'SSL Client'
        if: -> options.config['ssl.truststore.location']?
        keystore: options.config['ssl.truststore.location']
        storepass: options.config['ssl.truststore.password']
        caname: "hadoop_root_ca"
        cacert: options.ssl.cacert.source
        local: options.ssl.cacert.local

## Dependencies

    quote = require 'regexp-quote'

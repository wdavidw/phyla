

## Configure

    module.exports = (service) ->
      options = service.options

## Identities

Merge group and user from the Kafka broker configuration.

      options.group = merge {}, service.deps.kafka_broker[0].options.group, options.group
      options.user = merge {}, service.deps.kafka_broker[0].options.user, options.user
      # Admin principal
      options.admin ?= {}
      options.admin.principal ?= service.deps.kafka_broker[0].options.admin.principal
      options.admin.password ?= service.deps.kafka_broker[0].options.admin.password
      options.superusers ?= service.deps.kafka_broker[0].options.superusers
      # Ranger
      options.ranger_admin ?= service.deps.ranger_admin.options.admin if service.deps.ranger_admin

## Environment

      # Layout
      options.conf_dir ?= '/etc/kafka/conf'
      # Env
      options.env ?= {}
      # Misc
      options.hostname = service.node.hostname

## Kerberos

      # JAAS
      if service.deps.kafka_broker[0].options.config['zookeeper.set.acl'] is 'true'
        options.env['KAFKA_KERBEROS_PARAMS'] ?= "-Djava.security.auth.login.config=#{options.conf_dir}/kafka-client.jaas"
      # Kerberos Test Principal
      options.test_krb5_user ?= service.deps.test_user.options.krb5.user

## Configuration

      options.config ?= {}
      # Consumer
      options.consumer ?= {}
      options.consumer.config ?= {}
      options.consumer.config['zookeeper.connect'] ?= service.deps.kafka_broker[0].options.zookeeper_quorum
      options.consumer.config['group.id'] ?= 'ryba-consumer-group'
      # Producer
      options.producer ?= {}
      options.producer.config ?= {}
      options.producer.config['compression.codec'] ?= 'snappy'
      # for now the prop 'sasl.kerberos.service.name' has to be deleted because of
      # https://issues.apache.org/jira/browse/KAFKA-2974
      # http://mail-archives.apache.org/mod_mbox/kafka-commits/201512.mbox/%3Cacb73f26d3bd440ab8a9f33686db0020@git.apache.org%3E
      # which result with the error:
      # Conflicting serviceName values found in JAAS and Kafka configs value in JAAS file kafka, value in Kafka config kafka
      # fixed in 0.9.0.1
      # kafka.consumer.config['sasl.kerberos.service.name'] =  service.deps.kafka_broker[0].options.config['sasl.kerberos.service.name']
      delete options.consumer.config['sasl.kerberos.service.name']

## Brokers and protocols

Producer config does not support several protocol like kafka/broker (for
example the 'listeners' property), this is why we make dynamic discovery of the 
best protocol available and pass needed protocol to command line in the checks.

      options.protocols = service.deps.kafka_broker[0].options.protocols
      options.brokers = {}
      for protocol in options.protocols
        options.brokers[protocol] = for srv in service.deps.kafka_broker
          "#{srv.node.fqdn}:#{srv.options.ports[protocol]}"
      ssl_enabled = if  service.deps.kafka_broker[0].options.config['ssl.keystore.location'] then true else false
      sasl_enabled = if  service.deps.kafka_broker[0].options.kerberos then true else false
      recommended_protocol = if sasl_enabled
        if ssl_enabled then 'SASL_SSL' else 'SASL_PLAINTEXT'
      else
        if ssl_enabled then 'SSL' else 'PLAINTEXT'
      # Producer
      options.producer.config['security.protocol'] ?= options.protocols
      options.producer.config['metadata.broker.list'] ?= options.brokers[recommended_protocol].join ','
      options.producer.config['bootstrap.servers'] ?= options.brokers[recommended_protocol].join ','
      # Consumer
      options.consumer.config['security.protocol'] ?= recommended_protocol

## Log4j

      # Producer
      options.log4j ?= {}
      options.log4j['log4j.rootLogger'] ?= 'INFO, stdout'
      options.log4j['log4j.appender.stdout'] ?= 'org.apache.log4j.ConsoleAppender'
      options.log4j['log4j.appender.stdout.layout'] ?= 'org.apache.log4j.PatternLayout'
      options.log4j['log4j.appender.stdout.layout.ConversionPattern'] ?= '[%d] %p %m (%c)%n'

## SSL

      options.ssl = merge {}, service.deps.ssl?.options, options.ssl
      # Configuration
      ssl_enabled = service.deps.kafka_broker[0].options.protocols.some (protocol) ->
        protocol in ['SASL_SSL', 'SSL']
      if ssl_enabled
        options.config['ssl.truststore.location'] ?= "#{options.conf_dir}/truststore"
        options.config['ssl.truststore.password'] ?= 'ryba123'
        options.consumer.config['ssl.truststore.location'] ?= options.config['ssl.truststore.location']
        options.consumer.config['ssl.truststore.password'] ?= options.config['ssl.truststore.password']
        options.producer.config['ssl.truststore.location'] ?= options.config['ssl.truststore.location']
        options.producer.config['ssl.truststore.password'] ?= options.config['ssl.truststore.password']

## Test

      options.ranger_install = service.deps.ranger_kafka[0].options.install if service.deps.ranger_kafka
      options.test = merge {}, service.deps.test_user.options, options.test

## Wait

      options.wait_krb5_client = service.deps.krb5_client.options.wait
      options.wait_zookeeper_server = service.deps.zookeeper_server[0].options.wait
      options.wait_kafka_broker = service.deps.kafka_broker[0].options.wait
      options.wait_ranger_admin = service.deps.ranger_admin.options.wait if service.deps.ranger_admin

## Dependencies

    {merge} = require 'nikita/lib/misc'

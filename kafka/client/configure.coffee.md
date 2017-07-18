

## Configure

    module.exports = ->
      # Init
      options = @config.ryba.kafka ?= {}
      # ZooKeeper Quorum
      zoo_ctxs = @contexts('ryba/zookeeper/server').filter( (ctx) -> ctx.config.ryba.zookeeper.config['peerType'] is 'participant')
      zookeeper_quorum = for zoo_ctx in zoo_ctxs
        "#{zoo_ctx.config.host}:#{zoo_ctx.config.ryba.zookeeper.port}"
      ks_ctxs = @contexts 'ryba/kafka/broker'
      throw Error 'Cannot configure kafka consumer without broker' unless ks_ctxs.length > 0

## Identities

      options.group = merge ks_ctxs[0].config.ryba.kafka.group, options.group
      options.user = merge ks_ctxs[0].config.ryba.kafka.user, options.user

## Configuration

      #conf_dr
      options.config ?= {}
      options.conf_dir ?= '/etc/kafka/conf'
      #admin principal
      options.admin ?= {}
      options.admin.principal ?= ks_ctxs[0].config.ryba.kafka.admin.principal
      options.admin.password ?= ks_ctxs[0].config.ryba.kafka.admin.password
      # Consumer
      options.consumer ?= {}
      options.consumer.config ?= {}
      options.consumer.config['zookeeper.connect'] ?= zookeeper_quorum
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
      # kafka.consumer.config['sasl.kerberos.service.name'] =  ks_ctxs[0].config.ryba.kafka.broker.config['sasl.kerberos.service.name']
      delete options.consumer.config['sasl.kerberos.service.name']
      # producer config does not support several protocol like kafka/broker (e.g. 'listeners' property)
      # thats why we make dynamic discovery of the best protocol available
      # and pass needed protocol to command line in the checks
      protocols = ks_ctxs[0].config.ryba.kafka.broker.protocols
      ssl_enabled = if  ks_ctxs[0].config.ryba.kafka.broker.config['ssl.keystore.location'] then true else false
      sasl_enabled = if  ks_ctxs[0].config.ryba.kafka.broker.kerberos then true else false
      protocol = ''
      if sasl_enabled
        protocol = 'SASL_PLAINTEXT'
        if ssl_enabled
          protocol = 'SASL_SSL'
      else
        if ssl_enabled
          protocol = 'SSL'
        else
          protocol = 'PLAINTEXT'
      brokers = for ks_ctx in ks_ctxs
        "#{ks_ctx.config.host}:#{ks_ctx.config.ryba.kafka.broker.ports[protocol]}"
      options.protocols ?= protocols
      #producer
      options.producer.config['security.protocol'] ?= options.protocols
      options.producer.config['metadata.broker.list'] ?= brokers.join ','
      options.producer.config['bootstrap.servers'] ?= brokers.join ','
      options.producer.protocols ?= protocols
      #consumer
      options.consumer.config['security.protocol'] ?= options.protocols
      options.consumer.protocols ?= protocols


## Log4j

      # producer log4j
      options.log4j ?= {}
      options.log4j['log4j.rootLogger'] ?= 'INFO, stdout'
      options.log4j['log4j.appender.stdout'] ?= 'org.apache.log4j.ConsoleAppender'
      options.log4j['log4j.appender.stdout.layout'] ?= 'org.apache.log4j.PatternLayout'
      options.log4j['log4j.appender.stdout.layout.ConversionPattern'] ?= '[%d] %p %m (%c)%n'

## SSL

      ssl_enabled = false
      for protocol in ks_ctxs[0].config.ryba.kafka.broker.protocols
        continue unless ['SASL_SSL','SSL'].indexOf(protocol) > -1
        ssl_enabled = true
      if ssl_enabled
        options.config['ssl.truststore.location'] ?= "#{options.conf_dir}/truststore"
        options.config['ssl.truststore.password'] ?= 'ryba123'
        options.consumer.config['ssl.truststore.location'] ?= options.config['ssl.truststore.location']
        options.consumer.config['ssl.truststore.password'] ?= options.config['ssl.truststore.password']
        options.producer.config['ssl.truststore.location'] ?= options.config['ssl.truststore.location']
        options.producer.config['ssl.truststore.password'] ?= options.config['ssl.truststore.password']

## Kerberos

      options.env ?= {}
      if ks_ctxs[0].config.ryba.kafka.broker.config['zookeeper.set.acl'] is 'true'
        options.env['KAFKA_KERBEROS_PARAMS'] ?= "-Djava.security.auth.login.config=#{options.conf_dir}/kafka-client.jaas"
## Dependencies

    {merge} = require 'nikita/lib/misc'

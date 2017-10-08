
# Apache Atlas Hive Plugin Configuration

    module.exports = ->
      service = migration.call @, service, 'ryba/atlas/hive', ['ryba', 'atlas', 'hive'], require('nikita/lib/misc').merge require('.').use,
        kafka_broker: key: ['ryba', 'kafka', 'broker']
        hive_server2: key: ['ryba', 'hive', 'server2']
        atlas: key: ['ryba', 'atlas']
      @config.ryba.atlas ?= {}
      options = @config.ryba.atlas.hive = service.options

## Environment

      options.conf_dir = service.use.hive_server2.options.conf_dir

## Configuration

Mechanism: The Apache Hive Hook (or Atlas hook) is running directly inside the
hiveserver2's JVM. As a consequence, Kafka Client configuration must be configured 
on the hiveserver2 side.

Ryba does the follwing steps:
- Configure Hiveserver2' hive-site.xml file with Atlas Props
- Write Atlas Configuration file for hive's bridge. Atlas.Hive.Hook needs the 
atlas applcation file in the hive-server2's configuration directory. 

Note: The file must be named "atlas-application.properties" because it is
hard coded.

      service.use.hive_server2.options.atlas ?= {}
      service.use.hive_server2.options.atlas.client ?= {}
      options.client.properties ?= {}
      options.client.properties['atlas.http.authentication.enabled'] ?= service.use.atlas.options.application.properties['atlas.http.authentication.enabled']
      options.client.properties['atlas.http.authentication.type'] ?= service.use.atlas.options.application.properties['atlas.http.authentication.type']
      service.use.hive_server2.options.atlas.application ?= {}
      options.application.properties ?= {}
      options.application.properties['atlas.hook.hive.synchronous'] ?= 'false'
      options.application.properties['atlas.hook.hive.numRetries'] ?= '3'
      options.application.properties['atlas.hook.hive.minThreads'] ?= '5'
      options.application.properties['atlas.hook.hive.maxThreads'] ?= '5'
      options.application.properties['atlas.hook.hive.keepAliveTime'] ?= '10'
      options.application.properties['atlas.hook.hive.queueSize'] ?= '10000'
      service.use.hive_server2.options.site['atlas.cluster.name'] ?= "#{options.cluster_name}"
      # Step 1 - check if the rest adress already written
      # Step 2 (only if 1) Check if an url is already written
      service.use.hive_server2.options.site['atlas.rest.address'] = add_prop service.use.hive_server2.options.site['atlas.rest.address'], rest_address, ','
      service.use.hive_server2.options.site['hive.exec.post.hooks'] = add_prop service.use.hive_server2.options.site['hive.exec.post.hooks'], 'org.apache.atlas.hive.hook.HiveHook', ','
      # service.use.hive_server2.options.aux_jars = add_prop service.use.hive_server2.options.aux_jars, "/usr/hdp/current/atlas-client/hook/hive", ':'

## Kafka Notifications

      chanels = []
      chanels.push 'SASL_SSL' if @config.ryba.security is 'kerberos' and service.use.hive_server2.options.site['hive.server2.use.SSL'] is 'true'
      chanels.push 'SASL_PLAINTEXT' if @config.ryba.security is 'kerberos'
      chanels.push 'SSL' if service.use.hive_server2.options.site['hive.server2.use.SSL'] is 'true'
      chanels.push 'PLAINTEXT'
      options.application.properties['atlas.kafka.security.protocol'] ?= chanels[0]
      options.application.properties['atlas.notification.topics'] ?= service.use.atlas.options.application.properties['atlas.notification.topics']
      options.application.properties['atlas.kafka.bootstrap.servers'] ?= service.use.atlas.options.application.properties[prop]
      # Configure Hive Server2 JAAS Properties for posting notifications to Kafka
      if options.application.properties['atlas.kafka.security.protocol'] in ['SASL_PLAINTEXT','SASL_SSL']
        options.application.properties['atlas.jaas.KafkaClient.loginModuleControlFlag'] ?= 'required'
        options.application.properties['atlas.jaas.KafkaClient.loginModuleName'] ?= 'com.sun.security.auth.module.Krb5LoginModule'
        options.application.properties['atlas.jaas.KafkaClient.option.keyTab'] ?= service.use.hive_server2.options.site['hive.server2.authentication.kerberos.keytab']
        options.application.properties['atlas.jaas.KafkaClient.option.principal'] ?= service.use.hive_server2.options.site['hive.server2.authentication.kerberos.principal']
        options.application.properties['atlas.jaas.KafkaClient.option.serviceName'] ?= 'kafka'
        options.application.properties['atlas.jaas.KafkaClient.option.storeKey'] ?= 'true'
        options.application.properties['atlas.jaas.KafkaClient.option.useKeyTab'] ?= 'true'
      if options.application.properties['atlas.kafka.security.protocol'] in ['SSL','SASL_SSL']
        options.application.properties['atlas.kafka.ssl.truststore.location'] ?= service.use.hive_server.options.ssl.ssl_client['ssl.client.truststore.location']
        options.application.properties['atlas.kafka.ssl.truststore.password'] ?= service.use.hive_server.options.ssl.ssl_client['ssl.client.truststore.password']
      # Administators can choose a different protocol for Atlas Kafka Notification
      protocol = options.application.properties['atlas.kafka.security.protocol']
      unless protocol in service.use.kafka_broker[0].options.protocols
        throw Error "Atlas Hive Bridge Hook Selected Protocol #{options.application.kafka_chanel} is not allowed by Kafka Brokers configuration"
      brokers = service.use.kafka_broker.map( (srv) =>
        "#{srv.node.fqdn}:#{srv.options.ports[protocol]}"
      ).join ','
      # construcut the bootstrap listeners string base on channel
      # i.e.: SASL_SSL://master1.ryba:9096,master2.ryba:9096,master3.ryba:9096 for example
      options.application.properties['atlas.kafka.bootstrap.servers'] ?= "#{protocol}://#{brokers}"

## Dependencies

    migration = require 'masson/lib/migration'
      

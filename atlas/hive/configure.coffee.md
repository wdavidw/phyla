
# Apache Atlas Hive Plugin Configuration

    module.exports = (service) ->
      options = service.options

## Environment

      options.conf_dir = service.deps.hive_server2.options.conf_dir

## Libs
      
      options.oozie = service.deps.oozie
      options.oozie_user  = options.oozie.user if options.oozie
      options.atlas = service.deps.atlas[0]

## Configuration

Mechanism: The Apache Hive Hook (or Atlas hook) is running directly inside the
hiveserver2's JVM. As a consequence, Kafka Client configuration must be configured 
on the hiveserver2 side.
Ryba does the follwing steps:
- Configure Hiveserver2' hive-site.xml file with Atlas Props

Write Atlas Configuration file for hive's bridge. Atlas.Hive.Hook needs the atlas applcation
file in the hive-server2's configuration directory. 
Note: The file needs to be called atlas-application.properties as the name is
hard coded.

      service.deps.hive_server2.options.atlas ?= {}
      service.deps.hive_server2.options.atlas.client ?= {}
      options.client ?= {}
      options.client.properties ?= {}
      options.client.properties['atlas.http.authentication.enabled'] ?= options.atlas.options.application.properties['atlas.http.authentication.enabled']
      options.client.properties['atlas.http.authentication.type'] ?= options.atlas.options.application.properties['atlas.http.authentication.type']
      options.application ?= {}
      options.application.properties ?= {}
      options.application.properties['atlas.hook.hive.synchronous'] ?= 'false'
      options.application.properties['atlas.hook.hive.numRetries'] ?= '3'
      options.application.properties['atlas.hook.hive.minThreads'] ?= '5'
      options.application.properties['atlas.hook.hive.maxThreads'] ?= '5'
      options.application.properties['atlas.hook.hive.keepAliveTime'] ?= '10'
      options.application.properties['atlas.hook.hive.queueSize'] ?= '10000'
      service.deps.hive_server2.options.hive_site['atlas.cluster.name'] ?= "#{options.atlas.options.cluster_name}"
      # Step 1 - check if the rest adress already written
      # Step 2 (only if 1) Check if an url is already written
      service.deps.hive_server2.options.hive_site['atlas.rest.address'] = add_prop service.deps.hive_server2.options.hive_site['atlas.rest.address'], options.atlas.options.application.urls, ','
      service.deps.hive_server2.options.hive_site['hive.exec.post.hooks'] = add_prop service.deps.hive_server2.options.hive_site['hive.exec.post.hooks'], 'org.apache.atlas.hive.hook.HiveHook', ','
      # server2.aux_jars = add_prop server2.aux_jars, "/usr/hdp/current/atlas-client/hook/hive", ':'
      #Notifications
      chanels = []
      chanels.push 'SASL_SSL' if service.deps.hadoop_core.options.core_site['hadoop.security.authentication'] is 'kerberos' and service.deps.hive_server2.options.hive_site['hive.server2.use.SSL'] is 'true'
      chanels.push 'SASL_PLAINTEXT' if service.deps.hadoop_core.options.core_site['hadoop.security.authentication'] is 'kerberos'
      chanels.push 'SSL' if service.deps.hive_server2.options.hive_site['hive.server2.use.SSL'] is 'true'
      chanels.push 'PLAINTEXT'
      options.application.properties['atlas.kafka.security.protocol'] ?= chanels[0]
      options.application.properties['atlas.notification.topics'] ?= options.atlas.options.application.properties['atlas.notification.topics']
      options.application.properties['atlas.kafka.bootstrap.servers'] ?= options.atlas.options.application.properties['atlas.kafka.bootstrap.servers']
      # Configure Hive Server2 JAAS Properties for posting notifications to Kafka
      if options.application.properties['atlas.kafka.security.protocol'] in ['SASL_PLAINTEXT','SASL_SSL']
        options.application.properties['atlas.jaas.KafkaClient.loginModuleControlFlag'] ?= 'required'
        options.application.properties['atlas.jaas.KafkaClient.loginModuleName'] ?= 'com.sun.security.auth.module.Krb5LoginModule'
        options.application.properties['atlas.jaas.KafkaClient.option.keyTab'] ?= service.deps.hive_server2.options.hive_site['hive.server2.authentication.kerberos.keytab']
        options.application.properties['atlas.jaas.KafkaClient.option.principal'] ?= service.deps.hive_server2.options.hive_site['hive.server2.authentication.kerberos.principal']
        options.application.properties['atlas.jaas.KafkaClient.option.serviceName'] ?= 'kafka'
        options.application.properties['atlas.jaas.KafkaClient.option.storeKey'] ?= 'true'
        options.application.properties['atlas.jaas.KafkaClient.option.useKeyTab'] ?= 'true'
      if options.application.properties['atlas.kafka.security.protocol'] in ['SSL','SASL_SSL']
        #note: service.deps.hadoop_core.options should retrive the srv of the hive'server2 node
        options.application.properties['atlas.kafka.ssl.truststore.location'] ?= service.deps.hadoop_core.options.ssl_client['ssl.client.truststore.location']
        options.application.properties['atlas.kafka.ssl.truststore.password'] ?= service.deps.hadoop_core.options.ssl_client['ssl.client.truststore.password']
      #Administators can choose a different protocol for Atlas Kafka Notification
      protocol = options.application.properties['atlas.kafka.security.protocol']
      if protocol in service.deps.kafka_broker[0].options.protocols
        brokers = service.deps.kafka_broker.map( (srv) =>
          "#{srv.node.fqdn}:#{srv.options.ports[protocol]}"
        ).join ','
        # construcut the bootstrap listeners string base on channel
        # i.e.: SASL_SSL://master1.ryba:9096,master2.ryba:9096,master3.ryba:9096 for example
        options.application.properties['atlas.kafka.bootstrap.servers'] ?= "#{protocol}://#{brokers}"
      else
        throw Error "Atlas Hive Bridge Hook Selected Protocol #{options.application.kafka_chanel} is not allowed by Kafka Brokers configuration"
      #Kafka Ranger PLugin authorization
      if options.application.properties['atlas.kafka.security.protocol'] in  ['SASL_PLAINTEXT','SASL_SSL']
        options.atlas.options.kafka_policy.policyItems[0].users.push "#{service.deps.hive_server2.options.user.name}"
      if options.application.properties['atlas.kafka.security.protocol'] in  ['PLAINTEXT','SSL']
        options.atlas.options.kafka_policy.policyItems[0].users.push 'ANONYMOUS'
      if (options.application.properties['atlas.kafka.security.protocol'] in ['PLAINTEXT','SSL'])
        options.atlas.options.kafka_policy.policyItems[0].users.push 'ANONYMOUS'

## utility function

    add_prop = (value, add, separator) ->
      throw Error 'No separator provided' unless separator?
      value ?= ''
      return add if value.length is 0
      return if value.indexOf(add) is -1 then "#{value}#{separator}#{add}" else value

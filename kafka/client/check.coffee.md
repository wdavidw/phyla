
# Kafka Check

    module.exports = header: 'Kafka Client Check', handler: (options) ->

## Register

      @registry.register 'ranger_policy', 'ryba/ranger/actions/ranger_policy'

## Wait

      @call once: true, 'masson/core/krb5_client/wait', options.wait_krb5_client
      @call once: true, 'ryba/zookeeper/server/wait', options.wait_zookeeper_server
      @call once: true, 'ryba/kafka/broker/wait', options.wait_kafka_broker

## Add Ranger Policy

      @call
        header: 'Ranger'
        if: !!options.ranger_admin
      , ->
        @call 'ryba/ranger/admin/wait', once: true, options.wait_ranger_admin
        topics = options.protocols.map (prot) =>
          "check-#{options.hostname}-client-#{prot.toLowerCase().split('_').join('-')}-topic"
        users = ["#{options.test.user.name}", options.superusers...]
        users.push 'ANONYMOUS' if ('PLAINTEXT' in options.protocols) or ('SSL' in options.protocols)
        @wait.execute
          header: 'Wait Service'
          cmd: """
          curl --fail -H "Content-Type: application/json" -k -X GET \
            -u #{options.ranger_admin.username}:#{options.ranger_admin.password} \
            "#{options.ranger_install['POLICY_MGR_URL']}/service/public/v2/api/service/name/#{options.ranger_install['REPOSITORY_NAME']}"
          """
          code_skipped: [1,7,22] #22 is for 404 not found,7 is for not connected to host
        @ranger_policy
          header: 'Create Policy'
          username: options.ranger_admin.username
          password: options.ranger_admin.password
          url: options.ranger_install['POLICY_MGR_URL']
          policy:
            service: "#{options.ranger_install['REPOSITORY_NAME']}"
            name: "test-ryba-client-#{options.hostname}"
            description: "Policy for ryba kafka Client test"
            isAuditEnabled: true
            resources:
              topic:
                values: topics
                isExcludes: false
                isRecursive: false
            policyItems: [
                "accesses": [
                  'type': 'publish'
                  'isAllowed': true
                ,
                  'type': 'consume'
                  'isAllowed': true
                ,
                  'type': 'configure'
                  'isAllowed': true
                ,
                  'type': 'describe'
                  'isAllowed': true
                ,
                  'type': 'create'
                  'isAllowed': true
                ,
                  'type': 'delete'
                  'isAllowed': true
                ,
                  'type': 'kafka_admin'
                  'isAllowed': true
                ],
                'users': users
                'groups': []
                'conditions': []
                'delegateAdmin': false
              ]
        @wait
          time: 10000
          if: -> @status -1

## PLAINTEXT Protocol

Check Message by writing to a test topic on the PLAINTEXT channel.
Since new API (0.8-0.9) and security features, kafka broker are able to deal with
multiple channel with different protocols. For its internal functionment, it associates
an not authenticated user to ANONYMOUS name when client communicates on PLAINTEXT-SSL
protocols.

      @call
        header: 'PLAINTEXT'
        if: 'PLAINTEXT' in options.protocols
        retry: 3
      , ->
        test_topic = "check-#{options.hostname}-client-plaintext-topic"
        @system.execute
          if: options.env['KAFKA_KERBEROS_PARAMS']?
          cmd: mkcmd.kafka options.admin, """
          /usr/hdp/current/kafka-broker/bin/kafka-topics.sh --create \
            --zookeeper #{options.consumer.config['zookeeper.connect']} \
            --partitions #{options.brokers['PLAINTEXT'].length} \
            --replication-factor #{options.brokers['PLAINTEXT'].length} \
            --topic #{test_topic}
          """
          unless_exec: mkcmd.kafka options.admin, """
          /usr/hdp/current/kafka-broker/bin/kafka-topics.sh --list \
            --zookeeper #{options.consumer.config['zookeeper.connect']} \
          | grep #{test_topic}
          """
        @system.execute
          unless: options.env['KAFKA_KERBEROS_PARAMS']? or !!options.ranger_admin
          cmd: """
          /usr/hdp/current/kafka-broker/bin/kafka-topics.sh --create \
            --zookeeper #{options.consumer.config['zookeeper.connect']} \
            --partitions #{options.brokers['PLAINTEXT'].length} \
            --replication-factor #{options.brokers['PLAINTEXT'].length} \
            --topic #{test_topic}
          """
          unless_exec: """
          /usr/hdp/current/kafka-broker/bin/kafka-topics.sh --list \
            --zookeeper #{options.consumer.config['zookeeper.connect']} \
          | grep #{test_topic}
          """
        @system.execute
          if:  options.env['KAFKA_KERBEROS_PARAMS']?
          cmd: mkcmd.kafka options.admin, """
          (
            sleep 1
            /usr/hdp/current/kafka-broker/bin/kafka-acls.sh \
              --authorizer-properties zookeeper.connect=#{options.consumer.config['zookeeper.connect']} \
              --add \
              --allow-principal User:ANONYMOUS \
              --operation Read \
              --operation Write \
              --topic #{test_topic}
          )&
          (
          /usr/hdp/current/kafka-broker/bin/kafka-acls.sh \
            --authorizer-properties zookeeper.connect=#{options.consumer.config['zookeeper.connect']} \
            --add \
            --allow-principal User:ANONYMOUS \
            --consumer \
            --group #{options.consumer.config['group.id']} \
            --topic #{test_topic}
          )
          """
          unless_exec: mkcmd.kafka options.admin, """
          /usr/hdp/current/kafka-broker/bin/kafka-acls.sh --list \
            --authorizer-properties zookeeper.connect=#{options.consumer.config['zookeeper.connect']} \
            --topic #{test_topic} \
          | grep 'User:ANONYMOUS has Allow permission for operations: Write from hosts: *'
          """
        @system.execute
          unless:  options.env['KAFKA_KERBEROS_PARAMS']? or !!options.ranger_admin
          cmd: """
          (
            sleep 1
            /usr/hdp/current/kafka-broker/bin/kafka-acls.sh \
              --authorizer-properties zookeeper.connect=#{options.consumer.config['zookeeper.connect']} \
              --add --allow-principal User:ANONYMOUS \
              --operation Read \
              --operation Write \
              --topic #{test_topic}
          )&
          (
          /usr/hdp/current/kafka-broker/bin/kafka-acls.sh \
            --authorizer-properties zookeeper.connect=#{options.consumer.config['zookeeper.connect']} \
            --add \
            --allow-principal User:ANONYMOUS \
            --consumer \
            --group #{options.consumer.config['group.id']} \
            --topic #{test_topic}
          )
          """
          unless_exec: """
          /usr/hdp/current/kafka-broker/bin/kafka-acls.sh --list \
            --authorizer-properties zookeeper.connect=#{options.consumer.config['zookeeper.connect']} \
            --topic #{test_topic} \
          | grep 'User:ANONYMOUS has Allow permission for operations: Write from hosts: *'
          """
        @system.execute
          cmd: """
          (
            sleep 5
            echo 'hello #{options.hostname}' | /usr/hdp/current/kafka-broker/bin/kafka-console-producer.sh \
              --producer-property security.protocol=PLAINTEXT \
              --broker-list #{options.brokers['PLAINTEXT'].join ','} \
              --security-protocol PLAINTEXT \
              --producer.config #{options.conf_dir}/producer.properties \
              --topic #{test_topic}
          )&
          /usr/hdp/current/kafka-broker/bin/kafka-console-consumer.sh \
            --new-consumer \
            --delete-consumer-offsets \
            --bootstrap-server #{options.brokers['PLAINTEXT'].join ','} \
            --topic #{test_topic} \
            --security-protocol PLAINTEXT \
            --property security.protocol=PLAINTEXT \
            --consumer.config #{options.conf_dir}/consumer.properties \
            --zookeeper #{options.consumer.config['zookeeper.connect']} \
            --from-beginning \
            --max-messages 1 \
          | grep 'hello #{options.hostname}'
          """

## SSL Protocol

Check Message by writing to a test topic on the SSL channel. Truststore location 
and password given to line command because if executed before producer install
'/etc/kafka/conf/producer.properties' might be empty.

      @call
        header: 'SSL'
        retry: 3
        if: 'SSL' in options.protocols
      , ->
        test_topic = "check-#{options.hostname}-client-ssl-topic"
        @system.execute
          cmd: mkcmd.kafka options.admin, """
          /usr/hdp/current/kafka-broker/bin/kafka-topics.sh --create \
            --zookeeper #{options.consumer.config['zookeeper.connect']} \
            --partitions #{options.brokers['SSL'].length} \
            --replication-factor #{options.brokers['SSL'].length} \
            --topic #{test_topic}
          """
          unless_exec: mkcmd.kafka options.admin, """
          /usr/hdp/current/kafka-broker/bin/kafka-topics.sh --list \
            --zookeeper #{options.consumer.config['zookeeper.connect']} \
          | grep #{test_topic}
          """
        @system.execute
          unless: !!options.ranger_admin
          cmd: mkcmd.kafka options.admin, """
          (
            sleep 1
            /usr/hdp/current/kafka-broker/bin/kafka-acls.sh \
              --authorizer-properties zookeeper.connect=#{options.consumer.config['zookeeper.connect']} \
              --add --allow-principal User:ANONYMOUS \
              --operation Read \
              --operation Write \
              --topic #{test_topic}
          )&
          (
          /usr/hdp/current/kafka-broker/bin/kafka-acls.sh \
            --authorizer-properties zookeeper.connect=#{options.consumer.config['zookeeper.connect']} \
            --add \
            --allow-principal User:ANONYMOUS \
            --consumer \
            --group #{options.consumer.config['group.id']} \
            --topic #{test_topic}
          )
          """
          unless_exec: mkcmd.kafka options.admin, """
          /usr/hdp/current/kafka-broker/bin/kafka-acls.sh --list \
            --authorizer-properties \
            zookeeper.connect=#{options.consumer.config['zookeeper.connect']} \
            --topic #{test_topic} \
          | grep 'User:ANONYMOUS has Allow permission for operations: Write from hosts: *'
          """
        @system.execute
          cmd: """
          (
            sleep 5
            echo 'hello #{options.hostname}' | /usr/hdp/current/kafka-broker/bin/kafka-console-producer.sh \
              --producer-property security.protocol=SSL \
              --broker-list #{options.brokers['SSL'].join ','} \
              --security-protocol SSL \
              --producer-property ssl.truststore.location=#{options.config['ssl.truststore.location']} \
              --producer-property ssl.truststore.password=#{options.config['ssl.truststore.password']} \
              --producer.config #{options.conf_dir}/producer.properties \
              --topic #{test_topic}
          )&
          /usr/hdp/current/kafka-broker/bin/kafka-console-consumer.sh \
            --new-consumer \
            --delete-consumer-offsets \
            --bootstrap-server #{options.brokers['SSL'].join ','} \
            --topic #{test_topic} \
            --security-protocol SSL \
            --property security.protocol=SSL \
            --property ssl.truststore.location=#{options.config['ssl.truststore.location']} \
            --property ssl.truststore.password=#{options.config['ssl.truststore.password']} \
            --consumer.config #{options.conf_dir}/consumer.properties \
            --zookeeper #{options.consumer.config['zookeeper.connect']} \
            --from-beginning \
            --max-messages 1 \
          | grep 'hello #{options.hostname}'
          """

## SASL_PLAINTEXT Protocol

Check Message by writing to a test topic on the SASL_PLAINTEXT channel.

      @call
        header: 'SASL_PLAINTEXT'
        retry: 3
        if: 'SASL_PLAINTEXT' in options.protocols
      , ->
        test_topic = "check-#{options.hostname}-client-sasl-plaintext-topic"
        @system.execute
          cmd: mkcmd.kafka options.admin, """
          /usr/hdp/current/kafka-broker/bin/kafka-topics.sh --create \
            --zookeeper #{options.consumer.config['zookeeper.connect']} \
            --partitions #{options.brokers['SASL_PLAINTEXT'].length} \
            --replication-factor #{options.brokers['SASL_PLAINTEXT'].length} \
            --topic #{test_topic}
          """
          unless_exec: mkcmd.kafka options.admin, """
          /usr/hdp/current/kafka-broker/bin/kafka-topics.sh --list \
            --zookeeper #{options.consumer.config['zookeeper.connect']} \
          | grep #{test_topic}
          """
        @system.execute
          unless: !!options.ranger_admin
          cmd: mkcmd.kafka options.admin, """
          (
            sleep 1
            /usr/hdp/current/kafka-broker/bin/kafka-acls.sh \
              --authorizer-properties zookeeper.connect=#{options.consumer.config['zookeeper.connect']} \
              --add \
              --allow-principal User:#{options.test.user.name} \
              --operation Read \
              --operation Write \
              --topic #{test_topic}
          )&
          (
          /usr/hdp/current/kafka-broker/bin/kafka-acls.sh \
            --authorizer-properties zookeeper.connect=#{options.consumer.config['zookeeper.connect']} \
            --add \
            --allow-principal User:#{options.test.user.name} \
            --consumer --group #{options.config['group.id']} \
            --topic #{test_topic}
          )
          """
          unless_exec: mkcmd.kafka options.admin, """
          /usr/hdp/current/kafka-broker/bin/kafka-acls.sh  --list \
            --authorizer-properties zookeeper.connect=#{options.consumer.config['zookeeper.connect']} \
            --topic #{test_topic} \
          | grep 'User:#{options.test.user.name} has Allow permission for operations: Write from hosts: *'
          """
        @system.execute
          cmd:  mkcmd.test options.test_krb5_user, """
          (
            sleep 5
            echo 'hello #{options.hostname}' | /usr/hdp/current/kafka-broker/bin/kafka-console-producer.sh \
              --producer-property security.protocol=SASL_PLAINTEXT \
              --broker-list #{options.brokers['SASL_PLAINTEXT'].join ','} \
              --security-protocol SASL_PLAINTEXT \
              --producer.config #{options.conf_dir}/producer.properties \
              --topic #{test_topic}
          )&
          /usr/hdp/current/kafka-broker/bin/kafka-console-consumer.sh \
            --new-consumer \
            --delete-consumer-offsets \
            --bootstrap-server #{options.brokers['SASL_PLAINTEXT'].join ','} \
            --topic #{test_topic} \
            --security-protocol SASL_PLAINTEXT \
            --consumer.config #{options.conf_dir}/consumer.properties \
            --zookeeper #{options.consumer.config['zookeeper.connect']} \
            --from-beginning \
            --max-messages 1 \
          | grep 'hello #{options.hostname}'
          """

## SASL_SSL Protocol

Check Message by writing to a test topic on the SASL_SSL channel.
Trustore location and password given to line command because if executed before producer install
'/etc/kafka/conf/producer.properties' might be empty.

      @call
        header: 'SASL_SSL'
        retry: 3
        if: 'SASL_SSL' in options.protocols
      , ->
        test_topic = "check-#{options.hostname}-client-sasl-ssl-topic"
        @system.execute
          cmd: mkcmd.kafka options.admin, """
          /usr/hdp/current/kafka-broker/bin/kafka-topics.sh --create \
            --zookeeper #{options.consumer.config['zookeeper.connect']} \
            --partitions #{options.brokers['SASL_SSL'].length} \
            --replication-factor #{options.brokers['SASL_SSL'].length} \
            --topic #{test_topic}
          """
          unless_exec: mkcmd.kafka options.admin, """
          /usr/hdp/current/kafka-broker/bin/kafka-topics.sh \
            --list \
            --zookeeper #{options.consumer.config['zookeeper.connect']} \
          | grep #{test_topic}
          """
        @system.execute
          unless: !!options.ranger_admin
          cmd: mkcmd.kafka options.admin, """
          (
            sleep 1
            /usr/hdp/current/kafka-broker/bin/kafka-acls.sh \
              --authorizer-properties zookeeper.connect=#{options.consumer.config['zookeeper.connect']} \
              --add \
              --allow-principal User:#{options.test.user.name} \
              --operation Read \
              --operation Write \
              --topic #{test_topic}
          )&
          (
          /usr/hdp/current/kafka-broker/bin/kafka-acls.sh \
            --authorizer-properties zookeeper.connect=#{options.consumer.config['zookeeper.connect']} \
            --add \
            --allow-principal User:#{options.test.user.name} \
            --consumer \
            --group #{options.consumer.config['group.id']} \
            --topic #{test_topic}
          )
          """
          unless_exec: mkcmd.kafka options.admin, """
          /usr/hdp/current/kafka-broker/bin/kafka-acls.sh  --list \
            --authorizer-properties zookeeper.connect=#{options.consumer.config['zookeeper.connect']} \
            --topic #{test_topic} \
          | grep 'User:#{options.test.user.name} has Allow permission for operations: Write from hosts: *'
          """
        @system.execute
          cmd:  mkcmd.test options.test_krb5_user, """
          (
            sleep 5
            echo 'hello #{options.hostname}' | /usr/hdp/current/kafka-broker/bin/kafka-console-producer.sh \
              --producer-property security.protocol=SASL_SSL \
              --broker-list #{options.brokers['SASL_SSL'].join ','} \
              --security-protocol SASL_SSL \
              --producer-property ssl.truststore.location=#{options.config['ssl.truststore.location']} \
              --producer-property ssl.truststore.password=#{options.config['ssl.truststore.password']} \
              --producer.config #{options.conf_dir}/producer.properties \
              --topic #{test_topic}
          )&
          /usr/hdp/current/kafka-broker/bin/kafka-console-consumer.sh \
            --new-consumer \
            --delete-consumer-offsets \
            --bootstrap-server #{options.brokers['SASL_SSL'].join ','} \
            --topic #{test_topic} \
            --security-protocol SASL_SSL \
            --property security.protocol=SASL_SSL \
            --property ssl.truststore.location=#{options.config['ssl.truststore.location']} \
            --property ssl.truststore.password=#{options.config['ssl.truststore.password']} \
            --consumer.config #{options.conf_dir}/consumer.properties \
            --zookeeper #{options.consumer.config['zookeeper.connect']} \
            --from-beginning \
            --max-messages 1 \
          | grep 'hello #{options.hostname}'
          """

## Dependencies

    mkcmd = require '../../lib/mkcmd'

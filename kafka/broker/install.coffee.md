
# Kafka Broker Install

    module.exports = header: 'Kafka Broker Install', handler: ->
      {kafka, hadoop_group, realm, ssl} = @config.ryba
      krb5 = @config.krb5_client.admin[realm]

## Register

      @registry.register 'hdp_select', 'ryba/lib/hdp_select'
      @registry.register ['file', 'jaas'], 'ryba/lib/file_jaas'

## Wait

      @call once: true, 'masson/core/krb5_client/wait'

## Identities

By default, the "kafka" package create the following entries:

```bash
cat /etc/passwd | grep kafka
kafka:x:496:496:KAFKA:/home/kafka:/bin/bash
cat /etc/group | grep kafka
kafka:x:496:kafka
```

      @system.group header: 'Group', kafka.group
      @system.user header: 'User', kafka.user

## IPTables

| Service      | Port  | Proto       | Parameter          |
|--------------|-------|-------------|--------------------|
| Kafka Broker | 9092  | http        | port               |
| Kafka Broker | 9093  | https       | port               |
| Kafka Broker | 9094  | sasl_http   | port               |
| Kafka Broker | 9096  | sasl_https  | port               |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @call header: 'IPTables', handler: ->
        return unless @config.iptables.action is 'start'
        @tools.iptables
          rules: for proto in kafka.broker.protocols
            { chain: 'INPUT', jump: 'ACCEPT', dport: kafka.broker.ports[proto], protocol: 'tcp', state: 'NEW', comment: "Kafka Broker #{proto}" }

## Package

Install the Kafka consumer package and set it to the latest version. Note, we
select the "kafka-broker" hdp directory. There is no "kafka-consumer"
directories.

      @call header: 'Packages', handler: (options) ->
        @service
          name: 'kafka'
        @hdp_select
          name: 'kafka-broker'
        @system.mkdir
          target: '/var/lib/kafka'
          uid: kafka.user.name
          gid: kafka.user.name
        @service.init
          if_os: name: ['redhat','centos'], version: '6'
          header: 'Init Script'
          target: '/etc/init.d/kafka-broker'
          source: "#{__dirname}/../resources/kafka-broker.j2"
          local: true
          mode: 0o0755
          context: @config
        @call
          if_os: name: ['redhat','centos'], version: '7'
        , ->
          @service.init
            header: 'Systemd Script'
            target: '/usr/lib/systemd/system/kafka-broker.service'
            source: "#{__dirname}/../resources/kafka-broker-systemd.j2"
            local: true
            context: @config.ryba
            mode: 0o0640
          @system.tmpfs
            mount: kafka.broker.run_dir
            uid: kafka.user.name
            gid: kafka.group.name
            perm: '0750'

## Configure

Update the file "broker.properties" with the properties defined by the
"ryba.kafka.broker" configuration.

      @file
        header: 'Server properties'
        target: "#{kafka.broker.conf_dir}/server.properties"
        write: for k, v of kafka.broker.config
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true
        mode: 0o0750
        uid: kafka.user.name
        gid: kafka.group.name

## Metrics

Upload *.properties files in /etc/kafka-broker/conf directory.

      @call header: 'Metrics', handler: ->
        @call (_, callback) ->
          glob "#{__dirname}/../resources/*.properties", (err, files) =>
            for file in files
              continue if /^\./.test path.basename file
              @file
                source: file
                local: true
                target: "#{kafka.broker.conf_dir}/#{path.basename file}"
                binary: true
            @then callback
        @file
          source: "#{__dirname}/../resources/connect-console-sink.properties"
          local: true
          target: "#{kafka.broker.conf_dir}/connect-console-sink.properties"
          binary: true
        @file
          source: "#{__dirname}/../resources/connect-console-sink.properties"
          local: true
          target: "#{kafka.broker.conf_dir}/connect-console-sink.properties"
          binary: true
        @file
          source: "#{__dirname}/../resources/connect-console-sink.properties"
          local: true
          target: "#{kafka.broker.conf_dir}/connect-console-sink.properties"
          binary: true

## Env

Update the kafka-env.sh file (/etc/kafka-broker/conf/kafka-enh.sh)
Note: With systemd environment, JAVA_HOME needs to be defined.

      @file
        header: 'Environment'
        source: "#{__dirname}/../resources/kafka-env.sh"
        target: "#{kafka.broker.conf_dir}/kafka-env.sh"
        write: for k, v of kafka.broker.env
          match: RegExp "export #{k}=.*", 'm'
          replace: "export #{k}=\"#{v}\" # RYBA, DONT OVERWRITE"
          append: true
        backup: true
        local: true
        eof: true
        mode: 0o0750
        uid: kafka.user.name
        gid: kafka.group.name

## Logging

Set Log4j properties

      @file.properties
        header: 'Broker Log4j'
        target: "#{kafka.broker.conf_dir}/log4j.properties"
        content: kafka.broker.log4j.config
        backup: true
      @file.properties
        header: 'Common Log4j'
        target: "/etc/kafka/conf/log4j.properties"
        content: kafka.broker.log4j.config
        backup: true

Modify bin scripts to set $KAFKA_HOME variable to match /etc/kafka-broker/conf.
Replace KAFKA_BROKER_CMD kafka-broker conf directory path
This Fixs are needed to be able to isolate confs betwwen broker and client

      @call header: 'Fix Startup Script', handler: ->
        # @file
        #   target: "/usr/hdp/current/kafka-broker/bin/kafka"
        #   write: [
        #     match: /^KAFKA_BROKER_CMD=(.*)/m
        #     replace: "KAFKA_BROKER_CMD=\"$KAFKA_HOME/bin/kafka-server-broker-start.sh #{kafka.broker.conf_dir}/server.properties\""
        #   ]
        #   backup: true
        #   eof: true
        @file
          target: '/usr/hdp/current/kafka-broker/bin/kafka-server-start.sh'
          write: [
                match: RegExp "^exec.*$", 'mg'
                replace: "exec /usr/hdp/current/kafka-broker/bin/kafka-run-broker-class.sh $EXTRA_ARGS kafka.Kafka #{kafka.broker.conf_dir}/server.properties # RYBA DON'T OVERWRITE"
            ]
          backup: true
          eof: true
          mode: 0o755
        @system.copy
          source: '/usr/hdp/current/kafka-broker/bin/kafka-run-class.sh'
          target: '/usr/hdp/current/kafka-broker/bin/kafka-run-broker-class.sh'
          mode: 0o0755
        @file
          target: '/usr/hdp/current/kafka-broker/bin/kafka-run-broker-class.sh'
          write: [
            match: RegExp "^KAFKA_ENV=.*$", 'mg'
            replace: "KAFKA_ENV=#{kafka.broker.conf_dir}/kafka-env.sh # RYBA DON'T OVERWRITE"
          ]
          backup: true
          eof: true
          mode: 0o755

## Kerberos

Broker Server principal, keytab and JAAS

      @call 
        header: 'Kerberos'
        if: kafka.broker.config['zookeeper.set.acl'] is 'true'
        handler: ->
          @krb5.addprinc krb5,
            header: 'Broker Server Kerberos'
            principal: kafka.broker.kerberos['principal']
            randkey: true
            keytab: kafka.broker.kerberos['keyTab']
            uid: kafka.user.name
            gid: kafka.group.name
          @file.jaas
            header: 'Broker JAAS'
            target: "#{kafka.broker.conf_dir}/kafka-server.jaas"
            content:
              KafkaServer:
                principal: kafka.broker.kerberos['principal']
                keyTab: kafka.broker.kerberos['keyTab']
                useKeyTab: true
                storeKey: true
              Client:
                principal: kafka.broker.kerberos['principal']
                keyTab: kafka.broker.kerberos['keyTab']
                useKeyTab: true
                storeKey: true
            uid: kafka.user.name
            gid: kafka.group.name

Kafka Superuser principal generation

          @krb5.addprinc krb5,
            header: 'Kafka Superuser kerberos'
            principal: kafka.admin.principal
            password: kafka.admin.password

# SSL Server

Upload and register the SSL certificate and private key.
SSL is enabled at least for inter broker communication

      @call 
        header: 'SSL'
        handler: ->
          return if kafka.broker.config['replication.security.protocol'] is 'PLAINTEXT'
          @java.keystore_add
            keystore: kafka.broker.config['ssl.keystore.location']
            storepass: kafka.broker.config['ssl.keystore.password']
            caname: "hadoop_root_ca"
            cacert: "#{ssl.cacert.source}"
            key: "#{ssl.key.source}"
            cert: "#{ssl.cert.source}"
            keypass: kafka.broker.config['ssl.key.password']
            name: @config.shortname
            local: ssl.cacert.local
          @java.keystore_add
            keystore: kafka.broker.config['ssl.keystore.location']
            storepass: kafka.broker.config['ssl.keystore.password']
            caname: "hadoop_root_ca"
            cacert: "#{ssl.cacert.source}"
            local: ssl.cacert.local
          # imports kafka broker server hadoop_root_ca CA trustore
          @java.keystore_add
            keystore: kafka.broker.config['ssl.truststore.location']
            storepass: kafka.broker.config['ssl.truststore.password']
            caname: "hadoop_root_ca"
            cacert: "#{ssl.cacert.source}"
            local: ssl.cacert.local


## Layout

Directories in which Kafka data is stored. Each new partition that is created
will be placed in the directory which currently has the fewest partitions.

      @call header: 'Layout', handler: ->
        @system.mkdir (
          target: dir
          uid: kafka.user.name
          gid: kafka.group.name
          mode: 0o0750
          parent: true
        ) for dir in kafka.broker.config['log.dirs'].split ','
        @system.mkdir
          target: kafka.broker.log_dir
          uid: kafka.user.name
          gid: kafka.group.name
          mode: 0o0750
        @system.mkdir
          target: kafka.broker.run_dir
          uid: kafka.user.name
          gid: kafka.group.name
          mode: 0o0750

## Ranger Kafka Plugin Install

      @call
        if: -> @contexts('ryba/ranger/admin').length > 0
        handler: 'ryba/ranger/plugins/kafka/install'

## Dependencies

    glob = require 'glob'
    path = require 'path'
    quote = require 'regexp-quote'

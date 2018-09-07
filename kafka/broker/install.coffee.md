
# Kafka Broker Install

    module.exports = header: 'Kafka Broker Install', handler: ({options}) ->

## Register

      @registry.register 'hdp_select', 'ryba/lib/hdp_select'
      @registry.register ['file', 'jaas'], 'ryba/lib/file_jaas'

## Wait

      @call 'masson/core/krb5_client/wait', once: true, options.wait_krb5_client

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

## IPTables

| Service      | Port  | Proto       | Parameter          |
|--------------|-------|-------------|--------------------|
| Kafka Broker | 9092  | http        | port               |
| Kafka Broker | 9093  | https       | port               |
| Kafka Broker | 9094  | sasl_http   | port               |
| Kafka Broker | 9096  | sasl_https  | port               |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @tools.iptables
        header: 'IPTables'
        if: options.iptables
        rules: for protocol in options.protocols
          chain: 'INPUT', jump: 'ACCEPT', dport: options.ports[protocol], protocol: 'tcp', state: 'NEW', comment: "Kafka Broker #{protocol}"

## Package

Install the Kafka consumer package and set it to the latest version. Note, we
select the "kafka-broker" hdp directory. There is no "kafka-consumer"
directories.

      @call header: 'Packages', handler: ->
        @service
          name: 'kafka'
        @hdp_select
          name: 'kafka-broker'
        @system.mkdir
          target: '/var/lib/kafka'
          uid: options.user.name
          gid: options.user.name
        @service.init
          if_os: name: ['redhat','centos'], version: '6'
          header: 'Init Script'
          target: '/etc/init.d/kafka-broker'
          source: "#{__dirname}/../resources/kafka-broker.j2"
          local: true
          mode: 0o0755
          context: options: options
        @call
          if_os: name: ['redhat','centos'], version: '7'
        , ->
          @service.init
            header: 'Systemd Script'
            target: '/usr/lib/systemd/system/kafka-broker.service'
            source: "#{__dirname}/../resources/kafka-broker-systemd.j2"
            local: true
            context: options: options
            mode: 0o0640
          @system.tmpfs
            mount: options.run_dir
            uid: options.user.name
            gid: options.group.name
            perm: '0750'

## Configure

Update the file "broker.properties" with the properties defined in the
"config" option.

      @file
        header: 'Server properties'
        target: "#{options.conf_dir}/server.properties"
        write: for k, v of options.config
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true
        mode: 0o0750
        uid: options.user.name
        gid: options.group.name

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
                target: "#{options.conf_dir}/#{path.basename file}"
                binary: true
            @next callback
        @file
          source: "#{__dirname}/../resources/connect-console-sink.properties"
          local: true
          target: "#{options.conf_dir}/connect-console-sink.properties"
          binary: true
        @file
          source: "#{__dirname}/../resources/connect-console-sink.properties"
          local: true
          target: "#{options.conf_dir}/connect-console-sink.properties"
          binary: true
        @file
          source: "#{__dirname}/../resources/connect-console-sink.properties"
          local: true
          target: "#{options.conf_dir}/connect-console-sink.properties"
          binary: true

## Env

Update the kafka-env.sh file (/etc/kafka-broker/conf/kafka-enh.sh)
Note: With systemd environment, JAVA_HOME needs to be defined.

      @file
        header: 'Environment'
        source: "#{__dirname}/../resources/kafka-env.sh"
        target: "#{options.conf_dir}/kafka-env.sh"
        write: for k, v of options.env
          match: RegExp "export #{k}=.*", 'm'
          replace: "export #{k}=\"#{v}\" # RYBA, DONT OVERWRITE"
          append: true
        backup: true
        local: true
        eof: true
        mode: 0o0750
        uid: options.user.name
        gid: options.group.name

## Logging

Set Log4j properties

      @file.properties
        header: 'Broker Log4j'
        target: "#{options.conf_dir}/log4j.properties"
        content: options.log4j.properties
        backup: true
      @file.properties
        header: 'Common Log4j'
        target: "/etc/kafka/conf/log4j.properties"
        content: options.log4j.properties
        backup: true

Modify bin scripts to set $KAFKA_HOME variable to match /etc/kafka-broker/conf.
Replace KAFKA_BROKER_CMD kafka-broker conf directory path
This Fixs are needed to be able to isolate confs betwwen broker and client

      @call header: 'Fix Startup Script', handler: ->
        # @file
        #   target: "/usr/hdp/current/kafka-broker/bin/kafka"
        #   write: [
        #     match: /^KAFKA_BROKER_CMD=(.*)/m
        #     replace: "KAFKA_BROKER_CMD=\"$KAFKA_HOME/bin/kafka-server-broker-start.sh #{options.conf_dir}/server.properties\""
        #   ]
        #   backup: true
        #   eof: true
        @file
          target: '/usr/hdp/current/kafka-broker/bin/kafka-server-start.sh'
          write: [
                match: RegExp "^exec.*$", 'mg'
                replace: "exec /usr/hdp/current/kafka-broker/bin/kafka-run-broker-class.sh $EXTRA_ARGS kafka.Kafka #{options.conf_dir}/server.properties # RYBA DON'T OVERWRITE"
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
            replace: "KAFKA_ENV=#{options.conf_dir}/kafka-env.sh # RYBA DON'T OVERWRITE"
          ,
            match: RegExp "KAFKA_GC_LOG_OPTS=\"[^\"]+\"", 'mg'
            replace: """
            if [ -z "$KAFKA_GC_LOG_OPTS" ]; then
                KAFKA_GC_LOG_OPTS="-Xloggc:$LOG_DIR/$GC_LOG_FILE_NAME -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:+PrintGCTimeStamps "
              fi
            """
            replace: "KAFKA_ENV=#{options.conf_dir}/kafka-env.sh # RYBA DON'T OVERWRITE"
          ]
          backup: true
          eof: true
          mode: 0o755

## Kerberos

Broker Server principal, keytab and JAAS

      @call
        header: 'Kerberos'
        if: options.config['zookeeper.set.acl'] is 'true'
        handler: ->
          @krb5.addprinc options.krb5.admin,
            header: 'Broker Server Kerberos'
            principal: options.kerberos.principal
            randkey: true
            keytab: options.kerberos.keyTab
            uid: options.user.name
            gid: options.group.name
          @file.jaas
            header: 'Broker JAAS'
            target: "#{options.conf_dir}/kafka-server.jaas"
            content:
              KafkaServer:
                principal: options.kerberos.principal
                keyTab: options.kerberos.keyTab
                useKeyTab: true
                storeKey: true
              Client:
                principal: options.kerberos.principal
                keyTab: options.kerberos.keyTab
                useKeyTab: true
                storeKey: true
            uid: options.user.name
            gid: options.group.name

Kafka Superuser principal generation

          @krb5.addprinc options.krb5.admin,
            header: 'Kafka Superuser kerberos'
            principal: options.admin.principal
            password: options.admin.password

# SSL Server

Upload and register the SSL certificate and private key.
SSL is enabled at least for inter broker communication

      @call
        header: 'SSL'
        unless: options.config['replication.security.protocol'] is 'PLAINTEXT'
      , ->
        @java.keystore_add
          keystore: options.config['ssl.keystore.location']
          storepass: options.config['ssl.keystore.password']
          key: options.ssl.key.source
          cert: options.ssl.cert.source
          keypass: options.config['ssl.key.password']
          name: options.ssl.key.name
          local: options.ssl.cert.local
        @java.keystore_add
          keystore: options.config['ssl.keystore.location']
          storepass: options.config['ssl.keystore.password']
          caname: "hadoop_root_ca"
          cacert: options.ssl.cacert.source
          local: options.ssl.cacert.local
        # imports kafka broker server hadoop_root_ca CA truststore
        @java.keystore_add
          keystore: options.config['ssl.truststore.location']
          storepass: options.config['ssl.truststore.password']
          caname: "hadoop_root_ca"
          cacert: options.ssl.cacert.source
          local: options.ssl.cacert.local


## Layout

Directories in which Kafka data is stored. Each new partition that is created
will be placed in the directory which currently has the fewest partitions.

      @call header: 'Layout', handler: ->
        @system.mkdir (
          target: dir
          uid: options.user.name
          gid: options.group.name
          mode: 0o0750
          parent: true
        ) for dir in options.config['log.dirs'].split ','
        @system.mkdir
          target: options.log_dir
          uid: options.user.name
          gid: options.group.name
          mode: 0o0750
        @system.mkdir
          target: options.run_dir
          uid: options.user.name
          gid: options.group.name
          mode: 0o0750

## Dependencies

    glob = require 'glob'
    path = require 'path'
    quote = require 'regexp-quote'

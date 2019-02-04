
# Spark Livy Server Install

Install  dockerized Apache Spark Livy Server 0.2 container. The container can be build by ./bin/prepare
script or directly downloaded (from local computer only for now, no images available on dockerhub).

Run `ryba prepare` to create the Docker container.

    module.exports = header: 'Spark Livy Server', handler: ->
      {spark} = @config.ryba
      {hadoop_group, hdfs, hive, hbase, hadoop_conf_dir, realm, ssl} = @config.ryba
      krb5 = @config.krb5_client.admin[realm]
      tmp_location = "/var/tmp/@rybajs/metal/ssl"

## Wait

      @call once: true, '@rybajs/metal/spark2/history_server/wait'
      @call once: true, '@rybajs/metal/spark2/thrift_server/wait'

## IPTables

| Service           | Port  | Proto | Info                    |
|-------------------|-------|-------|-------------------------|
| spark livy server |  8889 | http  | Spark Livy HTTP server  |
| spark livy server |  8890 | https | Spark Livy HTTPS server |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @tools.iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: spark.livy.conf['livy.server.port'], protocol: 'tcp', state: 'NEW', comment: "Spark Livy Server" }
        ]
        if: @config.iptables.action is 'start'

## Identities

By default, the "spark" package create the following entries:

```bash
cat /etc/passwd | grep spark
spark:x:495:494:Spark:/var/lib/spark:/bin/bash
cat /etc/group | grep spark
spark:x:494:
```

      @system.group header: 'Group', spark.group
      @system.user header: 'User', spark.user

## Startup Script

Write startup script to /etc/init.d/service-hue-docker

      @call header: 'Startup Script', handler: ({options}) ->
        @service.init
          source: "#{__dirname}/../resources/#{spark.livy.service}"
          local: true
          target: "/etc/init.d/#{spark.livy.service}"
          context: spark.livy
          mode: 0o755
        @system.tmpfs
          if_os: name: ['redhat','centos'], version: '7'
          mount: spark.livy.pid_dir
          uid: spark.user.name
          gid: spark.group.name
          perm: '0750'

## Layout

      @call header: 'Layout', handler: ->
        @system.mkdir
          target: spark.livy.pid_dir
          uid: spark.user.name
          gid: spark.group.name
          mode: 0o0770
        @system.mkdir
          target: spark.livy.log_dir
          uid: spark.user.name
          gid: spark.group.name
          mode: 0o0770
        @system.mkdir
          target: spark.livy.conf_dir
          uid: spark.user.name
          gid: spark.group.name

## Spark Configuration

      @file.properties
        header: 'Livy Server Configuration'
        target: "#{spark.livy.conf_dir}/livy.conf"
        content: spark.livy.conf
        uid: spark.user.name
        gid: spark.group.name
        backup: true
        eof: true
      @service.restart
        name: 'spark-livy-server'
        if: -> @status -1

## Download Container

      @call header: 'Download Container', handler: ->
        tmp = spark.livy.image_dir
        md5 = spark.livy.md5 ?= true
        @file.download
          source: "#{spark.livy.build.directory}/#{spark.livy.build.tar}"
          target: "#{tmp}/#{spark.livy.build.tar}"
          binary: true
          md5: md5
        @docker_load
          input: "#{tmp}/#{spark.livy.build.tar}"

## kerberos

      @krb5.addprinc krb5,
        if: spark.livy.conf['livy.server.auth.kerberos.principal']
        header: 'Livy Server principal'
        principal: spark.livy.conf['livy.server.auth.kerberos.principal']
        keytab: spark.livy.conf['livy.server.auth.kerberos.keytab']
        randkey: true
        uid: spark.user.name
        gid: spark.group.name
        mode: 0o0600

## SSL 

      @call if: spark.livy.ssl_enabled , handler: ->
        @file.download
          source: ssl.cacert
          target: "#{tmp_location}/#{path.basename ssl.cacert}"
          mode: 0o0600
          shy: true
        @file.download
          source: ssl.cert
          target: "#{tmp_location}/#{path.basename ssl.cert}"
          mode: 0o0600
          shy: true
        @file.download
          source: ssl.key
          target: "#{tmp_location}/#{path.basename ssl.key}"
          mode: 0o0600
          shy: true
        @java.keystore_add
          keystore: spark.livy.keystore
          storepass: spark.livy.keystorePassword
          caname: "hadoop_root_ca"
          cacert: "#{tmp_location}/#{path.basename ssl.cacert}"
          key: "#{tmp_location}/#{path.basename ssl.key}"
          cert: "#{tmp_location}/#{path.basename ssl.cert}"
          keypass: spark.livy.keystorePassword
          name: @config.shortname
        @system.remove
          target: "#{tmp_location}/#{path.basename ssl.cacert}"
          shy: true
        @system.remove
          target: "#{tmp_location}/#{path.basename ssl.cert}"
          shy: true
        @system.remove
          target: "#{tmp_location}/#{path.basename ssl.key}"
          shy: true

## Docker run

      @docker_service
        header: 'Livy Spark Server Run'
        # force: -> @status -1
        image: "#{spark.livy.image}:#{spark.livy.build.version}"
        volume: [
          "#{hadoop_conf_dir}:#{hadoop_conf_dir}"
          "#{spark.conf_dir}:#{spark.conf_dir}"
          "#{spark.livy.conf_dir}:#{spark.livy.conf_dir}"
          "#{spark.livy.log_dir}:#{spark.livy.log_dir}"
          "#{spark.livy.pid_dir}:#{spark.livy.pid_dir}"
          '/etc/krb5.conf:/etc/krb5.conf'
          '/etc/security/keytabs:/etc/security/keytabs'
          '/usr/hdp/current/spark-client:/usr/hdp/current/spark-client'
        ]
        env: [
          "HADOOP_CONF_DIR=#{spark.livy.env['HADOOP_CONF_DIR']}"
          "SPARK_HOME=#{spark.livy.env['SPARK_HOME']}"
          "SPARK_CONF_DIR=#{spark.livy.env['SPARK_CONF_DIR']}"
          "LIVY_IDENT_STRING=#{spark.livy.env['LIVY_IDENT_STRING']}"
          "LIVY_LOG_DIR=#{spark.livy.env['LIVY_LOG_DIR']}"
          "LIVY_PID_DIR=#{spark.livy.env['LIVY_PID_DIR']}"
          "KRB5CCNAME=FILE:/tmp/krb5cc_#{spark.user.uid}"
        ]
        net: 'host'
        service: true
        name: spark.livy.container

    path = require 'path'

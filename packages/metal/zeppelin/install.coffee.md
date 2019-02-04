
# Zeppelin Install

Install Zeppelin with build dockerized image.
Configured for a YARN  cluster, running with spark 1.2.1.
Spark comes with 1.2.1 in HDP 2.2.4.

    module.exports = header: 'Zeppelin Install', handler: (options) ->

## Register

      @registry.register 'hconfigure', '@rybajs/metal/lib/hconfigure'

## Identitites

By default, the "zeppelin" package create the following
entries:

```bash
cat /etc/passwd | grep zeppelin
zeppelin:x:992:992:Zeppelin:/var/lib/zeppelin:/bin/bash
cat /etc/group | grep zeppelin
zeppelin:x:992:
```

      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user

## IPTables

| Service                 | Port  | Proto | Parameter                |
|-------------------------|-------|-------|--------------------------|
| Zeppelin Server http    | 9090  | tcp   | env[ZEPPELIN_PORT]       |
| Zeppelin Server https   | 9099  | tcp   | env[ZEPPELIN_PORT]       |
| Zeppelin Websocket      | 9091  | tcp   | env[ZEPPELIN_PORT] +  1  |
| Zeppelin Websocket      | 10000 | tcp   | env[ZEPPELIN_PORT] +  1  |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).
It's the  host' port server map from the container

      # @tools.iptables
      #   header: 'IPTables'
      #   rules: [
      #     { chain: 'INPUT', jump: 'ACCEPT', dport: options.env.ZEPPELIN_PORT, protocol: 'tcp', state: 'NEW', comment: "Zeppelin Server" }
      #   ]
      #   if: @config.iptables.action is 'start'

## Zeppelin SSL

Installs SSL certificates for Zeppelin. Creates truststore et keystore
SSL only required for the server

    # module.exports.push header: 'JKS stores', ->
    #  {ssl, ssl_server, ssl_client, zeppelin} = @config.ryba
    #  tmp_location = "/tmp/ryba_hdp_ssl_#{Date.now()}"
    #  modified = false
    #  @file.download
    #     source: ssl.cacert
    #     target: "#{tmp_location}_cacert"
    #     shy: true
    #  @file.download
    #     source: ssl.cert
    #     target: "#{tmp_location}_cert"
    #     shy: true
    #  @file.download
    #     source: ssl.key
    #     target: "#{tmp_location}_key"
    #     shy: true
    #  # Client: import certificate to all hosts
    #  @java.keystore_add
    #     keystore: options.site['zeppelin.ssl.keystore.path']
    #     storepass: options.site['zeppelin.ssl.keystore.password']
    #     caname: "hadoop_zeppelin_ca"
    #     cacert: "#{tmp_location}_cacert"
    #  # Server: import certificates, private and public keys to hosts with a server
    #  @java.keystore_add
    #     keystore: options.site['zeppelin.ssl.truststore.path']
    #     storepass: options.site['zeppelin.ssl.truststore.password']
    #     caname: "hadoop_zeppelin_ca"
    #     cacert: "#{tmp_location}_cacert"
    #     key: "#{tmp_location}_key"
    #     cert: "#{tmp_location}_cert"
    #     keypass: spark.ssl.fs['spark.ssl.keyPassword']
    #     name: ctx.config.shortname
    #  @java.keystore_add
    #     keystore: spark.ssl.fs['spark.ssl.keyStore']
    #     storepass: spark.ssl.fs['spark.ssl.keyStorePassword']
    #     caname: "hadoop_spark_ca"
    #     cacert: "#{tmp_location}_cacert"
    #  @system.remove
    #     target: "#{tmp_location}_cacert"
    #     shy: true
    #  @system.remove
    #     target: "#{tmp_location}_cert"
    #     shy: true
    #  @system.remove
    #     target: "#{tmp_location}_key"
    #     shy: true

## HDP select status

      @system.execute
        header: 'HDP Version'
        cmd:  "hdp-select versions | tail -1"
      , (err, executed, stdout, stderr) ->
        throw err if err
        hdp_select_version = stdout.trim() if executed
        options.env['ZEPPELIN_JAVA_OPTS'] ?= "-Dhdp.version=#{hdp_select_version}"

## Zeppelin spark assemblye Jar

Use the spark yarn assembly jar to execute spark aplication in yarn-client mode.

      # Migration: wdavidw 170930, according to [ZEPPELIN-7](https://issues.apache.org/jira/browse/ZEPPELIN-7), 
      # declaring SPARK_YARN_JAR is no longer necessary
      # @system.execute
      #   header: 'Spark'
      #   cmd: 'ls -l /usr/hdp/current/spark-client/lib/ | grep -m 1 assembly | awk {\'print $9\'}'
      # , (err, _, stdout) ->
      #   throw err if err
      #   spark_jar = stdout.trim()
      #   options.env['SPARK_YARN_JAR'] ?= "#{options.hdfs_defaultfs}/user/#{options.spark_user.name}/share/lib/#{spark_jar}"

## Zeppelin properties configuration

      @system.mkdir
        header: 'Directory'
        target: "#{options.conf_dir}"
        mode: 0o0750
      @hconfigure
        header: 'Configuration'
        target: "#{options.conf_dir}/zeppelin-site.xml"
        source: "#{__dirname}/resources/zeppelin-site.xml"
        local: true
        # local_default: true
        properties: options.zeppelin_site
        merge: true
        backup: true

TODO: remove download and write and replace it with a template

      @file
        header: 'Download Environment'
        unless_exists: true
        target: "#{options.conf_dir}/zeppelin-env.sh"
        source: "#{__dirname}/resources/zeppelin-env.sh"
        local: true
        uid: options.user.name
        gid: options.group.name
        mode: 0o755
      @file
        header: 'Update Environment'
        target: "#{options.conf_dir}/zeppelin-env.sh"
        write: for k, v of options.env
          match: RegExp "^export\\s+(#{quote k})(.*)$", 'm'
          replace: "export #{k}=#{v}"
          append: true
        backup: true
        eof: true

## Install Zeppelin docker image

Load Zeppelin docker image from local host

      @call header: 'Import', ->
        @file.download
          source: "#{options.cache_dir}/zeppelin.tar"
          target: "/tmp/zeppelin.tar" # TODO: add versioning
        @docker_load
          machine: 'ryba'
          source: "/tmp/zeppelin.tar"

## Runs Zeppelin container 

      # migration, wdavidw 170930, commenting websocket definition since the variable isnt used anywere
      # websocket = parseInt(options.site['zeppelin.server.port'])+1
      @docker.run
        header: 'Run'
        image: "#{options.prod.tag}"
        volume: [
          "#{options.hadoop_conf_dir}:#{options.hadoop_conf_dir}"
          "#{options.conf_dir}:/usr/lib/zeppelin/conf"
          '/etc/krb5.conf:/etc/krb5.conf'
          '/etc/security/keytabs:/etc/security/keytabs'
          '/usr/bin/hdfs:/usr/bin/hdfs'
          '/usr/bin/yarn:/usr/bin/yarn'
          '/usr/hdp:/usr/hdp'
          '/etc/spark/conf:/etc/spark/conf'
          '/etc/hive/conf:/etc/hive/conf'
          "#{options.log_dir}:/usr/lib/zeppelin/logs"
        ]
        net: 'host'
        name: 'zeppelin_notebook'
        # hostname: 'zeppelin_notebook.ryba'

## Dependencies

    quote = require 'regexp-quote'


# Apache Spark SQL Thrift Server

    module.exports =  header: 'Spark SQL Thrift Server Install', handler: ({options}) ->

## Register

      @registry.register 'hdp_select', 'ryba/lib/hdp_select'
      @registry.register 'hdfs_mkdir', 'ryba/lib/hdfs_mkdir'
      @registry.register 'hconfigure', 'ryba/lib/hconfigure'

## Identities

      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user

## Packages

      @service
        name: 'spark'
      @hdp_select
        name: 'spark-thriftserver'
      @service.init
        target: "/etc/init.d/spark-thrift-server"
        source: "#{__dirname}/../resources/spark-thrift-server.j2"
        local: true
        context: options: options
        backup: true
        mode: 0o0755
      @system.tmpfs
        if_os: name: ['redhat','centos'], version: '7'
        mount: options.pid_dir
        uid: options.user.name
        gid: options.hadoop_group.gid
        perm: '0750'

## IPTables

| Service              | Port  | Proto | Info              |
|----------------------|-------|-------|-------------------|
| spark history server | 10015 | http  | Spark HTTP server |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @tools.iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.hive_site['hive.server2.thrift.port'], protocol: 'tcp', state: 'NEW', comment: "Spark SQL Thrift Server (binary)" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.hive_site['hive.server2.thrift.http.port'], protocol: 'tcp', state: 'NEW', comment: "Spark SQL Thrift Server (http)" }
        ]
        if: options.iptables

## Layout

Custom mode: 0o0760 to allow hive user to write into /var/run/spark and /var/log/spark

      @call header: 'Layout', ->
        @system.mkdir
          target: options.pid_dir
          uid: options.user.name
          gid: options.hadoop_group.gid
          mode: 0o0770
        @system.mkdir
          target: options.log_dir
          uid: options.user.name
          gid: options.hadoop_group.gid
          mode: 0o0770
        @system.mkdir
          target: options.conf_dir
          uid: options.user.name
          gid: options.hadoop_group.gid
        @system.remove
          target: '/usr/hdp/current/spark-thriftserver/conf'
        @system.link
          target: '/usr/hdp/current/spark-thriftserver/conf'
          source: options.conf_dir

## HDFS Layout

      @hdfs_mkdir
        target: "/user/#{options.user_name}"
        user: options.user_name
        group: options.user_name
        mode: 0o0775
        krb5_user: options.hdfs_krb5_user

## Spark Conf

      @call header: 'Spark Configuration', ->
        @file.render
          target: "#{options.conf_dir}/spark-env.sh"
          source: "#{__dirname}/../resources/spark-env.sh.j2"
          local: true
          context: options: options
          backup: true
          uid: options.user.name
          gid: options.hadoop_group.gid
          mode: 0o0750
        @file.properties
          header: 'Spark Defaults'
          target: "#{options.conf_dir}/spark-defaults.conf"
          content: options.conf
          backup: true
          uid: options.user.name
          gid: options.hadoop_group.gid
          mode: 0o0750
          separator: ' '
        @file
          header: 'Spark env'
          target: "#{options.conf_dir}/spark-env.sh"
          # See "/usr/hdp/current/spark-historyserver/sbin/spark-daemon.sh" for
          # additionnal environmental variables.
          write: [
            match :/^export SPARK_PID_DIR=.*$/mg
            replace:"export SPARK_PID_DIR=#{options.pid_dir} # RYBA CONF \"options.pid_dir\", DONT OVERWRITE"
            append: true
          ,
            match :/^export SPARK_CONF_DIR=.*$/mg
            # replace:"export SPARK_CONF_DIR=#{spark.conf_dir} # RYBA CONF \"options.conf_dir\", DONT OVERWRITE"
            replace:"export SPARK_CONF_DIR=${SPARK_HOME:-/usr/hdp/current/spark-thriftserver}/conf # RYBA CONF \"options.conf_dir\", DONT OVERWRITE"
            append: true
          ,
            match :/^export SPARK_LOG_DIR=.*$/mg
            replace:"export SPARK_LOG_DIR=#{options.log_dir} # RYBA CONF \"options.log_dir\", DONT OVERWRITE"
            append: true
          ,
            match :/^export JAVA_HOME=.*$/mg
            replace:"export JAVA_HOME=#{options.java_home} # RYBA, DONT OVERWRITE"
            append: true
          ]

## Hive Client Conf

      @call header:'Hive Client Conf', ->
        @system.copy
          target: "#{options.conf_dir}/hive-site.xml"
          source: '/etc/hive/conf/hive-site.xml'

        @hconfigure
          target: "#{options.conf_dir}/hive-site.xml"
          properties: options.hive_site
          merge: true
          uid: options.user.name
          gid: options.hadoop_group.gid
          mode: 0o0750

## Spark SQL Thrift SSL Conf      

      @call
        header: 'SSL'
        if: -> options.hive_site['hive.server2.use.SSL'] is 'true'
      , ->
        tmp_location = "/var/tmp/ryba/ssl"
        @file.download
          source: options.ssl.cacert.source
          local: options.ssl.cacert.local
          target: "#{tmp_location}/#{path.basename options.ssl.cacert.source}"
          mode: 0o0600
          shy: true
        @file.download
          source: options.ssl.cert.source
          local: options.ssl.cert.local
          target: "#{tmp_location}/#{path.basename options.ssl.cert.source}"
          mode: 0o0600
          shy: true
        @file.download
          source: options.ssl.key.source
          local: options.ssl.key.local
          target: "#{tmp_location}/#{path.basename options.ssl.key.source}"
          mode: 0o0600
          shy: true
        @java.keystore_add
          keystore: options.hive_site['hive.server2.keystore.path']
          storepass: options.hive_site['hive.server2.keystore.password']
          caname: "hive_root_ca"
          cacert: "#{tmp_location}/#{path.basename options.ssl.cacert.source}"
          key: "#{tmp_location}/#{path.basename options.ssl.key.source}"
          cert: "#{tmp_location}/#{path.basename options.ssl.cert.source}"
          keypass: options.hive_site['hive.server2.keystore.password']
          name: options.hostname
        # @java.keystore_add
        #   keystore: hive.site['hive.server2.keystore.path']
        #   storepass: hive.site['hive.server2.keystore.password']
        #   caname: "hadoop_root_ca"
        #   cacert: "#{tmp_location}/#{path.basename ssl.cacert}"
        @system.remove
          target: "#{tmp_location}/#{path.basename options.ssl.cacert.source}"
          shy: true
        @system.remove
          target: "#{tmp_location}/#{path.basename options.ssl.cert.source}"
          shy: true
        @system.remove
          target: "#{tmp_location}/#{path.basename options.ssl.key.source}"
          shy: true
        @service
          srv_name: 'spark-thrift-server'
          state: 'restarted'
          if: -> @status()

## Log4j 

      @file.properties
        header: 'log4j Properties'
        target: "#{options.conf_dir}/log4j.properties"
        content: options.log4j
        backup: true

## Dependencies

    path = require 'path'
    quote = require 'regexp-quote'
    mkcmd = require '../../lib/mkcmd'

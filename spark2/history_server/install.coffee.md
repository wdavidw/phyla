
# Apache Spark History Server

The history servers comes with the spark-client package. The single difference 
is in the configuration for  kerberos properties.

We do not recommand using the spark WEB UI because it does not support SSL. 
Moreover it does make Yarn redirect the tracking URL to the WEBUI which prevents
the user to see the log after the job has finished in the YARN Resource Manager 
web interface.

    module.exports =  header: 'Spark History Server Install', handler: ({options}) ->

      @registry.register 'hdp_select', 'ryba/lib/hdp_select'
      @registry.register 'hdfs_mkdir', 'ryba/lib/hdfs_mkdir'
      @registry.register 'hconfigure', 'ryba/lib/hconfigure'

# Identities

      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user

# Packages

      @service
        name: 'spark2'
      @hdp_select
        name: 'spark2-historyserver'
      @service.init
        target: "/etc/init.d/spark2-history-server"
        source: "#{__dirname}/../resources/spark-history-server.j2"
        local: true
        context: options
        backup: true
        mode: 0o0755
      @system.tmpfs
        if_os: name: ['redhat','centos'], version: '7'
        mount: options.pid_dir
        uid: options.user.name
        gid: options.group.name
        perm: '0750'

# Layout

## IPTables

| Service              | Port  | Proto | Info              |
|----------------------|-------|-------|-------------------|
| spark history server | 18080 | http  | Spark HTTP server |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @tools.iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.conf['spark.ssl.historyServer.ui.port'], protocol: 'tcp', state: 'NEW', comment: "Spark HTTPS Server" }
        ]
        if: options.iptables

      @call header: 'Layout', ->
        @system.mkdir
          target: options.pid_dir
          uid: options.user.name
          gid: options.group.name
        @system.mkdir
          target: options.log_dir
          uid: options.user.name
          gid: options.group.name
        @system.mkdir
          target: options.conf_dir
          uid: options.user.name
          gid: options.group.name

## Spark History Server Configure

      @file
        header: 'Spark env'
        target: "#{options.conf_dir}/spark-env.sh"
        # See "/usr/hdp/current/spark-historyserver/sbin/spark-daemon.sh" for
        # additionnal environmental variables.
        write: [
          match :/^export SPARK_PID_DIR=.*$/mg
          replace:"export SPARK_PID_DIR=#{options.pid_dir} # RYBA CONF \"ryba.options.pid_dir\", DONT OVERWRITE"
          append: true
        ,
          match :/^export SPARK_CONF_DIR=.*$/mg
          # replace:"export SPARK_CONF_DIR=#{spark.conf_dir} # RYBA CONF \"ryba.spark.conf_dir\", DONT OVERWRITE"
          replace:"export SPARK_CONF_DIR=${SPARK_HOME:-/usr/hdp/current/spark-historyserver}/conf # RYBA CONF \"ryba.spark.conf_dir\", DONT OVERWRITE"
          append: true
        ,
          match :/^export SPARK_LOG_DIR=.*$/mg
          replace:"export SPARK_LOG_DIR=#{options.log_dir} # RYBA CONF \"ryba.spark.log_dir\", DONT OVERWRITE"
          append: true
        ,
          match :/^export JAVA_HOME=.*$/mg
          replace:"export JAVA_HOME=#{options.java_home} # RYBA, DONT OVERWRITE"
          append: true
        ]
      @file
        header: 'Spark-config'
        target: "/usr/hdp/current/spark-historyserver/sbin/spark-config.sh"
        write: [
          match :/^export SPARK_DAEMON_MEMORY=.*$/mg
          replace:"export SPARK_DAEMON_MEMORY=#{options.heapsize} # RYBA CONF \"ryba.options.heapsize\", DONT OVERWRITE"
          append: true
        ]
      @file
        header: 'Spark Defaults'
        target: "#{options.conf_dir}/spark-defaults.conf"
        write: for k, v of options.conf
          match: ///^#{quote k}\ .*$///mg
          replace: if v is null then "" else "#{k} #{v}"
          append: v isnt null
        backup: true
      @system.link
        source: options.conf_dir
        target: '/usr/hdp/current/spark-historyserver/conf'

## Clients Configuration

      @hconfigure
        header: 'Hive Site'
        target: "#{options.conf_dir}/hive-site.xml"
        source: "/etc/hive/conf/hive-site.xml"
        merge: true
        backup: true

      @hconfigure
        header: 'Core Site'
        target: "#{options.conf_dir}/core-site.xml"
        source: "/etc/hadoop/conf/core-site.xml"
        merge: true
        backup: true

      @system.copy
        target: "#{options.conf_dir}/hdfs-site.xml"
        source: "/etc/hadoop/conf/hdfs-site.xml"

## Kerberos

      @krb5.addprinc options.krb5.admin,
        header: 'Kerberos'
        principal: options.conf['spark.history.kerberos.principal']
        keytab: options.conf['spark.history.kerberos.keytab']
        randkey: true
        uid: options.user.name
        gid: options.group.name

## SSL

      @java.keystore_add
        keystore: options.keystore.target
        storepass: options.keystore.password
        key: options.ssl.key.source
        cert: options.ssl.cert.source
        keypass: options.keystore.target
        name: options.ssl.key.name
        local: options.ssl.cert.local
      @java.keystore_add
        keystore: options.keystore.target
        storepass: options.keystore.password
        caname: "hadoop_root_ca"
        cacert: options.ssl.cacert.source
        local: options.ssl.cacert.local
      # imports kafka broker server hadoop_root_ca CA truststore
      @java.keystore_add
        keystore: options.truststore.target
        storepass: options.truststore.target
        caname: "hadoop_root_ca"
        cacert: options.ssl.cacert.source
        local: options.ssl.cacert.local
      @system.execute
        cmd: """
          hadoop credential create spark.ssl.historyServer.keyPassword -value #{options.keystore.password} \
          -provider jceks://file#{options.conf_dir}/history-ui-credential.jceks
        """
        unless_exec: """
          hadoop credential list -provider jceks://file#{options.conf_dir}/history-ui-credential.jceks | grep spark.ssl.historyserver.keypassword
        """
      @system.execute
        cmd: """
          hadoop credential create spark.ssl.historyServer.keyStore -value #{options.keystore.password} \
          -provider jceks://file#{options.conf_dir}/history-ui-credential.jceks
        """
        unless_exec: """
          hadoop credential list -provider jceks://file#{options.conf_dir}/history-ui-credential.jceks | grep spark.ssl.historyserver.keystore
        """
      @system.execute
        cmd: """
          hadoop credential create spark.ssl.historyServer.trustStorePassword -value #{options.truststore.password} \
          -provider jceks://file#{options.conf_dir}/history-ui-credential.jceks
        """
        unless_exec: """
          hadoop credential list -provider jceks://file#{options.conf_dir}/history-ui-credential.jceks | grep spark.ssl.historyserver.truststorepassword
        """

## Dependencies

    quote = require 'regexp-quote'

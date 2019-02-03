
# Apache Spark Install

[Spark Installation][Spark-install] following hortonworks guidelines to install
Spark requires HDFS and Yarn. Install spark in Yarn cluster mode.

Resources:

[Tips and Tricks from Altic Scale][https://www.altiscale.com/blog/tips-and-tricks-for-running-spark-on-hadoop-part-2-2/)   

    module.exports = header: 'Spark Client Install', handler: (options) ->

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdfs_mkdir', 'ryba/lib/hdfs_mkdir'

## Identities

By default, the "spark" package create the following entries:

```bash
cat /etc/passwd | grep spark
spark:x:495:494:Spark:/var/lib/spark:/bin/bash
cat /etc/group | grep spark
spark:x:494:
```

      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user

## Spark Service Installation

Install the spark and python packages.

      @call header: 'Packages', ->
        @service
          name: 'spark'
        @service
          name: 'spark-python'

## HDFS Layout

      status = user_owner = group_owner = null
      spark_yarn_jar = options.conf['spark.yarn.jar']
      @system.execute
        header: 'HDFS Layout'
        cmd: mkcmd.hdfs options.hdfs_krb5_user, """
        hdfs dfs -mkdir -p /apps/#{options.user.name}
        hdfs dfs -chmod 755 /apps/#{options.user.name}
        hdfs dfs -put -f /usr/hdp/current/spark-client/lib/spark-assembly-*.jar #{spark_yarn_jar}
        hdfs dfs -chown #{options.user.name}:#{options.group.name} #{spark_yarn_jar}
        hdfs dfs -chmod 644 #{spark_yarn_jar}
        hdfs dfs -put /usr/hdp/current/spark-client/lib/spark-examples-*.jar /apps/#{options.user.name}/spark-examples.jar
        hdfs dfs -chown -R #{options.user.name}:#{options.group.name} /apps/#{options.user.name}
        """

## Spark Worker events log dir

      @hdfs_mkdir
        target: "/user/#{options.user.name}"
        mode: 0o0755
        user: options.user.name
        group: options.group.name
        krb5_user: options.hdfs_krb5_user
      @hdfs_mkdir
        target: options.conf['spark.eventLog.dir']
        mode: 0o1777
        user: options.user.name
        group: options.group.name
        krb5_user: options.hdfs_krb5_user

## SSL

Installs SSL certificates for spark. At the moment of this writing, Spark
supports SSL Only in akka mode and fs mode ( file sharing and date streaming).
The web ui does not support SSL.

SSL must be configured on each node and configured for each component involved
in communication using the particular protocol.

      @call
        header: 'JKS Keystore'
        if: -> options.conf['spark.ssl.enabled'] is 'true'
      , ->
        @java.keystore_add
          header: 'SSL'
          keystore: options.conf['spark.ssl.keyStore']
          storepass: options.conf['spark.ssl.keyStorePassword']
          key: options.ssl.key.source
          cert: options.ssl.cert.source
          keypass: options.conf['spark.ssl.keyPassword']
          name: options.ssl.key.name
          local: options.ssl.key.local
        @java.keystore_add
          keystore: options.conf['spark.ssl.keyStore']
          storepass: options.conf['spark.ssl.keyStorePassword']
          caname: 'hadoop_root_ca'
          cacert: options.ssl.cacert.source
          local: options.ssl.cacert.local
      @java.keystore_add
        header: 'JKS Truststore'
        keystore: options.conf['spark.ssl.trustStore']
        storepass: options.conf['spark.ssl.trustStorePassword']
        caname: 'hadoop_root_ca'
        cacert: options.ssl.cacert.source
        local: options.ssl.cacert.local

## Configuration files

Configure en environment file /etc/spark/conf/spark-env.sh and /etc/spark/conf/spark-defaults.conf
Set the version of the hadoop cluster to the latest one. Yarn cluster mode supports starting to 2.2.2-4
Set [Spark configuration][spark-conf] variables
The spark.logEvent.enabled property is set to true to enable the log to be available after the job
has finished (logs are only available in yarn-cluster mode). 

      @call header: 'Configure', ->
        hdp_current_version = null
        @system.execute
          cmd:  "hdp-select versions | tail -1"
        , (err, executed, stdout, stderr) ->
          return err if err
          hdp_current_version = stdout.trim() if executed
          options.conf['spark.driver.extraJavaOptions'] ?= "-Dhdp.version=#{hdp_current_version}"
          options.conf['spark.yarn.am.extraJavaOptions'] ?= "-Dhdp.version=#{hdp_current_version}"
        @call ->
          @file
            target: "#{options.conf_dir}/java-opts"
            content: "-Dhdp.version=#{hdp_current_version}"
          @hconfigure
            header: 'Hive Site'
            target: "#{options.conf_dir}/hive-site.xml"
            source: "/etc/hive/conf/hive-site.xml"
            properties: options.hive_site
            backup: true
          @file.render
            target: "#{options.conf_dir}/spark-env.sh"
            source: "#{__dirname}/../resources/spark-env.sh.j2"
            local: true
            context: options: options
            backup: true
          @file.properties
            target: "#{options.conf_dir}/spark-defaults.conf"
            content: options.conf
            merge: true
            separator: ' '
          @file
            if: options.conf['spark.metrics.conf']
            target: "#{options.conf_dir}/metrics.properties"
            write: for k, v of options.metrics
              match: ///^#{quote k}=.*$///mg
              replace: if v is null then "" else "#{k}=#{v}"
              append: v isnt null
            backup: true

## Dependencies

    mkcmd = require '../../lib/mkcmd'
    quote = require 'regexp-quote'
    string = require '@nikitajs/core/lib/misc/string'

[spark-conf]:https://spark.apache.org/docs/latest/configuration.html

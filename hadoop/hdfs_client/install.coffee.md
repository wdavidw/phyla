
# Hadoop HDFS Client Install

    module.exports = header: 'HDFS Client Install', handler: ({options}) ->

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'

## Env

Maintain the "hadoop-env.sh" file present in the HDP companion File.

The location for JSVC depends on the platform. The Hortonworks documentation
mentions "/usr/libexec/bigtop-utils" for RHEL/CentOS/Oracle Linux. While this is
correct for RHEL, it is installed in "/usr/lib/bigtop-utils" on my CentOS.

      @file.render
        header: 'Env'
        target: "#{options.conf_dir}/hadoop-env.sh"
        source: "#{__dirname}/../resources/hadoop-env.sh.j2"
        local: true
        context:
          HADOOP_ROOT_LOGGER: options.log4j.hadoop_root_logger
          HADOOP_SECURITY_LOGGER: options.log4j.hadoop_security_logger
          HDFS_AUDIT_LOGGER: options.log4j.hadoop_audit_logger
          HADOOP_HEAPSIZE: options.hadoop_heap
          HADOOP_LOG_DIR: ''
          HADOOP_PID_DIR: ''
          HADOOP_OPTS: options.hadoop_opts
          HADOOP_CLIENT_OPTS: options.hadoop_client_opts
          java_home: options.java_home
        uid: options.user.name
        gid: options.group.name
        mode: 0o755
        backup: true
        eof: true

## Hadoop Core Site

Update the "core-site.xml" configuration file with properties from the
"core_site" configuration.

      @hconfigure
        header: 'Core Site'
        target: "#{options.conf_dir}/core-site.xml"
        source: "#{__dirname}/../../resources/core_hadoop/core-site.xml"
        local: true
        properties: options.core_site
        backup: true

## Hadoop HDFS Site

Update the "hdfs-site.xml" configuration file with properties from the
"ryba.hdfs.site" configuration.

      @hconfigure
        header: 'HDFS Site'
        target: "#{options.conf_dir}/hdfs-site.xml"
        source: "#{__dirname}/../../resources/core_hadoop/hdfs-site.xml"
        local: true
        properties: options.hdfs_site
        uid: options.user.name
        gid: options.group.name
        backup: true

      @call header: 'Jars', ->
        core_jars = Object.keys(options.core_jars).map (k) -> options.core_jars[k]
        remote_files = null
        @call (_, callback) ->
          ssh = @ssh options.ssh
          ssh2fs.readdir ssh, '/usr/hdp/current/hadoop-hdfs-client/lib', (err, files) ->
            remote_files = files unless err
            callback err
        @call ->
          remove_files = []
          core_jars = for jar in core_jars
            filtered_files = multimatch remote_files, jar.match
            remove_files.push (filtered_files.filter (file) -> file isnt jar.filename)...
            continue if jar.filename in remote_files
            jar
          @system.remove ( # Remove jar if already uploaded
            target: path.join '/usr/hdp/current/hadoop-hdfs-client/lib', file
          ) for file in remove_files
          @file.download (
            source: jar.source
            target: path.join '/usr/hdp/current/hadoop-hdfs-client/lib', "#{jar.filename}"
          ) for jar in core_jars
          @file.download (
            source: jar.source
            target: path.join '/usr/hdp/current/hadoop-yarn-client/lib', "#{jar.filename}"
          ) for jar in core_jars

## SSL

      @call header: 'SSL', ->
        @hconfigure
          target: "#{options.conf_dir}/ssl-client.xml"
          properties: options.ssl_client
        @java.keystore_add
          keystore: options.ssl_client['ssl.client.truststore.location']
          storepass: options.ssl_client['ssl.client.truststore.password']
          caname: "hadoop_root_ca"
          cacert: options.ssl.cacert.source
          local: options.ssl.cacert.local

## Dependencies

    ssh2fs = require 'ssh2-fs'

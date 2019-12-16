# Hadoop HDFS JournalNode Install

It apply to a secured HDFS installation with Kerberos.

The JournalNode daemon is relatively lightweight, so these daemons may reasonably
be collocated on machines with other Hadoop daemons, for example NameNodes, the
JobTracker, or the YARN ResourceManager.

There must be at least 3 JournalNode daemons, since edit log modifications must
be written to a majority of JNs. To increase the number of failures a system
can tolerate, deploy an odd number of JNs because the system can tolerate at
most (N - 1) / 2 failures to continue to function normally.

    module.exports = header: 'HDFS JN Install', handler: ({options}) ->

## Register

      @registry.register 'hdp_select', '@rybajs/metal/lib/hdp_select'

## IPTables

| Service     | Port | Proto  | Parameter                                      |
|-------------|------|--------|------------------------------------------------|
| journalnode | 8485 | tcp    | hdp.hdfs.site['dfs.journalnode.rpc-address']   |
| journalnode | 8480 | tcp    | hdp.hdfs.site['dfs.journalnode.http-address']  |
| journalnode | 8481 | tcp    | hdp.hdfs.site['dfs.journalnode.https-address'] |

Note, "dfs.journalnode.rpc-address" is used by "dfs.namenode.shared.edits.dir".

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      rpc = options.hdfs_site['dfs.journalnode.rpc-address'].split(':')[1]
      http = options.hdfs_site['dfs.journalnode.http-address'].split(':')[1]
      https = options.hdfs_site['dfs.journalnode.https-address'].split(':')[1]
      @tools.iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: rpc, protocol: 'tcp', state: 'NEW', comment: "HDFS JournalNode" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: http, protocol: 'tcp', state: 'NEW', comment: "HDFS JournalNode" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: https, protocol: 'tcp', state: 'NEW', comment: "HDFS JournalNode" }
        ]
        if: options.iptables

## Layout

The JournalNode data are stored inside the directory defined by the
"dfs.journalnode.edits.dir" property.

      @call header: 'Layout', ->
        @system.mkdir
          target: "#{options.conf_dir}"
        @system.mkdir
          target: for dir in options.hdfs_site['dfs.journalnode.edits.dir'].split ','
            if dir.indexOf('file://') is 0
            then dir.substr(7) else dir
          uid: options.user.name
          gid: options.hadoop_group.name
        @system.mkdir
          target: "#{options.pid_dir}"
          uid: options.user.name
          gid: options.hadoop_group.name
          mode: 0o0755
          parent: true
        @system.mkdir
          target: "#{options.log_dir}"
          uid: options.user.name
          gid: options.group.name
          parent: true

## Service

Install the "hadoop-hdfs-journalnode" service, symlink the rc.d startup script
inside "/etc/init.d" and activate it on startup.

      @call header: 'Packages', ->
        @service
          name: 'hadoop-hdfs-journalnode'
        @hdp_select
          name: 'hadoop-hdfs-client' # Not checked
          name: 'hadoop-hdfs-journalnode'
        @service.init
          if_os: name: ['redhat','centos'], version: '6'
          header: 'Initd Script'
          target: '/etc/init.d/hadoop-hdfs-journalnode'
          source: "#{__dirname}/../resources/hadoop-hdfs-journalnode.j2"
          local: true
          context: options: options
          mode: 0o0755
        @call
          if_os: name: ['redhat','centos'], version: '7'
        , ->
          @service.init
            header: 'Systemd Script'
            target: '/usr/lib/systemd/system/hadoop-hdfs-journalnode.service'
            source: "#{__dirname}/../resources/hadoop-hdfs-journalnode-systemd.j2"
            local: true
            context: options: options
            mode: 0o0644
          @system.tmpfs
            header: 'Run Dir'
            mount: "#{options.pid_dir}"
            uid: options.user.name
            gid: options.group.name
            perm: '0755'

## Configure

Update the "hdfs-site.xml" file with the "dfs.journalnode.edits.dir" property.

Register the SPNEGO service principal in the form of "HTTP/{host}@{realm}" into
the "hdfs-site.xml" file. The impacted properties are
"dfs.journalnode.kerberos.internal.spnego.principal",
"dfs.journalnode.kerberos.principal" and "dfs.journalnode.keytab.file". The
SPNEGO token is stored inside the "/etc/security/keytabs/spnego.service.keytab"
keytab, also used by the NameNodes, DataNodes, ResourceManagers and
NodeManagers.

      @call header: 'Configure', ->
        @file.types.hfile
          header: 'Core Site'
          target: "#{options.conf_dir}/core-site.xml"
          source: "#{__dirname}/../../resources/core_hadoop/core-site.xml"
          local: true
          properties: options.core_site
          backup: true
        @file.types.hfile
          target: "#{options.conf_dir}/hdfs-site.xml"
          source: "#{__dirname}/../../resources/core_hadoop/hdfs-site.xml"
          local: true
          properties: options.hdfs_site
          uid: options.user.name
          gid: options.group.name
          backup: true
        @file
          header: 'Log4j'
          target: "#{options.conf_dir}/log4j.properties"
          source: "#{__dirname}/../resources/log4j.properties"
          local: true

Maintain the "hadoop-env.sh" file present in the HDP companion File.

The location for JSVC depends on the platform. The Hortonworks documentation
mentions "/usr/libexec/bigtop-utils" for RHEL/CentOS/Oracle Linux. While this is
correct for RHEL, it is installed in "/usr/lib/bigtop-utils" on my CentOS.

      @call header: 'Environment', ->
        HDFS_JOURNALNODE_OPTS = options.opts.base
        HDFS_JOURNALNODE_OPTS += " -D#{k}=#{v}" for k, v of options.opts.java_properties
        HDFS_JOURNALNODE_OPTS += " #{k}#{v}" for k, v of options.opts.jvm
        @file.render
          target: "#{options.conf_dir}/hadoop-env.sh"
          source: "#{__dirname}/../resources/hadoop-env.sh.j2"
          local: true
          context:
            HADOOP_HEAPSIZE: options.hadoop_heap
            HADOOP_LOG_DIR: options.log_dir
            HADOOP_PID_DIR: options.pid_dir
            HDFS_JOURNALNODE_OPTS: HDFS_JOURNALNODE_OPTS
            HADOOP_OPTS: options.hadoop_opts
            HADOOP_CLIENT_OPTS: ''
            java_home: options.java_home
          uid: options.user.name
          gid: options.group.name
          mode: 0o755
          backup: true
          eof: true
        

Configure the "hadoop-metrics2.properties" to connect Hadoop to a Metrics collector like Ganglia or Graphite.

        @file.properties
          header: 'Metrics'
          target: "#{options.conf_dir}/hadoop-metrics2.properties"
          content: options.metrics.config
          backup: true

## SSL

      @call header: 'SSL', retry: 0, ->
        options.ssl_client['ssl.client.truststore.location'] = "#{options.conf_dir}/truststore"
        options.ssl_server['ssl.server.keystore.location'] = "#{options.conf_dir}/keystore"
        options.ssl_server['ssl.server.truststore.location'] = "#{options.conf_dir}/truststore"
        @file.types.hfile
          target: "#{options.conf_dir}/ssl-server.xml"
          properties: options.ssl_server
        @file.types.hfile
          target: "#{options.conf_dir}/ssl-client.xml"
          properties: options.ssl_client
        # Client: import certificate to all hosts
        @java.keystore_add
          keystore: options.ssl_client['ssl.client.truststore.location']
          storepass: options.ssl_client['ssl.client.truststore.password']
          caname: 'hadoop_root_ca'
          cacert: options.ssl.cacert.source
          local: options.ssl.cacert.local
        # Server: import certificates, private and public keys to hosts with a server
        @java.keystore_add
          keystore: options.ssl_server['ssl.server.keystore.location']
          storepass: options.ssl_server['ssl.server.keystore.password']
          key: options.ssl.key.source
          cert: options.ssl.cert.source
          keypass: options.ssl_server['ssl.server.keystore.keypassword']
          name: options.ssl.key.name
          local:  options.ssl.key.local
        @java.keystore_add
          keystore: options.ssl_server['ssl.server.keystore.location']
          storepass: options.ssl_server['ssl.server.keystore.password']
          caname: 'hadoop_root_ca'
          cacert: options.ssl.cacert.source
          local: options.ssl.cacert.local

## Dependencies

    mkcmd = require '../../lib/mkcmd'


# Hadoop HDFS DataNode Install

A DataNode manages the storage attached to the node it run on. There
are usually one DataNode per node in the cluster. HDFS exposes a file
system namespace and allows user data to be stored in files. Internally,
a file is split into one or more blocks and these blocks are stored in
a set of DataNodes. The DataNodes also perform block creation, deletion,
and replication upon instruction from the NameNode.

In a Hight Availabity (HA) enrironment, in order to provide a fast
failover, it is necessary that the Standby node have up-to-date
information regarding the location of blocks in the cluster. In order
to achieve this, the DataNodes are configured with the location of both
NameNodes, and send block location information and heartbeats to both.

    module.exports = header: 'HDFS DN Install', handler: (options) ->

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdp_select', 'ryba/lib/hdp_select'

## IPTables

| Service   | Port       | Proto     | Parameter                  |
|-----------|------------|-----------|----------------------------|
| datanode  | 50010/1004 | tcp/http  | dfs.datanode.address       |
| datanode  | 50075/1006 | tcp/http  | dfs.datanode.http.address  |
| datanode  | 50475      | tcp/https | dfs.datanode.https.address |
| datanode  | 50020      | tcp       | dfs.datanode.ipc.address   |

The "dfs.datanode.address" default to "50010" in non-secured mode. In non-secured
mode, it must be set to a value below "1024" and default to "1004".

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      [_, dn_address] = options.hdfs_site['dfs.datanode.address'].split ':'
      [_, dn_http_address] = options.hdfs_site['dfs.datanode.http.address'].split ':'
      [_, dn_https_address] = options.hdfs_site['dfs.datanode.https.address'].split ':'
      [_, dn_ipc_address] = options.hdfs_site['dfs.datanode.ipc.address'].split ':'
      @tools.iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: dn_address, protocol: 'tcp', state: 'NEW', comment: "HDFS DN Data" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: dn_http_address, protocol: 'tcp', state: 'NEW', comment: "HDFS DN HTTP" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: dn_https_address, protocol: 'tcp', state: 'NEW', comment: "HDFS DN HTTPS" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: dn_ipc_address, protocol: 'tcp', state: 'NEW', comment: "HDFS DN Meta" }
        ]
        if: options.iptables

## Packages

Install the "hadoop-hdfs-datanode" service, symlink the rc.d startup script
inside "/etc/init.d" and activate it on startup.

      @call header: 'Packages', ->
        @service
          name: 'hadoop-hdfs-datanode'
        @hdp_select
          name: 'hadoop-hdfs-client' # Not checked
          name: 'hadoop-hdfs-datanode'
        @service.init
          if_os: name: ['redhat','centos'], version: '6'
          target: '/etc/init.d/hadoop-hdfs-datanode'
          source: "#{__dirname}/../resources/hadoop-hdfs-datanode.j2"
          local: true
          context: options: options
          mode: 0o0755
        @service.init
          if_os: name: ['redhat','centos'], version: '7'
          target: '/usr/lib/systemd/system/hadoop-hdfs-datanode.service'
          source: "#{__dirname}/../resources/hadoop-hdfs-datanode-systemd.j2"
          local: true
          context: options: options
          mode: 0o0644

      @call header: 'Compression', retry: 2, ->
        @service.remove 'snappy', if: options.attempt is 1
        @service name: 'snappy'
        @service name: 'snappy-devel'
        @system.link
          source: '/usr/lib64/libsnappy.so'
          target: '/usr/hdp/current/hadoop-client/lib/native/.'
        @call (_, callback) ->
          @service
            name: 'lzo-devel'
            relax: true
          , (err) ->
            @service.remove
              if: !!err
              name: 'lzo-devel'
            @then callback
        @service
          name: 'hadoop-lzo'
        @service
          name: 'hadoop-lzo-native'

## Layout

Create the DataNode data and pid directories. The data directory is set by the
"hdp.hdfs.site['dfs.datanode.data.dir']" and default to "/var/hdfs/data". The
pid directory is set by the "hdfs\_pid\_dir" and default to "/var/run/hadoop-hdfs"

      @call header: 'Layout', ->
        # no need to restrict parent directory and yarn will complain if not accessible by everyone
        pid_dir = options.secure_dn_pid_dir
        pid_dir = pid_dir.replace '$USER', options.user.name
        pid_dir = pid_dir.replace '$HADOOP_SECURE_DN_USER', options.user.name
        pid_dir = pid_dir.replace '$HADOOP_IDENT_STRING', options.user.name
        # TODO, in HDP 2.1, datanode are started as root but in HDP 2.2, we should
        # start it as HDFS and use JAAS
        @system.mkdir
          target: "#{options.conf_dir}"
        @system.mkdir
          target: for dir in options.hdfs_site['dfs.datanode.data.dir'].split ','
            if dir.indexOf('file://') is 0
              dir.substr(7) 
            else if dir.indexOf('file://') is -1
              dir
            else 
              dir.substr(dir.indexOf('file://')+7)
          uid: options.user.name
          gid: options.hadoop_group.name
          mode: 0o0750
          parent: true
        @system.tmpfs
          if_os: name: ['redhat','centos'], version: '7'
          mount: pid_dir
          uid: options.user.name
          gid: options.hadoop_group.name
          perm: '0750'
        @system.mkdir
          target: "#{pid_dir}"
          uid: options.user.name
          gid: options.hadoop_group.name
          mode: 0o0755
          parent: true
        @system.mkdir
          target: "#{options.log_dir}" #/#{options.user.name}
          uid: options.user.name
          gid: options.group.name
          parent: true
        @system.mkdir
          target: "#{path.dirname options.hdfs_site['dfs.domain.socket.path']}"
          uid: options.user.name
          gid: options.hadoop_group.name
          mode: 0o751
          parent: true

## Core Site

Update the "core-site.xml" configuration file with properties from the
"ryba.core_site" configuration.

      @hconfigure
        header: 'Core Site'
        target: "#{options.conf_dir}/core-site.xml"
        source: "#{__dirname}/../../resources/core_hadoop/core-site.xml"
        local: true
        properties: options.core_site
        backup: true

## HDFS Site

Update the "hdfs-site.xml" configuration file with the High Availabity properties
present inside the "hdp.ha\_client\_config" object.

      @hconfigure
        header: 'HDFS Site'
        target: "#{options.conf_dir}/hdfs-site.xml"
        source: "#{__dirname}/../../resources/core_hadoop/hdfs-site.xml"
        local: true
        properties: options.hdfs_site
        uid: options.user.name
        gid: options.hadoop_group.name
        backup: true

## Environment

Maintain the "hadoop-env.sh" file present in the HDP companion File.

The location for JSVC depends on the platform. The Hortonworks documentation
mentions "/usr/libexec/bigtop-utils" for RHEL/CentOS/Oracle Linux. While this is
correct for RHEL, it is installed in "/usr/lib/bigtop-utils" on my CentOS.

      @call header: 'Environment', ->
        options.java_opts += " -D#{k}=#{v}" for k, v of options.opts
        @file.render
          header: 'Environment'
          target: "#{options.conf_dir}/hadoop-env.sh"
          source: "#{__dirname}/../resources/hadoop-env.sh.j2"
          local: true
          context:
            HADOOP_ROOT_LOGGER: options.root_logger
            HADOOP_SECURITY_LOGGER: options.security_logger
            HDFS_AUDIT_LOGGER: options.audit_logger
            HADOOP_HEAPSIZE: options.hadoop_heap
            HADOOP_DATANODE_OPTS: options.java_opts
            HADOOP_LOG_DIR: options.log_dir
            HADOOP_PID_DIR: options.pid_dir
            HADOOP_OPTS: options.hadoop_opts
            HADOOP_CLIENT_OPTS: ''
            HADOOP_SECURE_DN_USER: options.user.name
            HADOOP_SECURE_DN_LOG_DIR: options.log_dir
            HADOOP_SECURE_DN_PID_DIR: options.secure_dn_pid_dir
            datanode_heapsize: options.heapsize
            datanode_newsize: options.newsize
            java_home: options.java_home
          uid: options.user.name
          gid: options.hadoop_group.name
          mode: 0o755
          backup: true
          eof: true

## Log4j

      @file
        header: 'Log4j'
        target: "#{options.conf_dir}/log4j.properties"
        source: "#{__dirname}/../resources/log4j.properties"
        local: true
        write: for k, v of options.log4j
          match: RegExp "#{k}=.*", 'm'
          replace: "#{k}=#{v}"
          append: true

## Hadoop Metrics

Configure the "hadoop-metrics2.properties" to connect Hadoop to a Metrics collector like Ganglia or Graphite.

      @file.properties
        header: 'Metrics'
        target: "#{options.conf_dir}/hadoop-metrics2.properties"
        content: options.hadoop_metrics.config
        backup: true

# Configure Master

Accoring to [Yahoo!](http://developer.yahoo.com/hadoop/tutorial/module7.html):
The conf/masters file contains the hostname of the
SecondaryNameNode. This should be changed from "localhost"
to the fully-qualified domain name of the node to run the
SecondaryNameNode service. It does not need to contain
the hostname of the JobTracker/NameNode machine;
Also some [interesting info about snn](http://blog.cloudera.com/blog/2009/02/multi-host-secondarynamenode-configuration/)

      # @file
      #   header: 'SNN Master'
      #   if: (-> @contexts('ryba/hadoop/hdfs_snn').length)
      #   content: "#{@contexts('ryba/hadoop/hdfs_snn')?.config?.host}"
      #   target: "#{options.conf_dir}/masters"
      #   uid: options.user.name
      #   gid: hadoop_group.name

## SSL

      @call header: 'SSL', retry: 0, ->
        options.ssl_server['ssl.server.keystore.location'] = "#{options.conf_dir}/keystore"
        options.ssl_server['ssl.server.truststore.location'] = "#{options.conf_dir}/truststore"
        options.ssl_client['ssl.client.truststore.location'] = "#{options.conf_dir}/truststore"
        @hconfigure
          target: "#{options.conf_dir}/ssl-server.xml"
          properties: options.ssl_server
        @hconfigure
          target: "#{options.conf_dir}/ssl-client.xml"
          properties: options.ssl_client
        # Client: import certificate to all hosts
        @java.keystore_add
          keystore: options.ssl_client['ssl.client.truststore.location']
          storepass: options.ssl_client['ssl.client.truststore.password']
          caname: "hadoop_root_ca"
          cacert: "#{options.ssl.cacert.source}"
          local: "#{options.ssl.cacert.local}"
        # Server: import certificates, private and public keys to hosts with a server
        @java.keystore_add
          keystore: options.ssl_server['ssl.server.keystore.location']
          storepass: options.ssl_server['ssl.server.keystore.password']
          caname: "hadoop_root_ca"
          key: "#{options.ssl.key.source}"
          cert: "#{options.ssl.cert.source}"
          keypass: options.ssl_server['ssl.server.keystore.keypassword']
          name: "#{options.ssl.key.name}"
          local: "#{options.ssl.key.local}"
        @java.keystore_add
          keystore: options.ssl_server['ssl.server.keystore.location']
          storepass: options.ssl_server['ssl.server.keystore.password']
          caname: "hadoop_root_ca"
          cacert: "#{options.ssl.cacert.source}"
          local: "#{options.ssl.cacert.local}"

## Kerberos

Create the DataNode service principal in the form of "dn/{host}@{realm}" and place its
keytab inside "/etc/security/keytabs/dn.service.keytab" with ownerships set to "hdfs:hadoop"
and permissions set to "0600".

        @krb5.addprinc
          header: 'Kerberos'
          principal: options.krb5.principal
          randkey: true
          keytab: options.krb5.keytab
          uid: options.user.name
          gid: options.group.name
          mode: 0o0600
        , options.krb5.admin

# Kernel

Configure kernel parameters at runtime. There are no properties set by default,
here's a suggestion:

*    vm.swappiness = 10
*    vm.overcommit_memory = 1
*    vm.overcommit_ratio = 100
*    net.core.somaxconn = 4096 (default socket listen queue size 128)

Note, we might move this middleware to Masson.

      @tools.sysctl
        header: 'Kernel'
        properties: options.sysctl
        merge: true
        comment: true

## Ulimit

Increase ulimit for the HDFS user. The HDP package create the following
files:

```bash
cat /etc/security/limits.d/hdfs.conf
hdfs   - nofile 32768
hdfs   - nproc  65536
```

The procedure follows [Kate Ting's recommandations][kate]. This is a cause
of error if you receive the message: 'Exception in thread "main" java.lang.OutOfMemoryError: unable to create new native thread'.

Also worth of interest are the [Pivotal recommandations][hawq] as well as the
[Greenplum recommandation from Nixus Technologies][greenplum], the
[MapR documentation][mapr] and [Hadoop Performance via Linux presentation][hpl].

Note, a user must re-login for those changes to be taken into account.

      @system.limits
        header: 'Ulimit'
        user: options.user.name
      , options.user.limits

This is a dirty fix of [this bug][jsvc-192].
When launched with -user parameter, jsvc downgrades user via setuid() system call,
but the operating system limits (max number of open files, for example) remains the same.
As jsvc is used by bigtop scripts to run hdfs via root, we also (in fact: only) 
need to fix limits to root account, until Bigtop integrates jsvc 1.0.6

      @system.limits
        header: 'Ulimit to root'
        user: 'root'
      , options.user.limits

## Dependencies

    misc = require 'nikita/lib/misc'
    path = require 'path'

[key_os]: http://fr.slideshare.net/vgogate/hadoop-configuration-performance-tuning
[jsvc-192]: https://issues.apache.org/jira/browse/DAEMON-192


# Hadoop HDFS NameNode Install

This implementation configure an HA HDFS cluster, using the [Quorum Journal Manager (QJM)](qjm)
feature  to share edit logs between the Active and Standby NameNodes. Hortonworks
provides [instructions to rollback a HA installation][rollback] that apply to Ambari.

Worth to investigate:

*   [RPC Congestion Control with FairCallQueue](https://issues.apache.org/jira/browse/HADOOP-9640)
*   [RPC fair share](https://issues.apache.org/jira/browse/HADOOP-10598)

[rollback]: http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.3.3/bk_Monitoring_Hadoop_Book/content/monitor-ha-undoing_2x.html

    module.exports = header: 'HDFS NN Install', handler: (options) ->

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdp_select', 'ryba/lib/hdp_select'

## Wait

      @call 'ryba/hadoop/hdfs_jn/wait', once: true, options.wait_hdfs_jn

## IPTables

| Service  | Port  | Proto | Parameter                  |
| -------- | ----- | ----- | -------------------------- |
| namenode | 50070 | tcp   | dfs.namdnode.http-address  |
| namenode | 50470 | tcp   | dfs.namenode.https-address |
| namenode | 8020  | tcp   | fs.defaultFS               |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      unless options.nameservice
        [_, port_rcp] = options.core_site['fs.defaultFS'].split ':'
        [_, port_rcp] = options.hdfs_site['dfs.namenode.http-address'].split ':'
        [_, port_rcp] = options.hdfs_site['dfs.namenode.https-address'].split ':'
      else
        [_, port_rcp] = options.hdfs_site["dfs.namenode.rpc-address.#{options.nameservice}.#{options.hostname}"].split ':'
        [_, port_http] = options.hdfs_site["dfs.namenode.http-address.#{options.nameservice}.#{options.hostname}"].split ':'
        [_, port_https] = options.hdfs_site["dfs.namenode.https-address.#{options.nameservice}.#{options.hostname}"].split ':'
      @tools.iptables
        header: 'IPTables'
        if: options.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: port_rcp, protocol: 'tcp', state: 'NEW', comment: "HDFS NN IPC" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: port_http, protocol: 'tcp', state: 'NEW', comment: "HDFS NN HTTP" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: port_https, protocol: 'tcp', state: 'NEW', comment: "HDFS NN HTTPS" }
        ]

## Service

Install the "hadoop-hdfs-namenode" service, symlink the rc.d startup script
inside "/etc/init.d" and activate it on startup.

      @call header: 'Packages', ->
        @service
          name: 'hadoop-hdfs-namenode'
        @hdp_select
          name: 'hadoop-hdfs-client' # Not checked
          name: 'hadoop-hdfs-namenode'
        @service.init
          if_os: name: ['redhat','centos'], version: '6'
          header: 'Initd Script'
          target: '/etc/init.d/hadoop-hdfs-namenode'
          source: "#{__dirname}/../resources/hadoop-hdfs-namenode.j2"
          local: true
          context: options: options
          mode: 0o0755
        @call
          if_os: name: ['redhat','centos'], version: '7'
        , ->
          @service.init
            header: 'Systemd Script'
            target: '/usr/lib/systemd/system/hadoop-hdfs-namenode.service'
            source: "#{__dirname}/../resources/hadoop-hdfs-namenode-systemd.j2"
            local: true
            context: options: options
            mode: 0o0644
          @system.tmpfs
            header: 'Run dir'
            mount: options.pid_dir
            uid: options.user.name
            gid: options.hadoop_group.name
            perm: '0750'

## Layout

Create the NameNode data and pid directories. The NameNode data is by defined in the
"/etc/hadoop/conf/hdfs-site.xml" file by the "dfs.namenode.name.dir" property. The pid
file is usually stored inside the "/var/run/hadoop-hdfs/hdfs" directory.

      @call header: 'Layout', ->
        @system.mkdir
          target: "#{options.conf_dir}"
        @system.mkdir
          target: for dir in options.hdfs_site['dfs.namenode.name.dir'].split ','
            if dir.indexOf('file://') is 0
            then dir.substr(7) else dir
          uid: options.user.name
          gid: options.hadoop_group.name
          mode: 0o755
          parent: true
        @system.mkdir
          target: "#{options.pid_dir.replace '$USER', options.user.name}"
          uid: options.user.name
          gid: options.hadoop_group.name
          mode: 0o755
        @system.mkdir
          target: "#{options.log_dir}"
          uid: options.user.name
          gid: options.group.name
          parent: true

## Configure

      @hconfigure
        header: 'Core Site'
        target: "#{options.conf_dir}/core-site.xml"
        source: "#{__dirname}/../../resources/core_hadoop/core-site.xml"
        local: true
        properties: options.core_site
        backup: true
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
            HADOOP_NAMENODE_OPTS: options.java_opts
            HADOOP_NAMENODE_INIT_HEAPSIZE: options.hadoop_namenode_init_heap
            HADOOP_LOG_DIR: options.log_dir
            HADOOP_PID_DIR: options.pid_dir
            HADOOP_OPTS: options.hadoop_opts
            HADOOP_CLIENT_OPTS: ''
            namenode_heapsize: options.heapsize
            namenode_newsize: options.newsize
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
        write: for k, v of options.log4j
          match: RegExp "#{k}=.*", 'm'
          replace: "#{k}=#{v}"
          append: true
        local: true

## Hadoop Metrics

Configure the "hadoop-metrics2.properties" to connect Hadoop to a Metrics collector like Ganglia or Graphite.

      @file.properties
        header: 'Metrics'
        target: "#{options.conf_dir}/hadoop-metrics2.properties"
        content: options.hadoop_metrics.config
        backup: true

## SSL

      @call header: 'SSL', retry: 0, ->
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

Create a service principal for this NameNode. The principal is named after
"nn/#{@config.host}@#{realm}".

      @krb5.addprinc options.krb5.admin,
        header: 'Kerberos'
        principal: options.hdfs_site['dfs.namenode.kerberos.principal'].replace '_HOST', options.fqdn
        keytab: options.hdfs_site['dfs.namenode.keytab.file']
        randkey: true
        uid: options.user.name
        gid: options.hadoop_group.name
        mode: 0o0600

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

## Include/Exclude

The "dfs.hosts" property specifies the file that contains a list of hosts that
are permitted to connect to the namenode. The full pathname of the file must be
specified. If the value is empty, all hosts are permitted.

The "dfs.hosts.exclude" property specifies the file that contains a list of
hosts that are not permitted to connect to the namenode.  The full pathname of
the file must be specified.  If the value is empty, no hosts are excluded.

      @file
        header: 'Include'
        content: "#{options.include.join '\n'}"
        target: "#{options.hdfs_site['dfs.hosts']}"
        eof: true
        backup: true
      @file
        header: 'Exclude'
        content: "#{options.exclude.join '\n'}"
        target: "#{options.hdfs_site['dfs.hosts.exclude']}"
        eof: true
        backup: true

## Slaves

The slaves file should contain the hostname of every machine in the cluster
which should start TaskTracker and DataNode daemons.

Helper scripts (described below) use this file in "/etc/hadoop/conf/slaves"
to run commands on many hosts at once. In order to use this functionality, ssh
trusts (via either passphraseless ssh or some other means, such as Kerberos)
must be established for the accounts used to run Hadoop.

      @file
        header: 'Slaves'
        content: options.slaves.join '\n'
        target: "#{options.conf_dir}/slaves"
        eof: true

## Format

Format the HDFS filesystem. This command is only run from the active NameNode and if
this NameNode isn't yet formated by detecting if the "current/VERSION" exists. The action
is only exected once all the JournalNodes are started. The NameNode is finally restarted
if the NameNode was formated.

      any_dfs_name_dir = options.hdfs_site['dfs.namenode.name.dir'].split(',')[0]
      any_dfs_name_dir = any_dfs_name_dir.substr(7) if any_dfs_name_dir.indexOf('file://') is 0
      # For non HA mode
      @system.execute
        header: 'Format Active'
        cmd: "su -l #{options.user.name} -c \"hdfs --config '#{options.conf_dir}' namenode -format\""
        unless: options.nameservice
        unless_exists: "#{any_dfs_name_dir}/current/VERSION"
      # For HA mode, on the leader namenode
      @system.execute
        header: 'Format Standby'
        cmd: "su -l #{options.user.name} -c \"hdfs --config '#{options.conf_dir}' namenode -format -clusterId '#{options.nameservice}'\""
        if: options.nameservice and options.active_nn_host is options.fqdn
        unless_exists: "#{any_dfs_name_dir}/current/VERSION"

## HA Init Standby NameNodes

Copy over the contents of the active NameNode metadata directories to an other,
unformatted NameNode. The command "hdfs namenode -bootstrapStandby" used for the transfer
is only executed on the standby NameNode.

      @call
        header: 'HA Init Standby'
        if: -> options.nameservice
        unless: -> options.fqdn is options.active_nn_host
      , ->
        @connection.wait
          host: options.active_nn_host
          port: 8020
        @system.execute
          cmd: "su -l #{options.user.name} -c \"hdfs --config '#{options.conf_dir}' namenode -bootstrapStandby -nonInteractive\""
          code_skipped: 5

## Policy

By default the service-level authorization is disabled in hadoop, to enable that
we need to set/configure the hadoop.security.authorization to true in
${HADOOP_CONF_DIR}/core-site.xml

      @hconfigure
        header: 'Policy'
        if: options.core_site['hadoop.security.authorization'] is 'true'
        target: "#{options.conf_dir}/hadoop-policy.xml"
        source: "#{__dirname}/../../resources/core_hadoop/hadoop-policy.xml"
        local: true
        properties: options.hadoop_policy
        backup: true
      @system.execute
        header: 'Policy Reloaded'
        if: -> @status -1
        cmd: mkcmd.hdfs @, "service hadoop-hdfs-namenode status && hdfs --config '#{options.conf_dir}' dfsadmin -refreshServiceAcl"
        code_skipped: 3

## Dependencies

    mkcmd = require '../../lib/mkcmd'
    {merge} = require 'nikita/lib/misc'

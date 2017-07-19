
# Hadoop HDFS NameNode Install

This implementation configure an HA HDFS cluster, using the [Quorum Journal Manager (QJM)](qjm)
feature  to share edit logs between the Active and Standby NameNodes. Hortonworks
provides [instructions to rollback a HA installation][rollback] that apply to Ambari.

Worth to investigate:

*   [RPC Congestion Control with FairCallQueue](https://issues.apache.org/jira/browse/HADOOP-9640)
*   [RPC fair share](https://issues.apache.org/jira/browse/HADOOP-10598)

[rollback]: http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.3.3/bk_Monitoring_Hadoop_Book/content/monitor-ha-undoing_2x.html

    module.exports = header: 'HDFS NN Install', handler: ->
      {ryba} = @config
      {ssl} = ryba
      {realm, core_site, hadoop_metrics, hadoop_group} = ryba
      {hdfs, active_nn_host, nameservice, hadoop_policy} = ryba
      krb5 = @config.krb5_client.admin[realm]

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdp_select', 'ryba/lib/hdp_select'

## Wait

      @call once: true, 'ryba/hadoop/hdfs_jn/wait'

## IPTables

| Service  | Port  | Proto | Parameter                  |
| -------- | ----- | ----- | -------------------------- |
| namenode | 50070 | tcp   | dfs.namdnode.http-address  |
| namenode | 50470 | tcp   | dfs.namenode.https-address |
| namenode | 8020  | tcp   | fs.defaultFS               |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @tools.iptables
        header: 'IPTables'
        if: @config.iptables.action is 'start'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: 50070, protocol: 'tcp', state: 'NEW', comment: "HDFS NN HTTP" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 50470, protocol: 'tcp', state: 'NEW', comment: "HDFS NN HTTPS" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 8020, protocol: 'tcp', state: 'NEW', comment: "HDFS NN IPC" }
          # { chain: 'INPUT', jump: 'ACCEPT', dport: 8019, protocol: 'tcp', state: 'NEW', comment: "HDFS NN IPC" }
          # { chain: 'INPUT', jump: 'ACCEPT', dport: 9000, protocol: 'tcp', state: 'NEW', comment: "HDFS NN IPC" }
        ]

## Service

Install the "hadoop-hdfs-namenode" service, symlink the rc.d startup script
inside "/etc/init.d" and activate it on startup.

      @call header: 'Packages', (options) ->
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
          context: @config
          mode: 0o0755
        @call
          if_os: name: ['redhat','centos'], version: '7'
        , ->
          @service.init
            header: 'Systemd Script'
            target: '/usr/lib/systemd/system/hadoop-hdfs-namenode.service'
            source: "#{__dirname}/../resources/hadoop-hdfs-namenode-systemd.j2"
            local: true
            context: @config.ryba
            mode: 0o0644
          @system.tmpfs
            header: 'Run dir'
            mount: hdfs.pid_dir
            uid: hdfs.user.name
            gid: hadoop_group.name
            perm: '0750'

## Layout

Create the NameNode data and pid directories. The NameNode data is by defined in the
"/etc/hadoop/conf/hdfs-site.xml" file by the "dfs.namenode.name.dir" property. The pid
file is usually stored inside the "/var/run/hadoop-hdfs/hdfs" directory.

      @call header: 'Layout', ->
        {hdfs, hadoop_group} = @config.ryba
        @system.mkdir
          target: "#{hdfs.nn.conf_dir}"
        @system.mkdir
          target: for dir in hdfs.nn.site['dfs.namenode.name.dir'].split ','
            if dir.indexOf('file://') is 0
            then dir.substr(7) else dir
          uid: hdfs.user.name
          gid: hadoop_group.name
          mode: 0o755
          parent: true
        @system.mkdir
          target: "#{hdfs.pid_dir.replace '$USER', hdfs.user.name}"
          uid: hdfs.user.name
          gid: hadoop_group.name
          mode: 0o755
        @system.mkdir
          target: "#{hdfs.log_dir}" #/#{hdfs.user.name}
          uid: hdfs.user.name
          gid: hdfs.group.name
          parent: true

## Configure

      @hconfigure
        header: 'Core Site'
        target: "#{hdfs.nn.conf_dir}/core-site.xml"
        source: "#{__dirname}/../../resources/core_hadoop/core-site.xml"
        local: true
        properties: merge {}, core_site, hdfs.nn.core_site
        backup: true
      @hconfigure
        header: 'HDFS Site'
        target: "#{hdfs.nn.conf_dir}/hdfs-site.xml"
        source: "#{__dirname}/../../resources/core_hadoop/hdfs-site.xml"
        local: true
        properties: hdfs.nn.site
        uid: hdfs.user.name
        gid: hadoop_group.name
        backup: true

## Environment

Maintain the "hadoop-env.sh" file present in the HDP companion File.

The location for JSVC depends on the platform. The Hortonworks documentation
mentions "/usr/libexec/bigtop-utils" for RHEL/CentOS/Oracle Linux. While this is
correct for RHEL, it is installed in "/usr/lib/bigtop-utils" on my CentOS.

      @call header: 'Environment', ->
        ryba.hdfs.nn.java_opts += " -D#{k}=#{v}" for k, v of ryba.hdfs.nn.opts
        @file.render
          header: 'Environment'
          target: "#{hdfs.nn.conf_dir}/hadoop-env.sh"
          source: "#{__dirname}/../resources/hadoop-env.sh.j2"
          local: true
          context:
            HADOOP_ROOT_LOGGER: ryba.hdfs.nn.root_logger
            HADOOP_SECURITY_LOGGER: ryba.hdfs.nn.security_logger
            HDFS_AUDIT_LOGGER: ryba.hdfs.nn.audit_logger
            HADOOP_HEAPSIZE: ryba.hadoop_heap
            HADOOP_NAMENODE_OPTS: ryba.hdfs.nn.java_opts
            HADOOP_NAMENODE_INIT_HEAPSIZE: ryba.hadoop_namenode_init_heap
            HADOOP_LOG_DIR: ryba.hdfs.log_dir
            HADOOP_PID_DIR: ryba.hdfs.pid_dir
            HADOOP_OPTS: ryba.hadoop_opts
            HADOOP_CLIENT_OPTS: ryba.hadoop_client_opts
            namenode_heapsize: ryba.hdfs.nn.heapsize
            namenode_newsize: ryba.hdfs.nn.newsize
            java_home: @config.java.java_home
          uid: hdfs.user.name
          gid: hadoop_group.name
          mode: 0o755
          backup: true
          eof: true

## Log4j

      @file
        header: 'Log4j'
        target: "#{hdfs.nn.conf_dir}/log4j.properties"
        source: "#{__dirname}/../resources/log4j.properties"
        write: for k, v of ryba.hdfs.nn.log4j
          match: RegExp "#{k}=.*", 'm'
          replace: "#{k}=#{v}"
          append: true
        local: true

## Hadoop Metrics

Configure the "hadoop-metrics2.properties" to connect Hadoop to a Metrics collector like Ganglia or Graphite.

      @file.properties
        header: 'Metrics'
        target: "#{hdfs.nn.conf_dir}/hadoop-metrics2.properties"
        content: hadoop_metrics.config
        backup: true

## SSL

      @call header: 'SSL', retry: 0, ->
        @hconfigure
          target: "#{hdfs.nn.conf_dir}/ssl-server.xml"
          properties: hdfs.nn.ssl_server
        @hconfigure
          target: "#{hdfs.nn.conf_dir}/ssl-client.xml"
          properties: hdfs.nn.ssl_client
        # Client: import certificate to all hosts
        @java.keystore_add
          keystore: hdfs.nn.ssl_client['ssl.client.truststore.location']
          storepass: hdfs.nn.ssl_client['ssl.client.truststore.password']
          caname: "hadoop_root_ca"
          cacert: "#{ssl.cacert.source}"
          local: ssl.cacert.local
        # Server: import certificates, private and public keys to hosts with a server
        @java.keystore_add
          keystore: hdfs.nn.ssl_server['ssl.server.keystore.location']
          storepass: hdfs.nn.ssl_server['ssl.server.keystore.password']
          caname: "hadoop_root_ca"
          cacert: "#{ssl.cacert.source}"
          key: "#{ssl.key.source}"
          cert: "#{ssl.cert.source}"
          keypass: hdfs.nn.ssl_server['ssl.server.keystore.keypassword']
          name: @config.shortname
          local: ssl.cacert.local
        @java.keystore_add
          keystore: hdfs.nn.ssl_server['ssl.server.keystore.location']
          storepass: hdfs.nn.ssl_server['ssl.server.keystore.password']
          caname: "hadoop_root_ca"
          cacert: "#{ssl.cacert.source}"
          local: ssl.cacert.local

## Kerberos

Create a service principal for this NameNode. The principal is named after
"nn/#{@config.host}@#{realm}".

      @krb5.addprinc krb5,
        header: 'Kerberos'
        principal: hdfs.nn.site['dfs.namenode.kerberos.principal'].replace '_HOST', @config.host
        keytab: hdfs.nn.site['dfs.namenode.keytab.file']
        randkey: true
        uid: hdfs.user.name
        gid: hadoop_group.name
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
        user: hdfs.user.name
      , hdfs.user.limits

## Include/Exclude

The "dfs.hosts" property specifies the file that contains a list of hosts that
are permitted to connect to the namenode. The full pathname of the file must be
specified. If the value is empty, all hosts are permitted.

The "dfs.hosts.exclude" property specifies the file that contains a list of
hosts that are not permitted to connect to the namenode.  The full pathname of
the file must be specified.  If the value is empty, no hosts are excluded.

      @file
        header: 'Include'
        content: "#{hdfs.include.join '\n'}"
        target: "#{hdfs.nn.site['dfs.hosts']}"
        eof: true
        backup: true
      @file
        header: 'Exclude'
        content: "#{hdfs.exclude.join '\n'}"
        target: "#{hdfs.nn.site['dfs.hosts.exclude']}"
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
        content: @contexts('ryba/hadoop/hdfs_dn').map((ctx) -> ctx.config.host).join '\n'
        target: "#{hdfs.nn.conf_dir}/slaves"
        eof: true

## Format

Format the HDFS filesystem. This command is only run from the active NameNode and if
this NameNode isn't yet formated by detecting if the "current/VERSION" exists. The action
is only exected once all the JournalNodes are started. The NameNode is finally restarted
if the NameNode was formated.

      # 'ryba/hadoop/hdfs_jn/wait'
      @call header: 'Format', ->
        any_dfs_name_dir = hdfs.nn.site['dfs.namenode.name.dir'].split(',')[0]
        any_dfs_name_dir = any_dfs_name_dir.substr(7) if any_dfs_name_dir.indexOf('file://') is 0
        is_hdfs_ha = @contexts('ryba/hadoop/hdfs_nn').length > 1
        # For non HA mode
        @system.execute
          cmd: "su -l #{hdfs.user.name} -c \"hdfs --config '#{hdfs.nn.conf_dir}' namenode -format\""
          unless: is_hdfs_ha
          unless_exists: "#{any_dfs_name_dir}/current/VERSION"
        # For HA mode, on the leader namenode
        @system.execute
          cmd: "su -l #{hdfs.user.name} -c \"hdfs --config '#{hdfs.nn.conf_dir}' namenode -format -clusterId '#{nameservice}'\""
          if: is_hdfs_ha and active_nn_host is @config.host
          unless_exists: "#{any_dfs_name_dir}/current/VERSION"

## HA Init Standby NameNodes

Copy over the contents of the active NameNode metadata directories to an other,
unformatted NameNode. The command "hdfs namenode -bootstrapStandby" used for the transfer
is only executed on the standby NameNode.

      @call
        header: 'HA Init Standby'
        if: -> @contexts('ryba/hadoop/hdfs_nn').length > 1
        unless: -> @config.host is active_nn_host
      , ->
        @connection.wait
          host: active_nn_host
          port: 8020
        @system.execute
          cmd: "su -l #{hdfs.user.name} -c \"hdfs --config '#{hdfs.nn.conf_dir}' namenode -bootstrapStandby -nonInteractive\""
          code_skipped: 5

## Policy

By default the service-level authorization is disabled in hadoop, to enable that
we need to set/configure the hadoop.security.authorization to true in
${HADOOP_CONF_DIR}/core-site.xml

      @hconfigure
        header: 'Policy'
        target: "#{hdfs.nn.conf_dir}/hadoop-policy.xml"
        source: "#{__dirname}/../../resources/core_hadoop/hadoop-policy.xml"
        local: true
        properties: hadoop_policy
        backup: true
        if: core_site['hadoop.security.authorization'] is 'true'
      @system.execute
        header: 'Policy Reloaded'
        cmd: mkcmd.hdfs @, "service hadoop-hdfs-namenode status && hdfs --config '#{hdfs.nn.conf_dir}' dfsadmin -refreshServiceAcl"
        code_skipped: 3
        if: -> @status -1

## Ranger HDFS Plugin Install

      @call
        if: -> @contexts('ryba/ranger/admin').length
      , ->
        @call 'ryba/ranger/plugins/hdfs/install'
        @call 'ryba/ranger/plugins/hdfs/setup'

## Dependencies

    mkcmd = require '../../lib/mkcmd'
    {merge} = require 'nikita/lib/misc'

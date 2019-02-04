
# Hadoop YARN Timeline Reader Install

The Timeline Reader is a stand-alone server daemon and doesn't need to be
co-located with any other service.

    module.exports = header: 'YARN TR Install', handler: ({options}) ->

## Register

      @registry.register 'hconfigure', '@rybajs/metal/lib/hconfigure'
      @registry.register 'hdp_select', '@rybajs/metal/lib/hdp_select'
      @registry.register ['file', 'jaas'], '@rybajs/metal/lib/file_jaas'
      @registry.register ['hdfs','put'], '@rybajs/metal/lib/actions/hdfs/put'
      @registry.register ['hdfs','chown'], '@rybajs/metal/lib/actions/hdfs/chown'
      @registry.register ['hdfs','mkdir'], '@rybajs/metal/lib/actions/hdfs/mkdir'      
      @registry.register 'ranger_policy', '@rybajs/metal/ranger/actions/ranger_policy'

## Identities

By default, the "hadoop-yarn-timelineserver" package create the following entries:

```bash
cat /etc/passwd | grep yarn
yarn:x:2403:2403:Hadoop YARN User:/var/lib/hadoop-yarn:/bin/bash
cat /etc/group | grep hadoop
hadoop:x:499:hdfs
```

      @system.group header: 'Hadoop Group', options.hadoop_group
      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user

## Wait

      @call once: true, 'masson/core/krb5_client/wait', options.wait_krb5_client
      @call once: true, '@rybajs/metal/hbase/master/wait', options.wait_hbase_master
      @call once: true, '@rybajs/metal/hbase/regionserver/wait', options.wait_hbase_regionserver


## IPTables

| Service   | Port   | Proto     | Parameter                                  |
|-----------|------- |-----------|--------------------------------------------|
| timeline  | 10200  | tcp/http  | yarn.timeline-service.address              |
| timeline  | 8188   | tcp/http  | yarn.timeline-service.reader.webapp.address       |
| timeline  | 8190   | tcp/https | yarn.timeline-service.reader.webapp.https.address |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      [_, rpc_port] = options.yarn_site['yarn.timeline-service.address'].split ':'
      [_, http_port] = options.yarn_site['yarn.timeline-service.reader.webapp.address'].split ':'
      [_, https_port] = options.yarn_site['yarn.timeline-service.reader.webapp.https.address'].split ':'
      @tools.iptables
        header: 'IPTables'
        if: options.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: rpc_port, protocol: 'tcp', state: 'NEW', comment: "Yarn Timeserver RPC" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: http_port, protocol: 'tcp', state: 'NEW', comment: "Yarn Timeserver HTTP" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: https_port, protocol: 'tcp', state: 'NEW', comment: "Yarn Timeserver HTTPS" }
        ]

## Service

Install the "hadoop-yarn-timelineserver" service, symlink the rc.d startup script
in "/etc/init.d/hadoop-hdfs-datanode" and define its startup strategy.

      @call header: 'Service', ->
        @service
          name: 'hadoop-yarn-timelineserver'
        @service
          name: 'hadoop-yarn-timelinereader'
        @hdp_select
          name: 'hadoop-yarn-client' # Not checked
          name: 'hadoop-yarn-timelinereader'
        @service.init
          header: 'Systemd Script'
          target: '/usr/lib/systemd/system/hadoop-yarn-timelinereader.service'
          source: "#{__dirname}/../resources/hadoop-yarn-timelinereader-systemd.j2"
          local: true
          context: options: options
          mode: 0o0644
        @system.tmpfs
          header: 'Run dir'
          mount: "#{options.pid_dir}"
          uid: options.user.name
          gid: options.hadoop_group.name
          perm: '0775'

# Layout

      @call header: 'Layout', ->
        leveldb_jar = null
        @system.mkdir
          target: "#{options.conf_dir}"
        @system.mkdir
          target: "#{options.pid_dir}"
          uid: options.user.name
          gid: options.hadoop_group.name
          mode: 0o775
        @system.mkdir
          target: "#{options.log_dir}"
          uid: options.user.name
          gid: options.hadoop_group.name
          parent: true

## Configuration

Update the "yarn-site.xml" configuration file.

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
        properties: options.hdfs_site
        backup: true
      @hconfigure
        header: 'YARN Site'
        target: "#{options.conf_dir}/yarn-site.xml"
        properties: options.yarn_site
        backup: true
      @hconfigure
        header: 'YARN Site'
        target: "#{options.ats2_hbase_conf_dir}/yarn-site.xml"
        properties: options.yarn_site
        backup: true
      @file
        header: 'Log4j'
        target: "#{options.conf_dir}/log4j.properties"
        source: "#{__dirname}/../resources/log4j.properties"
        local: true
      @call header: 'Environment', ->
        YARN_TIMELINESERVER_OPTS = options.opts.base
        YARN_TIMELINESERVER_OPTS += " -D#{k}=#{v}" for k, v of options.opts.java_properties
        YARN_TIMELINESERVER_OPTS += " #{k}#{v}" for k, v of options.opts.jvm
        @file.render
          target: "#{options.conf_dir}/yarn-env.sh"
          source: "#{__dirname}/../resources/yarn-env.sh.j2"
          local: true
          context:
            security_enabled: options.krb5.realm?
            hadoop_yarn_home: options.home
            java64_home: options.java_home
            yarn_log_dir: options.log_dir
            yarn_pid_dir: options.pid_dir
            hadoop_libexec_dir: ''
            hadoop_java_io_tmpdir: "#{options.log_dir}/tmp"
            yarn_heapsize: options.heapsize
            apptimelineserver_heapsize: options.heapsize
            yarn_ats_jaas_file: "#{options.conf_dir}/yarn-ats.jaas"
            # ryba options
            YARN_TIMELINESERVER_OPTS: YARN_TIMELINESERVER_OPTS
          uid: options.user.name
          gid: options.hadoop_group.name
          mode: 0o0755
          backup: true
      @file.render
        header: 'Env'
        target: "#{options.conf_dir}/hadoop-env.sh"
        source: "#{__dirname}/../resources/hadoop-env.sh.j2"
        local: true
        context:
          HADOOP_LOG_DIR: options.log_dir
          HADOOP_PID_DIR: options.pid_dir
          java_home: options.java_home
        uid: options.user.name
        gid: options.hadoop_group.name
        mode: 0o750
        backup: true
        eof: true

Configure the "hadoop-metrics2.properties" to connect Hadoop to a Metrics collector like Ganglia or Graphite.

      @file.properties
        header: 'Metrics'
        target: "#{options.conf_dir}/hadoop-metrics2.properties"
        content: options.metrics.config
        backup: true      

# HDFS Layout

See:

*   [YarnConfiguration](https://github.com/apache/hadoop/blob/trunk/hadoop-yarn-project/hadoop-yarn/hadoop-yarn-api/src/main/java/org/apache/hadoop/yarn/conf/YarnConfiguration.java#L1425-L1426)
*   [FileSystemApplicationHistoryStore](https://github.com/apache/hadoop/blob/trunk/hadoop-yarn-project/hadoop-yarn/hadoop-yarn-server/hadoop-yarn-server-applicationhistoryservice/src/main/java/org/apache/hadoop/yarn/server/applicationhistoryservice/FileSystemApplicationHistoryStore.java)

Note, this is not documented anywhere and might not be considered as a best practice.

      @call header: 'HDFS layout', ->
        return unless options.yarn_site['yarn.timeline-service.generic-application-history.store-class'] is "org.apache.hadoop.yarn.server.applicationhistoryservice.FileSystemApplicationHistoryStore"
        dir = options.yarn_site['yarn.timeline-service.fs-history-store.uri']
        @hdfs.mkdir
          header: 'history dir'
          nn_url: options.nn_url
          target: dir
          owner: options.user.name
          group: options.hadoop_group.name
          krb5_user: options.hdfs_krb5_user 
          mode: '1777'
        @hdfs.mkdir
          header: 'ats2 user dir'
          nn_url: options.nn_url
          target: "/user/#{options.ats_user.name}"
          owner: options.ats_user.name
          group: options.ats_group.name
          krb5_user: options.hdfs_krb5_user 
          mode: '0750'

## SSL

      @call header: 'SSL', ->
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
          local: options.ssl.key.local
        @java.keystore_add
          keystore: options.ssl_server['ssl.server.keystore.location']
          storepass: options.ssl_server['ssl.server.keystore.password']
          caname: "hadoop_root_ca"
          cacert: options.ssl.cacert.source
          local: options.ssl.cacert.local

## Kerberos

Create the Kerberos service principal by default in the form of
"ats/{host}@{realm}" and place its keytab inside
"/etc/security/keytabs/ats.service.keytab" with ownerships set to
"mapred:hadoop" and permissions set to "0600".

      @krb5.addprinc options.krb5.admin,
        header: 'Kerberos'
        principal: options.yarn_site['yarn.timeline-service.principal'].replace '_HOST', options.fqdn
        randkey: true
        keytab: options.yarn_site['yarn.timeline-service.keytab']
        uid: options.user.name
        gid: options.group.name
        mode: 0o0600
          
      @krb5.addprinc options.krb5.admin,
        header: 'Yarn HBase ATS Client Principal'
        principal: options.yarn_ats_user.principal
        password: options.yarn_ats_user.password
        unless: options.hbase_local

      @krb5.ktutil.add options.krb5.admin,
        unless: options.hbase_local
        header: 'Yarn HBase ATS Client Keytab'
        principal: options.yarn_ats_user.principal
        password: options.yarn_ats_user.password
        keytab: options.yarn_ats_user.keytab
        kadmin_server: options.krb5.admin.admin_server
        mode: 0o0640
        uid: options.ats_user.name      
        gid: options.hadoop_group.name      


## Kerberos JAAS

The JAAS file is used by the ResourceManager to initiate a secure connection 
with Zookeeper.

      @file.jaas
        header: 'Kerberos JAAS'
        target: "#{options.conf_dir}/yarn-ats.jaas"
        content: Client:
          principal: options.yarn_site['yarn.timeline-service.principal'].replace '_HOST', options.fqdn
          keyTab: options.yarn_site['yarn.timeline-service.keytab']
        uid: options.user.name
        gid: options.hadoop_group.name

## HBase Backend Client Configuration

      @call
        header: 'HBase Client Configuration'
      , ->
        @system.mkdir
          unless: options.hbase_local
          target: "#{options.ats2_hbase_conf_dir}"
          uid: options.ats_user.name
          gid: options.hadoop_group.name
          mode: 0o775
        @hconfigure
          unless: options.hbase_local
          header: 'HBase Site'
          target: "#{options.ats2_hbase_conf_dir}/hbase-site.xml"
          properties: options.hbase_site
          backup: true
          user: options.ats_user.name
          group: options.hadoop_group.name  
    
## Dependencies

    path = require 'path'
    mkcmd = require '../../lib/mkcmd'


# MapReduce JobHistoryServer Install

Install and configure the MapReduce Job History Server (JHS).

Run the command `./bin/ryba install -m ryba/hadoop/mapred_jhs` to install the
Job History Server.

    module.exports = header: 'MapReduce JHS Install', handler: (options) ->

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdp_select', 'ryba/lib/hdp_select'

## IPTables

| Service    | Port  | Proto | Parameter                                 |
|------------|-------|-------|-------------------------------------------|
| jobhistory | 10020 | tcp   | mapreduce.jobhistory.address              |
| jobhistory | 19888 | http  | mapreduce.jobhistory.webapp.address       |
| jobhistory | 19889 | https | mapreduce.jobhistory.webapp.https.address |
| jobhistory | 13562 | tcp   | mapreduce.shuffle.port                    |
| jobhistory | 10033 | tcp   | mapreduce.jobhistory.admin.address        |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      jhs_shuffle_port = options.mapred_site['mapreduce.shuffle.port']
      jhs_port = options.mapred_site['mapreduce.jobhistory.address'].split(':')[1]
      jhs_webapp_port = options.mapred_site['mapreduce.jobhistory.webapp.address'].split(':')[1]
      jhs_webapp_https_port = options.mapred_site['mapreduce.jobhistory.webapp.https.address'].split(':')[1]
      jhs_admin_port = options.mapred_site['mapreduce.jobhistory.admin.address'].split(':')[1]
      @tools.iptables
        header: 'IPTables'
        if: options.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: jhs_port, protocol: 'tcp', state: 'NEW', comment: "MapRed JHS Server" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: jhs_webapp_port, protocol: 'tcp', state: 'NEW', comment: "MapRed JHS WebApp" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: jhs_webapp_https_port, protocol: 'tcp', state: 'NEW', comment: "MapRed JHS WebApp" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: jhs_shuffle_port, protocol: 'tcp', state: 'NEW', comment: "MapRed JHS Shuffle" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: jhs_admin_port, protocol: 'tcp', state: 'NEW', comment: "MapRed JHS Admin Server" }
        ]

## Service

Install the "hadoop-mapreduce-historyserver" service, symlink the rc.d startup
script inside "/etc/init.d" and activate it on startup.

      @call header: 'Service', ->
        @service
          name: 'hadoop-mapreduce-historyserver'
        @hdp_select
          name: 'hadoop-mapreduce-client' # Not checked
          name: 'hadoop-mapreduce-historyserver'
        @service.init
          if_os: name: ['redhat','centos'], version: '6'
          header: 'Initd Script'
          target: '/etc/init.d/hadoop-mapreduce-historyserver'
          source: "#{__dirname}/../resources/hadoop-mapreduce-historyserver.j2"
          local: true
          context: options: options
          mode: 0o0755
        @call
          if_os: name: ['redhat','centos'], version: '7'
        , ->
          @service.init
            header: 'Systemd Script'
            target: '/usr/lib/systemd/system/hadoop-mapreduce-historyserver.service'
            source: "#{__dirname}/../resources/hadoop-mapreduce-historyserver-systemd.j2"
            local: true
            context: options: options
            mode: 0o0644
          @system.tmpfs
            header: 'Run dir'
            mount: "#{options.pid_dir}"
            uid: options.user.name
            gid: options.hadoop_group.name
            perm: '0755'

## Layout

Create the log and pid directories.

      @call header: 'Layout', ->
        @system.mkdir
          target: "#{options.log_dir}"
          uid: options.user.name
          gid: options.hadoop_group.name
          mode: 0o0755
        @system.mkdir
          target: "#{options.pid_dir}"
          uid: options.user.name
          gid: options.hadoop_group.name
          mode: 0o0755
        @system.mkdir
          target: options.mapred_site['mapreduce.jobhistory.recovery.store.leveldb.path']
          uid: options.user.name
          gid: options.hadoop_group.name
          mode: 0o0750
          parent: true
          if: options.mapred_site['mapreduce.jobhistory.recovery.store.class'] is 'org.apache.hadoop.mapreduce.v2.hs.HistoryServerLeveldbStateStoreService'

## Configure

Enrich the file "mapred-env.sh" present inside the Hadoop configuration
directory with the location of the directory storing the process pid.

Templated properties are "ryba.mapred.heapsize" and "ryba.mapred.pid_dir".

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
        header: 'MapRed Site'
        target: "#{options.conf_dir}/mapred-site.xml"
        properties: options.mapred_site
        backup: true
      @file
        header: 'Log4j'
        target: "#{options.conf_dir}/log4j.properties"
        source: "#{__dirname}/../resources/log4j.properties"
        local: true
      @file.render
        header: 'Mapred Env'
        target: "#{options.conf_dir}/mapred-env.sh"
        source: "#{__dirname}/../resources/mapred-env.sh.j2"
        context: options: options
        local: true
        backup: true
      @file.render
        header: 'Hadoop Env'
        target: "#{options.conf_dir}/hadoop-env.sh"
        source: "#{__dirname}/../resources/hadoop-env.sh.j2"
        local: true
        context:
          HADOOP_HEAPSIZE: options.hadoop_heap
          HADOOP_LOG_DIR: ''
          HADOOP_PID_DIR: options.pid_dir
          HADOOP_OPTS: options.hadoop_opts
          HADOOP_CLIENT_OPTS: options.hadoop_client_opts
          HADOOP_MAPRED_LOG_DIR: options.log_dir
          HADOOP_MAPRED_PID_DIR: options.pid_dir
          java_home: options.java_home
        uid: options.user.name
        gid: options.hadoop_group.name
        mode: 0o0755
        backup: true
      @file.render
        header: 'MapRed Env'
        target: "#{options.conf_dir}/mapred-env.sh"
        source: "#{__dirname}/../resources/mapred-env.sh.j2"
        local: true
        context: @config
        uid: options.user.name
        gid: options.hadoop_group.name
        mode: 0o0755
        backup: true

Configure the "hadoop-metrics2.properties" to connect Hadoop to a Metrics collector like Ganglia or Graphite.

      @file.properties
        header: 'Metrics'
        target: "#{options.conf_dir}/hadoop-metrics2.properties"
        content: options.hadoop_metrics.config
        backup: true

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
"jhs/{host}@{realm}" and place its keytab inside
"/etc/security/keytabs/jhs.service.keytab" with ownerships set to
"mapred:hadoop" and permissions set to "0600".

      @krb5.addprinc options.krb5.admin,
        header: 'Kerberos'
        principal: options.mapred_site['mapreduce.jobhistory.principal']
        randkey: true
        keytab: options.mapred_site['mapreduce.jobhistory.keytab']
        uid: options.user.name
        gid: options.hadoop_group.name
        mode: 0o0600

## HDFS Layout

Layout is inspired by [Hadoop recommandation](http://hadoop.apache.org/docs/r2.1.0-beta/hadoop-project-dist/hadoop-common/ClusterSetup.html)

      @system.execute
        header: 'HDFS Layout'
        cmd: mkcmd.hdfs @, """
        if ! hdfs --config #{options.conf_dir} dfs -test -d #{options.mapred_site['yarn.app.mapreduce.am.staging-dir']}/history; then
          hdfs --config #{options.conf_dir} dfs -mkdir -p #{options.mapred_site['yarn.app.mapreduce.am.staging-dir']}/history
          hdfs --config #{options.conf_dir} dfs -chmod 0755 #{options.mapred_site['yarn.app.mapreduce.am.staging-dir']}/history
          hdfs --config #{options.conf_dir} dfs -chown #{options.user.name}:#{options.hadoop_group.name} #{options.mapred_site['yarn.app.mapreduce.am.staging-dir']}/history
          modified=1
        fi
        if ! hdfs --config #{options.conf_dir} dfs -test -d /app-logs; then
          hdfs --config #{options.conf_dir} dfs -mkdir -p /app-logs
          hdfs --config #{options.conf_dir} dfs -chmod 1777 /app-logs
          hdfs --config #{options.conf_dir} dfs -chown #{options.user.name} /app-logs
          modified=1
        fi
        if [ $modified != "1" ]; then exit 2; fi
        """
        code_skipped: 2

## Dependencies

    mkcmd = require '../../lib/mkcmd'

[keys]: https://github.com/apache/hadoop-common/blob/trunk/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/DFSConfigKeys.java

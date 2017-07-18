
# MapReduce JobHistoryServer Install

Install and configure the MapReduce Job History Server (JHS).

Run the command `./bin/ryba install -m ryba/hadoop/mapred_jhs` to install the
Job History Server.

    module.exports = header: 'MapReduce JHS Install', handler: ->
      {yarn, mapred} = @config.ryba
      {ssl, ssl_server, ssl_client, mapred} = @config.ryba
      {mapred, hadoop_group, realm} = @config.ryba
      krb5 = @config.krb5_client.admin[realm]

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdp_select', 'ryba/lib/hdp_select'

## IPTables

| Service    | Port  | Proto | Parameter                           |
|------------|-------|-------|-------------------------------------|
| jobhistory | 10020 | tcp   | mapreduce.jobhistory.address        |
| jobhistory | 19888 | http  | mapreduce.jobhistory.webapp.address |
| jobhistory | 19889 | https | mapreduce.jobhistory.webapp.https.address |
| jobhistory | 13562 | tcp   | mapreduce.shuffle.port              |
| jobhistory | 10033 | tcp   | mapreduce.jobhistory.admin.address  |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      jhs_shuffle_port = mapred.site['mapreduce.shuffle.port']
      jhs_port = mapred.site['mapreduce.jobhistory.address'].split(':')[1]
      jhs_webapp_port = mapred.site['mapreduce.jobhistory.webapp.address'].split(':')[1]
      jhs_webapp_https_port = mapred.site['mapreduce.jobhistory.webapp.https.address'].split(':')[1]
      jhs_admin_port = mapred.site['mapreduce.jobhistory.admin.address'].split(':')[1]
      @tools.iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: jhs_port, protocol: 'tcp', state: 'NEW', comment: "MapRed JHS Server" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: jhs_webapp_port, protocol: 'tcp', state: 'NEW', comment: "MapRed JHS WebApp" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: jhs_webapp_https_port, protocol: 'tcp', state: 'NEW', comment: "MapRed JHS WebApp" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: jhs_shuffle_port, protocol: 'tcp', state: 'NEW', comment: "MapRed JHS Shuffle" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: jhs_admin_port, protocol: 'tcp', state: 'NEW', comment: "MapRed JHS Admin Server" }
        ]
        if: @config.iptables.action is 'start'

## Service

Install the "hadoop-mapreduce-historyserver" service, symlink the rc.d startup
script inside "/etc/init.d" and activate it on startup.

      @call header: 'Service', (options) ->
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
          context: @config
          mode: 0o0755
        @call
          if_os: name: ['redhat','centos'], version: '7'
        , ->
          @service.init
            header: 'Systemd Script'
            target: '/usr/lib/systemd/system/hadoop-mapreduce-historyserver.service'
            source: "#{__dirname}/../resources/hadoop-mapreduce-historyserver-systemd.j2"
            local: true
            context: @config.ryba
            mode: 0o0644
          @system.tmpfs
            header: 'Run dir'
            mount: "#{mapred.pid_dir}"
            uid: mapred.user.name
            gid: hadoop_group.name
            perm: '0755'

## Layout

Create the log and pid directories.

      @call header: 'Layout', ->
        {mapred, hadoop_group} = @config.ryba
        @system.mkdir
          target: "#{mapred.log_dir}"
          uid: mapred.user.name
          gid: hadoop_group.name
          mode: 0o0755
        @system.mkdir
          target: "#{mapred.pid_dir}"
          uid: mapred.user.name
          gid: hadoop_group.name
          mode: 0o0755
        @system.mkdir
          target: mapred.site['mapreduce.jobhistory.recovery.store.leveldb.path']
          uid: mapred.user.name
          gid: hadoop_group.name
          mode: 0o0750
          parent: true
          if: mapred.site['mapreduce.jobhistory.recovery.store.class'] is 'org.apache.hadoop.mapreduce.v2.hs.HistoryServerLeveldbStateStoreService'

## Configure

Enrich the file "mapred-env.sh" present inside the Hadoop configuration
directory with the location of the directory storing the process pid.

Templated properties are "ryba.mapred.heapsize" and "ryba.mapred.pid_dir".

      {core_site, mapred, hdfs, yarn, hadoop_metrics, hadoop_group} = @config.ryba
      @hconfigure
        header: 'Core Site'
        target: "#{mapred.jhs.conf_dir}/core-site.xml"
        source: "#{__dirname}/../../resources/core_hadoop/core-site.xml"
        local: true
        properties: core_site
        backup: true
      @hconfigure
        header: 'HDFS Site'
        target: "#{mapred.jhs.conf_dir}/hdfs-site.xml"
        properties: hdfs.site
        backup: true
      @hconfigure
        header: 'YARN Site'
        target: "#{mapred.jhs.conf_dir}/yarn-site.xml"
        properties: yarn.site
        backup: true
      @hconfigure
        header: 'MapRed Site'
        target: "#{mapred.jhs.conf_dir}/mapred-site.xml"
        properties: mapred.site
        backup: true
      @file
        header: 'Log4j'
        target: "#{mapred.jhs.conf_dir}/log4j.properties"
        source: "#{__dirname}/../resources/log4j.properties"
        local: true
      @file.render
        header: 'Mapred Env'
        target: "#{mapred.jhs.conf_dir}/mapred-env.sh"
        source: "#{__dirname}/../resources/mapred-env.sh.j2"
        context: @config
        local: true
        backup: true
      @file.render
        header: 'Hadoop Env'
        target: "#{mapred.jhs.conf_dir}/hadoop-env.sh"
        source: "#{__dirname}/../resources/hadoop-env.sh.j2"
        local: true
        context:
          HADOOP_HEAPSIZE: @config.ryba.hadoop_heap
          HADOOP_LOG_DIR: @config.ryba.hdfs.log_dir
          HADOOP_PID_DIR: @config.ryba.hdfs.pid_dir
          HADOOP_OPTS: @config.ryba.hadoop_opts
          HADOOP_CLIENT_OPTS: @config.ryba.hadoop_client_opts
          HADOOP_MAPRED_LOG_DIR: @config.ryba.mapred.log_dir
          HADOOP_MAPRED_PID_DIR: @config.ryba.mapred.pid_dir
          java_home: @config.java.java_home
        uid: mapred.user.name
        gid: hadoop_group.name
        mode: 0o0755
        backup: true
      @file.render
        header: 'MapRed Env'
        target: "#{mapred.jhs.conf_dir}/mapred-env.sh"
        source: "#{__dirname}/../resources/mapred-env.sh.j2"
        local: true
        context: @config
        uid: mapred.user.name
        gid: hadoop_group.name
        mode: 0o0755
        backup: true

Configure the "hadoop-metrics2.properties" to connect Hadoop to a Metrics collector like Ganglia or Graphite.

      @file.properties
        header: 'Metrics'
        target: "#{mapred.jhs.conf_dir}/hadoop-metrics2.properties"
        content: hadoop_metrics.config
        backup: true

## SSL

      @call header: 'SSL', retry: 0, ->
        ssl_client['ssl.client.truststore.location'] = "#{mapred.jhs.conf_dir}/truststore"
        ssl_server['ssl.server.keystore.location'] = "#{mapred.jhs.conf_dir}/keystore"
        ssl_server['ssl.server.truststore.location'] = "#{mapred.jhs.conf_dir}/truststore"
        @hconfigure
          target: "#{mapred.jhs.conf_dir}/ssl-server.xml"
          properties: ssl_server
        @hconfigure
          target: "#{mapred.jhs.conf_dir}/ssl-client.xml"
          properties: ssl_client
        # Client: import certificate to all hosts
        @java.keystore_add
          keystore: ssl_client['ssl.client.truststore.location']
          storepass: ssl_client['ssl.client.truststore.password']
          caname: "hadoop_root_ca"
          cacert: "#{ssl.cacert.source}"
          local: ssl.cacert.local
        # Server: import certificates, private and public keys to hosts with a server
        @java.keystore_add
          keystore: ssl_server['ssl.server.keystore.location']
          storepass: ssl_server['ssl.server.keystore.password']
          caname: "hadoop_root_ca"
          cacert: "#{ssl.cacert.source}"
          key: "#{ssl.key.source}"
          cert: "#{ssl.cert.source}"
          keypass: ssl_server['ssl.server.keystore.keypassword']
          name: @config.shortname
          local: ssl.cacert.local
        @java.keystore_add
          keystore: ssl_server['ssl.server.keystore.location']
          storepass: ssl_server['ssl.server.keystore.password']
          caname: "hadoop_root_ca"
          cacert: "#{ssl.cacert.source}"
          local: ssl.cacert.local

## Kerberos

Create the Kerberos service principal by default in the form of
"jhs/{host}@{realm}" and place its keytab inside
"/etc/security/keytabs/jhs.service.keytab" with ownerships set to
"mapred:hadoop" and permissions set to "0600".

      @krb5.addprinc krb5,
        header: 'Kerberos'
        principal: "jhs/#{@config.host}@#{realm}"
        randkey: true
        keytab: "/etc/security/keytabs/jhs.service.keytab"
        uid: mapred.user.name
        gid: hadoop_group.name
        mode: 0o0600

## HDFS Layout

Layout is inspired by [Hadoop recommandation](http://hadoop.apache.org/docs/r2.1.0-beta/hadoop-project-dist/hadoop-common/ClusterSetup.html)

      @system.execute
        header: 'HDFS Layout'
        cmd: mkcmd.hdfs @, """
        if ! hdfs dfs -test -d #{mapred.site['yarn.app.mapreduce.am.staging-dir']}/history; then
          hdfs dfs -mkdir -p #{mapred.site['yarn.app.mapreduce.am.staging-dir']}/history
          hdfs dfs -chmod 0755 #{mapred.site['yarn.app.mapreduce.am.staging-dir']}/history
          hdfs dfs -chown #{mapred.user.name}:#{hadoop_group.name} #{mapred.site['yarn.app.mapreduce.am.staging-dir']}/history
          modified=1
        fi
        if ! hdfs dfs -test -d /app-logs; then
          hdfs dfs -mkdir -p /app-logs
          hdfs dfs -chmod 1777 /app-logs
          hdfs dfs -chown #{yarn.user.name} /app-logs
          modified=1
        fi
        if [ $modified != "1" ]; then exit 2; fi
        """
        code_skipped: 2

## Dependencies

    mkcmd = require '../../lib/mkcmd'

[keys]: https://github.com/apache/hadoop-common/blob/trunk/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/DFSConfigKeys.java

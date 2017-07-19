
# Hadoop YARN ResourceManager Install

    module.exports = header: 'YARN RM Install', handler: ->
      {java} = @config
      {realm, core_site, hdfs, yarn, mapred, hadoop_group, hadoop_metrics, hadoop_libexec_dir} = @config.ryba
      {ssl, ssl_server, ssl_client} = @config.ryba
      krb5 = @config.krb5_client.admin[realm]

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdp_select', 'ryba/lib/hdp_select'
      @registry.register 'hdfs_mkdir', 'ryba/lib/hdfs_mkdir'
      @registry.register ['file', 'jaas'], 'ryba/lib/file_jaas'

## Identities

By default, the "zookeeper" package create the following entries:

```bash
cat /etc/passwd | grep yarn
yarn:x:2403:2403:Hadoop YARN User:/var/lib/hadoop-yarn:/bin/bash
cat /etc/group | grep hadoop
hadoop:x:498:hdfs
```

      @system.group header: 'Group', hadoop_group
      @system.user header: 'User', yarn.user

## IPTables

| Service         | Port  | Proto  | Parameter                                     |
|-----------------|-------|--------|-----------------------------------------------|
| resourcemanager | 8025  | tcp    | yarn.resourcemanager.resource-tracker.address | x
| resourcemanager | 8050  | tcp    | yarn.resourcemanager.address                  | x
| scheduler       | 8030  | tcp    | yarn.resourcemanager.scheduler.address        | x
| resourcemanager | 8088  | http   | yarn.resourcemanager.webapp.address           | x
| resourcemanager | 8090  | https  | yarn.resourcemanager.webapp.https.address     |
| resourcemanager | 8141  | tcp    | yarn.resourcemanager.admin.address            | x

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      id = if yarn.rm.site['yarn.resourcemanager.ha.enabled'] is 'true' then ".#{yarn.rm.site['yarn.resourcemanager.ha.id']}" else ''
      rules = []
      # Application
      rpc_port = yarn.rm.site["yarn.resourcemanager.address#{id}"].split(':')[1]
      rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: rpc_port, protocol: 'tcp', state: 'NEW', comment: "YARN RM Application Submissions" }
      # Scheduler
      s_port = yarn.rm.site["yarn.resourcemanager.scheduler.address#{id}"].split(':')[1]
      rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: s_port, protocol: 'tcp', state: 'NEW', comment: "YARN Scheduler" }
      # RM Scheduler
      admin_port = yarn.rm.site["yarn.resourcemanager.admin.address#{id}"].split(':')[1]
      rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: admin_port, protocol: 'tcp', state: 'NEW', comment: "YARN RM Scheduler" }
      # HTTP
      if yarn.rm.site['yarn.http.policy'] in ['HTTP_ONLY', 'HTTP_AND_HTTPS']
        http_port = yarn.rm.site["yarn.resourcemanager.webapp.address#{id}"].split(':')[1]
        rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: http_port, protocol: 'tcp', state: 'NEW', comment: "YARN RM Web UI" }
      # HTTPS
      if yarn.rm.site['yarn.http.policy'] in ['HTTPS_ONLY', 'HTTP_AND_HTTPS']
        https_port = yarn.rm.site["yarn.resourcemanager.webapp.https.address#{id}"].split(':')[1]
        rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: https_port, protocol: 'tcp', state: 'NEW', comment: "YARN RM Web UI" }
      # Resource Tracker
      rt_port = yarn.rm.site["yarn.resourcemanager.resource-tracker.address#{id}"].split(':')[1]
      rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: rt_port, protocol: 'tcp', state: 'NEW', comment: "YARN RM Application Submissions" }
      @tools.iptables
        header: 'IPTables'
        rules: rules
        if: @config.iptables.action is 'start'

## Service

Install the "hadoop-yarn-resourcemanager" service, symlink the rc.d startup script
inside "/etc/init.d" and activate it on startup.

      @call header: 'Service', (options) ->
        {yarn} = @config.ryba
        @service
          name: 'hadoop-yarn-resourcemanager'
        @hdp_select
          name: 'hadoop-yarn-client' # Not checked
          name: 'hadoop-yarn-resourcemanager'
        @service.init
          if_os: name: ['redhat','centos'], version: '6'
          header: 'Initd Script'
          target: '/etc/init.d/hadoop-yarn-resourcemanager'
          source: "#{__dirname}/../resources/hadoop-yarn-resourcemanager.j2"
          local: true
          context: @config
          mode: 0o0755
        @call
          if_os: name: ['redhat','centos'], version: '7'
        , ->
          @service.init
            header: 'Systemd Script'
            target: '/usr/lib/systemd/system/hadoop-yarn-resourcemanager.service'
            source: "#{__dirname}/../resources/hadoop-yarn-resourcemanager-systemd.j2"
            local: true
            context: @config.ryba
            mode: 0o0644
          @system.tmpfs
            header: 'Run dir'
            mount: "#{yarn.rm.pid_dir}"
            uid: yarn.user.name
            gid: hadoop_group.name
            perm: '0755'

      @call header: 'Layout', ->
        {yarn, hadoop_group} = @config.ryba
        @system.mkdir
          target: "#{yarn.rm.conf_dir}"
        @system.mkdir
          target: "#{yarn.rm.pid_dir}"
          uid: yarn.user.name
          gid: hadoop_group.name
          mode: 0o755
        @system.mkdir
          target: "#{yarn.rm.log_dir}"
          uid: yarn.user.name
          gid: yarn.group.name
          parent: true
        @file.touch
          target: "#{yarn.rm.site['yarn.resourcemanager.nodes.include-path']}"
        @file.touch
          target: "#{yarn.rm.site['yarn.resourcemanager.nodes.exclude-path']}"

## Configure

      @hconfigure
        header: 'Core Site'
        target: "#{yarn.rm.conf_dir}/core-site.xml"
        source: "#{__dirname}/../../resources/core_hadoop/core-site.xml"
        local: true
        properties: yarn.rm.core_site
        backup: true
      @hconfigure
        header: 'HDFS Site'
        target: "#{yarn.rm.conf_dir}/hdfs-site.xml"
        properties: hdfs.site
        backup: true
      @hconfigure
        label: 'YARN Site'
        target: "#{yarn.rm.conf_dir}/yarn-site.xml"
        source: "#{__dirname}/../../resources/core_hadoop/yarn-site.xml"
        local: true
        properties: yarn.rm.site
        backup: true
      @file
        header: 'Log4j'
        target: "#{yarn.rm.conf_dir}/log4j.properties"
        source: "#{__dirname}/../resources/log4j.properties"
        local: true
        write: for k, v of yarn.rm.log4j
          match: RegExp "#{k}=.*", 'm'
          replace: "#{k}=#{v}"
          append: true
      @call header: 'YARN Env', ->
        yarn.rm.java_opts += " -D#{k}=#{v}" for k, v of yarn.rm.opts
        @file.render
          target: "#{yarn.rm.conf_dir}/yarn-env.sh"
          source: "#{__dirname}/../resources/yarn-env.sh.j2"
          local: true
          context:
            JAVA_HOME: java.java_home
            HADOOP_YARN_HOME: yarn.rm.home
            YARN_LOG_DIR: yarn.rm.log_dir
            YARN_PID_DIR: yarn.rm.pid_dir
            HADOOP_LIBEXEC_DIR: hadoop_libexec_dir
            YARN_HEAPSIZE: yarn.heapsize
            YARN_RESOURCEMANAGER_HEAPSIZE: yarn.rm.heapsize
            YARN_RESOURCEMANAGER_OPTS: yarn.rm.java_opts
            YARN_OPTS: yarn.opts
            YARN_ROOT_LOGGER: yarn.rm.root_logger
          uid: yarn.user.name
          gid: hadoop_group.name
          mode: 0o0755
          backup: true
        @file.render
          header: 'Env'
          target: "#{yarn.rm.conf_dir}/hadoop-env.sh"
          source: "#{__dirname}/../resources/hadoop-env.sh.j2"
          local: true
          context:
            HADOOP_LOG_DIR: yarn.rm.log_dir
            HADOOP_PID_DIR: yarn.rm.pid_dir
            java_home: @config.java.java_home
          uid: yarn.user.name
          gid: hadoop_group.name
          mode: 0o750
          backup: true
          eof: true

Configure the "hadoop-metrics2.properties" to connect Hadoop to a Metrics collector like Ganglia or Graphite.

      @file.properties
        header: 'Metrics'
        target: "#{yarn.rm.conf_dir}/hadoop-metrics2.properties"
        content: hadoop_metrics.config
        backup: true

## MapRed Site

      @hconfigure # Ideally placed inside a mapred_jhs_client module
        header: 'MapRed Site'
        target: "#{yarn.rm.conf_dir}/mapred-site.xml"
        properties: mapred.site
        backup: true

## SSL

      @call header: 'SSL', retry: 0, ->
        ssl_client['ssl.client.truststore.location'] = "#{yarn.rm.conf_dir}/truststore"
        ssl_server['ssl.server.keystore.location'] = "#{yarn.rm.conf_dir}/keystore"
        ssl_server['ssl.server.truststore.location'] = "#{yarn.rm.conf_dir}/truststore"
        @hconfigure
          target: "#{yarn.rm.conf_dir}/ssl-server.xml"
          properties: ssl_server
        @hconfigure
          target: "#{yarn.rm.conf_dir}/ssl-client.xml"
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

      @krb5.addprinc krb5,
        header: 'Kerberos'
        principal: yarn.rm.site['yarn.resourcemanager.principal'].replace '_HOST', @config.host
        randkey: true
        keytab: yarn.rm.site['yarn.resourcemanager.keytab']
        uid: yarn.user.name
        gid: hadoop_group.name

## Kerberos JAAS

The JAAS file is used by the ResourceManager to initiate a secure connection 
with Zookeeper.

      @file.jaas
        header: 'Kerberos JAAS'
        target: "#{yarn.rm.conf_dir}/yarn-rm.jaas"
        content: Client:
          principal: yarn.rm.site['yarn.resourcemanager.principal'].replace '_HOST', @config.host
          keyTab: yarn.rm.site['yarn.resourcemanager.keytab']
        uid: yarn.user.name
        gid: hadoop_group.name

## Ulimit

Increase ulimit for the HDFS user. The HDP package create the following
files:

```bash
cat /etc/security/limits.d/yarn.conf
yarn   - nofile 32768
yarn   - nproc  65536
```

Note, a user must re-login for those changes to be taken into account. See
the "ryba/hadoop/hdfs" module for additional information.

      @system.limits
        header: 'Ulimit'
        user: yarn.user.name
      , yarn.user.limits

## Ranger YARN Plugin Install

      @call
        if: -> @contexts('ryba/ranger/admin').length > 0
      , ->
        @call -> @config.ryba.yarn_plugin_is_master = true
        @call 'ryba/ranger/plugins/yarn/install'

## Node Labels HDFS Layout

      @hdfs_mkdir
        if: yarn.rm.site['yarn.node-labels.enabled'] is 'true'
        header: 'HBase Master plugin HDFS audit dir'
        target: yarn.rm.site['yarn.node-labels.fs-store.root-dir']
        mode: 0o700
        user: yarn.user.name
        group: yarn.user.name
        unless_exec: mkcmd.hdfs @, "hdfs dfs -test -d #{yarn.rm.site['yarn.node-labels.fs-store.root-dir']}"

## Dependencies

    {merge} = require 'nikita/lib/misc'

## Todo: WebAppProxy.

It semms like it is run as part of rm by default and could also be started
separately on an edge node.

*   yarn.web-proxy.address    WebAppProxy                                   host:port for proxy to AM web apps. host:port if this is the same as yarn.resourcemanager.webapp.address or it is not defined then the ResourceManager will run the proxy otherwise a standalone proxy server will need to be launched.
*   yarn.web-proxy.keytab     /etc/security/keytabs/web-app.service.keytab  Kerberos keytab file for the WebAppProxy.
*   yarn.web-proxy.principal  wap/_HOST@REALM.TLD                           Kerberos principal name for the WebAppProxy.


[capacity]: http://hadoop.apache.org/docs/r2.5.0/hadoop-yarn/hadoop-yarn-site/CapacityScheduler.html

## Dependencies

    mkcmd = require '../../lib/mkcmd'

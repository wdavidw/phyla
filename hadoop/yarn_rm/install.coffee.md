
# Hadoop YARN ResourceManager Install

    module.exports = header: 'YARN RM Install', handler: (options) ->

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdp_select', 'ryba/lib/hdp_select'
      @registry.register 'hdfs_mkdir', 'ryba/lib/hdfs_mkdir'
      @registry.register ['file', 'jaas'], 'ryba/lib/file_jaas'

## Identities

By default, the "hadoop-yarn-resourcemanager" package create the following entries:

```bash
cat /etc/passwd | grep yarn
yarn:x:2403:2403:Hadoop YARN User:/var/lib/hadoop-yarn:/bin/bash
cat /etc/group | grep hadoop
hadoop:x:499:hdfs
```

      @system.group header: 'Hadoop Group', options.hadoop_group
      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user

## Ulimit

Increase ulimit for the HDFS user. The HDP package create the following
files:

```bash
cat /etc/security/limits.d/yarn.conf
yarn   - nofile 32768
yarn   - nproc  65536
```

Note, a user must re-login for those changes to be taken into account.

      @system.limits
        header: 'Ulimit'
        user: options.user.name
      , options.user.limits

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

      id = if options.yarn_site['yarn.resourcemanager.ha.enabled'] is 'true' then ".#{options.yarn_site['yarn.resourcemanager.ha.id']}" else ''
      rules = []
      # Application
      rpc_port = options.yarn_site["yarn.resourcemanager.address#{id}"].split(':')[1]
      rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: rpc_port, protocol: 'tcp', state: 'NEW', comment: "YARN RM Application Submissions" }
      # Scheduler
      s_port = options.yarn_site["yarn.resourcemanager.scheduler.address#{id}"].split(':')[1]
      rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: s_port, protocol: 'tcp', state: 'NEW', comment: "YARN Scheduler" }
      # RM Scheduler
      admin_port = options.yarn_site["yarn.resourcemanager.admin.address#{id}"].split(':')[1]
      rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: admin_port, protocol: 'tcp', state: 'NEW', comment: "YARN RM Scheduler" }
      # HTTP
      if options.yarn_site['yarn.http.policy'] in ['HTTP_ONLY', 'HTTP_AND_HTTPS']
        http_port = options.yarn_site["yarn.resourcemanager.webapp.address#{id}"].split(':')[1]
        rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: http_port, protocol: 'tcp', state: 'NEW', comment: "YARN RM Web UI" }
      # HTTPS
      if options.yarn_site['yarn.http.policy'] in ['HTTPS_ONLY', 'HTTP_AND_HTTPS']
        https_port = options.yarn_site["yarn.resourcemanager.webapp.https.address#{id}"].split(':')[1]
        rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: https_port, protocol: 'tcp', state: 'NEW', comment: "YARN RM Web UI" }
      # Resource Tracker
      rt_port = options.yarn_site["yarn.resourcemanager.resource-tracker.address#{id}"].split(':')[1]
      rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: rt_port, protocol: 'tcp', state: 'NEW', comment: "YARN RM Application Submissions" }
      @tools.iptables
        header: 'IPTables'
        if: options.iptables
        rules: rules

## Service

Install the "hadoop-yarn-resourcemanager" service, symlink the rc.d startup script
inside "/etc/init.d" and activate it on startup.

      @call header: 'Service', ->
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
          context: options: options
          mode: 0o0755
        @call
          if_os: name: ['redhat','centos'], version: '7'
        , ->
          @service.init
            header: 'Systemd Script'
            target: '/usr/lib/systemd/system/hadoop-yarn-resourcemanager.service'
            source: "#{__dirname}/../resources/hadoop-yarn-resourcemanager-systemd.j2"
            local: true
            context: options: options
            mode: 0o0644
          @system.tmpfs
            header: 'Run dir'
            mount: "#{options.pid_dir}"
            uid: options.user.name
            gid: options.hadoop_group.name
            perm: '0755'

      @call header: 'Layout', ->
        @system.mkdir
          target: "#{options.conf_dir}"
        @system.mkdir
          target: "#{options.pid_dir}"
          uid: options.user.name
          gid: options.hadoop_group.name
          mode: 0o755
        @system.mkdir
          target: "#{options.log_dir}"
          uid: options.user.name
          gid: options.group.name
          parent: true
        @file.touch
          target: "#{options.yarn_site['yarn.resourcemanager.nodes.include-path']}"
        @file.touch
          target: "#{options.yarn_site['yarn.resourcemanager.nodes.exclude-path']}"

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
        properties: options.hdfs_site
        backup: true
      @hconfigure
        label: 'YARN Site'
        target: "#{options.conf_dir}/yarn-site.xml"
        source: "#{__dirname}/../../resources/core_hadoop/yarn-site.xml"
        local: true
        properties: options.yarn_site
        backup: true
      @file
        header: 'Log4j'
        target: "#{options.conf_dir}/log4j.properties"
        source: "#{__dirname}/../resources/log4j.properties"
        local: true
        write: for k, v of options.log4j.properties
          match: RegExp "#{k}=.*", 'm'
          replace: "#{k}=#{v}"
          append: true
      @call header: 'YARN Env', ->
        YARN_RESOURCEMANAGER_OPTS = options.opts.base
        YARN_RESOURCEMANAGER_OPTS += " -D#{k}=#{v}" for k, v of options.opts.java_properties
        YARN_RESOURCEMANAGER_OPTS += " #{k}#{v}" for k, v of options.opts.jvm
        @file.render
          target: "#{options.conf_dir}/yarn-env.sh"
          source: "#{__dirname}/../resources/yarn-env.sh.j2"
          local: true
          context:
            JAVA_HOME: options.java_home
            HADOOP_YARN_HOME: options.home
            YARN_LOG_DIR: options.log_dir
            YARN_PID_DIR: options.pid_dir
            HADOOP_LIBEXEC_DIR: ''
            YARN_HEAPSIZE: options.heapsize
            YARN_RESOURCEMANAGER_HEAPSIZE: options.heapsize
            YARN_RESOURCEMANAGER_OPTS: YARN_RESOURCEMANAGER_OPTS
            # YARN_OPTS: options.client_opts # should be yarn_client.opts, not sure if needed
            YARN_ROOT_LOGGER: options.log4j.root_logger
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

## MapRed Site

      # @hconfigure # Ideally placed inside a mapred_jhs_client module
      #   header: 'MapRed Site'
      #   target: "#{options.conf_dir}/mapred-site.xml"
      #   properties: options.mapred_site
      #   backup: true

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
          local: options.ssl.key.local
        @java.keystore_add
          keystore: options.ssl_server['ssl.server.keystore.location']
          storepass: options.ssl_server['ssl.server.keystore.password']
          caname: 'hadoop_root_ca'
          cacert: options.ssl.cacert.source
          local: options.ssl.cacert.local

## Kerberos

      @krb5.addprinc options.krb5.admin,
        header: 'Kerberos'
        principal: options.yarn_site['yarn.resourcemanager.principal'].replace '_HOST', options.fqdn
        randkey: true
        keytab: options.yarn_site['yarn.resourcemanager.keytab']
        uid: options.user.name
        gid: options.hadoop_group.name

## Kerberos JAAS

The JAAS file is used by the ResourceManager to initiate a secure connection 
with Zookeeper.

      @file.jaas
        header: 'Kerberos JAAS'
        target: "#{options.conf_dir}/yarn-rm.jaas"
        content: Client:
          principal: options.yarn_site['yarn.resourcemanager.principal'].replace '_HOST', options.fqdn
          keyTab: options.yarn_site['yarn.resourcemanager.keytab']
        uid: options.user.name
        gid: options.hadoop_group.name

## Ranger YARN Plugin Install

      # @call
      #   if: -> @contexts('ryba/ranger/admin').length > 0
      # , ->
      #   @call -> options.yarn_plugin_is_master = true
      #   @call 'ryba/ranger/plugins/yarn/install'

## Node Labels HDFS Layout

      @hdfs_mkdir
        if: options.yarn_site['yarn.node-labels.enabled'] is 'true'
        header: 'HBase Master plugin HDFS audit dir'
        target: options.yarn_site['yarn.node-labels.fs-store.root-dir']
        mode: 0o700
        user: options.user.name
        group: options.group.name
        unless_exec: mkcmd.hdfs options.hdfs_krb5_user, "hdfs --config #{options.conf_dir} dfs -test -d #{options.yarn_site['yarn.node-labels.fs-store.root-dir']}"

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

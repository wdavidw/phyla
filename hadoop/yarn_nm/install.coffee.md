
# HADOOP YARN NodeManager Install

    module.exports = header: 'YARN NM Install', handler: ->
      {java} = @config
      {realm, hadoop_group, hadoop_metrics, hadoop_conf_dir, core_site, hdfs, yarn, container_executor, hadoop_libexec_dir} = @config.ryba
      {ssl, ssl_server, ssl_client} = @config.ryba
      krb5 = @config.krb5_client.admin[realm]

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdp_select', 'ryba/lib/hdp_select'

## Wait

      @call once: true, 'masson/core/krb5_client/wait'
      @wait once: true, 'ryba/hadoop/hdfs_nn/wait'

## IPTables

| Service    | Port | Proto  | Parameter                          |
|------------|------|--------|------------------------------------|
| nodemanager | 45454 | tcp  | yarn.nodemanager.address           | x
| nodemanager | 8040  | tcp  | yarn.nodemanager.localizer.address |
| nodemanager | 8042  | tcp  | yarn.nodemanager.webapp.address    |
| nodemanager | 8044  | tcp  | yarn.nodemanager.webapp.https.address    |

IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

      nm_port = yarn.site['yarn.nodemanager.address'].split(':')[1]
      nm_localizer_port = yarn.site['yarn.nodemanager.localizer.address'].split(':')[1]
      nm_webapp_port = yarn.site['yarn.nodemanager.webapp.address'].split(':')[1]
      nm_webapp_https_port = yarn.site['yarn.nodemanager.webapp.https.address'].split(':')[1]
      @tools.iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: nm_port, protocol: 'tcp', state: 'NEW', comment: "YARN NM Container" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: nm_localizer_port, protocol: 'tcp', state: 'NEW', comment: "YARN NM Localizer" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: nm_webapp_port, protocol: 'tcp', state: 'NEW', comment: "YARN NM Web UI" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: nm_webapp_https_port, protocol: 'tcp', state: 'NEW', comment: "YARN NM Web Secured UI" }
        ]
        if: @config.iptables.action is 'start'

## Packages

Install the "hadoop-yarn-nodemanager" service, symlink the rc.d startup script
inside "/etc/init.d" and activate it on startup.

      @call header: 'Packages', (options) ->
        @service
          name: 'hadoop-yarn-nodemanager'
        @hdp_select
          # name: 'hadoop-yarn-client' # Not checked
          name: 'hadoop-yarn-nodemanager'
        @service.init
          if_os: name: ['redhat','centos'], version: '6'
          header: 'Initd Script'
          target: '/etc/init.d/hadoop-yarn-nodemanager'
          source: "#{__dirname}/../resources/hadoop-yarn-nodemanager.j2"
          local: true
          context: @config
          mode: 0o0755
        @service # Seems like NM complain with message "java.lang.ClassNotFoundException: Class org.apache.hadoop.mapred.ShuffleHandler not found"
          name: 'hadoop-mapreduce'
        @hdp_select
          name: 'hadoop-client'
        @call
          if_os: name: ['redhat','centos'], version: '7'
        , ->
          @service.init
            header: 'Systemd Script'
            target: '/usr/lib/systemd/system/hadoop-yarn-nodemanager.service'
            source: "#{__dirname}/../resources/hadoop-yarn-nodemanager-systemd.j2"
            local: true
            context: @config.ryba
            mode: 0o0644
          @system.tmpfs
            if_os: name: ['redhat','centos'], version: '7'
            mount: "#{yarn.nm.pid_dir}"
            uid: yarn.user.name
            gid: hadoop_group.name
            perm: '0755'
        @call
          if: yarn.site['spark.shuffle.service.enabled'] is 'true'
          header: 'Spark Worker Shuffle Package'
        , ->
          @service
            name: 'spark_*-yarn-shuffle'
          @system.execute
            cmd: """
            file_lib=`ls /usr/hdp/current/spark-client/lib/* | grep yarn-shuffle.jar`
            file_aux=`ls /usr/hdp/current/spark-client/aux/* | grep yarn-shuffle.jar`
            file=''
            if [ -f "$file_lib" ] ; 
              then file=$file_lib ; 
            else if [ -f "$file_aux" ] ; 
              then file=$file_aux ; 
            fi;
            name=`basename $file`
            target="/usr/hdp/current/hadoop-yarn-nodemanager/lib/${name}"
            source=`readlink $target`
            if [ "$source" == "$file" ] ;
              then exit 3 ;
              else
                rm -f $target;
                ln -s $file $target;
                exit 0;
                fi;
            fi;
            """
            code_skipped: 3

      @call header: 'Layout', ->
        @system.mkdir
          target: "#{yarn.nm.conf_dir}"
        @system.mkdir
          target: "#{yarn.nm.pid_dir}"
          uid: yarn.user.name
          gid: hadoop_group.name
          mode: 0o0755
        @system.mkdir
          target: "#{yarn.nm.log_dir}"
          uid: yarn.user.name
          gid: yarn.group.name
          parent: true
        @system.mkdir
          target: yarn.site['yarn.nodemanager.log-dirs'].split ','
          uid: yarn.user.name
          gid: hadoop_group.name
          mode: 0o0755
          parent: true
        @system.mkdir
          target: yarn.site['yarn.nodemanager.local-dirs'].split ','
          uid: yarn.user.name
          gid: hadoop_group.name
          mode: 0o0755
          parent: true
        @system.mkdir
          target: yarn.site['yarn.nodemanager.recovery.dir'] 
          uid: yarn.user.name
          gid: hadoop_group.name
          mode: 0o0750
          parent: true

## Capacity Planning

Naive discovery of the memory and CPU allocated by this NodeManager.

It is recommended to use the "capacity" script prior install Hadoop on
your cluster. It will suggest you relevant values for your servers with a
global view of your system. In such case, this middleware is bypassed and has
no effect. Also, this isnt included inside the configuration because it need an
SSH connection to the node to gather the memory and CPU informations.

      @call
        header: 'Capacity Planning'
        unless: yarn.site['yarn.nodemanager.resource.memory-mb'] and yarn.site['yarn.nodemanager.resource.cpu-vcores']
      , ->
        # diskNumber = yarn.site['yarn.nodemanager.local-dirs'].length
        yarn.site['yarn.nodemanager.resource.memory-mb'] ?= Math.round @meminfo.MemTotal / 1024 / 1024 * .8
        yarn.site['yarn.nodemanager.resource.cpu-vcores'] ?= @cpuinfo.length

## Configure

      @hconfigure
        header: 'Core Site'
        target: "#{yarn.nm.conf_dir}/core-site.xml"
        source: "#{__dirname}/../../resources/core_hadoop/core-site.xml"
        local: true
        properties: core_site
        backup: true
      @hconfigure
        header: 'HDFS Site'
        target: "#{yarn.nm.conf_dir}/hdfs-site.xml"
        properties: hdfs.site
        backup: true
      @hconfigure
        header: 'YARN Site'
        target: "#{yarn.nm.conf_dir}/yarn-site.xml"
        source: "#{__dirname}/../../resources/core_hadoop/yarn-site.xml"
        local: true
        properties: yarn.site
        backup: true
      @file
        header: 'Log4j'
        target: "#{yarn.nm.conf_dir}/log4j.properties"
        source: "#{__dirname}/../resources/log4j.properties"
        local: true
      @call header: 'YARN Env', ->
        yarn.nm.java_opts += " -D#{k}=#{v}" for k, v of yarn.nm.opts 
        @file.render
          header: 'YARN Env'
          target: "#{yarn.nm.conf_dir}/yarn-env.sh"
          source: "#{__dirname}/../resources/yarn-env.sh.j2"
          local: true
          context:
            JAVA_HOME: java.java_home
            HADOOP_YARN_HOME: yarn.nm.home
            YARN_LOG_DIR: yarn.nm.log_dir
            YARN_PID_DIR: yarn.nm.pid_dir
            HADOOP_LIBEXEC_DIR: hadoop_libexec_dir
            YARN_HEAPSIZE: yarn.heapsize
            YARN_NODEMANAGER_HEAPSIZE: yarn.nm.heapsize
            YARN_NODEMANAGER_OPTS: yarn.nm.java_opts
            YARN_OPTS: yarn.opts
          uid: yarn.user.name
          gid: hadoop_group.name
          mode: 0o0755
          backup: true
      @file.render
        header: 'Env'
        target: "#{yarn.nm.conf_dir}/hadoop-env.sh"
        source: "#{__dirname}/../resources/hadoop-env.sh.j2"
        local: true
        context:
          HADOOP_LOG_DIR: yarn.nm.log_dir
          HADOOP_PID_DIR: yarn.nm.pid_dir
          java_home: @config.java.java_home
        uid: yarn.user.name
        gid: hadoop_group.name
        mode: 0o750
        backup: true
        eof: true

Configure the "hadoop-metrics2.properties" to connect Hadoop to a Metrics collector like Ganglia or Graphite.

      @file.properties
        header: 'Metrics'
        target: "#{yarn.nm.conf_dir}/hadoop-metrics2.properties"
        content: hadoop_metrics.config
        backup: true

## Container Executor

Important: path seems hardcoded to "../etc/hadoop/container-executor.cfg", 
running `/usr/hdp/current/hadoop-yarn-client/bin/container-executor` will print
"Configuration file ../etc/hadoop/container-executor.cfg not found." if missing.

The parent directory must be owned by root or it will print: "Caused by:
ExitCodeException exitCode=24: File File /etc/hadoop/conf must be owned by root,
but is owned by 2401"

      @call header: 'Container Executor', ->
        ce_group = container_executor['yarn.nodemanager.linux-container-executor.group']
        ce = '/usr/hdp/current/hadoop-yarn-nodemanager/bin/container-executor'
        @system.chown
          target: ce
          uid: 'root'
          gid: ce_group
        @system.chmod
          target: ce
          mode: 0o6050
        @system.mkdir
          target: "#{hadoop_conf_dir}"
          uid: 'root'
        @file.ini
          target: "#{hadoop_conf_dir}/container-executor.cfg"
          content: container_executor
          uid: 'root'
          gid: ce_group
          mode: 0o0640
          separator: '='
          backup: true

## SSL

      @call header: 'SSL', retry: 0, ->
        ssl_client['ssl.client.truststore.location'] = "#{yarn.nm.conf_dir}/truststore"
        ssl_server['ssl.server.keystore.location'] = "#{yarn.nm.conf_dir}/keystore"
        ssl_server['ssl.server.truststore.location'] = "#{yarn.nm.conf_dir}/truststore"
        @hconfigure
          target: "#{yarn.nm.conf_dir}/ssl-server.xml"
          properties: ssl_server
        @hconfigure
          target: "#{yarn.nm.conf_dir}/ssl-client.xml"
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

Create the Kerberos user to the Node Manager service. By default, it takes the
form of "rm/{fqdn}@{realm}"

      @krb5.addprinc krb5,
        header: 'Kerberos'
        principal: yarn.site['yarn.nodemanager.principal'].replace '_HOST', @config.host
        randkey: true
        keytab: yarn.site['yarn.nodemanager.keytab']
        uid: yarn.user.name
        gid: hadoop_group.name

## Cgroups Configuration

YARN Nodemanager can be configured to mount automatically the cgroup path on start.
If `yarn.nodemanager.linux-container-executor.cgroups.mount` is set to true,
Ryba just mkdirs the path.
Is `yarn.nodemanager.linux-container-executor.cgroups.mount` is set to false,
it creates and persist a cgroup for yarn by registering into the /etc/cgconfig configuration.
Note: For now (December 2016 - HDP 2.5.3.0), yarn does not support `systemctl` cgroups
on Centos/Redhat7 OS. Legacy cgconfig and cgroup-tools package must be used. (masson/core/cgroups)

      @call
        header: 'Cgroups Auto'
        if: -> yarn.site['yarn.nodemanager.linux-container-executor.cgroups.mount'] is 'true'
      , ->
        @service
          name: 'libcgroup'
        # .execute
        #   cmd: 'mount -t cgroup -o cpu cpu /cgroup'
        #   code_skipped: 32
        @system.mkdir
          target: "#{yarn.site['yarn.nodemanager.linux-container-executor.cgroups.mount-path']}/cpu"
          mode: 0o1777
          parent: true
      @call
        header: 'Cgroups Manual'
        unless: -> yarn.site['yarn.nodemanager.linux-container-executor.cgroups.mount'] is 'true'
      , (options) ->
        hierarchy = yarn.site['yarn.nodemanager.linux-container-executor.cgroups.hierarchy'] ?= "/#{ryba.yarn.user.name}"
        @system.cgroups
          target: '/etc/cgconfig.d/yarn.cgconfig.conf'
          merge: false
          groups: yarn.cgroup
        @service.restart
          name: 'cgconfig'
          if: -> @status -1
        @call (options) ->
          yarn.site['yarn.nodemanager.linux-container-executor.cgroups.mount-path'] = options.store['nikita:cgroups:mount']
          @hconfigure
            header: 'YARN Site'
            target: "#{yarn.nm.conf_dir}/yarn-site.xml"
            properties: yarn.site
            merge: true
            backup: true

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

### HDFS Layout

Create the YARN log directory defined by the property 
"yarn.nodemanager.remote-app-log-dir". The default value in the HDP companion
files is "/app-logs". The command `hdfs dfs -ls /` should print:

```
drwxrwxrwt   - yarn   hadoop            0 2014-05-26 11:01 /app-logs
```

Layout is inspired by [Hadoop recommandation](http://hadoop.apache.org/docs/r2.1.0-beta/hadoop-project-dist/hadoop-common/ClusterSetup.html)

      remote_app_log_dir = yarn.site['yarn.nodemanager.remote-app-log-dir']
      @system.execute
        header: 'HDFS layout'
        cmd: mkcmd.hdfs @, """
        hdfs --config #{hadoop_conf_dir} dfs -mkdir -p #{remote_app_log_dir}
        hdfs --config #{hadoop_conf_dir} dfs -chown #{yarn.user.name}:#{hadoop_group.name} #{remote_app_log_dir}
        hdfs --config #{hadoop_conf_dir} dfs -chmod 1777 #{remote_app_log_dir}
        """
        unless_exec: "[[ hdfs dfs -d #{remote_app_log_dir} ]]"
        code_skipped: 2

## Ranger YARN Plugin Install

      @call
        if: -> @contexts('ryba/ranger/admin').length > 0
      , ->
        @call -> @config.ryba.yarn_plugin_is_master = false
        @call 'ryba/ranger/plugins/yarn/install'

## Dependencies

    mkcmd = require '../../lib/mkcmd'

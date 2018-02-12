
# YARN NodeManager Configuration

## Exemple

```json
{ "ryba": { "yarn": { "nm": {
    "opts": "",
    "heapsize": "1024"
} } } }
```

    module.exports = (service) ->
      options = service.options

## Identities

      options.hadoop_group = merge {}, service.deps.hadoop_core.options.hadoop_group, options.hadoop_group
      options.group = merge {}, service.deps.hadoop_core.options.yarn.group, options.group
      options.user = merge {}, service.deps.hadoop_core.options.yarn.user, options.user

## Kerberos

      options.krb5 ?= {}
      options.krb5.realm ?= service.deps.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      throw Error 'Required Options: "realm"' unless options.krb5.realm
      options.krb5.admin ?= service.deps.krb5_client.options.admin[options.krb5.realm]

## Environment

      # Layout
      options.home ?= '/usr/hdp/current/hadoop-yarn-nodemanager'
      options.log_dir ?= '/var/log/hadoop-yarn'
      options.pid_dir ?= '/var/run/hadoop-yarn'
      options.conf_dir ?= '/etc/hadoop-yarn-nodemanager/conf'
      # Java
      options.java_home ?= service.deps.java.options.java_home
      options.heapsize ?= '1024m'
      options.newsize ?= '200m'
      # Misc
      options.fqdn ?= service.node.fqdn
      options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'
      options.iptables_rules ?= []
      options.libexec ?= '/usr/hdp/current/hadoop-client/libexec'
      options.hdfs_krb5_user = service.deps.hadoop_core.options.hdfs.krb5_user

## Configuration

      # Hadoop core "core-site.xml"
      options.core_site = merge {}, service.deps.hdfs_client[0].options.core_site, options.core_site or {}
      # HDFS client "hdfs-site.xml"
      options.hdfs_site = merge {}, service.deps.hdfs_client[0].options.hdfs_site, options.hdfs_site or {}
      # Yarn NodeManager "yarn-site.xml"
      options.yarn_site ?= {}
      options.yarn_site['yarn.http.policy'] ?= 'HTTPS_ONLY' # HTTP_ONLY or HTTPS_ONLY or HTTP_AND_HTTPS
      # Working Directories (see capacity for server resource discovery)
      options.yarn_site['yarn.nodemanager.local-dirs'] ?= ['/var/yarn/local']
      options.yarn_site['yarn.nodemanager.local-dirs'] = options.yarn_site['yarn.nodemanager.local-dirs'].join ',' if Array.isArray options.yarn_site['yarn.nodemanager.local-dirs']
      options.yarn_site['yarn.nodemanager.log-dirs'] ?= ['/var/yarn/logs']
      options.yarn_site['yarn.nodemanager.log-dirs'] = options.yarn_site['yarn.nodemanager.log-dirs'].join ',' if Array.isArray options.yarn_site['yarn.nodemanager.log-dirs']
      # Configuration
      # options.yarn_site['yarn.scheduler.minimum-allocation-mb'] ?= null # Make sure we erase hdp default value
      # options.yarn_site['yarn.scheduler.maximum-allocation-mb'] ?= null # Make sure we erase hdp default value
      options.yarn_site['yarn.nodemanager.address'] ?= "#{service.node.fqdn}:45454"
      options.yarn_site['yarn.nodemanager.localizer.address'] ?= "#{service.node.fqdn}:8040"
      options.yarn_site['yarn.nodemanager.webapp.address'] ?= "#{service.node.fqdn}:8042"
      options.yarn_site['yarn.nodemanager.webapp.https.address'] ?= "#{service.node.fqdn}:8044"
      options.yarn_site['yarn.nodemanager.remote-app-log-dir'] ?= "/app-logs"
      options.yarn_site['yarn.nodemanager.keytab'] ?= '/etc/security/keytabs/nm.service.keytab'
      options.yarn_site['yarn.nodemanager.principal'] ?= "nm/_HOST@#{options.krb5.realm}"
      options.yarn_site['yarn.nodemanager.vmem-pmem-ratio'] ?= '2.1'
      # Cloudera recommand setting [vmem-check to false on Centos/RHEL 6 due to its aggressive allocation of virtual memory](http://blog.cloudera.com/blog/2014/04/apache-hadoop-yarn-avoiding-6-time-consuming-gotchas/)
      # by default, "yarn.nodemanager.vmem-check-enabled" is true (see in yarn-default.xml)
      options.yarn_site['yarn.nodemanager.pmem-check-enabled'] ?= 'true'
      options.yarn_site['yarn.nodemanager.vmem-check-enabled'] ?= 'true'
      options.yarn_site['yarn.nodemanager.resource.percentage-physical-cpu-limit'] ?= '100'
      options.yarn_site['yarn.nodemanager.container-executor.class'] ?= 'org.apache.hadoop.yarn.server.nodemanager.LinuxContainerExecutor'
      options.yarn_site['yarn.nodemanager.linux-container-executor.group'] ?= 'yarn'
      options.yarn_site['yarn.nodemanager.linux-container-executor.cgroups.strict-resource-usage'] ?= 'false' # By default, iyarn.nodemanager.container-executor.clasf spare CPU cycles are available, containers are allowed to exceed the CPU limits set for them
      # Fix bug in HDP companion files (missing "s")
      options.yarn_site['yarn.nodemanager.log.retain-second'] ?= null
      options.yarn_site['yarn.nodemanager.log.retain-seconds'] ?= '604800'
      # Configurations for History Server (Not sure wether this should be deployed on NMs):
      options.yarn_site['yarn.log-aggregation-enable'] ?= 'true'
      options.yarn_site['yarn.log-aggregation.retain-seconds'] ?= '2592000' #  30 days, how long to keep aggregation logs before deleting them. -1 disables. Be careful, set this too small and you will spam the name node.
      options.yarn_site['yarn.log-aggregation.retain-check-interval-seconds'] ?= '-1' # Time between checks for aggregated log retention. If set to 0 or a negative value then the value is computed as one-tenth of the aggregated log retention time. Be careful, set this too small and you will spam the name node.

## System Options

      options.opts ?= {}
      options.opts.base ?= ''
      options.opts.java_properties ?= {}
      options.opts.jvm ?= {}
      options.opts.jvm['-Xms'] ?= options.heapsize
      options.opts.jvm['-Xmx'] ?= options.heapsize
      options.opts.jvm['-XX:NewSize='] ?= options.newsize #should be 1/8 of datanode heapsize
      options.opts.jvm['-XX:MaxNewSize='] ?= options.newsize #should be 1/8 of datanode heapsize

## Container Executor

[YARN containers][container] in a secure cluster use the operating system 
facilities to offer execution isolation for containers. Secure containers 
execute under the credentials of the job user. The operating system enforces 
access restriction for the container. The container must run as the use that 
submitted the application.

Secure Containers work only in the context of secured YARN clusters.

      options.container_executor ?= {}
      options.container_executor['yarn.nodemanager.local-dirs'] ?= options.yarn_site['yarn.nodemanager.local-dirs']
      options.container_executor['yarn.nodemanager.linux-container-executor.group'] ?= options.yarn_site['yarn.nodemanager.linux-container-executor.group']
      options.container_executor['yarn.nodemanager.log-dirs'] = options.yarn_site['yarn.nodemanager.log-dirs']
      options.container_executor['banned.users'] ?= 'hdfs,yarn,mapred,bin'
      options.container_executor['min.user.id'] ?= '0'

## Work Preserving Recovery

See ResourceManager for additionnal informations.

      options.yarn_site['yarn.nodemanager.recovery.enabled'] ?= 'true'
      options.yarn_site['yarn.nodemanager.recovery.dir'] ?= '/var/yarn/recovery-state'

## Configuration for CGroups

Resources:
*   [YARN-600: Hook up cgroups CPU settings to the number of virtual cores allocated](https://issues.apache.org/jira/browse/YARN-600)
*   [YARN-810: CGroup ceiling enforcement on CPU](https://issues.apache.org/jira/browse/YARN-810)
*   [Using YARN with Cgroups](http://riccomini.name/posts/hadoop/2013-06-14-yarn-with-cgroups/)
*   [VCore Configuration In Hadoop](http://jason4zhu.blogspot.fr/2014/10/vcore-configuration-in-hadoop.html)

      # isLinuxContainer = options.yarn_site['yarn.nodemanager.container-executor.class'] is 'org.apache.hadoop.yarn.server.nodemanager.LinuxContainerExecutor'
      # options.yarn_site['yarn.nodemanager.linux-container-executor.resources-handler.class'] ?= 'org.apache.hadoop.yarn.server.nodemanager.util.CgroupsLCEResourcesHandler'
      # options.yarn_site['yarn.nodemanager.linux-container-executor.cgroups.hierarchy'] ?= '/hadoop-yarn'
      # options.yarn_site['yarn.nodemanager.linux-container-executor.cgroups.mount'] ?= 'true'
      # options.yarn_site['yarn.nodemanager.linux-container-executor.cgroups.mount-path'] ?= '/cgroup'
      options.yarn_site['yarn.nodemanager.linux-container-executor.resources-handler.class'] ?= 'org.apache.hadoop.yarn.server.nodemanager.util.CgroupsLCEResourcesHandler'
      hierarchy = options.yarn_site['yarn.nodemanager.linux-container-executor.cgroups.hierarchy'] ?= "/#{options.user.name}"
      options.yarn_site['yarn.nodemanager.linux-container-executor.cgroups.mount'] ?= 'false'
      options.yarn_site['yarn.nodemanager.linux-container-executor.cgroups.mount-path'] ?= '/cgroup'
      # HDP doc, probably incorrect
      # options.yarn_site['yarn.nodemanager.container-executor.cgroups.hierarchy'] ?= options.yarn_site['yarn.nodemanager.linux-container-executor.cgroups.hierarchy']
      # options.yarn_site['yarn.nodemanager.container-executor.cgroups.mount'] ?= options.yarn_site['yarn.nodemanager.linux-container-executor.cgroups.mount']
      # options.yarn_site['yarn.nodemanager.container-executor.resources-handler.class'] ?= options.yarn_site['yarn.nodemanager.container-executor.resources-handler.class']
      # options.yarn_site['yarn.nodemanager.container-executor.group'] ?= 'hadoop'
      if options.yarn_site['yarn.nodemanager.linux-container-executor.cgroups.mount'] is 'false'
        # default values
        options.cgroup ?=
          "#{options.user.name}":
            perm:
              task:
                'uid': "#{options.user.name}"
                'gid': "#{options.user.name}"
              admin:
                'uid': "#{options.user.name}"
                'gid': "#{options.user.name}"
            cpu:
              'cpu.rt_period_us': "\"1000000\""
              'cpu.rt_runtime_us': "\"0\""
              'cpu.cfs_period_us': "\"100000\""
              'cpu.cfs_quota_us': "\"-1\""
              'cpu.shares': '\"1024\"'

## SSL

      options.ssl = merge {}, service.deps.hadoop_core.options.ssl, options.ssl
      options.ssl_server = merge {}, service.deps.hadoop_core.options.ssl_server, options.ssl_server or {},
        'ssl.server.keystore.location': "#{options.conf_dir}/keystore"
        'ssl.server.truststore.location': "#{options.conf_dir}/truststore"
      options.ssl_client = merge {}, service.deps.hadoop_core.options.ssl_client, options.ssl_client or {},
        'ssl.client.truststore.location': "#{options.conf_dir}/truststore"

## Metrics

      options.metrics = merge {}, service.deps.metrics?.options, options.metrics

      options.metrics.config ?= {}
      options.metrics.sinks ?= {}
      options.metrics.sinks.file_enabled ?= true
      options.metrics.sinks.ganglia_enabled ?= false
      options.metrics.sinks.graphite_enabled ?= false
      # File sink
      if options.metrics.sinks.file_enabled
        options.metrics.config["*.sink.file.#{k}"] ?= v for k, v of service.deps.metrics.options.sinks.file.config if service.deps.metrics?.options?.sinks?.file_enabled
        options.metrics.config['maptask.sink.file.class'] ?= 'org.apache.hadoop.metrics2.sink.FileSink'
        options.metrics.config['maptask.sink.file.filename'] ?= 'maptask-metrics.out'
        options.metrics.config['nodemanager.sink.file.class'] ?= 'org.apache.hadoop.metrics2.sink.FileSink'
        options.metrics.config['nodemanager.sink.file.filename'] ?= 'nodemanager-metrics.out'
        options.metrics.config['reducetask.sink.file.class'] ?= 'org.apache.hadoop.metrics2.sink.FileSink'
        options.metrics.config['reducetask.sink.file.filename'] ?= 'reducetask-metrics.out'
      # Ganglia sink, accepted properties are "servers" and "supportsparse"
      if options.metrics.sinks.ganglia_enabled
        options.metrics.config['nodemanager.sink.ganglia.class'] ?= options.metrics.ganglia.class
        options.metrics.config['nodemanager.sink.ganglia.servers'] ?= "#{service.deps.ganglia.node.fqdn}:#{service.deps.ganglia.options.nn_port}"
        options.metrics.config['maptask.sink.ganglia.class'] ?= options.metrics.ganglia.class
        options.metrics.config['maptask.sink.ganglia.servers'] ?= "#{service.deps.ganglia.node.fqdn}:#{service.deps.ganglia.options.nn_port}"
        options.metrics.config['reducetask.sink.ganglia.class'] ?= options.metrics.ganglia.class
        options.metrics.config['reducetask.sink.ganglia.servers'] ?= "#{service.deps.ganglia.node.fqdn}:#{service.deps.ganglia.options.nn_port}"
        options.metrics.config["*.sink.ganglia.#{k}"] ?= v for k, v of options.sinks.ganglia.config if service.deps.metrics?.options?.sinks?.ganglia_enabled
      # Graphite Sink
      if options.metrics.sinks.graphite_enabled
        throw Error 'Missing remote_host ryba.yarn.nm.metrics.sinks.graphite.config.server_host' unless options.metrics.sinks.graphite.config.server_host?
        throw Error 'Missing remote_port ryba.yarn.nm.metrics.sinks.graphite.config.server_port' unless options.metrics.sinks.graphite.config.server_port?
        options.metrics.config["nodemanager.sink.graphite.class"] ?= 'org.apache.hadoop.metrics2.sink.GraphiteSink'
        options.metrics.config["maptask.sink.graphite.class"] ?= 'org.apache.hadoop.metrics2.sink.GraphiteSink'
        options.metrics.config["reducetask.sink.graphite.class"] ?= 'org.apache.hadoop.metrics2.sink.GraphiteSink'
        options.metrics.config["*.sink.graphite.#{k}"] ?= v for k, v of service.deps.metrics.options.sinks.graphite.config if service.deps.metrics?.options?.sinks?.graphite_enabled

## List of Services

      options.yarn_site['yarn.nodemanager.aux-services'] ?= 'mapreduce_shuffle'
      options.yarn_site['yarn.nodemanager.aux-services.mapreduce_shuffle.class'] ?= 'org.apache.hadoop.mapred.ShuffleHandler'

## Wait

      # Import Rules
      options.wait_krb5_client = service.deps.krb5_client.options.wait
      options.wait_zookeeper_server = service.deps.zookeeper_server[0].options.wait
      options.wait_hdfs_nn = service.deps.hdfs_nn[0].options.wait
      # Default configuration required by wait
      for srv in service.deps.yarn_nm
        srv.options.yarn_site ?= {}
        srv.options.yarn_site['yarn.nodemanager.address'] ?= "#{srv.node.fqdn}:45454"
        srv.options.yarn_site['yarn.nodemanager.localizer.address'] ?= "#{srv.node.fqdn}:8040"
        srv.options.yarn_site['yarn.nodemanager.webapp.address'] ?= "#{srv.node.fqdn}:8042"
        srv.options.yarn_site['yarn.nodemanager.webapp.https.address'] ?= "#{srv.node.fqdn}:8044"
      # Local Rules
      options.wait = {}
      options.wait.tcp = for srv in service.deps.yarn_nm
        port = srv.options.yarn_site['yarn.nodemanager.address'].split(':')[1]
        host: srv.node.fqdn, port: port
      options.wait.tcp_localiser = for srv in service.deps.yarn_nm
        port = srv.options.yarn_site['yarn.nodemanager.localizer.address'].split(':')[1]
        host: srv.node.fqdn, port: port
      options.wait.webapp = for srv in service.deps.yarn_nm
        protocol = if options.yarn_site['yarn.http.policy'] is 'HTTP_ONLY' then '' else 'https.'
        port = srv.options.yarn_site["yarn.nodemanager.webapp.#{protocol}address"].split(':')[1]
        host: srv.node.fqdn, port: port
      options.wait.tcp_local =
        host: options.yarn_site['yarn.nodemanager.address'].split(':')[0]
        port: options.yarn_site['yarn.nodemanager.address'].split(':')[1]
      options.wait.tcp_local_localiser =
        host: options.yarn_site['yarn.nodemanager.localizer.address'].split(':')[0]
        port: options.yarn_site['yarn.nodemanager.localizer.address'].split(':')[1]
      protocol = if options.yarn_site['yarn.http.policy'] is 'HTTP_ONLY' then '' else 'https.'
      options.wait.webapp_local =
        port: options.yarn_site["yarn.nodemanager.webapp.#{protocol}address"].split(':')[1]
        host: options.yarn_site["yarn.nodemanager.webapp.#{protocol}address"].split(':')[0]
      
        

## Dependencies

    {merge} = require 'nikita/lib/misc'

[yarn-cgroup-red7]: https://issues.apache.org/jira/browse/YARN-2194
[container]: http://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/SecureContainer.html

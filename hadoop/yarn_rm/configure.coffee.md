
## Configuration

```json
{ "ryba": { "yarn": { "rm": {
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
      options.home ?= '/usr/hdp/current/hadoop-yarn-client'
      options.log_dir ?= '/var/log/hadoop/yarn'
      options.pid_dir ?= '/var/run/hadoop/yarn'
      options.conf_dir ?= '/etc/hadoop-yarn-resourcemanager/conf'
      # Java
      options.java_home ?= service.deps.java.options.java_home
      options.heapsize ?= '1024m'
      options.newsize ?= '200m'
      # Misc
      options.fqdn = service.node.fqdn
      options.hostname = service.node.hostname
      options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'
      options.clean_logs ?= false
      options.hdfs_krb5_user = service.deps.hadoop_core.options.hdfs.krb5_user
      options.nn_url = service.deps.hdfs_client[0].options.nn_url

## System Options

      options.opts ?= {}
      options.opts.base ?= ''
      options.opts.java_properties ?= {}
      options.opts.jvm ?= {}
      options.opts.jvm['-Xms'] ?= options.heapsize
      options.opts.jvm['-Xmx'] ?= options.heapsize
      options.opts.jvm['-XX:NewSize='] ?= options.newsize #should be 1/8 of heapsize
      options.opts.jvm['-XX:MaxNewSize='] ?= options.newsize #should be 1/8 of heapsize

## Configuration

      # Hadoop core "core-site.xml"
      options.core_site = merge {}, service.deps.hdfs_client[0].options.core_site, options.core_site or {}
      # HDFS client "hdfs-site.xml"
      options.hdfs_site = merge {}, service.deps.hdfs_client[0].options.hdfs_site, options.hdfs_site or {}
      # Yarn NodeManager "yarn-site.xml"
      options.yarn_site ?= {}
      # Configuration
      options.yarn_site['yarn.http.policy'] ?= 'HTTPS_ONLY' # HTTP_ONLY or HTTPS_ONLY or HTTP_AND_HTTPS
      options.yarn_site['yarn.resourcemanager.ha.id'] ?= service.node.hostname
      options.yarn_site['yarn.resourcemanager.nodes.include-path'] ?= "#{options.conf_dir}/yarn.include"
      options.yarn_site['yarn.resourcemanager.nodes.exclude-path'] ?= "#{options.conf_dir}/yarn.exclude"
      options.yarn_site['yarn.resourcemanager.keytab'] ?= '/etc/security/keytabs/rm.service.keytab'
      options.yarn_site['yarn.resourcemanager.principal'] ?= "rm/_HOST@#{options.krb5.realm}"
      options.yarn_site['yarn.resourcemanager.scheduler.class'] ?= 'org.apache.hadoop.yarn.server.resourcemanager.scheduler.capacity.CapacityScheduler'

## Yarn TimeLineService Layout

      if service.deps.yarn_tr?.length > 0
        options.yarn_hbase_embedded ?= service.deps.yarn_tr[0].options.yarn_hbase_embedded

## Configuration for Memory and CPU

hadoop jar /usr/lib/hadoop-mapreduce/hadoop-mapreduce-examples.jar pi -Dmapreduce.map.cpu.vcores=32 1 1

The value for the yarn.scheduler.maximum-allocation-vcores should not be larger
than the value for the yarn.nodemanager.resource.cpu-vcores parameter on any
NodeManager. Document states that resource requests are capped at the maximum
allocation limit and a container is eventually granted. Tests in version 2.4
instead shows that the containers are never granted, and no progress is made by
the application (zombie state).

      options.yarn_site['yarn.scheduler.minimum-allocation-mb'] ?= '256'
      options.yarn_site['yarn.scheduler.maximum-allocation-mb'] ?= '2048'
      options.yarn_site['yarn.scheduler.minimum-allocation-vcores'] ?= 1
      options.yarn_site['yarn.scheduler.maximum-allocation-vcores'] ?= 32

## Zookeeper

The Zookeeper quorum is used for HA and recovery. High availability
with automatic failover stores information inside "yarn.resourcemanager.ha.automatic-failover.zk-base-path"
(default to "/yarn-leader-election"). Work preserving recovery stores
information inside "yarn.resourcemanager.zk-state-store.parent-path" (default to
"/rmstore").

      options.yarn_site['yarn.resourcemanager.zk-address'] ?= service.deps.zookeeper_server
      .filter (srv) -> srv.options.config['peerType'] is 'participant'
      .map (srv) -> "#{srv.node.fqdn}:#{srv.options.config['clientPort']}"
      .join ','

Enable JAAS/Kerberos connection between YARN RM and ZooKeeper.

      options.opts.java_properties['java.security.auth.login.config'] ?= "#{options.conf_dir}/yarn-rm.jaas"

## High Availability with Manual Failover

Cloudera [High Availability Guide][cloudera_ha] provides a nice documentation
about each configuration and where they should apply.

Unless specified otherwise, the active ResourceManager is the first one defined
inside the configuration.

      if service.instances.length is 1
        options.yarn_site['yarn.resourcemanager.ha.enabled'] = 'false'
      else if service.instances.length is 2
        options.yarn_site['yarn.resourcemanager.ha.enabled'] = 'true'
        options.yarn_site['yarn.resourcemanager.cluster-id'] ?= 'yarn_cluster_01'
        options.yarn_site['yarn.resourcemanager.ha.rm-ids'] ?= service.instances.map( (instance) -> instance.node.hostname ).join ','
        # Flag to enable override of the default kerberos authentication
        # filter with the RM authentication filter to allow authentication using
        # delegation tokens(fallback to kerberos if the tokens are missing)
        options.yarn_site["yarn.resourcemanager.webapp.delegation-token-auth-filter.enabled"] ?= "true" # YARN default is "true"
      else
        throw Error "Invalid Number Of ResourceManager"
      for srv in service.deps.yarn_rm
        # srv.config.ryba.yarn ?= {}
        # srv.config.ryba.yarn.rm ?= {}
        srv.options.yarn_site ?= {}
        srv.options.yarn_site['yarn.resourcemanager.ha.id'] ?= srv.node.hostname
        id = if options.yarn_site['yarn.resourcemanager.ha.enabled'] is 'true' then ".#{srv.options.yarn_site['yarn.resourcemanager.ha.id']}" else ''
        options.yarn_site["yarn.resourcemanager.address#{id}"] ?= "#{srv.node.fqdn}:8050"
        options.yarn_site["yarn.resourcemanager.scheduler.address#{id}"] ?= "#{srv.node.fqdn}:8030"
        options.yarn_site["yarn.resourcemanager.admin.address#{id}"] ?= "#{srv.node.fqdn}:8141"
        options.yarn_site["yarn.resourcemanager.webapp.address#{id}"] ?= "#{srv.node.fqdn}:8088"
        options.yarn_site["yarn.resourcemanager.webapp.https.address#{id}"] ?= "#{srv.node.fqdn}:8090"
        options.yarn_site["yarn.resourcemanager.resource-tracker.address#{id}"] ?= "#{srv.node.fqdn}:8025"

## High Availability with optional automatic failover

      options.yarn_site['yarn.resourcemanager.ha.automatic-failover.enabled'] ?= 'true'
      options.yarn_site['yarn.resourcemanager.ha.automatic-failover.embedded'] ?= 'true'
      options.yarn_site['yarn.resourcemanager.ha.automatic-failover.zk-base-path'] ?= '/yarn-leader-election'

## Logs Aggregation

      options.yarn_site['yarn.nodemanager.remote-app-log-dir'] ?= '/app-logs'
      options.yarn_site['yarn.nodemanager.remote-app-log-dir-suffix'] ?= 'logs'
      options.yarn_site['yarn.log-aggregation-enable'] ?= 'true'
      options.yarn_site['yarn.log-aggregation.retain-seconds'] ?= '2592000' #  30 days, how long to keep aggregation logs before deleting them. -1 disables. Be careful, set this too small and you will spam the name node.
      options.yarn_site['yarn.log-aggregation.retain-check-interval-seconds'] ?= '-1' # Time between checks for aggregated log retention. If set to 0 or a negative value then the value is computed as one-tenth of the aggregated log retention time. Be careful, set this too small and you will spam the name node.
      options.yarn_site['yarn.generic-application-history.save-non-am-container-meta-info'] ?= 'true'

## MapReduce JobHistory Server

      if service.deps.mapred_jhs
        options.yarn_site['mapreduce.jobhistory.principal'] ?= service.deps.mapred_jhs.options.mapred_site['mapreduce.jobhistory.principal']
        options.yarn_site['yarn.resourcemanager.bind-host'] ?= '0.0.0.0'
        # TODO: detect https and port, see "../mapred_jhs/check"
        jhs_protocol = if service.deps.mapred_jhs.options.mapred_site['mapreduce.jobhistory.address'] is 'HTTP_ONLY' then 'http' else 'https'
        jhs_protocol_key = if jhs_protocol is 'http' then '' else '.https'
        jhs_address = service.deps.mapred_jhs.options.mapred_site["mapreduce.jobhistory.webapp#{jhs_protocol_key}.address"]
        options.yarn_site['yarn.log.server.url'] ?= "#{jhs_protocol}://#{jhs_address}/jobhistory/logs/"

## Preemption

Preemption is enabled by default. With Preemption, under-served queues can begin
to claim their allocated cluster resources almost immediately, without having to
wait for other queues' applications to finish running. Containers are only
killed as a last resort.

      # Enables preemption
      options.yarn_site['yarn.resourcemanager.scheduler.monitor.enable'] ?= 'true'
      # List of SchedulingEditPolicy classes that interact with the scheduler.
      options.yarn_site['yarn.resourcemanager.scheduler.monitor.policies'] ?= 'org.apache.hadoop.yarn.server.resourcemanager.monitor.capacity.ProportionalCapacityPreemptionPolicy'
      # The time in milliseconds between invocations of this policy.
      options.yarn_site['yarn.resourcemanager.monitor.capacity.preemption.monitoring_interval'] ?= '3000'
      # The time in milliseconds between requesting a preemption from an application and killing the container.
      options.yarn_site['yarn.resourcemanager.monitor.capacity.preemption.max_wait_before_kill'] ?= '15000'
      # The maximum percentage of resources preempted in a single round.
      options.yarn_site['yarn.resourcemanager.monitor.capacity.preemption.total_preemption_per_round'] ?= '0.1'

## [Work Preserving Recovery][restart]

Work Preserving Recovery is a feature that enhances ResourceManager to
keep functioning across restarts and also makes ResourceManager down-time
invisible to end-users.

[Phase1][YARN-556-pdf] covered by [YARN-128] allowed YARN to continue to
function across RM restarts in a user transparent manner. [Phase2][YARN-556-pdf]
covered by [YARN-556] refresh the dynamic container state of the cluster from
the node managers (NMs) after RM restart such as restarting AM’s and killing
containers is not required.

Restart Recovery apply separately to both the ResourceManager and NodeManager.
The functionnality is supported by [Cloudera][cloudera_wp] and [Hortonworks][hdp_wp].

HDP companion files enable by default the recovery mode. Its implementation
default to the ZooKeeper based state-store implementation. Unless specified,
the root znode where the ResourceManager state is stored is inside "/rmstore".

ZooKeeper is used in the context of restart recovering and high availability.

About the 'root-node.acl', the [mailing list][ml_root_acl] mentions: For the
exclusive create-delete access, the RMs use username:password where the username
is yarn.resourcemanager.address and the password is a secure random number. One
should use that config only when they are not happy with this implicit default
mechanism.

Here's an example:

```
RM1: yarncluster:shared-password:rwa,rm1:secret-password:cd
RM2: yarncluster:shared-password:rwa,rm2:secret-password:cd
```

To remove the entry (not tested) when transitioning from HA to normal mode:

```
/usr/lib/zookeeper/bin/zkCli.sh -server master2.ryba:2181
setAcl /rmstore/ZKRMStateRoot world:anyone:rwacd
rmr /rmstore/ZKRMStateRoot
```

      options.yarn_site['yarn.resourcemanager.recovery.enabled'] ?= 'true'
      options.yarn_site['yarn.resourcemanager.work-preserving-recovery.enabled'] ?= 'true'
      options.yarn_site['yarn.resourcemanager.am.max-attempts'] ?= '2'
      options.yarn_site['yarn.resourcemanager.store.class'] ?= 'org.apache.hadoop.yarn.server.resourcemanager.recovery.ZKRMStateStore'
      # https://zookeeper.apache.org/doc/r3.1.2/zookeeperProgrammers.html#sc_ZooKeeperAccessControl
      # ACLs to be used for setting permissions on ZooKeeper znodes.
      options.yarn_site['yarn.resourcemanager.zk-acl'] ?= 'sasl:rm:rwcda'
      # About 'yarn.resourcemanager.zk-state-store.root-node.acl'
      # See http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/cdh_hag_rm_ha_config.html
      # The ACLs used for the root node of the ZooKeeper state store. The ACLs
      # set here should allow both ResourceManagers to read, write, and
      # administer, with exclusive access to create and delete. If nothing is
      # specified, the root node ACLs are automatically generated on the basis
      # of the ACLs specified through yarn.resourcemanager.zk-acl. But that
      # leaves a security hole in a secure setup. To configure automatic failover:
      options.yarn_site['yarn.resourcemanager.zk-state-store.parent-path'] ?= '/rmstore'
      options.yarn_site['yarn.resourcemanager.zk-num-retries'] ?= '500'
      options.yarn_site['yarn.resourcemanager.zk-retry-interval-ms'] ?= '2000'
      options.yarn_site['yarn.resourcemanager.zk-timeout-ms'] ?= '10000'

## Capacity Scheduler

      # TODO Capacity Scheduler node_labels http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.3.2/bk_yarn_resource_mgt/content/configuring_node_labels.html
      options.capacity_scheduler ?= {}
      options.capacity_scheduler['yarn.scheduler.capacity.default.minimum-user-limit-percent'] ?= '100'
      options.capacity_scheduler['yarn.scheduler.capacity.maximum-am-resource-percent'] ?= '0.2'
      options.capacity_scheduler['yarn.scheduler.capacity.maximum-applications'] ?= '10000'
      options.capacity_scheduler['yarn.scheduler.capacity.node-locality-delay'] ?= '40'
      options.capacity_scheduler['yarn.scheduler.capacity.resource-calculator'] ?= 'org.apache.hadoop.yarn.util.resource.DominantResourceCalculator'
      options.capacity_scheduler['yarn.scheduler.capacity.root.accessible-node-labels'] ?= null
      options.capacity_scheduler['yarn.scheduler.capacity.root.accessible-node-labels.default.capacity'] ?= null # was 100
      options.capacity_scheduler['yarn.scheduler.capacity.root.accessible-node-labels.default.maximum-capacity'] ?= null # was 100
      options.capacity_scheduler['yarn.scheduler.capacity.root.acl_administer_queue'] ?= '*'
      # options.capacity_scheduler['yarn.scheduler.capacity.root.capacity'] ?= '100'
      options.capacity_scheduler['yarn.scheduler.capacity.root.default-node-label-expression'] ?= ' '
      options.capacity_scheduler['yarn.scheduler.capacity.root.default.acl_administer_jobs'] ?= '*'
      options.capacity_scheduler['yarn.scheduler.capacity.root.default.acl_submit_applications'] ?= '*'
      options.capacity_scheduler['yarn.scheduler.capacity.root.default.capacity'] ?= '100'
      options.capacity_scheduler['yarn.scheduler.capacity.root.default.maximum-capacity'] ?= '100'
      options.capacity_scheduler['yarn.scheduler.capacity.root.default.state'] ?= 'RUNNING'
      options.capacity_scheduler['yarn.scheduler.capacity.root.default.user-limit-factor'] ?= '1'
      # Defines root's child queue named 'default'
      options.capacity_scheduler['yarn.scheduler.capacity.root.queues'] ?= 'default'
      options.capacity_scheduler['yarn.scheduler.capacity.queue-mappings'] ?= '' # Introduce by hadoop 2.7
      options.capacity_scheduler['yarn.scheduler.capacity.queue-mappings-override.enable'] ?= 'false' # Introduce by hadoop 2.7

## Node Labels

      options.yarn_site['yarn.node-labels.enabled'] ?= 'true'
      options.yarn_site['yarn.node-labels.fs-store.root-dir'] ?= "#{options.core_site['fs.defaultFS']}/apps/yarn/node-labels"

## Admin Web UI

      #Current YARN web UI allows anyone to kill any application as long as the user can login to the web UI.
      options.yarn_site['yarn.resourcemanager.webapp.ui-actions.enabled'] ?= 'false'

## HDP3 features
enable yarn ui 2 (apache YARN 3 feature). availabe at https://master01.metal.ryba:8090/ui2/

      options.yarn_site['yarn.webapp.ui2.enable'] ?= 'true'
      options.yarn_site['yarn.resourcemanager.placement-constraints.handler'] ?= 'scheduler'
      #yarn.webapp.ui2.war-file-path is not needed as HDP3 has build yarn with the ui

enable yarn api service
      
      options.yarn_site['yarn.webapp.api-service.enable'] ?= 'true'

## ProxyUser

      options.core_site["hadoop.proxyuser.#{options.user.name}.groups"] ?= '*'
      options.core_site["hadoop.proxyuser.#{options.user.name}.hosts"] ?= '*'
      for srv in [service.deps.hdfs_client..., service.deps.hdfs_nn...]
        srv.options.core_site ?= {}
        srv.options.core_site["hadoop.proxyuser.#{options.user.name}.groups"] ?= '*'
        srv.options.core_site["hadoop.proxyuser.#{options.user.name}.hosts"] ?= '*'

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
        options.metrics.config['resourcemanager.sink.file.class'] ?= 'org.apache.hadoop.metrics2.sink.FileSink'
        options.metrics.config['resourcemanager.sink.file.filename'] ?= 'resourcemanager-metrics.out'
      # Ganglia sink, accepted properties are "servers" and "supportsparse"
      if options.metrics.sinks.ganglia_enabled
        options.metrics.config['resourcemanager.sink.ganglia.class'] ?= options.metrics.ganglia.class
        options.metrics.config['resourcemanager.sink.ganglia.servers'] ?= "#{service.deps.ganglia.node.fqdn}:#{service.deps.ganglia.options.nn_port}"
        options.metrics.config["*.sink.ganglia.#{k}"] ?= v for k, v of options.sinks.ganglia.config if service.deps.metrics?.options?.sinks?.ganglia_enabled
      # Graphite Sink
      if options.metrics.sinks.graphite_enabled
        throw Error 'Missing remote_host ryba.yarn.rm.metrics.sinks.graphite.config.server_host' unless options.metrics.sinks.graphite.config.server_host?
        throw Error 'Missing remote_port ryba.yarn.rm.metrics.sinks.graphite.config.server_port' unless options.metrics.sinks.graphite.config.server_port?
        options.metrics.config["resourcemanager.sink.graphite.class"] ?= 'org.apache.hadoop.metrics2.sink.GraphiteSink'
        options.metrics.config["*.sink.graphite.#{k}"] ?= v for k, v of service.deps.metrics.options.sinks.graphite.config if service.deps.metrics?.options?.sinks?.graphite_enabled

## Configuration for Log4J

      options.log4j = merge {}, service.deps.log4j?.options, options.log4j
      options.log4j.root_logger ?= 'INFO,EWMA,RFA'
      options.opts.java_properties['yarn.server.resourcemanager.appsummary.logger'] = 'INFO,RMSUMMARY'
      options.opts.java_properties['yarn.server.resourcemanager.audit.logger'] = 'INFO,RMAUDIT'
      # adding SOCKET appender
      if options.log4j.remote_host? and options.log4j.remote_port?
        options.log4j.socket_client ?= "SOCKET"
        # Root logger
        if options.log4j.root_logger.indexOf(options.log4j.socket_client) is -1
        then options.log4j.root_logger += ",#{options.log4j.socket_client}"
        # Security Logger
        if options.opts.java_properties['yarn.server.resourcemanager.appsummary.logger'].indexOf(options.log4j.socket_client) is -1
        then options.opts.java_properties['yarn.server.resourcemanager.appsummary.logger'] += ",#{options.log4j.socket_client}"
        # Audit Logger
        if options.opts.java_properties['yarn.server.resourcemanager.audit.logger'].indexOf(options.log4j.socket_client) is -1
        then options.opts.java_properties['yarn.server.resourcemanager.audit.logger'] += ",#{options.log4j.socket_client}"

        options.opts.java_properties['hadoop.log.application'] = 'resourcemanager'
        options.opts.java_properties['hadoop.log.remote_host'] = options.log4j.remote_host
        options.opts.java_properties['hadoop.log.remote_port'] = options.log4j.remote_port

        options.log4j.socket_opts ?=
          Application: '${hadoop.log.application}'
          RemoteHost: '${hadoop.log.remote_host}'
          Port: '${hadoop.log.remote_port}'
          ReconnectionDelay: '10000'

        options.log4j.properties = merge options.log4j.properties, appender
          type: 'org.apache.log4j.net.SocketAppender'
          name: options.log4j.socket_client
          logj4: options.log4j.properties
          properties: options.log4j.socket_opts

## Run docker container on YARN
With YARN 3.1.0, docker container can be launched by nodemanager.
      
      # options.yarn_site['module.enabled'] ?= 'true'
      # options.yarn_site['docker.binary'] ?= '/usr/bin/docker'
      # options.yarn_site['docker.allowed.capabilities'] ?= ''
      # options.yarn_site['docker.allowed.devices'] ?= ''
      # options.yarn_site['docker.allowed.networks'] ?= 'host,default'
      # options.yarn_site['docker.allowed.ro-mounts'] ?= '/sys/fs/cgroup'
      # options.yarn_site['docker.allowed.rw-mounts'] ?= '/sys/fs/cgroup,/data/1/yarn/local,/data/2/yarn/local,/data/1/yarn/log,/data/2/yarn/log'
      # options.yarn_site['docker.host-pid-namespace.enabled'] ?= 'false'
      # options.yarn_site['docker.privileged-containers.enabled'] ?= 'false'
      # options.yarn_site['docker.privileged-containers.registries'] ?= 'bakalian.ryba:5000,bakalian.ryba'


## Export to Mapreduce HistoryServer
      
      id = if options.yarn_site['yarn.resourcemanager.ha.enabled'] is 'true' then ".#{options.yarn_site['yarn.resourcemanager.ha.id']}" else ''
      for property in [
        'yarn.http.policy'
        'yarn.log.server.url'
        'yarn.resourcemanager.principal'
        'yarn.resourcemanager.cluster-id'
        'yarn.nodemanager.remote-app-log-dir'
        'yarn.nodemanager.remote-app-log-dir-suffix'
        'yarn.log-aggregation-enable'
        'yarn.log-aggregation.retain-seconds'
        'yarn.log-aggregation.retain-check-interval-seconds'
        'yarn.generic-application-history.save-non-am-container-meta-info'
        'yarn.resourcemanager.ha.enabled'
        'yarn.resourcemanager.ha.rm-ids'
        'yarn.resourcemanager.webapp.delegation-token-auth-filter.enabled'
        "yarn.resourcemanager.address#{id}"
        "yarn.resourcemanager.scheduler.address#{id}"
        "yarn.resourcemanager.admin.address#{id}"
        "yarn.resourcemanager.webapp.address#{id}"
        "yarn.resourcemanager.webapp.https.address#{id}"
        "yarn.resourcemanager.resource-tracker.address#{id}"
      ]
        service.deps.mapred_jhs.options.yarn_site[property] ?= options.yarn_site[property]

## Wait

      options.wait_krb5_client = service.deps.krb5_client.options.wait
      options.wait_zookeeper_server = service.deps.zookeeper_server[0].options.wait
      options.wait_hdfs_dn = service.deps.hdfs_dn[0].options.wait
      options.wait_mapred_jhs = service.deps.mapred_jhs.options.wait
      options.wait = {}
      options.wait.tcp = for srv in service.deps.yarn_rm
        [fqdn, port] = unless options.yarn_site['yarn.resourcemanager.ha.enabled'] is 'true'
        then srv.options.yarn_site["yarn.resourcemanager.address#{id}"].split(':')
        else
          id = ".#{srv.options.yarn_site['yarn.resourcemanager.ha.id'] or srv.node.fqdn}"
          srv.options.yarn_site["yarn.resourcemanager.address#{id}"] ?= "#{srv.node.fqdn}:8050"
          srv.options.yarn_site["yarn.resourcemanager.address#{id}"].split(':')
        host: fqdn, port: port
      options.wait.admin = for srv in service.deps.yarn_rm
        [fqdn, port] = unless options.yarn_site['yarn.resourcemanager.ha.enabled'] is 'true'
        then srv.options.yarn_site["yarn.resourcemanager.admin.address#{id}"].split(':')
        else
          id = ".#{srv.options.yarn_site['yarn.resourcemanager.ha.id'] or srv.node.fqdn}"
          srv.options.yarn_site["yarn.resourcemanager.admin.address#{id}"] ?= "#{srv.node.fqdn}:8141"
          srv.options.yarn_site["yarn.resourcemanager.admin.address#{id}"].split(':')
        host: fqdn, port: port
      options.wait.webapp = for srv in service.deps.yarn_rm
        protocol = if options.yarn_site['yarn.http.policy'] is 'HTTP_ONLY' then '' else '.https'
        default_http_port = if protocol is '' then '8088' else '8090'
        [fqdn, port] = unless options.yarn_site['yarn.resourcemanager.ha.enabled'] is 'true'
        then srv.options.yarn_site["yarn.resourcemanager.webapp#{protocol}.address#{id}"].split(':')
        else
          id = ".#{srv.options.yarn_site['yarn.resourcemanager.ha.id'] or srv.node.fqdn}"
          srv.options.yarn_site["yarn.resourcemanager.webapp#{protocol}.address#{id}"] ?= "#{srv.node.fqdn}:#{default_http_port}"
          srv.options.yarn_site["yarn.resourcemanager.webapp#{protocol}.address#{id}"].split(':')
        host: fqdn, port: port

## Dependencies

    appender = require '../../lib/appender'
    {merge} = require 'nikita/lib/misc'

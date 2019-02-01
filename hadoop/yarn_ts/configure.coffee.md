
# Hadoop YARN Timeline Server Configure

```json
{ "ryba": { "yarn": { "ats": {
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
      options.ats_user = service.deps.hadoop_core.options.ats.user
      options.ats_group = service.deps.hadoop_core.options.ats.group

## Kerberos

      options.krb5 ?= {}
      options.krb5.realm ?= service.deps.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      throw Error 'Required Options: "realm"' unless options.krb5.realm
      options.krb5.admin ?= service.deps.krb5_client.options.admin[options.krb5.realm]
      
## Environment

      # Layout
      options.home ?= '/usr/hdp/current/hadoop-yarn-timelineserver'
      options.log_dir ?= '/var/log/hadoop/yarn'
      options.pid_dir ?= '/var/run/hadoop/yarn'
      options.conf_dir ?= '/etc/hadoop-yarn-timelineserver/conf'
      # Java
      options.java_home ?= service.deps.java.options.java_home
      options.heapsize ?= '1024m'
      options.newsize ?= '200m'
      # Misc
      options.fqdn = service.node.fqdn
      options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'
      options.hdfs_krb5_user = service.deps.hadoop_core.options.hdfs.krb5_user

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
      # Yarn ATS "yarn-site.xml"
      options.yarn_site ?= {}
      # The hostname of the Timeline service web application.
      options.yarn_site['yarn.timeline-service.hostname'] ?= service.node.fqdn
      options.yarn_site['yarn.http.policy'] ?= 'HTTPS_ONLY' # HTTP_ONLY or HTTPS_ONLY or HTTP_AND_HTTPS
      # Advanced Configuration
      options.yarn_site['yarn.timeline-service.address'] ?= "#{service.node.fqdn}:10200"
      options.yarn_site['yarn.timeline-service.webapp.address'] ?= "#{service.node.fqdn}:8188"
      options.yarn_site['yarn.timeline-service.webapp.https.address'] ?= "#{service.node.fqdn}:8190"
      options.yarn_site['yarn.timeline-service.handler-thread-count'] ?= "100" # HDP default is "10"
      options.yarn_site['yarn.timeline-service.http-cross-origin.enabled'] ?= "true"
      options.yarn_site['yarn.timeline-service.http-cross-origin.allowed-origins'] ?= "*"
      options.yarn_site['yarn.timeline-service.http-cross-origin.allowed-methods'] ?= "GET,POST,HEAD"
      options.yarn_site['yarn.timeline-service.http-cross-origin.allowed-headers'] ?= "X-Requested-With,Content-Type,Accept,Origin"
      options.yarn_site['yarn.timeline-service.http-cross-origin.max-age'] ?= "1800"
      # Generic-data related Configuration
      # Yarn doc: yarn.timeline-service.generic-application-history.enabled = false
      options.yarn_site['yarn.timeline-service.generic-application-history.enabled'] ?= 'true'
      options.yarn_site['yarn.timeline-service.generic-application-history.save-non-am-container-meta-info'] ?= 'true'
      options.yarn_site['yarn.timeline-service.generic-application-history.store-class'] ?= "org.apache.hadoop.yarn.server.applicationhistoryservice.FileSystemApplicationHistoryStore"
      options.yarn_site['yarn.timeline-service.fs-history-store.uri'] ?= '/apps/ats' # Not documented, default to "$(hadoop.tmp.dir)/yarn/timeline/generic-history""
      # Enabling Generic Data Collection (HDP specific)
      options.yarn_site['yarn.resourcemanager.system-metrics-publisher.enabled'] ?= "true"
      # Per-framework-date related Configuration
      # Indicates to clients whether or not the Timeline Server is enabled. If
      # it is enabled, the TimelineClient library used by end-users will post
      # entities and events to the Timeline Server.
      options.yarn_site['yarn.timeline-service.enabled'] ?= "true"
      # Timeline Server Store
      options.yarn_site['yarn.timeline-service.store-class'] ?= "org.apache.hadoop.yarn.server.timeline.LeveldbTimelineStore"
      options.yarn_site['yarn.timeline-service.leveldb-timeline-store.path'] ?= "/var/yarn/timeline"
      options.yarn_site['yarn.timeline-service.ttl-enable'] ?= "true"
      options.yarn_site['yarn.timeline-service.ttl-ms'] ?= "#{604800000 * 2}" # 14 days, HDP default is "604800000"
      # Kerberos Authentication
      options.yarn_site['yarn.timeline-service.principal'] ?= "ats/_HOST@#{options.krb5.realm}"
      options.yarn_site['yarn.timeline-service.keytab'] ?= '/etc/security/keytabs/ats.service.keytab'
      options.yarn_site['yarn.timeline-service.http-authentication.type'] ?= "kerberos"
      options.yarn_site['yarn.timeline-service.http-authentication.kerberos.principal'] ?= "HTTP/_HOST@#{options.krb5.realm}"
      options.yarn_site['yarn.timeline-service.http-authentication.kerberos.keytab'] ?= options.core_site['hadoop.http.authentication.kerberos.keytab']
      # Timeline Server Authorization (ACLs)
      options.yarn_site['yarn.acl.enable'] ?= "true"
      # options.yarn_site['yarn.admin.acl'] ?= "#{options.user.name}"
       # List of users separated by commas
      # SSL, must be added to "core-site.xml"
      # options.yarn_site['hadoop.ssl.require.client.cert'] ?= "false"
      # options.yarn_site['hadoop.ssl.hostname.verifier'] ?= "DEFAULT"
      # options.yarn_site['hadoop.ssl.keystores.factory.class'] ?= "org.apache.hadoop.security.ssl.FileBasedKeyStoresFactory"
      # options.yarn_site['hadoop.ssl.server.conf'] ?= "ssl-server.xml"
      # options.yarn_site['hadoop.ssl.client.conf'] ?= "ssl-client.xml"

## YARN ATS 1.5

      options.yarn_site['yarn.timeline-service.version'] ?= '1.0'
      if options.yarn_site['yarn.timeline-service.version'] is '1.5'
        options.yarn_site['yarn.timeline-service.store-class'] = 'org.apache.hadoop.yarn.server.timeline.EntityGroupFSTimelineStore'
        options.yarn_site['yarn.timeline-service.entity-group-fs-store.active-dir'] ?= '/ats/active/'
        options.yarn_site['yarn.timeline-service.entity-group-fs-store.done-dir'] ?= '/ats/done'
        options.yarn_site['yarn.timeline-service.entity-group-fs-store.group-id-plugin-classes'] ?= 'org.apache.tez.dag.history.logging.ats.TimelineCachePluginImpl'
        options.yarn_site['yarn.timeline-service.entity-group-fs-store.summary-store'] ?= 'org.apache.hadoop.yarn.server.timeline.RollingLevelDBTimelineStore'

## SSL

      options.ssl = merge {}, service.deps.hadoop_core.options.ssl, options.ssl
      options.ssl_server = merge {}, service.deps.hadoop_core.options.ssl_server, options.ssl_server or {},
        'ssl.server.keystore.location': "#{options.conf_dir}/keystore"
        'ssl.server.truststore.location': "#{options.conf_dir}/truststore"
      options.ssl_client = merge {}, service.deps.hadoop_core.options.ssl_client, options.ssl_client or {},
        'ssl.client.truststore.location': "#{options.conf_dir}/truststore"

## Metrics

      options.metrics = merge {}, service.deps.hadoop_core.options.metrics, options.metrics

## Import/Export to Yarn RM
      
      # service.deps.yarn_ts.options.yarn_site['yarn.admin.acl'] ?= "#{options.user.name}"
      #Import Yarn Global properties
      for property in [
        'yarn.nodemanager.remote-app-log-dir'
        'yarn.nodemanager.remote-app-log-dir-suffix'
        'yarn.log-aggregation-enable'
        'yarn.log-aggregation.retain-seconds'
        'yarn.log-aggregation.retain-check-interval-seconds'
        'yarn.generic-application-history.save-non-am-container-meta-info'
        'yarn.http.policy'
        'yarn.log.server.url'
        'yarn.resourcemanager.principal'
        'yarn.resourcemanager.cluster-id'
        'yarn.resourcemanager.ha.enabled'
        'yarn.resourcemanager.ha.rm-ids'
      ]
        options.yarn_site[property] ?= service.deps.yarn_rm[0].options.yarn_site[property]

      #Import Yarn RM specific properties
      for srv in service.deps.yarn_rm
        id = if srv.options.yarn_site['yarn.resourcemanager.ha.enabled'] is 'true' then ".#{srv.options.yarn_site['yarn.resourcemanager.ha.id']}" else ''
        for property in [
          'yarn.resourcemanager.webapp.delegation-token-auth-filter.enabled'
          "yarn.resourcemanager.address#{id}"
          "yarn.resourcemanager.scheduler.address#{id}"
          "yarn.resourcemanager.admin.address#{id}"
          "yarn.resourcemanager.webapp.address#{id}"
          "yarn.resourcemanager.webapp.https.address#{id}"
          "yarn.resourcemanager.resource-tracker.address#{id}"
        ]
          options.yarn_site[property] ?= srv.options.yarn_site[property]
      #Export
      for srv in service.deps.yarn_rm
        for property in [
          'yarn.timeline-service.version'
          'yarn.timeline-service.enabled'
          'yarn.timeline-service.address'
          'yarn.timeline-service.webapp.address'
          'yarn.timeline-service.webapp.https.address'
          'yarn.timeline-service.reader.webapp.address'
          'yarn.timeline-service.reader.webapp.https.address'
          'yarn.timeline-service.principal'
          'yarn.timeline-service.http-authentication.type'
          'yarn.timeline-service.http-authentication.kerberos.principal'
          'yarn.timeline-service.version'
          'yarn.timeline-service.store-class'
          'yarn.timeline-service.entity-group-fs-store.active-dir'
          'yarn.timeline-service.entity-group-fs-store.done-dir'
          'yarn.timeline-service.entity-group-fs-store.group-id-plugin-classes'
          'yarn.timeline-service.entity-group-fs-store.summary-store'
          'yarn.timeline-service.ttl-enable'
          'yarn.timeline-service.ttl-ms'
          'yarn.generic-application-history.save-non-am-container-meta-info'
          ]
            srv.options.yarn_site[property] ?= options.yarn_site[property]

## Wait

      options.wait_krb5_client = service.deps.krb5_client.options.wait
      options.wait_hdfs_nn = service.deps.hdfs_nn[0].options.wait
      options.wait = {}
      options.wait.webapp = for srv in service.deps.yarn_ts
        srv.options.yarn_site['yarn.http.policy'] ?= options.yarn_site['yarn.http.']
        srv.options.yarn_site['yarn.timeline-service.webapp.address'] ?= "#{srv.node.fqdn}:8188"
        srv.options.yarn_site['yarn.timeline-service.webapp.https.address'] ?= "#{srv.node.fqdn}:8190"
        protocol = if srv.options.yarn_site['yarn.http.policy'] is 'HTTP_ONLY' then '' else 'https.'
        [host, port] = srv.options.yarn_site["yarn.timeline-service.webapp.#{protocol}address"].split ':'
        host: host, port: port

## Dependencies

    {merge} = require '@nikita/core/lib/misc'

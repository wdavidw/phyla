

# YARN Client Configure

    module.exports = (service) ->
      options = service.options

## Environment

      options.log_dir ?= '/var/log/hadoop-yarn'
      # options.pid_dir ?= '/var/run/hadoop-yarn'
      options.conf_dir ?= service.deps.hadoop_core.options.conf_dir
      options.opts ?= ''
      options.heapsize ?= '1024'
      options.home ?= '/usr/hdp/current/hadoop-yarn-client'
      # Misc
      options.java_home ?= service.deps.java.options.java_home

## Identities

      options.group = merge {}, service.deps.hadoop_core.options.yarn.group, options.group
      options.user = merge {}, service.deps.hadoop_core.options.yarn.user, options.user
      # Kerberos Test Principal
      options.test_krb5_user ?= service.deps.test_user.options.krb5.user

## Configuration

      options.yarn_site ?= {}
      options.yarn_site['yarn.http.policy'] ?= 'HTTPS_ONLY' # HTTP_ONLY or HTTPS_ONLY or HTTP_AND_HTTPS
      # Configure yarn
      # Fix yarn application classpath, some application like the distributed shell
      # wont replace "hdp.version" and result in class not found.
      # options.yarn_site['yarn.application.classpath'] ?= "$HADOOP_CONF_DIR,/usr/hdp/${hdp.version}/hadoop-client/*,/usr/hdp/${hdp.version}/hadoop-client/lib/*,/usr/hdp/${hdp.version}/hadoop-hdfs-client/*,/usr/hdp/${hdp.version}/hadoop-hdfs-client/lib/*,/usr/hdp/${hdp.version}/hadoop-yarn-client/*,/usr/hdp/${hdp.version}/hadoop-yarn-client/lib/*"
      options.yarn_site['yarn.application.classpath'] ?= "$HADOOP_CONF_DIR,/usr/hdp/current/hadoop-client/*,/usr/hdp/current/hadoop-client/lib/*,/usr/hdp/current/hadoop-hdfs-client/*,/usr/hdp/current/hadoop-hdfs-client/lib/*,/usr/hdp/current/hadoop-yarn-client/*,/usr/hdp/current/hadoop-yarn-client/lib/*"
      # The default value of yarn.generic-application-history.save-non-am-container-meta-info
      # is true, so there is no change in behavior. For clusters with more than
      # 100 nodes, we recommend this configuration value be set to false to
      # reduce the load on the Application Timeline Service.
      # see http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.2.8/bk_HDP_RelNotes/content/behav-changes-228.html
      default_save_am_info = if service.deps.yarn_nm.length > 100 then 'false' else 'true'
      options.yarn_site['yarn.generic-application-history.save-non-am-container-meta-info'] ?= "#{default_save_am_info}"

## Yarn Timeline Server

      for property in [
        'yarn.timeline-service.enabled'
        'yarn.timeline-service.address'
        'yarn.timeline-service.webapp.address'
        'yarn.timeline-service.webapp.https.address'
        'yarn.timeline-service.principal'
        'yarn.timeline-service.http-authentication.type'
        'yarn.timeline-service.http-authentication.kerberos.principal'
      ]
        options.yarn_site[property] ?= if service.deps.yarn_ats then service.deps.yarn_ats.options.yarn_site[property] else null

      for srv in service.deps.yarn_nm
        for property in [
          # 'yarn.log-aggregation-enable'
          # 'yarn.log-aggregation.retain-check-interval-seconds'
          # 'yarn.log-aggregation.retain-seconds'
          'yarn.nodemanager.remote-app-log-dir'
        ]
          options.yarn_site[property] ?= srv.options.yarn_site[property]

      for srv in service.deps.yarn_rm
        id = if srv.options.yarn_site['yarn.resourcemanager.ha.enabled'] is 'true' then ".#{srv.options.yarn_site['yarn.resourcemanager.ha.id']}" else ''
        for property in [
          'yarn.resourcemanager.principal'
          'yarn.http.policy'
          'yarn.log.server.url'
          'yarn.resourcemanager.cluster-id'
          'yarn.resourcemanager.ha.enabled'
          'yarn.resourcemanager.ha.rm-ids'
          'yarn.resourcemanager.webapp.delegation-token-auth-filter.enabled'
          "yarn.resourcemanager.address#{id}"
          "yarn.resourcemanager.scheduler.address#{id}"
          "yarn.resourcemanager.admin.address#{id}"
          "yarn.resourcemanager.webapp.address#{id}"
          "yarn.resourcemanager.webapp.https.address#{id}"
        ]
          options.yarn_site[property] ?= srv.options.yarn_site[property]

## Wait

      options.wait_yarn_ts = service.deps.yarn_ts[0].options.wait
      options.wait_yarn_rm = service.deps.yarn_rm[0].options.wait

## Dependencies

    {merge} = require 'nikita/lib/misc'

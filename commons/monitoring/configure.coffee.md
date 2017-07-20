
# Configure Monitoring Objects

    module.exports = ->
      {db_admin, krb5_user} = @config.ryba
      options = @config.ryba.monitoring ?= {}

## Credentials

"credentials" object contains credentials for components that use authentication.
If a credential is disabled, tests that need this credential will be disabled.

      options.credentials ?= {}
      options.credentials.krb5_user ?= {}
      options.credentials.krb5_user.enabled ?= true
      if options.credentials.krb5_user.enabled
        options.credentials.krb5_user[k] ?= v for k,v of krb5_user
        unless options.credentials.krb5_user.password? or options.credentials.krb5_user.keytab?
          throw Error 'Required property: either ryba.monitoring.credentials.krb5_user.password or ryba.monitoring.credentials.krb5_user.keytab'
      options.credentials.knox_user ?= {}
      options.credentials.knox_user.enabled ?= true
      if options.credentials.knox_user.enabled
        options.credentials.knox_user.username ?= 'ryba'
        throw Error 'Required property: ryba.monitoring.credentials.knox_user.password' unless options.credentials.knox_user.password?
      options.credentials.sql_user ?= {}
      options.credentials.sql_user.enabled ?= true
      if options.credentials.sql_user.enabled
        options.credentials.sql_user.username ?= 'ryba'
        throw Error 'Required property: ryba.monitoring.credentials.sql_user.password' unless options.credentials.sql_user.password?
      options.credentials.swarm_user ?= {}
      options.credentials.swarm_user.enabled ?= true
      if options.credentials.swarm_user.enabled
        options.credentials.swarm_user.username ?= 'ryba'
        throw Error 'Required property: ryba.monitoring.credentials.swarm_user.password' unless options.credentials.swarm_user.password
        throw Error 'Required property: ryba.monitoring.credentials.swarm_user.cert' unless options.credentials.swarm_user.cert
        throw Error 'Required property: ryba.monitoring.credentials.swarm_user.key' unless options.credentials.swarm_user.key

## Default Configuration

Default "monitoring object" (servicegroups, hosts, etc) configuration.

      options.hostgroups ?= {}
      options.hosts ?= {}
      options.servicegroups ?= {}
      options.services ?= {}
      options.commands ?= {}
      options.realms ?= {}
      options.realms.All ?= {}
      options.clusters ?= {}
      options.contactgroups ?= {}
      options.contacts ?= {}
      options.dependencies ?= {}
      options.escalations ?= {}
      options.hostescalations ?= {}
      options.serviceescalations ?= {}
      options.timeperiods ?= {}
      # Hostgroups
      options.hostgroups['by_roles'] ?= {}
      options.hostgroups['by_roles'].alias ?= 'Role View'
      options.hostgroups['by_roles'].hostgroup_members ?= []
      options.hostgroups['by_topology'] ?= {}
      options.hostgroups['by_topology'].alias ?= 'Topological View'
      options.hostgroups['by_topology'].hostgroup_members ?= []
      options.hostgroups['watcher'] ?= {}
      options.hostgroups['watcher'].alias ?= 'Cluster Watchers'
      options.hostgroups['watcher'].hostgroup_members ?= []

### Templates

Templates are generic (abstract) objects that can define commons properties by heritage.
They must have register set to 0 to not be instanciated

      # Hosts
      options.hosts['generic-host'] ?= {}
      options.hosts['generic-host'].use ?= ''
      options.hosts['generic-host'].check_command ?= 'check_host'
      options.hosts['generic-host'].max_check_attempts ?= '2'
      options.hosts['generic-host'].check_interval ?= '300'
      options.hosts['generic-host'].retry_interval ?= '60'
      options.hosts['generic-host'].active_checks_enabled ?= '1'
      options.hosts['generic-host'].check_period ?= 'everytime'
      options.hosts['generic-host'].event_handler_enabled ?= '0'
      options.hosts['generic-host'].flap_detection_enabled ?= '1'
      options.hosts['generic-host'].process_perf_data ?= '1'
      options.hosts['generic-host'].retain_status_information ?= '1'
      options.hosts['generic-host'].retain_nonstatus_information ?= '1'
      options.hosts['generic-host'].contactgroups ?= ['admins']
      options.hosts['generic-host'].notification_interval ?= '3600'
      options.hosts['generic-host'].notification_period ?= 'everytime'
      options.hosts['generic-host'].notification_options ?= 'd,u,r,f'
      options.hosts['generic-host'].notification_enabled ?= '1'
      options.hosts['generic-host'].register = '0' # IT'S A TEMPLATE !
      options.hosts['linux-server'] ?= {}
      options.hosts['linux-server'].use ?= 'generic-host'
      options.hosts['linux-server'].check_interval ?= '60'
      options.hosts['linux-server'].retry_interval ?= '20'
      options.hosts['linux-server'].register = '0' # IT'S A TEMPLATE !
      options.hosts['aggregates'] ?= {}
      options.hosts['aggregates'].use ?= 'generic-host'
      options.hosts['aggregates'].check_command ?= 'ok'
      options.hosts['aggregates'].register = '0' # IT'S A TEMPLATE !
      # Services
      options.services['generic-service'] ?= {}
      options.services['generic-service'].use ?= ''
      options.services['generic-service'].active_checks_enabled ?= '1'
      options.services['generic-service'].passive_checks_enabled ?= '1'
      options.services['generic-service'].parallelize_check ?= '1'
      options.services['generic-service'].obsess_over_service ?= '1'
      options.services['generic-service'].check_freshness ?= '1'
      options.services['generic-service'].first_notification_delay ?= '0'
      options.services['generic-service'].freshness_threshold ?= '3600'
      options.services['generic-service'].notifications_enabled ?= '1'
      options.services['generic-service'].flap_detection_enabled ?= '0'
      options.services['generic-service'].failure_prediction_enabled ?= '1'
      options.services['generic-service'].process_perf_data ?= '1'
      options.services['generic-service'].retain_status_information ?= '1'
      options.services['generic-service'].retain_nonstatus_information ?= '1'
      options.services['generic-service'].is_volatile ?= '0'
      options.services['generic-service'].check_period ?= 'everytime'
      options.services['generic-service'].max_check_attempts ?= '2'
      options.services['generic-service'].check_interval ?= '300'
      options.services['generic-service'].retry_interval ?= '60'
      options.services['generic-service'].contactgroups ?= 'admins'
      options.services['generic-service'].notifications_options ?= 'w,u,c,r'
      options.services['generic-service'].notification_interval ?= '3600'
      options.services['generic-service'].notification_period ?= 'everytime'
      options.services['generic-service'].business_rule_output_template ?= '$($HOSTNAME$: $SERVICEDESC$)$'
      options.services['generic-service'].register = '0'
      options.services['unit-service'] ?= {}
      options.services['unit-service'].use ?= 'generic-service'
      options.services['unit-service'].register = '0'
      options.services['unit-service'].check_interval = '30'
      options.services['unit-service'].retry_interval = '10'
      options.services['bp-service'] ?= {}
      options.services['bp-service'].use ?= 'unit-service'
      options.services['bp-service'].register ?= '0'
      options.services['process-service'] ?= {}
      options.services['process-service'].use ?= 'unit-service'
      options.services['process-service'].event_handler_enabled ?= '1'
      options.services['process-service'].event_handler ?= 'service_start!$_SERVICEPROCESS_NAME$'
      options.services['process-service'].register = '0'
      options.services['cert-service'] ?= {}
      options.services['cert-service'].use ?= 'unit-service'
      options.services['cert-service'].check_interval = '1800'
      options.services['cert-service'].register ?= '0'
      options.services['functional-service'] ?= {}
      options.services['functional-service'].use ?= 'generic-service'
      options.services['functional-service'].check_interval = '600'
      options.services['functional-service'].retry_interval = '30'
      options.services['functional-service'].register = '0'
      # ContactGroups
      options.contactgroups['admins'] ?= {}
      options.contactgroups['admins'].alias ?= 'Administrators'
      # Contacts
      options.contacts['generic-contact'] ?= {}
      options.contacts['generic-contact'].use ?= ''
      options.contacts['generic-contact'].service_notification_period ?= 'everytime'
      options.contacts['generic-contact'].host_notification_period ?= 'everytime'
      options.contacts['generic-contact'].service_notification_options ?= 'w,u,c,r,f'
      options.contacts['generic-contact'].host_notification_options ?= 'd,u,r,f,s'
      options.contacts['generic-contact'].service_notification_commands ?= 'notify-service-by-email'
      options.contacts['generic-contact'].host_notification_commands ?= 'notify-host-by-email'
      options.contacts['generic-contact'].host_notifications_enabled ?= '1'
      options.contacts['generic-contact'].service_notifications_enabled ?= '1'
      options.contacts['generic-contact'].can_submit_commands ?= '0'
      options.contacts['generic-contact'].register = '0'
      options.contacts['admin-contact'] ?= {}
      options.contacts['admin-contact'].use ?= 'generic-contact'
      options.contacts['admin-contact'].can_submit_commands ?= '1'
      options.contacts['admin-contact'].is_admin ?= '1'
      options.contacts['admin-contact'].contactgroups ?= ['admins']
      options.contacts['admin-contact'].register = '0'
      options.contacts['admin'] ?= {}
      options.contacts['admin'].use ?= 'admin-contact'
      options.contacts['admin'].register ?= '1'
      unless options.contacts['admin'].password or "#{options.contacts['admin'].register}" is '0'
        throw Error "Missing property: ryba.monitoring.contacts.admin.password"
      options.contacts['readonly-contact'] ?= {}
      options.contacts['readonly-contact'].use ?= 'generic-contact'
      options.contacts['readonly-contact'].alias ?= 'Read-Only Users'
      options.contacts['readonly-contact'].contactgroups ?= ['readonly']
      options.contacts['readonly-contact'].host_notifications_enabled ?= '0'
      options.contacts['readonly-contact'].service_notifications_enabled ?= '0'
      options.contacts['readonly-contact'].register = '0'
      # Timeperiods
      options.timeperiods['everytime'] ?= {}
      options.timeperiods['everytime'].alias ?= 'Everytime'
      options.timeperiods['everytime'].time ?= {}
      for day in ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
        options.timeperiods['everytime'].time[day] ?= '00:00-24:00'
      # Timeperiods
      options.timeperiods['office'] ?= {}
      options.timeperiods['office'].alias ?= 'Office time'
      options.timeperiods['office'].time ?= {}
      for day in ['monday', 'tuesday', 'wednesday', 'thursday', 'friday']
        options.timeperiods['office'].time[day] ?= '07:00-19:00'
      options.timeperiods.none ?= {}
      options.timeperiods.none.alias ?= 'Never'
      options.timeperiods.none.time = {}
      # Commands
      options.commands['notify-host-by-email'] ?= '/usr/bin/printf "%b" "Monitoring Notification\\n\\nType: $NOTIFICATIONTYPE$\\nHost: $HOSTNAME$\\nState: $HOSTSTATE$\\nAddress: $HOSTADDRESS$\\nDate: $SHORTDATETIME$\\nInfo: $HOSTOUTPUT$" | mailx -s "Host $NOTIFICATIONTYPE$: $HOSTNAME$ is $HOSTSTATE$" $CONTACTEMAIL$'
      options.commands['notify-service-by-email'] ?= '/usr/bin/printf "%b" "Monitoring Notification\\n\\nNotification Type: $NOTIFICATIONTYPE$\\n\\nService: $SERVICEDESC$\\nHost:$HOSTALIAS$\\nAddress: $HOSTADDRESS$\\nState: $SERVICESTATE$\\nDate: $SHORTDATETIME$\\nInfo : $SERVICEOUTPUT$" | mailx -s "Service $NOTIFICATIONTYPE$: $SERVICEDESC$ ($HOSTALIAS$) is $SERVICESTATE$"  $CONTACTEMAIL$'

## Object from Ryba

This function creates hostgroups and servicegroups from ryba (sub)modules

      initgroup = (name, parent, alias) ->
        alias ?= "#{name.charAt(0).toUpperCase()}#{name.slice 1}"
        options.servicegroups[name] ?= {}
        options.servicegroups[name].alias ?= "#{alias} Services"
        options.servicegroups[name].members ?= []
        options.servicegroups[name].servicegroup_members ?= []
        options.servicegroups[name].servicegroup_members = [options.servicegroups[name].servicegroup_members] unless Array.isArray options.servicegroups[name].servicegroup_members
        options.servicegroups[parent].servicegroup_members.push name if parent? and name not in options.servicegroups[parent].servicegroup_members
        options.hostgroups[name] ?= {}
        options.hostgroups[name].alias ?= "#{alias} Hosts"
        options.hostgroups[name].members ?= []
        options.hostgroups[name].hostgroup_members ?= []
        parent ?= 'by_roles'
        options.hostgroups[parent].hostgroup_members.push name unless name in hostgroups[parent].hostgroup_members

      create_dependency = (s1, s2, h1, h2) ->
        h2 ?= h1
        dep = options.dependencies["#{s1} / #{s2}"] ?= {}
        dep.service ?= s2
        dep.dependent_service ?= s1
        dep.hosts ?= [h2]
        dep.dependent_hosts ?= [h1]
        dep.inherits_parent ?= '1'
        dep.execution_failure_criteria ?= 'c,u,p'
        dep.notification_failure_criteria ?= 'c,u,p'

### Declare ALL services

      # initgroup 'mysql'
      # initgroup 'mysql_server', 'mysql', 'MySQL Server'
      # initgroup 'zookeeper'
      # initgroup 'zookeeper_server', 'zookeeper', 'Zookeeper Server'
      # initgroup 'zookeeper_client', 'zookeeper', 'Zookeeper Client'
      # initgroup 'hadoop'
      # initgroup 'hdfs', 'hadoop', 'HDFS'
      # initgroup 'hdfs_nn', 'hdfs', 'HDFS NameNode'
      # initgroup 'hdfs_jn', 'hdfs', 'HDFS JournalNode'
      # initgroup 'zkfc', 'hdfs', 'HDFS ZKFC'
      # initgroup 'hdfs_dn', 'hdfs', 'HDFS DataNode'
      # initgroup 'httpfs', 'hdfs', 'HttpFS'
      # initgroup 'hdfs_client', 'hdfs', 'HDFS Client'
      # initgroup 'yarn', 'hadoop', 'YARN'
      # initgroup 'yarn_rm', 'yarn', 'YARN ResourceManager'
      # initgroup 'yarn_nm', 'yarn', 'YARN NodeManager'
      # initgroup 'yarn_ts', 'yarn', 'YARN Timeline Server'
      # initgroup 'yarn_client', 'yarn', 'YARN Client'
      # initgroup 'mapreduce', 'hadoop', 'MapReduce'
      # initgroup 'mapred_jhs', 'mapreduce', 'MapReduce JobHistory Server'
      # initgroup 'mapred_client', 'mapreduce', 'MapReduce Client'
      # initgroup 'hbase', null, 'HBase'
      # initgroup 'hbase_master', 'hbase', 'HBase Master'
      # initgroup 'hbase_regionserver', 'hbase', 'HBase RegionServer'
      # initgroup 'hbase_rest', 'hbase', 'HBase REST'
      # initgroup 'hbase_thrift', 'hbase', 'HBase Thrift'
      # initgroup 'hbase_client', 'hbase', 'HBase Client'
      # initgroup 'phoenix'
      # initgroup 'phoenix_master', 'phoenix', 'Phoenix Master'
      # initgroup 'phoenix_regionserver', 'phoenix', 'Phoenix RegionServer'
      # initgroup 'phoenix_client', 'phoenix', 'Phoenix Client'
      # initgroup 'opentsdb', null, 'OpenTSDB'
      # initgroup 'hive'
      # initgroup 'hiveserver2', 'hive', 'HiveServer2'
      # initgroup 'hcatalog', 'hive', 'HCatalog'
      # initgroup 'webhcat', 'hive', 'WebHCat'
      # initgroup 'hive_client', 'hive', 'WebHCat'
      # initgroup 'tez'
      # initgroup 'oozie'
      # initgroup 'oozie_server', 'oozie', 'Oozie Server'
      # initgroup 'oozie_client', 'oozie', 'Oozie Client'
      # initgroup 'kafka'
      # initgroup 'kafka_broker', 'kafka', 'Kafka Broker'
      # initgroup 'kafka_producer', 'kafka', 'Kafka Producer'
      # initgroup 'kafka_consumer', 'kafka', 'Kafka Consumer'
      # initgroup 'spark'
      # initgroup 'spark_hs', 'spark', 'Spark History Server'
      # initgroup 'spark_client', 'spark', 'Spark Client'
      # initgroup 'elasticsearch', null, 'ElasticSearch'
      # initgroup 'solr', null, 'SolR'
      # initgroup 'titan', null, 'Titan DB'
      # initgroup 'rexster'
      # initgroup 'pig'
      # initgroup 'sqoop'
      # initgroup 'falcon'
      # initgroup 'flume'
      # initgroup 'hue'
      # initgroup 'knox'
      # initgroup 'zeppelin'

## Configure from context

This function is called with a context, taken from internal context, or imported.
An external configuration can be obtained with an instance of ryba using
'configure' command

Theses functions are used to generate business rules

      bp_miss = (n, name, g) -> "bp_rule!(100%,1,-#{n} of: #{ if g? then "g:#{g}" else '*'},r:^#{name}?)"
      bp_has_quorum = (name, g) -> "bp_rule!(100%,1,50% of: #{ if g? then "g:#{g}" else '*'},r:^#{name}?)"
      bp_has_one = (name, g) -> "bp_rule!(100%,1,100% of: #{ if g? then "g:#{g}" else '*'},r:^#{name}?)"
      bp_has_all = (name, g) -> "bp_rule!(100%,1,1 of: #{ if g? then "g:#{g}" else '*'},r:^#{name}?)"
      #bp_has_percent = (name, w, c, g) -> "bp_rule!(100%,#{w}%,#{c}% of: #{ if g? then "g:#{g}" else '*'},r:^#{name}?)"

      from_contexts = (ctxs, clustername) ->
        clustername ?= ctxs[0].config.ryba.nameservice or 'default'
        options.clusters[clustername] ?= {}
        hg = options.hostgroups[clustername] ?= {}
        hg.members ?= []
        hg.members = [hg.members] unless Array.isArray hg.members
        hg.hostgroup_members ?= []
        hg.hostgroup_members = [hg.hostgroup_members] unless Array.isArray hg.hostgroup_members
        options.hostgroups.by_topology.hostgroup_members.push clustername unless clustername in options.hostgroups.by_topology.hostgroup_members
        # Watchers -> Special host with name of the cluster, for cluster business rules
        w = options.hosts[clustername] ?= {}
        w.ip = '0.0.0.0'
        w.alias = "#{clustername} Watcher"
        w.hostgroups = ['watcher']
        w.use = 'aggregates'
        w.cluster ?= clustername
        w.notes ?= clustername
        w.realm = options.clusters[clustername].realm if options.clusters[clustername].realm?
        w.modules ?= []
        w.modules = [w.modules] unless Array.isArray w.modules
        options.hostgroups[clustername].members.push clustername
        # True Servers
        for ctx in ctxs
          {host, shortname, ip, ryba} = ctx.config
          options.hostgroups[clustername].members.push host
          h = options.hosts[host] ?= {}
          h.ip ?= ip
          h.hostgroups ?= []
          h.hostgroups = [h.hostgroups] unless Array.isArray h.hostgroups
          h.use ?= 'linux-server'
          #h.config ?= ctx.config
          h.realm ?= options.clusters[clustername].realm
          h.cluster ?= clustername
          h.notes ?= clustername

###  Declare services

          # TODO: put db_admin username/password
          if 'masson/commons/mysql/server' in ctx.services or 'masson/commons/mariadb/server' in ctx.services
            w.modules.push 'mysql_server' unless 'mysql_server' in w.modules
            h.hostgroups.push 'mysql_server' unless 'mysql_server' in h.hostgroups
            options.services['MySQL - TCP'] ?= {}
            options.services['MySQL - TCP'].hosts ?= []
            options.services['MySQL - TCP'].hosts.push host
            options.services['MySQL - TCP'].servicegroups ?= ['mysql_server']
            options.services['MySQL - TCP'].use ?= 'process-service'
            options.services['MySQL - TCP']['_process_name'] ?= 'mysqld'
            options.services['MySQL - TCP'].check_command ?= "check_tcp!#{db_admin.mysql.port}"
            if options.credentials.sql_user.enabled
              options.services['MySQL - Connection time'] ?= {}
              options.services['MySQL - Connection time'].hosts ?= []
              options.services['MySQL - Connection time'].hosts.push host
              options.services['MySQL - Connection time'].servicegroups ?= ['mysql_server']
              options.services['MySQL - Connection time'].use ?= 'unit-service'
              options.services['MySQL - Connection time'].check_command ?= "check_mysql!#{db_admin.mysql.port}!connection-time!3!10"
              create_dependency 'MySQL - Connection time', 'MySQL - TCP', host
              options.services['MySQL - Slow queries'] ?= {}
              options.services['MySQL - Slow queries'].hosts ?= []
              options.services['MySQL - Slow queries'].hosts.push host
              options.services['MySQL - Slow queries'].servicegroups ?= ['mysql_server']
              options.services['MySQL - Slow queries'].use ?= 'functional-service'
              options.services['MySQL - Slow queries'].check_command ?= "check_mysql!#{db_admin.mysql.port}!slow-queries!0,25!1"
              create_dependency 'MySQL - Slow queries', 'MySQL - TCP', host
              options.services['MySQL - Slave lag'] ?= {}
              options.services['MySQL - Slave lag'].hosts ?= []
              options.services['MySQL - Slave lag'].hosts.push host
              options.services['MySQL - Slave lag'].servicegroups ?= ['mysql_server']
              options.services['MySQL - Slave lag'].use ?= 'unit-service'
              options.services['MySQL - Slave lag'].check_command ?= "check_mysql!#{db_admin.mysql.port}!slave-lag!3!10"
              create_dependency 'MySQL - Slave lag', 'MySQL - TCP', host
              options.services['MySQL - Slave IO running'] ?= {}
              options.services['MySQL - Slave IO running'].hosts ?= []
              options.services['MySQL - Slave IO running'].hosts.push host
              options.services['MySQL - Slave IO running'].servicegroups ?= ['mysql_server']
              options.services['MySQL - Slave IO running'].use ?= 'unit-service'
              options.services['MySQL - Slave IO running'].check_command ?= "check_mysql!#{db_admin.mysql.port}!slave-io-running!1!1"
              create_dependency 'MySQL - Slave IO running', 'MySQL - TCP', host
              options.services['MySQL - Connected Threads'] ?= {}
              options.services['MySQL - Connected Threads'].hosts ?= []
              options.services['MySQL - Connected Threads'].hosts.push host
              options.services['MySQL - Connected Threads'].servicegroups ?= ['mysql_server']
              options.services['MySQL - Connected Threads'].use ?= 'unit-service'
              options.services['MySQL - Connected Threads'].check_command ?= "check_mysql!#{db_admin.mysql.port}!threads-connected!80!100"
              create_dependency 'MySQL - Connected Threads', 'MySQL - TCP', host
          if 'ryba/zookeeper/server' in ctx.services
            w.modules.push 'zookeeper_server' unless 'zookeeper_server' in w.modules
            h.hostgroups.push 'zookeeper_server' unless 'zookeeper_server' in h.hostgroups
            options.services['Zookeeper Server - TCP'] ?= {}
            options.services['Zookeeper Server - TCP'].hosts ?= []
            options.services['Zookeeper Server - TCP'].hosts.push host
            options.services['Zookeeper Server - TCP'].servicegroups ?= ['zookeeper_server']
            options.services['Zookeeper Server - TCP'].use ?= 'process-service'
            options.services['Zookeeper Server - TCP']['_process_name'] ?= 'zookeeper-server'
            options.services['Zookeeper Server - TCP'].check_command ?= "check_tcp!#{ryba.zookeeper.port}"
            options.services['Zookeeper Server - State'] ?= {}
            options.services['Zookeeper Server - State'].hosts ?= []
            options.services['Zookeeper Server - State'].hosts.push host
            options.services['Zookeeper Server - State'].servicegroups ?= ['zookeeper_server']
            options.services['Zookeeper Server - State'].use ?= 'unit-service'
            options.services['Zookeeper Server - State'].check_command ?= "check_socket!#{ryba.zookeeper.port}!ruok!imok"
            create_dependency 'Zookeeper Server - State', 'Zookeeper Server - TCP', host
            options.services['Zookeeper Server - Connections'] ?= {}
            options.services['Zookeeper Server - Connections'].hosts ?= []
            options.services['Zookeeper Server - Connections'].hosts.push host
            options.services['Zookeeper Server - Connections'].servicegroups ?= ['zookeeper_server']
            options.services['Zookeeper Server - Connections'].use ?= 'unit-service'
            options.services['Zookeeper Server - Connections'].check_command ?= "check_zk_stat!#{ryba.zookeeper.port}!connections!300!350"
            create_dependency 'Zookeeper Server - Connections', 'Zookeeper Server - TCP', host
          if 'ryba/hadoop/hdfs_nn' in ctx.services
            w.modules.push 'hdfs_nn' unless 'hdfs_nn' in w.modules
            h.hostgroups.push 'hdfs_nn' unless 'hdfs_nn' in h.hostgroups
            options.services['HDFS NN - TCP'] ?= {}
            options.services['HDFS NN - TCP'].hosts ?= []
            options.services['HDFS NN - TCP'].hosts.push host
            options.services['HDFS NN - TCP'].servicegroups ?= ['hdfs_nn']
            options.services['HDFS NN - TCP'].use ?= 'process-service'
            options.services['HDFS NN - TCP']['_process_name'] ?= 'hadoop-hdfs-namenode'
            rpc = ryba.hdfs.nn.site["dfs.namenode.rpc-address.#{ryba.nameservice}.#{shortname}"].split(':')[1]
            options.services['HDFS NN - TCP'].check_command ?= "check_tcp!#{rpc}"
            options.services['HDFS NN - WebService'] ?= {}
            options.services['HDFS NN - WebService'].hosts ?= []
            options.services['HDFS NN - WebService'].hosts.push host
            options.services['HDFS NN - WebService'].servicegroups ?= ['hdfs_nn']
            options.services['HDFS NN - WebService'].use ?= 'unit-service'
            https = ryba.hdfs.nn.site["dfs.namenode.https-address.#{ryba.nameservice}.#{shortname}"].split(':')[1]
            options.services['HDFS NN - WebService'].check_command ?= "check_tcp!#{https}!-S"
            create_dependency 'HDFS NN - WebService', 'HDFS NN - TCP', host
            options.services['HDFS NN - Certificate'] ?= {}
            options.services['HDFS NN - Certificate'].hosts ?= []
            options.services['HDFS NN - Certificate'].hosts.push host
            options.services['HDFS NN - Certificate'].servicegroups ?= ['hdfs_nn']
            options.services['HDFS NN - Certificate'].use ?= 'cert-service'
            options.services['HDFS NN - Certificate'].check_command ?= "check_cert!#{https}!120!60"
            create_dependency 'HDFS NN - Certificate', 'HDFS NN - WebService', host
            options.services['HDFS NN - RPC latency'] ?= {}
            options.services['HDFS NN - RPC latency'].hosts ?= []
            options.services['HDFS NN - RPC latency'].hosts.push host
            options.services['HDFS NN - RPC latency'].servicegroups ?= ['hdfs_nn']
            options.services['HDFS NN - RPC latency'].use ?= 'unit-service'
            options.services['HDFS NN - RPC latency'].check_command ?= "check_rpc_latency!NameNode!#{https}!3000!5000!-S"
            create_dependency 'HDFS NN - RPC latency', 'HDFS NN - WebService', host
            options.services['HDFS NN - Last checkpoint'] ?= {}
            options.services['HDFS NN - Last checkpoint'].hosts ?= []
            options.services['HDFS NN - Last checkpoint'].hosts.push host
            options.services['HDFS NN - Last checkpoint'].servicegroups ?= ['hdfs_nn']
            options.services['HDFS NN - Last checkpoint'].use ?= 'unit-service'
            options.services['HDFS NN - Last checkpoint'].check_command ?= "check_nn_last_checkpoint!#{https}!21600!1000000!120%!200%!-S"
            create_dependency 'HDFS NN - RPC latency', 'HDFS NN - WebService', host
            options.services['HDFS NN - Name Dir status'] ?= {}
            options.services['HDFS NN - Name Dir status'].hosts ?= []
            options.services['HDFS NN - Name Dir status'].hosts.push host
            options.services['HDFS NN - Name Dir status'].servicegroups ?= ['hdfs_nn']
            options.services['HDFS NN - Name Dir status'].use ?= 'unit-service'
            options.services['HDFS NN - Name Dir status'].check_command ?= "check_nn_namedirs_status!#{https}!-S"
            create_dependency 'HDFS NN - Name Dir status', 'HDFS NN - WebService', host
            options.services['HDFS NN - Utilization'] ?= {}
            options.services['HDFS NN - Utilization'].hosts ?= []
            options.services['HDFS NN - Utilization'].hosts.push host
            options.services['HDFS NN - Utilization'].servicegroups ?= ['hdfs_nn']
            options.services['HDFS NN - Utilization'].use ?= 'unit-service'
            options.services['HDFS NN - Utilization'].check_command ?= "check_hdfs_capacity!#{https}!80%!90%!-S"
            create_dependency 'HDFS NN - Utilization', 'HDFS NN - WebService', host
            options.services['HDFS NN - UnderReplicated blocks'] ?= {}
            options.services['HDFS NN - UnderReplicated blocks'].hosts ?= []
            options.services['HDFS NN - UnderReplicated blocks'].hosts.push host
            options.services['HDFS NN - UnderReplicated blocks'].servicegroups ?= ['hdfs_nn']
            options.services['HDFS NN - UnderReplicated blocks'].use ?= 'unit-service'
            options.services['HDFS NN - UnderReplicated blocks'].check_command ?= "check_hdfs_state!#{https}!FSNamesystemState!UnderReplicatedBlocks!1000!2000!-S"
            create_dependency 'HDFS NN - UnderReplicated blocks', 'HDFS NN - WebService', host
          if 'ryba/hadoop/hdfs_jn' in ctx.services
            w.modules.push 'hdfs_jn' unless 'hdfs_jn' in w.modules
            h.hostgroups.push 'hdfs_jn' unless 'hdfs_jn' in h.hostgroups
            options.services['HDFS JN - TCP SSL'] ?= {}
            options.services['HDFS JN - TCP SSL'].hosts ?= []
            options.services['HDFS JN - TCP SSL'].hosts.push host
            options.services['HDFS JN - TCP SSL'].servicegroups ?= ['hdfs_jn']
            options.services['HDFS JN - TCP SSL'].use ?= 'process-service'
            options.services['HDFS JN - TCP SSL']['_process_name'] ?= 'hadoop-hdfs-journalnode'
            https = ryba.hdfs.site['dfs.journalnode.https-address'].split(':')[1]
            options.services['HDFS JN - TCP SSL'].check_command ?= "check_tcp!#{https}!-S"
            options.services['HDFS JN - Certificate'] ?= {}
            options.services['HDFS JN - Certificate'].hosts ?= []
            options.services['HDFS JN - Certificate'].hosts.push host
            options.services['HDFS JN - Certificate'].servicegroups ?= ['hdfs_jn']
            options.services['HDFS JN - Certificate'].use ?= 'process-service'
            options.services['HDFS JN - Certificate'].check_command ?= "check_cert!#{https}!120!60"
            create_dependency 'HDFS JN - Certificate', 'HDFS JN - TCP SSL', host
          if 'ryba/hadoop/hdfs_dn' in ctx.services
            w.modules.push 'hdfs_dn' unless 'hdfs_dn' in w.modules
            h.hostgroups.push 'hdfs_dn' unless 'hdfs_dn' in h.hostgroups
            options.services['HDFS DN - TCP SSL'] ?= {}
            options.services['HDFS DN - TCP SSL'].hosts ?= []
            options.services['HDFS DN - TCP SSL'].hosts.push host
            options.services['HDFS DN - TCP SSL'].servicegroups ?= ['hdfs_dn']
            options.services['HDFS DN - TCP SSL'].use ?= 'process-service'
            options.services['HDFS DN - TCP SSL']['_process_name'] ?= 'hadoop-hdfs-datanode'
            options.services['HDFS DN - TCP SSL'].check_command ?= "check_tcp!#{ryba.hdfs.site['dfs.datanode.https.address'].split(':')[1]}!-S"
            options.services['HDFS DN - Certificate'] ?= {}
            options.services['HDFS DN - Certificate'].hosts ?= []
            options.services['HDFS DN - Certificate'].hosts.push host
            options.services['HDFS DN - Certificate'].servicegroups ?= ['hdfs_dn']
            options.services['HDFS DN - Certificate'].use ?= 'cert-service'
            options.services['HDFS DN - Certificate'].check_command ?= "check_cert!#{ryba.hdfs.site['dfs.datanode.https.address'].split(':')[1]}!120!60"
            create_dependency 'HDFS DN - Certificate', 'HDFS DN - TCP SSL', host
            options.services['HDFS DN - Free space'] ?= {}
            options.services['HDFS DN - Free space'].hosts ?= []
            options.services['HDFS DN - Free space'].hosts.push host
            options.services['HDFS DN - Free space'].servicegroups ?= ['hdfs_dn']
            options.services['HDFS DN - Free space'].use ?= 'unit-service'
            options.services['HDFS DN - Free space'].check_command ?= "check_dn_storage!#{ryba.hdfs.site['dfs.datanode.https.address'].split(':')[1]}!75%!90%!-S"
            create_dependency 'HDFS DN - Free space', 'HDFS DN - TCP SSL', host
          if 'ryba/hadoop/zkfc' in ctx.services
            w.modules.push 'hdfs_zkfc' unless 'hdfs_zkfc' in w.modules
            h.hostgroups.push 'hdfs_zkfc' unless 'hdfs_zkfc' in h.hostgroups
            options.services['ZKFC - TCP'] ?= {}
            options.services['ZKFC - TCP'].hosts ?= []
            options.services['ZKFC - TCP'].hosts.push host
            options.services['ZKFC - TCP'].servicegroups ?= ['hdfs_zkfc']
            options.services['ZKFC - TCP'].use ?= 'process-service'
            options.services['ZKFC - TCP']['_process_name'] ?= 'hadoop-hdfs-zkfc'
            options.services['ZKFC - TCP'].check_command ?= "check_tcp!#{ryba.hdfs.nn.site['dfs.ha.zkfc.port']}"
          if 'ryba/hadoop/httpfs' in ctx.services
            w.modules.push 'httpfs' unless 'httpfs' in w.modules
            h.hostgroups.push 'httpfs' unless 'httpfs' in h.hostgroups
            options.services['HttpFS - WebService'] ?= {}
            options.services['HttpFS - WebService'].hosts ?= []
            options.services['HttpFS - WebService'].hosts.push host
            options.services['HttpFS - WebService'].servicegroups ?= ['httpfs']
            options.services['HttpFS - WebService'].use ?= 'process-service'
            options.services['HttpFS - WebService']['_process_name'] ?= 'hadoop-httpfs'
            options.services['HttpFS - WebService'].check_command ?= "check_tcp!#{ryba.httpfs.http_port}"
            options.services['HttpFS - Certificate'] ?= {}
            options.services['HttpFS - Certificate'].hosts ?= []
            options.services['HttpFS - Certificate'].hosts.push host
            options.services['HttpFS - Certificate'].servicegroups ?= ['httpfs']
            options.services['HttpFS - Certificate'].use ?= 'cert-service'
            options.services['HttpFS - Certificate'].check_command ?= "check_cert!#{ryba.httpfs.http_port}!120!60"
            create_dependency 'HttpFS - Certificate', 'HttpFS - WebService', host
          if 'ryba/hadoop/yarn_rm' in ctx.services
            w.modules.push 'yarn_rm' unless 'yarn_rm' in w.modules
            h.hostgroups.push 'yarn_rm' unless 'yarn_rm' in h.hostgroups
            options.services['YARN RM - Admin TCP'] ?= {}
            options.services['YARN RM - Admin TCP'].hosts ?= []
            options.services['YARN RM - Admin TCP'].hosts.push host
            options.services['YARN RM - Admin TCP'].servicegroups ?= ['yarn_rm']
            options.services['YARN RM - Admin TCP'].use ?= 'process-service'
            options.services['YARN RM - Admin TCP']['_process_name'] ?= 'hadoop-yarn-resourcemanager'
            options.services['YARN RM - Admin TCP'].check_command ?= "check_tcp!8141"
            options.services['YARN RM - WebService'] ?= {}
            options.services['YARN RM - WebService'].hosts ?= []
            options.services['YARN RM - WebService'].hosts.push host
            options.services['YARN RM - WebService'].servicegroups ?= ['yarn_rm']
            options.services['YARN RM - WebService'].use ?= 'unit-service'
            options.services['YARN RM - WebService'].check_command ?= 'check_tcp!8090!-S'
            options.services['YARN RM - Certificate'] ?= {}
            options.services['YARN RM - Certificate'].hosts ?= []
            options.services['YARN RM - Certificate'].hosts.push host
            options.services['YARN RM - Certificate'].servicegroups ?= ['yarn_rm']
            options.services['YARN RM - Certificate'].use ?= 'cert-service'
            options.services['YARN RM - Certificate'].check_command ?= "check_cert!8090!120!60"
            create_dependency 'YARN RM - Certificate', 'YARN RM - WebService', host
          if 'ryba/hadoop/yarn_nm' in ctx.services
            w.modules.push 'yarn_nm' unless 'yarn_nm' in w.modules
            h.hostgroups.push 'yarn_nm' unless 'yarn_nm' in h.hostgroups
            options.services['YARN NM - TCP'] ?= {}
            options.services['YARN NM - TCP'].hosts ?= []
            options.services['YARN NM - TCP'].hosts.push host
            options.services['YARN NM - TCP'].servicegroups ?= ['yarn_nm']
            options.services['YARN NM - TCP'].use ?= 'process-service'
            options.services['YARN NM - TCP']['_process_name'] ?= 'hadoop-yarn-nodemanager'
            options.services['YARN NM - TCP'].check_command ?= "check_tcp!45454"
            options.services['YARN NM - WebService'] ?= {}
            options.services['YARN NM - WebService'].hosts ?= []
            options.services['YARN NM - WebService'].hosts.push host
            options.services['YARN NM - WebService'].servicegroups ?= ['yarn_nm']
            options.services['YARN NM - WebService'].use ?= 'unit-service'
            options.services['YARN NM - WebService'].check_command ?= 'check_tcp!8044!-S'
            options.services['YARN NM - Certificate'] ?= {}
            options.services['YARN NM - Certificate'].hosts ?= []
            options.services['YARN NM - Certificate'].hosts.push host
            options.services['YARN NM - Certificate'].servicegroups ?= ['yarn_nm']
            options.services['YARN NM - Certificate'].use ?= 'cert-service'
            options.services['YARN NM - Certificate'].check_command ?= 'check_cert!8044!120!60'
            create_dependency 'YARN NM - Certificate', 'YARN NM - WebService', host
            options.services['YARN NM - Health'] ?= {}
            options.services['YARN NM - Health'].hosts ?= []
            options.services['YARN NM - Health'].hosts.push host
            options.services['YARN NM - Health'].servicegroups ?= ['yarn_nm']
            options.services['YARN NM - Health'].use ?= 'unit-service'
            options.services['YARN NM - Health'].check_command ?= 'check_nm_info!8044!nodeHealthy!true!-S'
            create_dependency 'YARN NM - Health', 'YARN NM - WebService', host
          if 'ryba/hadoop/yarn_ts' in ctx.services
            w.modules.push 'yarn_ts' unless 'yarn_ts' in w.modules
            h.hostgroups.push 'yarn_ts' unless 'yarn_ts' in h.hostgroups
            options.services['YARN TS - TCP'] ?= {}
            options.services['YARN TS - TCP'].hosts ?= []
            options.services['YARN TS - TCP'].hosts.push host
            options.services['YARN TS - TCP'].servicegroups ?= ['yarn_ts']
            options.services['YARN TS - TCP'].use ?= 'process-service'
            options.services['YARN TS - TCP']['_process_name'] ?= 'hadoop-yarn-timelineserver'
            options.services['YARN TS - TCP'].check_command ?= "check_tcp!10200"
            options.services['YARN TS - WebService'] ?= {}
            options.services['YARN TS - WebService'].hosts ?= []
            options.services['YARN TS - WebService'].hosts.push host
            options.services['YARN TS - WebService'].servicegroups ?= ['yarn_ts']
            options.services['YARN TS - WebService'].use ?= 'unit-service'
            options.services['YARN TS - WebService'].check_command ?= 'check_tcp!8190!-S'
            options.services['YARN TS - Certificate'] ?= {}
            options.services['YARN TS - Certificate'].hosts ?= []
            options.services['YARN TS - Certificate'].hosts.push host
            options.services['YARN TS - Certificate'].servicegroups ?= ['yarn_ts']
            options.services['YARN TS - Certificate'].use ?= 'cert-service'
            options.services['YARN TS - Certificate'].check_command ?= 'check_cert!8190!120!60'
            create_dependency 'YARN TS - Certificate', 'YARN TS - WebService', host
          if 'ryba/hbase/master' in ctx.services
            w.modules.push 'hbase_master' unless 'hbase_master' in w.modules
            h.hostgroups.push 'hbase_master' unless 'hbase_master' in h.hostgroups
            options.services['HBase Master - TCP'] ?= {}
            options.services['HBase Master - TCP'].hosts ?= []
            options.services['HBase Master - TCP'].hosts.push host
            options.services['HBase Master - TCP'].servicegroups ?= ['hbase_master']
            options.services['HBase Master - TCP'].use ?= 'process-service'
            options.services['HBase Master - TCP']['_process_name'] ?= 'hbase-master'
            options.services['HBase Master - TCP'].check_command ?= "check_tcp!#{ryba.hbase.master.site['hbase.master.port']}"
            options.services['HBase Master - WebUI'] ?= {}
            options.services['HBase Master - WebUI'].hosts ?= []
            options.services['HBase Master - WebUI'].hosts.push host
            options.services['HBase Master - WebUI'].servicegroups ?= ['hbase_master']
            options.services['HBase Master - WebUI'].use ?= 'unit-service'
            options.services['HBase Master - WebUI'].check_command ?= "check_tcp!#{ryba.hbase.master.site['hbase.master.info.port']}!-S"
            create_dependency 'HBase Master - WebUI', 'HBase Master - TCP', host
            options.services['HBase Master - Certificate'] ?= {}
            options.services['HBase Master - Certificate'].hosts ?= []
            options.services['HBase Master - Certificate'].hosts.push host
            options.services['HBase Master - Certificate'].servicegroups ?= ['hbase_master']
            options.services['HBase Master - Certificate'].use ?= 'cert-service'
            options.services['HBase Master - Certificate'].check_command ?= "check_cert!#{ryba.hbase.master.site['hbase.master.info.port']}!120!60"
            create_dependency 'HBase Master - Certificate', 'HBase Master - WebUI', host
          if 'ryba/hbase/regionserver' in ctx.services
            w.modules.push 'hbase_regionserver' unless 'hbase_regionserver' in w.modules
            h.hostgroups.push 'hbase_regionserver' unless 'hbase_regionserver' in h.hostgroups
            options.services['HBase RegionServer - TCP'] ?= {}
            options.services['HBase RegionServer - TCP'].hosts ?= []
            options.services['HBase RegionServer - TCP'].hosts.push host
            options.services['HBase RegionServer - TCP'].servicegroups ?= ['hbase_regionserver']
            options.services['HBase RegionServer - TCP'].use ?= 'process-service'
            options.services['HBase RegionServer - TCP']['_process_name'] ?= 'hbase-regionserver'
            options.services['HBase RegionServer - TCP'].check_command ?= "check_tcp!#{ryba.hbase.rs.site['hbase.regionserver.port']}"
            options.services['HBase RegionServer - WebUI'] ?= {}
            options.services['HBase RegionServer - WebUI'].hosts ?= []
            options.services['HBase RegionServer - WebUI'].hosts.push host
            options.services['HBase RegionServer - WebUI'].servicegroups ?= ['hbase_regionserver']
            options.services['HBase RegionServer - WebUI'].use ?= 'unit-service'
            options.services['HBase RegionServer - WebUI'].check_command ?= "check_tcp!#{ryba.hbase.rs.site['hbase.regionserver.info.port']}!-S"
            options.services['HBase RegionServer - Certificate'] ?= {}
            options.services['HBase RegionServer - Certificate'].hosts ?= []
            options.services['HBase RegionServer - Certificate'].hosts.push host
            options.services['HBase RegionServer - Certificate'].servicegroups ?= ['hbase_regionserver']
            options.services['HBase RegionServer - Certificate'].use ?= 'cert-service'
            options.services['HBase RegionServer - Certificate'].check_command ?= "check_cert!#{ryba.hbase.rs.site['hbase.regionserver.info.port']}!120!60"
            create_dependency 'HBase RegionServer - Certificate', 'HBase RegionServer - WebUI', host
          if 'ryba/hbase/rest' in ctx.services
            w.modules.push 'hbase_rest' unless 'hbase_rest' in w.modules
            h.hostgroups.push 'hbase_rest' unless 'hbase_rest' in h.hostgroups
            options.services['HBase REST - WebService'] ?= {}
            options.services['HBase REST - WebService'].hosts ?= []
            options.services['HBase REST - WebService'].hosts.push host
            options.services['HBase REST - WebService'].servicegroups ?= ['hbase_rest']
            options.services['HBase REST - WebService'].use ?= 'process-service'
            options.services['HBase REST - WebService']['_process_name'] ?= 'hbase-rest'
            options.services['HBase REST - WebService'].check_command ?= "check_tcp!#{ryba.hbase.rest.site['hbase.rest.port']}!-S"
            options.services['HBase REST - Certificate'] ?= {}
            options.services['HBase REST - Certificate'].hosts ?= []
            options.services['HBase REST - Certificate'].hosts.push host
            options.services['HBase REST - Certificate'].servicegroups ?= ['hbase_rest']
            options.services['HBase REST - Certificate'].use ?= 'cert-service'
            options.services['HBase REST - Certificate'].check_command ?= "check_cert!#{ryba.hbase.rest.site['hbase.rest.port']}!120!60"
            create_dependency 'HBase REST - Certificate', 'HBase REST - WebService', host
            options.services['HBase REST - WebUI'] ?= {}
            options.services['HBase REST - WebUI'].hosts ?= []
            options.services['HBase REST - WebUI'].hosts.push host
            options.services['HBase REST - WebUI'].servicegroups ?= ['hbase_rest']
            options.services['HBase REST - WebUI'].use ?= 'unit-service'
            options.services['HBase REST - WebUI'].check_command ?= "check_tcp!#{ryba.hbase.rest.site['hbase.rest.info.port']}"
          if 'ryba/hbase/thrift' in ctx.services
            w.modules.push 'hbase_thrift' unless 'hbase_thrift' in w.modules
            h.hostgroups.push 'hbase_thrift' unless 'hbase_thrift' in h.hostgroups
            options.services['HBase Thrift - TCP SSL'] ?= {}
            options.services['HBase Thrift - TCP SSL'].hosts ?= []
            options.services['HBase Thrift - TCP SSL'].hosts.push host
            options.services['HBase Thrift - TCP SSL'].servicegroups ?= ['hbase_thrift']
            options.services['HBase Thrift - TCP SSL'].use ?= 'process-service'
            options.services['HBase Thrift - TCP SSL']['_process_name'] ?= 'hbase-thrift'
            options.services['HBase Thrift - TCP SSL'].check_command ?= "check_tcp!#{ryba.hbase.thrift.site['hbase.thrift.port']}!-S"
            options.services['HBase Thrift - Certificate'] ?= {}
            options.services['HBase Thrift - Certificate'].hosts ?= []
            options.services['HBase Thrift - Certificate'].hosts.push host
            options.services['HBase Thrift - Certificate'].servicegroups ?= ['hbase_thrift']
            options.services['HBase Thrift - Certificate'].use ?= 'cert-service'
            options.services['HBase Thrift - Certificate'].check_command ?= "check_cert!#{ryba.hbase.thrift.site['hbase.thrift.port']}!120!60"
            create_dependency 'HBase Thrift - Certificate', 'HBase Thrift - TCP SSL', host
          if 'ryba/hive/hcatalog' in ctx.services
            w.modules.push 'hcatalog' unless 'hcatalog' in w.modules
            h.hostgroups.push 'hcatalog' unless 'hcatalog' in h.hostgroups
            options.services['HCatalog - TCP'] ?= {}
            options.services['HCatalog - TCP'].hosts ?= []
            options.services['HCatalog - TCP'].hosts.push host
            options.services['HCatalog - TCP'].servicegroups ?= ['hcatalog']
            options.services['HCatalog - TCP'].use ?= 'process-service' #'unit-service'
            options.services['HCatalog - TCP']['_process_name'] ?= 'hive-hcatalog-server'
            options.services['HCatalog - TCP'].check_command ?= "check_tcp!#{ryba.hive.server2.site['hive.metastore.uris'].split(',')[0].split(':')[2]}"
          if 'ryba/hive/server2' in ctx.services
            w.modules.push 'hiveserver2' unless 'hiveserver2' in w.modules
            h.hostgroups.push 'hiveserver2' unless 'hiveserver2' in h.hostgroups
            options.services['Hiveserver2 - TCP SSL'] ?= {}
            options.services['Hiveserver2 - TCP SSL'].hosts ?= []
            options.services['Hiveserver2 - TCP SSL'].hosts.push host
            options.services['Hiveserver2 - TCP SSL'].servicegroups ?= ['hiveserver2']
            options.services['Hiveserver2 - TCP SSL'].use ?= 'unit-service' #'process-service'
            options.services['Hiveserver2 - TCP SSL']['_process_name'] ?= 'hive-server2'
            options.services['Hiveserver2 - TCP SSL'].check_command ?= "check_tcp!#{ryba.hive.server2.site['hive.server2.thrift.port']}!-S"
            options.services['Hiveserver2 - Certificate'] ?= {}
            options.services['Hiveserver2 - Certificate'].hosts ?= []
            options.services['Hiveserver2 - Certificate'].hosts.push host
            options.services['Hiveserver2 - Certificate'].servicegroups ?= ['hiveserver2']
            options.services['Hiveserver2 - Certificate'].use ?= 'cert-service'
            options.services['Hiveserver2 - Certificate'].check_command ?= "check_cert!#{ryba.hive.server2.site['hive.server2.thrift.port']}!120!60"
            create_dependency 'Hiveserver2 - Certificate', 'Hiveserver2 - TCP SSL', host
          if 'ryba/hive/webhcat' in ctx.services
            w.modules.push 'webhcat' unless 'webhcat' in w.modules
            h.hostgroups.push 'webhcat' unless 'webhcat' in h.hostgroups
            options.services['WebHCat - WebService'] ?= {}
            options.services['WebHCat - WebService'].hosts ?= []
            options.services['WebHCat - WebService'].hosts.push host
            options.services['WebHCat - WebService'].servicegroups ?= ['webhcat']
            options.services['WebHCat - WebService'].use ?= 'process-service'
            options.services['WebHCat - WebService']['_process_name'] ?= 'hive-webhcat-server'
            options.services['WebHCat - WebService'].check_command ?= "check_tcp!#{ryba.webhcat.site['templeton.port']}"
            options.services['WebHCat - Status'] ?= {}
            options.services['WebHCat - Status'].hosts ?= []
            options.services['WebHCat - Status'].hosts.push host
            options.services['WebHCat - Status'].servicegroups ?= ['webhcat']
            options.services['WebHCat - Status'].use ?= 'unit-service'
            options.services['WebHCat - Status'].check_command ?= "check_webhcat_status!#{ryba.webhcat.site['templeton.port']}"
            create_dependency 'WebHCat - Status', 'WebHCat - WebService', host
            options.services['WebHCat - Database'] ?= {}
            options.services['WebHCat - Database'].hosts ?= []
            options.services['WebHCat - Database'].hosts.push host
            options.services['WebHCat - Database'].servicegroups ?= ['webhcat']
            options.services['WebHCat - Database'].use ?= 'unit-service'
            options.services['WebHCat - Database'].check_command ?= "check_webhcat_database!#{ryba.webhcat.site['templeton.port']}"
            create_dependency 'WebHCat - Database', 'WebHCat - WebService', host
          if 'ryba/oozie/server' in ctx.services
            w.modules.push 'oozie_server' unless 'oozie_server' in w.modules
            h.hostgroups.push 'oozie_server' unless 'oozie_server' in h.hostgroups
            options.services['Oozie Server - WebUI'] ?= {}
            options.services['Oozie Server - WebUI'].hosts ?= []
            options.services['Oozie Server - WebUI'].hosts.push host
            options.services['Oozie Server - WebUI'].servicegroups ?= ['oozie_server']
            options.services['Oozie Server - WebUI'].use ?= 'process-service'
            options.services['Oozie Server - WebUI']['_process_name'] ?= 'oozie'
            options.services['Oozie Server - WebUI'].check_command ?= "check_tcp!#{ryba.oozie.http_port}!-S"
            options.services['Oozie Server - Certificate'] ?= {}
            options.services['Oozie Server - Certificate'].hosts ?= []
            options.services['Oozie Server - Certificate'].hosts.push host
            options.services['Oozie Server - Certificate'].servicegroups ?= ['oozie_server']
            options.services['Oozie Server - Certificate'].use ?= 'cert-service'
            options.services['Oozie Server - Certificate'].check_command ?= "check_cert!#{ryba.oozie.http_port}!120!60"
            create_dependency 'Oozie Server - Certificate', 'Oozie Server - WebUI', host
          if 'ryba/kafka/broker' in ctx.services
            w.modules.push 'kafka_broker' unless 'kafka_broker' in w.modules
            h.hostgroups.push 'kafka_broker' unless 'kafka_broker' in h.hostgroups
            for protocol in ryba.kafka.broker.protocols
              options.services["Kafka Broker - TCP #{protocol}"] ?= {}
              options.services["Kafka Broker - TCP #{protocol}"].hosts ?= []
              options.services["Kafka Broker - TCP #{protocol}"].hosts.push host
              options.services["Kafka Broker - TCP #{protocol}"].servicegroups ?= ['kafka_broker']
              options.services["Kafka Broker - TCP #{protocol}"].use ?= 'unit-service'
              options.services["Kafka Broker - TCP #{protocol}"].check_command ?= "check_tcp!#{ryba.kafka.broker.ports[protocol]}"
            options.services['Kafka Broker - TCPs'] ?= {}
            options.services['Kafka Broker - TCPs'].hosts ?= []
            options.services['Kafka Broker - TCPs'].hosts.push host
            options.services['Kafka Broker - TCPs'].servicegroups ?= ['kafka_broker']
            options.services['Kafka Broker - TCPs'].use ?= 'process-service'
            options.services['Kafka Broker - TCPs']['_process_name'] ?= 'kafka-broker'
            options.services['Kafka Broker - TCPs'].check_command ?= "bp_rule!($HOSTNAME$,r:^Kafka Broker - TCP .*$)"
          if 'ryba/ranger/admin' in ctx.services
            w.modules.push 'ranger' unless 'ranger' in w.modules
            h.hostgroups.push 'ranger' unless 'ranger' in h.hostgroups
            options.services['Ranger - WebUI'] ?= {}
            options.services['Ranger - WebUI'].hosts ?= []
            options.services['Ranger - WebUI'].hosts.push host
            options.services['Ranger - WebUI'].servicegroups ?= ['ranger']
            options.services['Ranger - WebUI'].use ?= 'process-service'
            options.services['Ranger - WebUI']['_process_name'] ?= 'ranger-admin'
            if ryba.ranger.admin.site['ranger.service.https.attrib.ssl.enabled'] is 'true'
              options.services['Ranger - WebUI'].check_command ?= "check_tcp!#{ryba.ranger.admin.site['ranger.service.https.port']}!-S"
              options.services['Ranger - Certificate'] ?= {}
              options.services['Ranger - Certificate'].hosts ?= []
              options.services['Ranger - Certificate'].hosts.push host
              options.services['Ranger - Certificate'].servicegroups ?= ['ranger']
              options.services['Ranger - Certificate'].use ?= 'cert-service'
              options.services['Ranger - Certificate'].check_command ?= "check_cert!#{ryba.ranger.admin.site['ranger.service.https.port']}!120!60"
              create_dependency 'Ranger - Certificate', 'Ranger - WebUI', host
            else
              options.services['Ranger - WebUI'].check_command ?= "check_tcp!#{ryba.ranger.admin.site['ranger.service.http.port']}"
          if 'ryba/opentsdb' in ctx.services
            w.modules.push 'opentsdb' unless 'opentsdb' in w.modules
            h.hostgroups.push 'opentsdb' unless 'opentsdb' in h.hostgroups
            options.services['OpenTSDB - WebService'] ?= {}
            options.services['OpenTSDB - WebService'].hosts ?= []
            options.services['OpenTSDB - WebService'].hosts.push host
            options.services['OpenTSDB - WebService'].servicegroups ?= ['opentsdb']
            options.services['OpenTSDB - WebService'].use ?= 'process-service'
            options.services['OpenTSDB - WebService']['_process_name'] ?= 'opentsdb'
            options.services['OpenTSDB - WebService'].check_command ?= "check_tcp!#{ryba.opentsdb.config['tsd.network.port']}"
          if 'ryba/phoenix/queryserver' in ctx.services
            w.modules.push 'phoenix_qs' unless 'phoenix_qs' in w.modules
            h.hostgroups.push 'phoenix_qs' unless 'phoenix_qs' in h.hostgroups
            options.services['Phoenix QueryServer - TCP'] ?= {}
            options.services['Phoenix QueryServer - TCP'].hosts ?= []
            options.services['Phoenix QueryServer - TCP'].hosts.push host
            options.services['Phoenix QueryServer - TCP'].servicegroups ?= ['phoenix_qs']
            options.services['Phoenix QueryServer - TCP'].use ?= 'process-service'
            options.services['Phoenix QueryServer - TCP']['_process_name'] ?= 'phoenix-queryserver'
            options.services['Phoenix QueryServer - TCP'].check_command ?= "check_tcp!#{ryba.phoenix.queryserver.site['phoenix.queryserver.http.port']}"
          if 'ryba/spark/history_server' in ctx.services
            w.modules.push 'spark_hs' unless 'spark_hs' in w.modules
            h.hostgroups.push 'spark_hs' unless 'spark_hs' in h.hostgroups
            options.services['Spark HistoryServer - WebUI'] ?= {}
            options.services['Spark HistoryServer - WebUI'].hosts ?= []
            options.services['Spark HistoryServer - WebUI'].hosts.push host
            options.services['Spark HistoryServer - WebUI'].servicegroups ?= ['spark_hs']
            options.services['Spark HistoryServer - WebUI'].use ?= 'process-service'
            options.services['Spark HistoryServer - WebUI']['_process_name'] ?= 'spark-history-server'
            options.services['Spark HistoryServer - WebUI'].check_command ?= "check_tcp!#{ryba.spark.history.conf['spark.history.ui.port']}"
          if 'ryba/spark/history_server' in ctx.services
            w.modules.push 'spark_ls' unless 'spark_ls' in w.modules
            h.hostgroups.push 'spark_ls' unless 'spark_ls' in h.hostgroups
            options.services['Spark LivyServer - WebService'] ?= {}
            options.services['Spark LivyServer - WebService'].hosts ?= []
            options.services['Spark LivyServer - WebService'].hosts.push host
            options.services['Spark LivyServer - WebService'].servicegroups ?= ['spark_ls']
            options.services['Spark LivyServer - WebService'].use ?= 'process-service'
            options.services['Spark LivyServer - WebService']['_process_name'] ?= 'spark-livy-server'
            options.services['Spark LivyServer - WebService'].check_command ?= "check_tcp!#{ryba.spark.livy.port}"
          if 'ryba/elasticsearch' in ctx.services
            w.modules.push 'elasticsearch' unless 'elasticsearch' in w.modules
            h.hostgroups.push 'elasticsearch' unless 'elasticsearch' in h.hostgroups
            options.services['ElasticSearch - WebService'] ?= {}
            options.services['ElasticSearch - WebService'].hosts ?= []
            options.services['ElasticSearch - WebService'].hosts.push host
            options.services['ElasticSearch - WebService'].servicegroups ?= ['elasticsearch']
            options.services['ElasticSearch - WebService'].use ?= 'process-service'
            options.services['ElasticSearch - WebService']['_process_name'] ?= 'elasticsearch'
            options.services['ElasticSearch - WebService'].check_command ?= 'check_tcp!9200'
            options.services['ElasticSearch - TCP'] ?= {}
            options.services['ElasticSearch - TCP'].hosts ?= []
            options.services['ElasticSearch - TCP'].hosts.push host
            options.services['ElasticSearch - TCP'].servicegroups ?= ['elasticsearch']
            options.services['ElasticSearch - TCP'].use ?= 'unit-service'
            options.services['ElasticSearch - TCP'].check_command ?= 'check_tcp!9300'
          if 'ryba/swarm/manager' in ctx.services
            w.modules.push 'swarm_manager' unless 'swarm_manager' in w.modules
            h.hostgroups.push 'swarm_manager' unless 'swarm_manager' in h.hostgroups
            options.services['Swarm Manager - TCP'] ?= {}
            options.services['Swarm Manager - TCP'].hosts ?= []
            options.services['Swarm Manager - TCP'].hosts.push host
            options.services['Swarm Manager - TCP'].servicegroups ?= ['elasticsearch']
            options.services['Swarm Manager - TCP'].use ?= 'unit-service'
            options.services['Swarm Manager - TCP'].check_command ?= "check_tcp!#{ryba.swarm.manager.listen_port}"
            if options.credentials.swarm_user.enabled
              options.services['Swarm Containers - TCPs'] ?= {}
              options.services['Swarm Containers - TCPs'].hosts ?= []
              options.services['Swarm Containers - TCPs'].hosts.push host
              options.services['Swarm Containers - TCPs'].servicegroups ?= ['elasticsearch']
              options.services['Swarm Containers - TCPs'].use ?= 'unit-service'
              options.services['Swarm Containers - TCPs'].check_command ?= "check_es_containers_tcps!#{ryba.swarm.manager.listen_port}!#{options.credentials.swarm_user.cert}!#{options.credentials.swarm_user.key}!-S"
              create_dependency 'Swarm Containers - TCPs', 'Swarm Manager - TCP', host
              options.services['Swarm Containers - Status'] ?= {}
              options.services['Swarm Containers - Status'].hosts ?= []
              options.services['Swarm Containers - Status'].hosts.push host
              options.services['Swarm Containers - Status'].servicegroups ?= ['elasticsearch']
              options.services['Swarm Containers - Status'].use ?= 'unit-service'
              options.services['Swarm Containers - Status'].check_command ?= "check_es_containers_status!#{ryba.swarm.manager.listen_port}!#{options.credentials.swarm_user.ca_cert}!#{options.credentials.swarm_user.cert}!#{options.credentials.swarm_user.key}!-S"
              create_dependency 'Swarm Containers - Status', 'Swarm Containers - TCPs', host
          if 'ryba/rexster' in ctx.services
            w.modules.push 'rexster' unless 'rexster' in w.modules
            h.hostgroups.push 'rexster' unless 'rexster' in h.hostgroups
            options.services['Rexster - WebUI'] ?= {}
            options.services['Rexster - WebUI'].hosts ?= []
            options.services['Rexster - WebUI'].hosts.push host
            options.services['Rexster - WebUI'].servicegroups ?= ['rexster']
            options.services['Rexster - WebUI'].use ?= 'process-service'
            options.services['Rexster - WebUI']['_process_name'] ?= 'rexster'
            options.services['Rexster - WebUI'].check_command ?= "check_tcp!#{ryba.rexster.config.http['server-port']}"
          if 'ryba/atlas' in ctx.services
            w.modules.push 'atlas' unless 'atlas' in w.modules
            h.hostgroups.push 'atlas' unless 'atlas' in h.hostgroups
            options.services['Atlas - WebUI'] ?= {}
            options.services['Atlas - WebUI'].hosts ?= []
            options.services['Atlas - WebUI'].hosts.push host
            options.services['Atlas - WebUI'].servicegroups ?= ['atlas']
            options.services['Atlas - WebUI'].use ?= 'process-service'
            options.services['Atlas - WebUI']['_process_name'] ?= 'atlas-metadata-server'
            if ryba.atlas.application.properties['atlas.enableTLS'] is 'true'
              options.services['Atlas - WebUI'].check_command ?= "check_tcp!#{ryba.atlas.application.properties['atlas.server.https.port']}"
              options.services['Atlas - Certificate'] ?= {}
              options.services['Atlas - Certificate'].hosts ?= []
              options.services['Atlas - Certificate'].hosts.push host
              options.services['Atlas - Certificate'].servicegroups ?= ['atlas']
              options.services['Atlas - Certificate'].use ?= 'cert-service'
              options.services['Atlas - Certificate'].check_command ?= "check_cert!#{ryba.atlas.application.properties['atlas.server.https.port']}!120!60"
              create_dependency 'Atlas - Certificate', 'Atlas - WebUI', host
            else
              options.services['Atlas - WebUI'].check_command ?= "check_tcp!#{ryba.atlas.application.properties['atlas.server.http.port']}"
          if 'ryba/huedocker' in ctx.services
            w.modules.push 'hue' unless 'hue' in w.modules
            h.hostgroups.push 'hue' unless 'hue' in h.hostgroups
            options.services['Hue - WebUI'] ?= {}
            options.services['Hue - WebUI'].hosts ?= []
            options.services['Hue - WebUI'].hosts.push host
            options.services['Hue - WebUI'].servicegroups ?= ['hue']
            options.services['Hue - WebUI'].use ?= 'process-service'
            options.services['Hue - WebUI']['_process_name'] ?= 'hue-server-docker'
            if ryba.hue_docker.ssl
              options.services['Hue - WebUI'].check_command ?= "check_tcp!#{ryba.hue_docker.ini.desktop.http_port}!-S"
              options.services['Hue - Certificate'] ?= {}
              options.services['Hue - Certificate'].hosts ?= []
              options.services['Hue - Certificate'].hosts.push host
              options.services['Hue - Certificate'].servicegroups ?= ['hue']
              options.services['Hue - Certificate'].use ?= 'cert-service'
              options.services['Hue - Certificate'].check_command ?= "check_cert!#{ryba.hue_docker.ini.desktop.http_port}!120!60"
              create_dependency 'Hue - Certificate', 'Hue - WebUI', host
            else
              options.services['Hue - WebUI'].check_command ?= "check_tcp!#{ryba.hue_docker.ini.desktop.http_port}"
          if 'ryba/knox' in ctx.services
            w.modules.push 'knox' unless 'knox' in w.modules
            h.hostgroups.push 'knox' unless 'knox' in h.hostgroups
            options.services['Knox - WebService'] ?= {}
            options.services['Knox - WebService'].hosts ?= []
            options.services['Knox - WebService'].hosts.push host
            options.services['Knox - WebService'].servicegroups ?= ['knox']
            options.services['Knox - WebService'].use ?= 'process-service'
            options.services['Knox - WebService']['_process_name'] ?= 'knox-server'
            options.services['Knox - WebService'].check_command ?= "check_tcp!#{ryba.knox.site['gateway.port']}!-S"
            options.services['Knox - Certificate'] ?= {}
            options.services['Knox - Certificate'].hosts ?= []
            options.services['Knox - Certificate'].hosts.push host
            options.services['Knox - Certificate'].servicegroups ?= ['knox']
            options.services['Knox - Certificate'].use ?= 'cert-service'
            options.services['Knox - Certificate'].check_command ?= "check_cert!#{ryba.knox.site['gateway.port']}!120!60"
            create_dependency 'Knox - Certificate', 'Knox - WebService', host
            if options.credentials.knox_user.enabled
              options.services['Knox - HBase Scan'] ?= {}
              options.services['Knox - HBase Scan'].hosts ?= []
              options.services['Knox - HBase Scan'].hosts.push host
              options.services['Knox - HBase Scan'].servicegroups ?= ['knox', 'hbase']
              options.services['Knox - HBase Scan'].use ?= 'functional-service'
              options.services['Knox - HBase Scan'].check_command ?= "check_hbase_scan!#{ryba.knox.site['gateway.port']}!hbase:meta!-S"
              create_dependency 'Knox - HBase Scan', 'Knox - WebService', host
              options.services['Knox - HBase Write'] ?= {}
              options.services['Knox - HBase Write'].hosts ?= []
              options.services['Knox - HBase Write'].hosts.push host
              options.services['Knox - HBase Write'].servicegroups ?= ['knox', 'hbase']
              options.services['Knox - HBase Write'].use ?= 'functional-service'
              options.services['Knox - HBase Write'].check_command ?= "check_hbase_write!#{ryba.knox.site['gateway.port']}!#{ryba.hbase.client.test.namespace}:monitoring!cf1!-S"
              create_dependency 'Knox - HBase Write', 'Knox - WebService', host
              options.services['Knox - HDFS Write'] ?= {}
              options.services['Knox - HDFS Write'].hosts.push host
              options.services['Knox - HDFS Write'].servicegroups ?= ['knox', 'hdfs']
              options.services['Knox - HDFS Write'].use ?= 'functional-service'
              options.services['Knox - HDFS Write'].check_command ?= "check_hdfs_write!#{ryba.knox.site['gateway.port']}!-S"
              create_dependency 'Knox - HDFS Write', 'Knox - WebService', host
          if 'ryba/nifi' in ctx.services
            {properties} = ryba.nifi.config
            w.modules.push 'nifi' unless 'nifi' in w.modules
            h.hostgroups.push 'nifi' unless 'nifi' in h.hostgroups
            # get nifi port
            options.services['NiFi - WebUI'] ?= {}
            options.services['NiFi - WebUI'].hosts ?= []
            options.services['NiFi - WebUI'].hosts.push host
            options.services['NiFi - WebUI'].servicegroups ?= ['nifi']
            options.services['NiFi - WebUI'].use ?= 'process-service'
            options.services['NiFi - WebUI']['_process_name'] ?= 'nifi'
            if properties['nifi.cluster.protocol.is.secure'] is 'true'
              options.services['NiFi - WebUI'].check_command ?= "check_tcp!#{properties['nifi.web.https.port']}!-S"
              options.services['NiFi - Certificate'] ?= {}
              options.services['NiFi - Certificate'].hosts ?= []
              options.services['NiFi - Certificate'].hosts.push host
              options.services['NiFi - Certificate'].servicegroups ?= ['nifi']
              options.services['NiFi - Certificate'].use ?= 'cert-service'
              options.services['NiFi - Certificate'].check_command ?= "check_cert!#{properties['nifi.web.https.port']}!120!60"
              create_dependency 'NiFi - Certificate', 'NiFi - WebUI', host
            else
              options.services['NiFi - WebUI'].check_command ?= "check_tcp!#{properties['nifi.web.http.port']}"
            options.services['NiFi - TCP'] ?= {}
            options.services['NiFi - TCP'].hosts ?= []
            options.services['NiFi - TCP'].hosts.push host
            options.services['NiFi - TCP'].servicegroups ?= ['nifi']
            options.services['NiFi - TCP'].use ?= 'unit-service'
            options.services['NiFi - TCP'].check_command ?= "check_tcp!#{properties['nifi.cluster.node.protocol.port']}"
            create_dependency 'NiFi - TCP', 'NiFi - WebUI', host

### Watcher services

        if 'mysql_server' in w.modules
          options.services['MySQL - Available'] ?= {}
          options.services['MySQL - Available'].hosts ?= []
          options.services['MySQL - Available'].hosts.push clustername
          options.services['MySQL - Available'].servicegroups ?= ['mysql_server']
          options.services['MySQL - Available'].use ?= 'bp-service'
          options.services['MySQL - Available'].check_command ?= bp_has_one 'MySQL - TCP', '$HOSTNAME$'
        if 'zookeeper_server' in w.modules
          options.services['Zookeeper Server - Available'] ?= {}
          options.services['Zookeeper Server - Available'].hosts ?= []
          options.services['Zookeeper Server - Available'].hosts.push clustername
          options.services['Zookeeper Server - Available'].servicegroups ?= ['zookeeper_server']
          options.services['Zookeeper Server - Available'].use ?= 'bp-service'
          options.services['Zookeeper Server - Available'].check_command ?= bp_has_quorum 'Zookeeper Server - TCP', '$HOSTNAME$'
        if 'hdfs_nn' in w.modules
          options.services['HDFS NN - Available'] ?= {}
          options.services['HDFS NN - Available'].hosts ?= []
          options.services['HDFS NN - Available'].hosts.push clustername
          options.services['HDFS NN - Available'].servicegroups ?= ['hdfs_nn']
          options.services['HDFS NN - Available'].use ?= 'bp-service'
          options.services['HDFS NN - Available'].check_command ?= bp_has_one 'HDFS NN - TCP', '$HOSTNAME$'
          options.services['HDFS NN - Active Node'] ?= {}
          options.services['HDFS NN - Active Node'].hosts ?= []
          options.services['HDFS NN - Active Node'].hosts.push clustername
          options.services['HDFS NN - Active Node'].servicegroups ?= ['hdfs_nn']
          options.services['HDFS NN - Active Node'].use ?= 'unit-service'
          options.services['HDFS NN - Active Node'].check_command ?= 'active_nn!50470!-S'
        if 'hdfs_zkfc' in w.modules
          options.services['ZKFC - Available'] ?= {}
          options.services['ZKFC - Available'].hosts ?= []
          options.services['ZKFC - Available'].hosts.push clustername
          options.services['ZKFC - Available'].servicegroups ?= ['hdfs_zkfc']
          options.services['ZKFC - Available'].use ?= 'bp-service'
          options.services['ZKFC - Available'].check_command ?= bp_has_all 'ZKFC - TCP', '$HOSTNAME$'
          create_dependency 'ZKFC - Available', 'Zookeeper Server - Available', clustername
        if 'hdfs_jn' in w.modules
          options.services['HDFS JN - Available'] ?= {}
          options.services['HDFS JN - Available'].hosts ?= []
          options.services['HDFS JN - Available'].hosts.push clustername
          options.services['HDFS JN - Available'].servicegroups ?= ['hdfs_jn']
          options.services['HDFS JN - Available'].use ?= 'bp-service'
          options.services['HDFS JN - Available'].check_command ?= bp_has_quorum 'HDFS JN - TCP SSL', '$HOSTNAME$'
        if 'hdfs_dn' in w.modules
          options.services['HDFS DN - Available'] ?= {}
          options.services['HDFS DN - Available'].hosts ?= []
          options.services['HDFS DN - Available'].hosts.push clustername
          options.services['HDFS DN - Available'].servicegroups ?= ['hdfs_dn']
          options.services['HDFS DN - Available'].use ?= 'bp-service'
          options.services['HDFS DN - Available'].check_command ?= bp_miss 3, 'HDFS DN - TCP SSL', '$HOSTNAME$'
          options.services['HDFS DN - Nodes w/ Free space'] ?= {}
          options.services['HDFS DN - Nodes w/ Free space'].hosts ?= []
          options.services['HDFS DN - Nodes w/ Free space'].hosts.push clustername
          options.services['HDFS DN - Nodes w/ Free space'].servicegroups ?= ['hdfs_dn']
          options.services['HDFS DN - Nodes w/ Free space'].use ?= 'bp-service'
          options.services['HDFS DN - Nodes w/ Free space'].check_command ?= bp_has_one 'HDFS DN - Free space', '$HOSTNAME$'
        if 'httpfs' in w.modules
          options.services['HttpFS - Available'] ?= {}
          options.services['HttpFS - Available'].hosts ?= []
          options.services['HttpFS - Available'].hosts.push clustername
          options.services['HttpFS - Available'].servicegroups ?= ['httpfs']
          options.services['HttpFS - Available'].use ?= 'bp-service'
          options.services['HttpFS - Available'].check_command ?= bp_has_one 'HttpFS - WebService', '$HOSTNAME$'
        if 'yarn_rm' in w.modules
          options.services['YARN RM - Available'] ?= {}
          options.services['YARN RM - Available'].hosts ?= []
          options.services['YARN RM - Available'].hosts.push clustername
          options.services['YARN RM - Available'].servicegroups ?= ['yarn_rm']
          options.services['YARN RM - Available'].use ?= 'bp-service'
          options.services['YARN RM - Available'].check_command ?= bp_has_one 'YARN RM - Admin TCP', '$HOSTNAME$'
          create_dependency 'YARN RM - Available', 'Zookeeper Server - Available', clustername
          options.services['YARN RM - Active Node'] ?= {}
          options.services['YARN RM - Active Node'].hosts ?= []
          options.services['YARN RM - Active Node'].hosts.push clustername
          options.services['YARN RM - Active Node'].servicegroups ?= ['hdfs_nn']
          options.services['YARN RM - Active Node'].use ?= 'unit-service'
          options.services['YARN RM - Active Node'].check_command ?= 'active_rm!8090!-S'
          create_dependency 'YARN RM - Active Node', 'YARN RM - Available', clustername
          options.services['YARN RM - TCP SSL'] ?= {}
          options.services['YARN RM - TCP SSL'].hosts ?= []
          options.services['YARN RM - TCP SSL'].hosts.push clustername
          options.services['YARN RM - TCP SSL'].servicegroups ?= ['yarn_rm']
          options.services['YARN RM - TCP SSL'].use ?= 'unit-service'
          options.services['YARN RM - TCP SSL'].check_command ?= "check_tcp_ha!'YARN RM - Active Node'!8050"
          create_dependency 'YARN RM - TCP SSL', 'YARN RM - Active Node', clustername
          options.services['YARN RM - Scheduler TCP'] ?= {}
          options.services['YARN RM - Scheduler TCP'].hosts ?= []
          options.services['YARN RM - Scheduler TCP'].hosts.push clustername
          options.services['YARN RM - Scheduler TCP'].servicegroups ?= ['yarn_rm']
          options.services['YARN RM - Scheduler TCP'].use ?= 'unit-service'
          options.services['YARN RM - Scheduler TCP'].check_command ?= "check_tcp_ha!'YARN RM - Active Node'!8030"
          create_dependency 'YARN RM - Scheduler TCP', 'YARN RM - Active Node', clustername
          options.services['YARN RM - Tracker TCP'] ?= {}
          options.services['YARN RM - Tracker TCP'].hosts ?= []
          options.services['YARN RM - Tracker TCP'].hosts.push clustername
          options.services['YARN RM - Tracker TCP'].servicegroups ?= ['yarn_rm']
          options.services['YARN RM - Tracker TCP'].use ?= 'unit-service'
          options.services['YARN RM - Tracker TCP'].check_command ?= "check_tcp_ha!'YARN RM - Active Node'!8025"
          create_dependency 'YARN RM - Tracker TCP', 'YARN RM - Active Node', clustername
          options.services['YARN RM - RPC latency'] ?= {}
          options.services['YARN RM - RPC latency'].hosts ?= []
          options.services['YARN RM - RPC latency'].hosts.push clustername
          options.services['YARN RM - RPC latency'].servicegroups ?= ['yarn_rm']
          options.services['YARN RM - RPC latency'].use ?= 'unit-service'
          options.services['YARN RM - RPC latency'].check_command ?= "check_rpc_latency_ha!'YARN RM - Active Node'!ResourceManager!8090!3000!5000!-S"
          create_dependency 'YARN RM - RPC latency', 'YARN RM - Active Node', clustername
        if 'yarn_nm' in w.modules
          options.services['YARN NM - Available'] ?= {}
          options.services['YARN NM - Available'].hosts ?= []
          options.services['YARN NM - Available'].hosts.push clustername
          options.services['YARN NM - Available'].servicegroups ?= ['yarn_nm']
          options.services['YARN NM - Available'].use ?= 'bp-service'
          options.services['YARN NM - Available'].check_command ?= bp_miss 3, 'YARN NM - TCP', '$HOSTNAME$'
        if 'hbase_master' in w.modules
          options.services['HBase Master - Available'] ?= {}
          options.services['HBase Master - Available'].hosts ?= []
          options.services['HBase Master - Available'].hosts.push clustername
          options.services['HBase Master - Available'].servicegroups ?= ['hbase_master']
          options.services['HBase Master - Available'].use ?= 'bp-service'
          options.services['HBase Master - Available'].check_command ?= bp_has_one 'HBase Master - TCP', '$HOSTNAME$'
          create_dependency 'HBase Master - Available', 'Zookeeper Server - Available', clustername
          create_dependency 'HBase Master - Available', 'HDFS - Available', clustername
          options.services['HBase Master - Active Node'] ?= {}
          options.services['HBase Master - Active Node'].hosts ?= []
          options.services['HBase Master - Active Node'].hosts.push clustername
          options.services['HBase Master - Active Node'].servicegroups ?= ['hdfs_nn']
          options.services['HBase Master - Active Node'].use ?= 'unit-service'
          options.services['HBase Master - Active Node'].check_command ?= 'active_hm!60010!-S'
          create_dependency 'HBase Master - Active Node', 'HBase Master - Available', clustername
          options.services['HBase - Unavailable Regions'] ?= {}
          options.services['HBase - Unavailable Regions'].hosts ?= []
          options.services['HBase - Unavailable Regions'].hosts.push clustername
          options.services['HBase - Unavailable Regions'].servicegroups ?= ['hbase']
          options.services['HBase - Unavailable Regions'].use ?= 'functional-service'
          options.services['HBase - Unavailable Regions'].check_command ?= 'check_hbase_unavailable_regions!60010!-S'
          options.services['HBase - Replication logs'] ?= {}
          options.services['HBase - Replication logs'].hosts ?= []
          options.services['HBase - Replication logs'].hosts.push clustername
          options.services['HBase - Replication logs'].servicegroups ?= ['hbase']
          options.services['HBase - Replication logs'].use ?= 'functional-service'
          options.services['HBase - Replication logs'].check_command ?= 'check_hdfs_content_summary!50470!/apps/hbase/data/oldWALs!spaceConsumed!824633720832!1099511627776!-S' # 768GiB | 1TiB
        if 'hbase_regionserver' in w.modules
          options.services['HBase RegionServer - Available'] ?= {}
          options.services['HBase RegionServer - Available'].hosts ?= []
          options.services['HBase RegionServer - Available'].hosts.push clustername
          options.services['HBase RegionServer - Available'].servicegroups ?= ['hbase_regionserver']
          options.services['HBase RegionServer - Available'].use ?= 'bp-service'
          options.services['HBase RegionServer - Available'].check_command ?= bp_miss '20%', 'HBase RegionServer - TCP', '$HOSTNAME$'
          create_dependency 'HBase RegionServer - Available', 'Zookeeper Server - Available', clustername
        if 'hbase_rest' in w.modules
          options.services['HBase REST - Available'] ?= {}
          options.services['HBase REST - Available'].hosts ?= []
          options.services['HBase REST - Available'].hosts.push clustername
          options.services['HBase REST - Available'].servicegroups ?= ['hbase_rest']
          options.services['HBase REST - Available'].use ?= 'bp-service'
          options.services['HBase REST - Available'].check_command ?= bp_has_one 'HBase REST - WebService', '$HOSTNAME$'
        if 'hbase_thrift' in w.modules
          options.services['HBase Thrift - Available'] ?= {}
          options.services['HBase Thrift - Available'].hosts ?= []
          options.services['HBase Thrift - Available'].hosts.push clustername
          options.services['HBase Thrift - Available'].servicegroups ?= ['hbase_thrift']
          options.services['HBase Thrift - Available'].use ?= 'bp-service'
          options.services['HBase Thrift - Available'].check_command ?= bp_has_one 'HBase Thrift - TCP SSL', '$HOSTNAME$'
        if 'hcatalog' in w.modules
          options.services['HCatalog - Available'] ?= {}
          options.services['HCatalog - Available'].hosts ?= []
          options.services['HCatalog - Available'].hosts.push clustername
          options.services['HCatalog - Available'].servicegroups ?= ['hcatalog']
          options.services['HCatalog - Available'].use ?= 'bp-service'
          options.services['HCatalog - Available'].check_command ?= bp_has_one 'HCatalog - TCP', '$HOSTNAME$'
        if 'hiveserver2' in w.modules
          options.services['Hiveserver2 - Available'] ?= {}
          options.services['Hiveserver2 - Available'].hosts ?= []
          options.services['Hiveserver2 - Available'].hosts.push clustername
          options.services['Hiveserver2 - Available'].servicegroups ?= ['hiveserver2']
          options.services['Hiveserver2 - Available'].use ?= 'bp-service'
          options.services['Hiveserver2 - Available'].check_command ?= bp_has_one 'Hiveserver2 - TCP SSL', '$HOSTNAME$'
        if 'webhcat' in w.modules
          options.services['WebHCat - Available'] ?= {}
          options.services['WebHCat - Available'].hosts ?= []
          options.services['WebHCat - Available'].hosts.push clustername
          options.services['WebHCat - Available'].servicegroups ?= ['webhcat']
          options.services['WebHCat - Available'].use ?= 'bp-service'
          options.services['WebHCat - Available'].check_command ?= bp_has_one 'WebHCat - WebService', '$HOSTNAME$'
        if 'oozie_server' in w.modules
          options.services['Oozie Server - Available'] ?= {}
          options.services['Oozie Server - Available'].hosts ?= []
          options.services['Oozie Server - Available'].hosts.push clustername
          options.services['Oozie Server - Available'].servicegroups ?= ['oozie_server']
          options.services['Oozie Server - Available'].use ?= 'bp-service'
          options.services['Oozie Server - Available'].check_command ?= bp_has_one 'Oozie Server - WebUI', '$HOSTNAME$'
        if 'kafka_broker' in w.modules
          options.services['Kafka Broker - Available'] ?= {}
          options.services['Kafka Broker - Available'].hosts ?= []
          options.services['Kafka Broker - Available'].hosts.push clustername
          options.services['Kafka Broker - Available'].servicegroups ?= ['kafka_broker']
          options.services['Kafka Broker - Available'].use ?= 'bp-service'
          options.services['Kafka Broker - Available'].check_command ?= bp_has_one 'Kafka Broker - TCPs', '$HOSTNAME$'
          create_dependency 'Kafka Broker - Available', 'Zookeeper Server - Available', clustername
        if 'opentsdb' in w.modules
          options.services['OpenTSDB - Available'] ?= {}
          options.services['OpenTSDB - Available'].hosts ?= []
          options.services['OpenTSDB - Available'].hosts.push clustername
          options.services['OpenTSDB - Available'].servicegroups ?= ['opentsdb']
          options.services['OpenTSDB - Available'].use ?= 'bp-service'
          options.services['OpenTSDB - Available'].check_command ?= bp_has_one 'OpenTSDB - WebService', '$HOSTNAME$'
          create_dependency 'OpenTSDB - Available', 'HBase - Available', clustername
        if 'phoenix_qs' in w.modules
          options.services['Phoenix QueryServer - Available'] ?= {}
          options.services['Phoenix QueryServer - Available'].hosts ?= []
          options.services['Phoenix QueryServer - Available'].hosts.push clustername
          options.services['Phoenix QueryServer - Available'].servicegroups ?= ['phoenix_qs']
          options.services['Phoenix QueryServer - Available'].use ?= 'bp-service'
          options.services['Phoenix QueryServer - Available'].check_command ?= bp_has_one 'Phoenix QueryServer - TCP', '$HOSTNAME$'
          create_dependency 'Phoenix QueryServer - Available', 'HBase - Available', clustername
        if 'spark_hs' in w.modules
          options.services['Spark HistoryServer - Available'] ?= {}
          options.services['Spark HistoryServer - Available'].hosts ?= []
          options.services['Spark HistoryServer - Available'].hosts.push clustername
          options.services['Spark HistoryServer - Available'].servicegroups ?= ['spark_qs']
          options.services['Spark HistoryServer - Available'].use ?= 'bp-service'
          options.services['Spark HistoryServer - Available'].check_command ?= bp_has_one 'Spark HistoryServer - TCP', '$HOSTNAME$'
        if 'spark_ls' in w.modules
          options.services['Spark LivyServer - Available'] ?= {}
          options.services['Spark LivyServer - Available'].hosts ?= []
          options.services['Spark LivyServer - Available'].hosts.push clustername
          options.services['Spark LivyServer - Available'].servicegroups ?= ['spark_ls']
          options.services['Spark LivyServer - Available'].use ?= 'bp-service'
          options.services['Spark LivyServer - Available'].check_command ?= bp_has_one 'Spark LivyServer - TCP', '$HOSTNAME$'  
        if 'elasticsearch' in w.modules
          options.services['ElasticSearch - Available'] ?= {}
          options.services['ElasticSearch - Available'].hosts ?= []
          options.services['ElasticSearch - Available'].hosts.push clustername
          options.services['ElasticSearch - Available'].servicegroups ?= ['elasticsearch']
          options.services['ElasticSearch - Available'].use ?= 'bp-service'
          options.services['ElasticSearch - Available'].check_command ?= bp_has_quorum 'ElasticSearch - TCP', '$HOSTNAME$'
        if 'atlas' in w.modules
          options.services['Atlas - Available'] ?= {}
          options.services['Atlas - Available'].hosts ?= []
          options.services['Atlas - Available'].hosts.push clustername
          options.services['Atlas - Available'].servicegroups ?= ['atlas']
          options.services['Atlas - Available'].use ?= 'bp-service'
          options.services['Atlas - Available'].check_command ?= bp_has_one 'Atlas - WebUI', '$HOSTNAME$'
        if 'ranger' in w.modules
          options.services['Ranger - Available'] ?= {}
          options.services['Ranger - Available'].hosts ?= []
          options.services['Ranger - Available'].hosts.push clustername
          options.services['Ranger - Available'].servicegroups ?= ['ranger']
          options.services['Ranger - Available'].use ?= 'bp-service'
          options.services['Ranger - Available'].check_command ?= bp_has_one 'Ranger - WebUI', '$HOSTNAME$'
        if 'knox' in w.modules
          options.services['Knox - Available'] ?= {}
          options.services['Knox - Available'].hosts ?= []
          options.services['Knox - Available'].hosts.push clustername
          options.services['Knox - Available'].servicegroups ?= ['knox']
          options.services['Knox - Available'].use ?= 'bp-service'
          options.services['Knox - Available'].check_command ?= bp_has_one 'Knox - WebService', '$HOSTNAME$'
        if 'hue' in w.modules
          options.services['Hue - Available'] ?= {}
          options.services['Hue - Available'].hosts ?= []
          options.services['Hue - Available'].hosts.push clustername
          options.services['Hue - Available'].servicegroups ?= ['hue']
          options.services['Hue - Available'].use ?= 'bp-service'
          options.services['Hue - Available'].check_command ?= bp_has_one 'Hue - WebUI', '$HOSTNAME$'
        if 'nifi' in w.modules
          options.services['NiFi - Available'] ?= {}
          options.services['NiFi - Available'].hosts ?= []
          options.services['NiFi - Available'].hosts.push clustername
          options.services['NiFi - Available'].servicegroups ?= ['nifi']
          options.services['NiFi - Available'].use ?= 'bp-service'
          options.services['NiFi - Available'].check_command ?= bp_has_quorum 'NiFi - WebUI', '$HOSTNAME$'
        options.services['Hadoop - CORE'] ?= {}
        options.services['Hadoop - CORE'].hosts ?= []
        options.services['Hadoop - CORE'].hosts.push clustername
        options.services['Hadoop - CORE'].servicegroups ?= ['hadoop']
        options.services['Hadoop - CORE'].use ?= 'bp-service'
        options.services['Hadoop - CORE'].check_command ?= "bp_rule!(100%,1,1 of: $HOSTNAME$,YARN - Available & $HOSTNAME$,HDFS - Available & $HOSTNAME$,Zookeeper Server - Available)"
        options.services['HDFS - Available'] ?= {}
        options.services['HDFS - Available'].hosts ?= []
        options.services['HDFS - Available'].hosts.push clustername
        options.services['HDFS - Available'].servicegroups ?= ['hdfs']
        options.services['HDFS - Available'].use ?= 'bp-service'
        options.services['HDFS - Available'].check_command ?= "bp_rule!($HOSTNAME$,HDFS NN - Available & $HOSTNAME$,HDFS DN - Available & $HOSTNAME$,HDFS JN - Available)"
        options.services['YARN - Available'] ?= {}
        options.services['YARN - Available'].hosts ?= []
        options.services['YARN - Available'].hosts.push clustername
        options.services['YARN - Available'].servicegroups ?= ['yarn']
        options.services['YARN - Available'].use ?= 'bp-service'
        options.services['YARN - Available'].check_command ?= "bp_rule!($HOSTNAME$,YARN RM - Available & $HOSTNAME$,YARN NM - Available)"
        options.services['HBase - Available'] ?= {}
        options.services['HBase - Available'].hosts ?= []
        options.services['HBase - Available'].hosts.push clustername
        options.services['HBase - Available'].servicegroups ?= ['yarn']
        options.services['HBase - Available'].use ?= 'bp-service'
        options.services['HBase - Available'].check_command ?= "bp_rule!($HOSTNAME$,HBase Master - Available & $HOSTNAME$,HBase RegionServer - Available)"
        options.services['Cluster Availability'] ?= {}
        options.services['Cluster Availability'].hosts ?= []
        options.services['Cluster Availability'].hosts.push clustername
        options.services['Cluster Availability'].use ?= 'bp-service'
        options.services['Cluster Availability'].check_command ?= bp_has_all '.*Available', '$HOSTNAME$'

      if options.contexts?
        for clustername, ctx_dir of options.contexts
          from_contexts.call @, glob.sync("#{ctx_dir}/*").map((f) -> require f), clustername
      else
        from_contexts.call @, @contexts '**'

## Normalize

      # HostGroups
      for name, group of options.hostgroups
        group.alias ?= name
        group.members ?= []
        group.members = [group.members] unless Array.isArray group.members
        group.hostgroup_members ?= []
        group.hostgroup_members = [group.hostgroup_members] unless Array.isArray group.hostgroup_members
      # Disable host membership !
      options.hostgroups.by_roles.members = []
      # Hosts
      for name, host of options.hosts
        host.alias ?= name
        host.use ?= 'generic-host'
        host.hostgroups ?= []
        host.hostgroups = [host.hostgroups] unless Array.isArray host.hostgroups
      # ServiceGroups
      for name, group of options.servicegroups
        group.alias ?= "#{name.charAt(0).toUpperCase()}#{name.slice 1}"
        group.members ?= []
        group.members = [group.members] unless Array.isArray group.members
        group.servicegroup_members ?= []
        group.servicegroup_members = [group.servicegroup_members] unless Array.isArray group.servicegroup_members
      for name, service of options.services
        service.escalations = [service.escalations] if service.escalations? and not Array.isArray service.escalations
        service.servicegroups = [service.servicegroups] if service.servicegroups? and not Array.isArray service.servicegroups
      # Realm
      default_realm = false
      for name, realm of options.realms
        realm.members ?= []
        realm.members = [realm.members] unless Array.isArray realm.members
        if realm.default is '1'
          throw Error 'Multiple default Realms detected. Please fix the configuration' if default_realm
          default_realm = true
        else realm.default = '0'
      options.realms.All.default = '1' unless default_realm
      options.realms.All.members ?= k unless k is 'All' for k in Object.keys options.realms
      # ContactGroups
      for name, group of options.contactgroups
        group.alias ?= name
        group.members ?= []
        group.members = [group.members] unless Array.isArray group.members
        group.contactgroup_members ?= []
        group.contactgroup_members = [group.contactgroup_members] unless Array.isArray group.contactgroup_members
      # Contacts
      for name, contact of options.contacts
        contact.alias ?= name
        contact.contactgroups ?= []
        contact.use ?= 'generic-contact'
        contact.contactgroups = [contact.contactgroups] unless Array.isArray contact.contactgroups
      # Dependencies
      for name, dep of options.dependencies
        throw Error "Unvalid dependency #{name}, please provide hosts or hostsgroups" unless dep.hosts? or dep.hostgroups?
        throw Error "Unvalid dependency #{name}, please provide dependent_hosts or dependent_hostsgroups" unless dep.dependent_hosts? or dep.dependent_hostgroups?
        throw Error "Unvalid dependency #{name}, please provide service" unless dep.service?
        throw Error "Unvalid dependency #{name}, please provide dependent_service" unless dep.dependent_service?
      # Escalations
      for name, esc of options.serviceescalations
        throw Error "Unvalid escalation #{name}, please provide hosts or hostsgroups" unless esc.hosts? or esc.hostgroups?
        throw Error "Unvalid escalation #{name}, please provide contacts or contactgroups" unless esc.contacts? or esc.contactgroups?
        throw Error "Unvalid escalation #{name}, please provide first_notification or first_notification_time" unless esc.first_notification? or esc.first_notification_time?
        throw Error "Unvalid escalation #{name}, please provide last_notification or last_notification_time" unless esc.last_notification? or esc.last_notification_time?
        esc.hosts = [esc.hosts] unless Array.isArray esc.hosts
        esc.hostgroups = [esc.hostgroups] unless Array.isArray esc.hostgroups
        esc.contacts = [esc.contacts] unless Array.isArray esc.contacts
        esc.contactgroups = [esc.contactgroups] unless Array.isArray esc.contactgroups
      for name, esc of options.escalations
        throw Error "Unvalid escalation #{name}, please provide contacts or contactgroups" unless esc.contacts? or esc.contactgroups?
        throw Error "Unvalid escalation #{name}, please provide first_notification or first_notification_time" unless esc.first_notification? or esc.first_notification_time?
        throw Error "Unvalid escalation #{name}, please provide last_notification or last_notification_time" unless esc.last_notification? or esc.last_notification_time?
        esc.contacts = [esc.contacts] unless Array.isArray esc.contacts
        esc.contactgroups = [esc.contactgroups] unless Array.isArray esc.contactgroups
      # Timeperiods
      for name, period of options.timeperiods
        period.alias ?= name
        period.time ?= {}

## Dependencies

    fs = require 'fs'
    glob = require 'glob'
    {merge} = require 'nikita/lib/misc'
    path = require 'path'

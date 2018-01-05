
# Configure Monitoring Objects

    module.exports = (service) ->
      options = service.options

## Credentials

"credentials" object contains credentials for components that use authentication.
If a credential is disabled, tests that need this credential will be disabled.

      options.credentials ?= {}
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
      options.services['generic-service'].max_check_attempts ?= '3'
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

      create_dependency = (s1, s2, h1, h2) ->
        h2 ?= h1
        dep = options.dependencies["#{s1} / #{s2}"] ?= {}
        dep.service ?= s2
        dep.dependent_service ?= s1
        if Array.isArray h2
          dep.hosts ?= []
          dep.hosts.push h2...
        else
          dep.hosts ?= [h2]
        if Array.isArray h1
          dep.dependent_hosts ?= []
          dep.dependent_hosts.push h1...
        else
          dep.dependent_hosts ?= [h1] 
        dep.inherits_parent ?= '1'
        dep.execution_failure_criteria ?= 'c,u,p'
        dep.notification_failure_criteria ?= 'c,u,p'

## Configure from service

This function is called with a context, taken from internal context, or imported.
An external configuration can be obtained with an instance of ryba using
'configure' command

Theses functions are used to generate business rules

      bp_miss = (n, name, g) -> "bp_rule!(100%,1,-#{n} of: #{ if g? then "g:#{g}" else '*'},r:^#{name}?)"
      bp_has_quorum = (name, g) -> "bp_rule!(100%,1,50% of: #{ if g? then "g:#{g}" else '*'},r:^#{name}?)"
      bp_has_one = (name, g) -> "bp_rule!(100%,1,100% of: #{ if g? then "g:#{g}" else '*'},r:^#{name}?)"
      bp_has_all = (name, g) -> "bp_rule!(100%,1,1 of: #{ if g? then "g:#{g}" else '*'},r:^#{name}?)"
      #bp_has_percent = (name, w, c, g) -> "bp_rule!(100%,#{w}%,#{c}% of: #{ if g? then "g:#{g}" else '*'},r:^#{name}?)"


## Declare Services

      add_hostgroup_to_host = (hostgroup, fqdn) ->
        
      

      from_nodes = (nodes, clustername, config) ->
        
        # clustername ?= ctxs[0].config.ryba.nameservice or 'default'
        options.clusters[clustername] ?= {}
        options.hostgroups[clustername] ?= {}
        options.hostgroups[clustername].members ?= []
        options.hostgroups[clustername].members = [options.hostgroups[clustername].members] unless Array.isArray options.hostgroups[clustername].members
        options.hostgroups[clustername].hostgroup_members ?= []
        options.hostgroups[clustername].hostgroup_members = [options.hostgroups[clustername].hostgroup_members] unless Array.isArray options.hostgroups[clustername].hostgroup_members
        options.hostgroups.by_topology.hostgroup_members.push clustername unless clustername in options.hostgroups.by_topology.hostgroup_members
        # Watchers -> Special host with name of the cluster, for cluster business rules
        options.hosts[clustername] ?= {}
        options.hosts[clustername].ip = '0.0.0.0'
        options.hosts[clustername].alias = "#{clustername} Watcher"
        options.hosts[clustername].hostgroups = ['watcher']
        options.hosts[clustername].use = 'aggregates'
        options.hosts[clustername].cluster ?= clustername
        options.hosts[clustername].notes ?= clustername
        options.hosts[clustername].realm = options.clusters[clustername].realm if options.clusters[clustername].realm?
        options.hosts[clustername].modules ?= []
        options.hosts[clustername].modules = [options.hosts[clustername].modules] unless Array.isArray options.hosts[clustername].modules
        options.hostgroups[clustername].members.push clustername
        
### Declare Services
The service discovery is now update to work with masson2. its based on services oobject
from normzlized configuration.
        
        s = store config
        # init hostsgroups
        for fqdn, node of nodes
          host = fqdn
          options.hostgroups[clustername].members.push host
          options.hosts[fqdn] ?= {}
          options.hosts[fqdn].ip ?= node.ip
          options.hosts[fqdn].hostgroups ?= []
          options.hosts[fqdn].hostgroups = [options.hosts[fqdn].hostgroups] unless Array.isArray options.hosts[fqdn].hostgroups
          options.hosts[fqdn].use ?= 'linux-server'
          #options.hosts[fqdn].config ?= ctx.config
          options.hosts[fqdn].realm ?= options.clusters[clustername].realm
          options.hosts[fqdn].cluster ?= clustername
          options.hosts[fqdn].notes ?= clustername
        for name, service of config.clusters[clustername].services
          srv =  s.service(clustername,name)
        # True Servers
        # return

###  Declare services

          add_hosts_to_srv = (srvname, instances) ->
            options.services[srvname].hosts ?= []
            for instance in instances
              options.services[srvname].hosts.push instance.node.fqdn unless instance.node.fqdn in options.services[srvname].hosts
          add_srv_to_host_hostgroups = (srvname, instances) ->
            for instance in instances
              options.hosts[instance.node.fqdn].hostgroups ?= []
              options.hosts[instance.node.fqdn].hostgroups.push srvname unless srvname in options.hosts[instance.node.fqdn].hostgroups
          add_srv_to_cluster = (srvname, clustername) ->
            options.hosts[clustername].modules.push srvname unless srvname in options.hosts[clustername].modules
          create_service = (opts) ->
            throw Error "Missing service name" unless opts.name?
            throw Error "Missing service instances" unless opts.instances?
            throw Error "Missing service servicegroup" unless opts.servicegroup?
            throw Error "Missing service use" unless opts.use?
            throw Error "Missing service process_name" if (opts.use is 'process-service') and (!opts.process_name?)
            throw Error "Missing service check_command" unless opts.check_command?
            throw Error "use is unkown" if options.use? and options?.use not in ['process-service','unit-service','functional-service']
            options.services[opts.name] ?= {}
            options.services[opts.name].hosts ?= []
            options.services[opts.name].hosts.push opts.instances.map( (instance) -> instance.node.fqdn )...
            opts.servicegroup = [opts.servicegroup] unless Array.isArray opts.servicegroup
            options.services[opts.name].servicegroups ?= opts.servicegroup
            options.services[opts.name].use ?= opts.use
            options.services[opts.name]['_process_name'] ?= opts.process_name
            options.services[opts.name].check_command ?= opts.check_command

          # TODO: put ryba.db_admin username/password
          if 'masson/commons/mysql/server' is srv.module
            add_srv_to_cluster 'mysql_server', clustername
            add_srv_to_host_hostgroups  'mysql_server', srv.instances
            create_service
              name: 'MySQL - TCP'
              servicegroup: 'mysql_server'
              instances: srv.instances
              use: 'process-service'
              process_name: 'mysqld'
              check_command: "check_tcp!#{srv.instances[0].options.my_cnf['mysqld']['port']}"
            if options.credentials.sql_user.enabled
              create_service
                name: 'MySQL - Connection time'
                servicegroup: 'mysql_server'
                instances: srv.instances
                use: 'unit-service'
                check_command: "check_mysql!#{srv.instances[0].options.my_cnf['mysqld']['port']}!connection-time!3!10"
              #slow queries
              create_service
                name: 'MySQL - Slow queries'
                servicegroup: 'mysql_server'
                instances: srv.instances
                use: 'functional-service'
                check_command: "check_mysql!#{srv.instances[0].options.my_cnf['mysqld']['port']}!slow-queries!0,25!1"
              create_dependency 'MySQL - Slow queries', 'MySQL - TCP', srv.instances[0].node.fqdn
              #slave lag
              if srv.instances.length > 1
                create_service
                  name: 'MySQL - Slave lag'
                  servicegroup: 'mysql_server'
                  instances: srv.instances
                  use: 'unit-service'
                  check_command: "check_mysql!#{srv.instances[0].options.my_cnf['mysqld']['port']}!slave-lag!3!10"
                create_dependency 'MySQL - Slave lag', 'MySQL - TCP', srv.instances[0].node.fqdn
                #slave io replication
                create_service
                  name: 'MySQL - Slave IO running'
                  servicegroup: 'mysql_server'
                  instances: srv.instances
                  use: 'unit-service'
                  check_command: "check_mysql!#{srv.instances[0].options.my_cnf['mysqld']['port']}!slave-io-running!1!1"
                create_dependency 'MySQL - Slave IO running', 'MySQL - TCP', srv.instances[0].node.fqdn
              # connected threads
                create_service
                  name: 'MySQL - Slave lag'
                  servicegroup: 'mysql_server'
                  instances: srv.instances
                  use: 'unit-service'
                  check_command: "check_mysql!#{srv.instances[0].options.my_cnf['mysqld']['port']}!threads-connected!100!120"
              create_dependency 'MySQL - Connected Threads', 'MySQL - TCP', srv.instances[0].node.fqdn
          # TODO: put db_admin username/password
          if 'masson/commons/mariadb/server' is srv.module
            add_srv_to_cluster 'mariadb_server', clustername
            add_srv_to_host_hostgroups  'mariadb_server', srv.instances
            #TCP
            create_service
              name: 'MariaDB - TCP'
              servicegroup: 'mysql_server'
              instances: srv.instances
              use: 'process-service'
              process_name: 'mariadb'
              check_command: "check_tcp!#{srv.instances[0].options.my_cnf['mysqld']['port']}"
            if options.credentials.sql_user.enabled
              create_service
                name: 'MariaDB - Connection time'
                servicegroup: 'mysql_server'
                instances: srv.instances
                use: 'unit-service'
                check_command: "check_mysql!#{srv.instances[0].options.my_cnf['mysqld']['port']}!connection-time!3!10"
              create_dependency 'MariaDB - Connection time', 'MariaDB - TCP', srv.instances[0].node.fqdn
              # mariadb replication slow queries lag
              if srv.instances.length > 1
                create_service
                  name: 'MariaDB - Slow queries'
                  servicegroup: 'mysql_server'
                  instances: srv.instances
                  use: 'functional-service'
                  check_command: "check_mysql!#{srv.instances[0].options.my_cnf['mysqld']['port']}!slow-queries!0,25!1"
                create_dependency 'MariaDB - Slow queries', 'MariaDB - TCP', srv.instances[0].node.fqdn
                # mariadb replication slave lag
                create_service
                  name: 'MariaDB - Slave lag'
                  servicegroup: 'mysql_server'
                  instances: srv.instances
                  use: 'unit-service'
                  check_command: "check_mysql!#{srv.instances[0].options.my_cnf['mysqld']['port']}!slave-lag!3!10"
                create_dependency 'MariaDB - Slave lag', 'MariaDB - TCP', srv.instances[0].node.fqdn
                #Slave io
                create_service
                  name: 'MariaDB - Slave IO running'
                  servicegroup: 'mysql_server'
                  instances: srv.instances
                  use: 'unit-service'
                  check_command: "check_mysql!#{srv.instances[0].options.my_cnf['mysqld']['port']}!slave-io-running!1!1"
                create_dependency 'MariaDB - Slave IO running', 'MariaDB - TCP', srv.instances[0].node.fqdn
              #Connected Threads
              create_service
                name: 'MariaDB - Connected Threads'
                servicegroup: 'mysql_server'
                instances: srv.instances
                use: 'unit-service'
                check_command: "check_mysql!#{srv.instances[0].options.my_cnf['mysqld']['port']}!threads-connected!100!120"
              create_dependency 'MariaDB - Connected Threads', 'MariaDB - TCP', srv.instances[0].node.fqdn
          if 'ryba/zookeeper/server' is srv.module
            add_srv_to_cluster 'zookeeper_server', clustername
            add_srv_to_host_hostgroups  'zookeeper_server', srv.instances
            create_service
              name: 'Zookeeper Server - TCP'
              servicegroup: 'zookeeper_server'
              instances: srv.instances
              use: 'process-service'
              process_name: 'zookeeper-server'
              check_command: "check_tcp!#{srv.instances[0].options.config.clientPort}"
            # Zookeeper State
            create_service
              name: 'Zookeeper Server - State'
              servicegroup: 'zookeeper_server'
              instances: srv.instances
              use: 'unit-service'
              check_command: "check_socket!#{srv.instances[0].options.config.clientPort}!ruok!imok"
            create_dependency 'Zookeeper Server - State', 'Zookeeper Server - TCP', srv.instances[0].node.fqdn
            # Zookeeper connection
            create_service
              name: 'Zookeeper Server - Connections'
              servicegroup: 'zookeeper_server'
              instances: srv.instances
              use: 'unit-service'
              check_command: "check_zk_stat!#{srv.instances[0].options.config.clientPort}!connections!300!350"
            create_dependency 'Zookeeper Server - Connections', 'Zookeeper Server - TCP', srv.instances[0].node.fqdn
          if 'ryba/hadoop/hdfs_nn' is srv.module
            add_srv_to_cluster 'hdfs_nn', clustername
            add_srv_to_host_hostgroups  'hdfs_nn', srv.instances
            # read rpc port for hdfs nn
            protocol = if srv.instances[0].options.hdfs_site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
            nameservice = if srv.instances[0].options.nameservice then ".#{srv.instances[0].options.nameservice}" else ''
            shortname = if srv.instances[0].options.nameservice then ".#{srv.instances[0].options.hostname}" else ''
            address_rpc = srv.instances[0].options.hdfs_site["dfs.namenode.rpc-address#{nameservice}#{shortname}"]
            [_, rpc_port] = address_rpc.split ':'
            address = srv.instances[0].options.hdfs_site["dfs.namenode.#{protocol}-address#{nameservice}#{shortname}"]
            [_, port] = address.split ':'
            # TCP Port
            create_service
              name: 'HDFS NN - TCP'
              servicegroup: 'hdfs_nn'
              instances: srv.instances
              use: 'process-service'
              process_name: 'hadoop-hdfs-namenode'
              check_command:  "check_tcp!#{rpc_port}"
            create_service
              name: 'HDFS NN - WebService'
              servicegroup: 'hdfs_nn'
              instances: srv.instances
              use: 'unit-service'
              check_command:  "check_tcp!#{port}!-S"
            create_dependency 'HDFS NN - WebService', 'HDFS NN - TCP', srv.instances[0].node.fqdn
            # certificate
            create_service
              name: 'HDFS NN - Certificate'
              servicegroup: 'hdfs_nn'
              instances: srv.instances
              use: 'cert-service'
              check_command: "check_cert!#{port}!120!60"
            create_dependency 'HDFS NN - Certificate', 'HDFS NN - WebService', srv.instances[0].node.fqdn
            # Safe Mode
            create_service
              name: 'HDFS NN - Safe Mode'
              servicegroup: 'hdfs_nn'
              instances: srv.instances
              use: 'unit-service'
              check_command: "check_hdfs_safemode!#{port}!-S"
            create_dependency 'HDFS NN - Safe Mode', 'HDFS NN - WebService', srv.instances[0].node.fqdn
            # Latency
            create_service
              name: 'HDFS NN - RPC latency'
              servicegroup: 'hdfs_nn'
              instances: srv.instances
              use: 'unit-service'
              check_command: "check_rpc_latency!NameNode!#{port}!3000!5000!-S"
            create_dependency 'HDFS NN - RPC latency', 'HDFS NN - WebService', srv.instances[0].node.fqdn
            # Last Checkpoint
            create_service
              name: 'HDFS NN - Last checkpoint'
              servicegroup: 'hdfs_nn'
              instances: srv.instances
              use: 'unit-service'
              check_command: "check_nn_last_checkpoint!#{port}!21600!1000000!120%!200%!-S"
            create_dependency 'HDFS NN - RPC latency', 'HDFS NN - WebService', srv.instances[0].node.fqdn
            # Name dir status
            create_service
              name: 'HDFS NN - Name Dir status'
              servicegroup: 'hdfs_nn'
              instances: srv.instances
              use: 'unit-service'
              check_command:"check_nn_namedirs_status!#{port}!-S"
            create_dependency 'HDFS NN - Name Dir status', 'HDFS NN - WebService', srv.instances[0].node.fqdn
            # Utilization
            create_service
              name: 'HDFS NN - Utilization'
              servicegroup: 'hdfs_nn'
              instances: srv.instances
              use: 'unit-service'
              check_command: "check_hdfs_capacity!#{port}!80%!90%!-S"
            create_dependency 'HDFS NN - Utilization', 'HDFS NN - WebService', srv.instances[0].node.fqdn
            # Under replicated block
            create_service
              name: 'HDFS NN - UnderReplicated blocks'
              servicegroup: 'hdfs_nn'
              instances: srv.instances
              use: 'unit-service'
              check_command: "check_hdfs_state!#{port}!FSNamesystemState!UnderReplicatedBlocks!1000!2000!-S"
            create_dependency 'HDFS NN - UnderReplicated blocks', 'HDFS NN - WebService', srv.instances[0].node.fqdn
          # HDFS JN
          if 'ryba/hadoop/hdfs_jn' is srv.module
            add_srv_to_cluster 'hdfs_jn', clustername
            add_srv_to_host_hostgroups  'hdfs_jn', srv.instances
            # TCP Port
            protocol = if srv.instances[0].options.hdfs_site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
            port = srv.instances[0].options.hdfs_site["dfs.journalnode.#{protocol}-address"].split(':')[1]
            create_service
              name: 'HDFS JN - TCP SSL'
              servicegroup: 'hdfs_jn'
              instances: srv.instances
              use: 'process-service'
              process_name: 'hadoop-hdfs-journalnode'
              check_command: "check_tcp!#{port}!-S"
            # Certificate
            create_service
              name: 'HDFS JN - Certificate'
              servicegroup: 'hdfs_jn'
              instances: srv.instances
              use: 'cert-service'
              process_name: 'hadoop-hdfs-journalnode'
              check_command: "check_cert!#{port}!120!60"
            create_dependency 'HDFS JN - Certificate', 'HDFS JN - TCP SSL', srv.instances[0].node.fqdn
          if 'ryba/hadoop/hdfs_dn' is srv.module
            add_srv_to_cluster 'hdfs_dn', clustername
            add_srv_to_host_hostgroups  'hdfs_dn', srv.instances
            # TCP Port
            protocol = if srv.instances[0].options.hdfs_site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
            port = srv.instances[0].options.hdfs_site["dfs.datanode.#{protocol}.address"].split(':')[1]
            create_service
              name: 'HDFS DN - TCP SSL'
              servicegroup: 'hdfs_dn'
              instances: srv.instances
              use: 'process-service'
              process_name: 'hadoop-hdfs-datanode'
              check_command: "check_tcp!#{port}!-S"
            # Certificate
            create_service
              name: 'HDFS DN - Certificate'
              servicegroup: 'hdfs_dn'
              instances: srv.instances
              use: 'cert-service'
              check_command: "check_cert!#{port}!120!60"
            create_dependency 'HDFS DN - Certificate', 'HDFS DN - TCP SSL', srv.instances[0].node.fqdn
            #Free space
            create_service
              name: 'HDFS DN - Free space'
              servicegroup: 'hdfs_dn'
              instances: srv.instances
              use: 'unit-service'
              check_command: "check_dn_storage!#{port}!75%!90%!-S"
            create_dependency 'HDFS DN - Free space', 'HDFS DN - TCP SSL', srv.instances[0].node.fqdn
          if 'ryba/hadoop/zkfc' is srv.module
            add_srv_to_cluster 'hdfs_zkfc', clustername
            add_srv_to_host_hostgroups  'hdfs_zkfc', srv.instances
            # TCP Port
            create_service
              name: 'ZKFC - TCP'
              servicegroup: 'hdfs_zkfc'
              instances: srv.instances
              use: 'process-service'
              process_name: 'hadoop-hdfs-zkfc'
              check_command: "check_tcp!#{srv.instances[0].options.hdfs_site['dfs.ha.zkfc.port']}"
          if 'ryba/hadoop/httpfs' is srv.module
            add_srv_to_cluster 'httpfs', clustername
            add_srv_to_host_hostgroups  'httpfs', srv.instances
            # Webservice
            create_service
              name: 'HttpFS - WebService'
              servicegroup: 'httpfs'
              instances: srv.instances
              use: 'process-service'
              process_name: 'hadoop-httpfs'
              check_command: "check_tcp!#{srv.instances[0].options.http_port}"
            # Certificate
            create_service
              name: 'HttpFS - Certificate'
              servicegroup: 'httpfs'
              instances: srv.instances
              use: 'cert-service'
              check_command: "check_cert!#{srv.instances[0].options.http_port}!120!60"
            create_dependency 'HttpFS - Certificate', 'HttpFS - WebService', srv.instances[0].node.fqdn
          if 'ryba/hadoop/yarn_rm' is srv.module
            add_srv_to_cluster 'yarn_rm', clustername
            add_srv_to_host_hostgroups  'yarn_rm', srv.instances
            # Admin TCP
            create_service
              name: 'YARN RM - Admin TCP'
              servicegroup: 'yarn_rm'
              instances: srv.instances
              use: 'process-service'
              process_name: 'hadoop-yarn-resourcemanager'
              check_command: "check_tcp!8141"
            # WebService
            create_service
              name: 'YARN RM - WebService'
              servicegroup: 'yarn_rm'
              instances: srv.instances
              use: 'unit-service'
              check_command: 'check_tcp!8090!-S'
            # Certificate
            create_service
              name: 'YARN RM - Certificate'
              servicegroup: 'yarn_rm'
              instances: srv.instances
              use: 'unit-service'
              check_command: "check_cert!8090!120!60"
            create_dependency 'YARN RM - Certificate', 'YARN RM - WebService', srv.instances[0].node.fqdn
          if 'ryba/hadoop/yarn_nm' is srv.module
            add_srv_to_cluster 'yarn_nm', clustername
            add_srv_to_host_hostgroups  'yarn_nm', srv.instances
            # TCP Port
            create_service
              name: 'YARN NM - TCP'
              servicegroup: 'yarn_nm'
              instances: srv.instances
              use: 'process-service'
              process_name: 'hadoop-yarn-nodemanager'
              check_command: "check_tcp!45454"
            # WebService
            create_service
              name: 'YARN NM - WebService'
              servicegroup: 'yarn_nm'
              instances: srv.instances
              use: 'unit-service'
              check_command: 'check_tcp!8044!-S'
            # Certificate
            create_service
              name: 'YARN NM - Certificate'
              servicegroup: 'yarn_nm'
              instances: srv.instances
              use: 'cert-service'
              check_command: 'check_cert!8044!120!60'
            create_dependency 'YARN NM - Certificate', 'YARN NM - WebService', srv.instances[0].node.fqdn
            # Health
            create_service
              name: 'YARN NM - Health'
              servicegroup: 'yarn_nm'
              instances: srv.instances
              use: 'unit-service'
              check_command: 'check_nm_info!8044!nodeHealthy!true!-S'
            create_dependency 'YARN NM - Health', 'YARN NM - WebService', srv.instances[0].node.fqdn
          if 'ryba/hadoop/mapred_jhs' is srv.module
            add_srv_to_cluster 'mapred_jhs', clustername
            add_srv_to_host_hostgroups  'mapred_jhs', srv.instances
            # TCP Port
            create_service
              name: 'MapReduce JHS - TCP'
              servicegroup: 'mapred_jhs'
              instances: srv.instances
              use: 'process-service'
              process_name: 'hadoop-mapreduce-historyserver'
              check_command: "check_tcp!10020"
            # webservice
            create_service
              name: 'MapReduce JHS - WebService'
              servicegroup: 'mapred_jhs'
              instances: srv.instances
              use: 'unit-service'
              check_command: 'check_tcp!19889!-S'
            # Certificate
            create_service
              name: 'MapReduce JHS - Certificate'
              servicegroup: 'mapred_jhs'
              instances: srv.instances
              use: 'cert-service'
              check_command: 'check_cert!19889!120!60'
            create_dependency 'MapReduce JHS - Certificate', 'MapReduce JHS - WebService', srv.instances[0].node.fqdn
          if 'ryba/hadoop/yarn_ts' is srv.module
            add_srv_to_cluster 'yarn_ts', clustername
            add_srv_to_host_hostgroups  'yarn_ts', srv.instances
            # Port TCP
            create_service
              name: 'YARN TS - TCP'
              servicegroup: 'yarn_ts'
              instances: srv.instances
              use: 'process-service'
              process_name: 'hadoop-yarn-timelineserver'
              check_command: "check_tcp!10200"
            # Webservice
            create_service
              name: 'YARN TS - WebService'
              servicegroup: 'yarn_ts'
              instances: srv.instances
              use: 'unit-service'
              check_command: 'check_tcp!8190!-S'
            # Certificate
            create_service
              name: 'YARN TS - Certificate'
              servicegroup: 'yarn_ts'
              instances: srv.instances
              use: 'cert-service'
              check_command: 'check_cert!8190!120!60'
            create_dependency 'YARN TS - Certificate', 'YARN TS - WebService', srv.instances[0].node.fqdn
          if 'ryba/hbase/master' is srv.module
            add_srv_to_cluster 'hbase_master', clustername
            add_srv_to_host_hostgroups  'hbase_master', srv.instances
            # HBase Master
            create_service
              name: 'HBase Master - TCP'
              servicegroup: 'hbase_master'
              instances: srv.instances
              use: 'process-service'
              process_name: 'hbase-master'
              check_command: "check_tcp!#{srv.instances[0].options.hbase_site['hbase.master.port']}"
            # WebUI
            create_service
              name: 'HBase Master - WebUI'
              servicegroup: 'hbase_master'
              instances: srv.instances
              use: 'unit-service'
              check_command: "check_tcp!#{srv.instances[0].options.hbase_site['hbase.master.info.port']}!-S"
            create_dependency 'HBase Master - WebUI', 'HBase Master - TCP', srv.instances[0].node.fqdn
            # Certificate
            create_service
              name: 'HBase Master - Certificate'
              servicegroup: 'hbase_master'
              instances: srv.instances
              use: 'cert-service'
              check_command: "check_cert!#{srv.instances[0].options.hbase_site['hbase.master.info.port']}!120!60"
            create_dependency 'HBase Master - Certificate', 'HBase Master - WebUI', srv.instances[0].node.fqdn
          if 'ryba/hbase/regionserver' is srv.module
            add_srv_to_cluster 'hbase_regionserver', clustername
            add_srv_to_host_hostgroups  'hbase_regionserver', srv.instances
            # TCP Port
            create_service
              name: 'HBase RegionServer - TCP'
              servicegroup: 'hbase_regionserver'
              instances: srv.instances
              use: 'process-service'
              process_name: 'hbase-regionserver'
              check_command: "check_tcp!#{srv.instances[0].options.hbase_site['hbase.regionserver.port']}"
            # WebUI
            create_service
              name: 'HBase RegionServer - WebUI'
              servicegroup: 'hbase_regionserver'
              instances: srv.instances
              use: 'unit-service'
              check_command: "check_tcp!#{srv.instances[0].options.hbase_site['hbase.regionserver.info.port']}!-S"
            # Certificate
            create_service
              name: 'HBase RegionServer - Certificate'
              servicegroup: 'hbase_regionserver'
              instances: srv.instances
              use: 'cert-service'
              check_command: "check_cert!#{srv.instances[0].options.hbase_site['hbase.regionserver.info.port']}!120!60"
            create_dependency 'HBase RegionServer - Certificate', 'HBase RegionServer - WebUI', srv.instances[0].node.fqdn
          if 'ryba/hbase/rest' is srv.module
            add_srv_to_cluster 'hbase_rest', clustername
            add_srv_to_host_hostgroups  'hbase_rest', srv.instances
            # WebService
            create_service
              name: 'HBase REST - WebService'
              servicegroup: 'hbase_rest'
              instances: srv.instances
              use: 'process-service'
              process_name: 'hbase-rest'
              check_command: "check_tcp!#{srv.instances[0].options.hbase_site['hbase.rest.port']}!-S"
            #WEBUI
            create_service
              name: 'HBase REST - WebUI'
              servicegroup: 'hbase_rest'
              instances: srv.instances
              use: 'unit-service'
              check_command: "check_tcp!#{srv.instances[0].options.hbase_site['hbase.rest.info.port']}"
            # Certificate
            create_service
              name: 'HBase REST - Certificate'
              servicegroup: 'hbase_rest'
              instances: srv.instances
              use: 'cert-service'
              check_command: "check_cert!#{srv.instances[0].options.hbase_site['hbase.rest.port']}!120!60"
            create_dependency 'HBase REST - Certificate', 'HBase REST - WebService', srv.instances[0].node.fqdn
          if 'ryba/hbase/thrift' is srv.module
            add_srv_to_cluster 'hbase_thrift', clustername
            add_srv_to_host_hostgroups  'hbase_thrift', srv.instances
            # TCP SSL
            create_service
              name: 'HBase Thrift - TCP SSL'
              servicegroup: 'hbase_thrift'
              instances: srv.instances
              use: 'process-service'
              process_name: 'hbase-thrift'
              check_command:"check_tcp!#{srv.instances[0].options.hbase_site['hbase.thrift.port']}!-S"
            #certificate
            create_service
              name: 'HBase Thrift - Certificate'
              servicegroup: 'hbase_thrift'
              instances: srv.instances
              use: 'cert-service'
              check_command: "check_cert!#{srv.instances[0].options.hbase_site['hbase.thrift.port']}!120!60"
            create_dependency 'HBase Thrift - Certificate', 'HBase Thrift - TCP SSL', srv.instances[0].node.fqdn
          if 'ryba/hive/hcatalog' is srv.module
            add_srv_to_cluster 'hcatalog', clustername
            add_srv_to_host_hostgroups  'hcatalog', srv.instances
            # TCP Port
            create_service
              name: 'HCatalog - TCP'
              servicegroup: 'hcatalog'
              instances: srv.instances
              use: 'process-service'
              process_name: 'hive-hcatalog-server'
              check_command: "check_tcp!#{srv.instances[0].options.hive_site['hive.metastore.port']}"
          if 'ryba/hive/server2' is srv.module
            add_srv_to_cluster 'hiveserver2', clustername
            add_srv_to_host_hostgroups  'hiveserver2', srv.instances
            # TCP Port
            create_service
              name: 'Hiveserver2 - TCP SSL'
              servicegroup: 'hiveserver2'
              instances: srv.instances
              use: 'process-service'
              process_name: 'hive-server2'
              check_command: "check_tcp!#{srv.instances[0].options.hive_site['hive.server2.thrift.port']}"
            # Certificate
            create_service
              name: 'Hiveserver2 - Certificate'
              servicegroup: 'hiveserver2'
              instances: srv.instances
              use: 'cert-service'
              check_command: "check_cert!#{srv.instances[0].options.hive_site['hive.server2.thrift.port']}!120!60"
            create_dependency 'Hiveserver2 - Certificate', 'Hiveserver2 - TCP SSL', srv.instances[0].node.fqdn
          if 'ryba/hive/webhcat' is srv.module
            add_srv_to_cluster 'webhcat', clustername
            add_srv_to_host_hostgroups  'webhcat', srv.instances
            # TCP Port
            create_service
              name: 'WebHCat - WebService'
              servicegroup: 'webhcat'
              instances: srv.instances
              use: 'process-service'
              process_name: 'hive-webhcat-server'
              check_command: "check_tcp!#{srv.instances[0].options.webhcat_site['templeton.port']}"
            # Status
            create_service
              name: 'WebHCat - Status'
              servicegroup: 'webhcat'
              instances: srv.instances
              use: 'unit-service'
              check_command: "check_webhcat_status!#{srv.instances[0].options.webhcat_site['templeton.port']}"
            create_dependency 'WebHCat - Status', 'WebHCat - WebService', srv.instances[0].node.fqdn
            create_service
              name: 'WebHCat - Database'
              servicegroup: 'webhcat'
              instances: srv.instances
              use: 'unit-service'
              check_command: "check_webhcat_database!#{srv.instances[0].options.webhcat_site['templeton.port']}!default"
            create_dependency 'WebHCat - Database', 'WebHCat - WebService', srv.instances[0].node.fqdn
          if 'ryba/oozie/server' is srv.module
            add_srv_to_cluster 'oozie_server', clustername
            add_srv_to_host_hostgroups  'oozie_server', srv.instances
            # TCP Port
            create_service
              name: 'Oozie Server - WebUI'
              servicegroup: 'oozie_server'
              instances: srv.instances
              use: 'process-service'
              process_name: 'oozie'
              check_command: "check_tcp!#{srv.instances[0].options.http_port}!-S"
            # Certificate
            create_service
              name: 'Oozie Server - Certificate'
              servicegroup: 'oozie_server'
              instances: srv.instances
              use: 'cert-service'
              check_command: "check_cert!#{srv.instances[0].options.http_port}!120!60"
            create_dependency 'Oozie Server - Certificate', 'Oozie Server - WebUI', srv.instances[0].node.fqdn
          if 'ryba/kafka/broker' is srv.module
            add_srv_to_cluster 'kafka_broker', clustername
            add_srv_to_host_hostgroups  'kafka_broker', srv.instances
            for protocol in srv.instances[0].options.protocols
              create_service
                name: "Kafka Broker - TCP #{protocol}"
                servicegroup: 'kafka_broker'
                instances: srv.instances
                use: 'unit-service'
                check_command: "check_tcp!#{srv.instances[0].options.ports[protocol]}"
            # TCP Ports
            create_service
              name: 'Kafka Broker - TCPs'
              servicegroup: 'kafka_broker'
              instances: srv.instances
              use: 'process-service'
              process_name: 'kafka-broker'
              check_command: "bp_rule!($HOSTNAME$,r:^Kafka Broker - TCP .*$)"
          if 'ryba/ranger/admin' is srv.module
            add_srv_to_cluster 'ranger', clustername
            add_srv_to_host_hostgroups  'ranger', srv.instances
            # Ranger - Admin
            check_command = "check_tcp!#{srv.instances[0].options.site['ranger.service.http.port']}"
            if srv.instances[0].options.site['ranger.service.https.attrib.ssl.enabled'] is 'true'
              check_command = "check_tcp!#{srv.instances[0].options.site['ranger.service.https.port']}!-S"
              create_service
                name: 'Ranger - WebUI'
                servicegroup: 'ranger'
                instances: srv.instances
                use: 'process-service'
                process_name: 'ranger-admin'
                check_command: check_command
              create_service
                name: 'Ranger - Certificate'
                servicegroup: 'ranger'
                instances: srv.instances
                use: 'cert-service'
                check_command: "check_cert!#{srv.instances[0].options.site['ranger.service.https.port']}!120!60"
              create_dependency 'Ranger - Certificate', 'Ranger - WebUI', srv.instances[0].node.fqdn
            else
              create_service
                name: 'Ranger - WebUI'
                servicegroup: 'ranger'
                instances: srv.instances
                use: 'process-service'
                process_name: 'ranger-admin'
                check_command: check_command
          if 'ryba/opentsdb' is srv.module
            add_srv_to_cluster 'opentsdb', clustername
            add_srv_to_host_hostgroups  'opentsdb', srv.instances
            create_service
              name: 'OpenTSDB - WebService'
              servicegroup: 'opentsdb'
              instances: srv.instances
              use: 'process-service'
              process_name: 'opentsdb'
              check_command: "check_tcp!#{srv.instances[0].options.config['tsd.network.port']}"
          if 'ryba/phoenix/queryserver' is srv.module
            add_srv_to_cluster 'phoenix_qs', clustername
            add_srv_to_host_hostgroups  'phoenix_qs', srv.instances
            # TCP Port
            create_service
              name: 'Phoenix QueryServer - TCP'
              servicegroup: 'phoenix_qs'
              instances: srv.instances
              use: 'process-service'
              process_name: 'phoenix-queryserver'
              check_command: "check_tcp!#{srv.instances[0].options.phoenix_site['phoenix.queryserver.http.port']}"
          if 'ryba/spark/history_server' is srv.module
            add_srv_to_cluster 'spark_hs', clustername
            add_srv_to_host_hostgroups  'spark_hs', srv.instances
            create_service
              name: 'Spark HistoryServer - WebUI'
              servicegroup: 'spark_hs'
              instances: srv.instances
              use: 'process-service'
              process_name: 'spark-history-server'
              check_command: "check_tcp!#{srv.instances[0].options.conf['spark.history.ui.port']}"
          if 'ryba/spark/livy_server' is srv.module
            add_srv_to_cluster 'spark_ls', clustername
            add_srv_to_host_hostgroups  'spark_ls', srv.instances
            create_service
              name: 'Spark LivyServer - WebService'
              servicegroup: 'spark_ls'
              instances: srv.instances
              use: 'process-service'
              process_name: 'spark-livy-server'
              check_command: "check_tcp!#{srv.instances[0].options.port}"
          # if 'ryba/elasticsearch' is srv.module
          #   options.hosts[clustername].modules.push 'elasticsearch' unless 'elasticsearch' in options.hosts[clustername].modules
          #   options.hosts[fqdn].hostgroups.push 'elasticsearch' unless 'elasticsearch' in options.hosts[fqdn].hostgroups
          #   options.services['ElasticSearch - WebService'] ?= {}
          #   options.services['ElasticSearch - WebService'].hosts ?= []
          #   options.services['ElasticSearch - WebService'].hosts.push host
          #   options.services['ElasticSearch - WebService'].servicegroups ?= ['elasticsearch']
          #   options.services['ElasticSearch - WebService'].use ?= 'process-service'
          #   options.services['ElasticSearch - WebService']['_process_name'] ?= 'elasticsearch'
          #   options.services['ElasticSearch - WebService'].check_command ?= 'check_tcp!9200'
          #   options.services['ElasticSearch - TCP'] ?= {}
          #   options.services['ElasticSearch - TCP'].hosts ?= []
          #   options.services['ElasticSearch - TCP'].hosts.push host
          #   options.services['ElasticSearch - TCP'].servicegroups ?= ['elasticsearch']
          #   options.services['ElasticSearch - TCP'].use ?= 'unit-service'
          #   options.services['ElasticSearch - TCP'].check_command ?= 'check_tcp!9300'
          if 'ryba/swarm/manager' is srv.module
            add_srv_to_cluster 'swarm_manager', clustername
            add_srv_to_host_hostgroups  'swarm_manager', srv.instances
            create_service
              name: 'Swarm Manager - TCP'
              servicegroup: 'elasticsearch'
              instances: srv.instances
              use: 'unit-service'
              check_command: "check_tcp!#{srv.instances[0].options.listen_port}"
            if options.credentials.swarm_user.enabled
              create_service
                name: 'ES Containers - TCPs'
                servicegroup: 'elasticsearch'
                instances: srv.instances
                use: 'unit-service'
                check_command: "check_es_containers_tcps!#{srv.instances[0].options.listen_port}!-S"
              create_dependency 'ES Containers - TCPs', 'Swarm Manager - TCP', srv.instances[0].node.fqdn
              create_service
                name: 'ES Containers - Status'
                servicegroup: 'elasticsearch'
                instances: srv.instances
                use: 'unit-service'
                check_command: "check_es_containers_status!#{srv.instances[0].options.listen_port}!-S"
              create_dependency 'ES Containers - Status', 'ES Containers - TCPs', srv.instances[0].node.fqdn
          # if 'ryba/rexster' is srv.module
          #   options.hosts[clustername].modules.push 'rexster' unless 'rexster' in options.hosts[clustername].modules
          #   options.hosts[fqdn].hostgroups.push 'rexster' unless 'rexster' in options.hosts[fqdn].hostgroups
          #   options.services['Rexster - WebUI'] ?= {}
          #   options.services['Rexster - WebUI'].hosts ?= []
          #   options.services['Rexster - WebUI'].hosts.push host
          #   options.services['Rexster - WebUI'].servicegroups ?= ['rexster']
          #   options.services['Rexster - WebUI'].use ?= 'process-service'
          #   options.services['Rexster - WebUI']['_process_name'] ?= 'rexster'
          #   options.services['Rexster - WebUI'].check_command ?= "check_tcp!#{ryba.rexster.config.http['server-port']}"
          if 'ryba/atlas' is srv.module
            add_srv_to_cluster 'atlas', clustername
            add_srv_to_host_hostgroups  'atlas', srv.instances
            if srv.instances[0].options.application.properties['atlas.enableTLS'] is 'true'
              create_service
                name: 'Atlas - WebUI'
                servicegroup: 'atlas'
                instances: srv.instances
                use: 'process-service'
                process_name: 'atlas-metadata-server'
                check_command: "check_tcp!#{srv.instances[0].options.application.properties['atlas.server.https.port']}"
              create_service
                name: 'Atlas - Certificate'
                servicegroup: 'atlas'
                instances: srv.instances
                use: 'cert-service'
                check_command: "check_cert!#{srv.instances[0].options.application.properties['atlas.server.https.port']}!120!60"
              create_dependency 'Atlas - Certificate', 'Atlas - WebUI', srv.instances[0].node.fqdn
            else
              create_service
                name: 'Atlas - WebUI'
                servicegroup: 'atlas'
                instances: srv.instances
                use: 'process-service'
                process_name: 'atlas-metadata-server'
                check_command: "check_tcp!#{srv.instances[0].options.application.properties['atlas.server.http.port']}"
          if 'ryba/huedocker' is srv.module
            add_srv_to_cluster 'hue', clustername
            add_srv_to_host_hostgroups  'hue', srv.instances
            create_service
              name: 'Hue - WebUI'
              servicegroup: 'hue'
              instances: srv.instances
              use: 'process-service'
              process_name: 'hue-server-docker'
              check_command: "check_cert!#{srv.instances[0].options.ini.desktop.http_port}!120!60"
            if srv.instances[0].options.ssl.enabled
              create_service
                name: 'Hue - Certificate'
                servicegroup: 'hue'
                instances: srv.instances
                use: 'cert-service'
                check_command:"check_cert!#{srv.instances[0].options.ini.desktop.http_port}!120!60"
              create_dependency 'Hue - Certificate', 'Hue - WebUI', srv.instances[0].node.fqdn
          if 'ryba/knox/server' is srv.module
            add_srv_to_cluster 'knox', clustername
            add_srv_to_host_hostgroups  'knox', srv.instances
            #TCP Port
            create_service
              name: 'Knox - WebService'
              servicegroup: 'knox'
              instances: srv.instances
              use: 'process-service'
              process_name: 'knox-server'
              check_command: "check_tcp!#{srv.instances[0].options.gateway_site['gateway.port']}!-S"
            # Certificate
            create_service
              name: 'Knox - Certificate'
              servicegroup: 'knox'
              instances: srv.instances
              use: 'cert-service'
              check_command: "check_cert!#{srv.instances[0].options.gateway_site['gateway.port']}!120!60"
            create_dependency 'Knox - Certificate', 'Knox - WebService', srv.instances[0].node.fqdn
            if options.credentials.knox_user.enabled
              create_service
                name: 'Knox - HBase Scan'
                servicegroup: ['knox', 'hbase']
                instances: srv.instances
                use: 'functional-service'
                check_command: "check_hbase_scan!#{srv.instances[0].options.gateway_site['gateway.port']}!hbase:meta!-S"
              create_dependency 'Knox - HBase Scan', 'Knox - WebService', srv.instances[0].node.fqdn
              create_service
                name: 'Knox - HBase Write'
                servicegroup: ['knox', 'hbase']
                instances: srv.instances
                use: 'functional-service'
                check_command: "check_hbase_write!#{srv.instances[0].options.gateway_site['gateway.port']}!#{srv.instances[0].options.hbase_client_test_namespace}:monitoring!cf1!-S"
              create_dependency 'Knox - HBase Write', 'Knox - WebService', srv.instances[0].node.fqdn
              create_service
                name: 'Knox - HDFS Write'
                servicegroup: ['knox', 'hdfs']
                instances: srv.instances
                use: 'functional-service'
                check_command: "check_hdfs_write!#{srv.instances[0].options.gateway_site['gateway.port']}!-S"
              create_dependency 'Knox - HDFS Write', 'Knox - WebService', srv.instances[0].node.fqdn
          if 'ryba/nifi' is srv.module
            add_srv_to_cluster 'nifi', clustername
            add_srv_to_host_hostgroups  'nifi', srv.instances
            #TCP Port
            if srv.instances[0].options.properties['nifi.cluster.protocol.is.secure'] is 'true'
              create_service
                name: 'NiFi - WebUI'
                servicegroup: 'nifi'
                instances: srv.instances
                use: 'process-service'
                process_name: 'nifi'
                check_command: "check_tcp!#{srv.instances[0].options.properties['nifi.web.https.port']}!-S"
              create_service
                name: 'NiFi - Certificate'
                servicegroup: 'nifi'
                instances: srv.instances
                use: 'cert-service'
                check_command: "check_cert!#{srv.instances[0].options.properties['nifi.web.https.port']}!120!60"
              create_dependency 'NiFi - Certificate', 'NiFi - WebUI', srv.instances[0].node.fqdn
            else
              create_service
                name: 'NiFi - WebUI'
                servicegroup: 'nifi'
                instances: srv.instances
                use: 'process-service'
                process_name: 'nifi'
                check_command: "check_tcp!#{srv.instances[0].options.properties['nifi.web.http.port']}!-S"
            create_service
              name: 'NiFi - TCP'
              servicegroup: 'nifi'
              instances: srv.instances
              use: 'unit-service'
              check_command: "check_tcp!#{srv.instances[0].options.properties['nifi.cluster.node.protocol.port']}"
            create_dependency 'NiFi - TCP', 'NiFi - WebUI', srv.instances[0].node.fqdn

### Watcher services

        if 'mysql_server' in options.hosts[clustername].modules
          options.services['MySQL - Available'] ?= {}
          options.services['MySQL - Available'].hosts ?= []
          options.services['MySQL - Available'].hosts.push clustername
          options.services['MySQL - Available'].servicegroups ?= ['mysql_server']
          options.services['MySQL - Available'].use ?= 'bp-service'
          options.services['MySQL - Available'].check_command ?= bp_has_one 'MySQL - TCP', '$HOSTNAME$'
        if 'mariadb_server' in options.hosts[clustername].modules
          options.services['MariaDB - Available'] ?= {}
          options.services['MariaDB - Available'].hosts ?= []
          options.services['MariaDB - Available'].hosts.push clustername
          options.services['MariaDB - Available'].servicegroups ?= ['mysql_server']
          options.services['MariaDB - Available'].use ?= 'bp-service'
          options.services['MariaDB - Available'].check_command ?= bp_has_one 'MariaDB - TCP', '$HOSTNAME$'
        if 'zookeeper_server' in options.hosts[clustername].modules
          options.services['Zookeeper Server - Available'] ?= {}
          options.services['Zookeeper Server - Available'].hosts ?= []
          options.services['Zookeeper Server - Available'].hosts.push clustername
          options.services['Zookeeper Server - Available'].servicegroups ?= ['zookeeper_server']
          options.services['Zookeeper Server - Available'].use ?= 'bp-service'
          options.services['Zookeeper Server - Available'].check_command ?= bp_has_quorum 'Zookeeper Server - TCP', '$HOSTNAME$'
        if 'hdfs_nn' in options.hosts[clustername].modules
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
          create_dependency 'HDFS NN - Active Node', 'HDFS NN - Available', clustername
          options.services['HDFS NN - Live DNs'] ?= {}
          options.services['HDFS NN - Live DNs'].hosts ?= []
          options.services['HDFS NN - Live DNs'].hosts.push clustername
          options.services['HDFS NN - Live DNs'].servicegroups ?= ['hdfs_nn']
          options.services['HDFS NN - Live DNs'].use ?= 'unit-service'
          options.services['HDFS NN - Live DNs'].check_command ?= 'check_live_dn!50470!-S'
          create_dependency 'HDFS NN - Live DNs', 'HDFS NN - Active Node', clustername
        if 'hdfs_zkfc' in options.hosts[clustername].modules
          options.services['ZKFC - Available'] ?= {}
          options.services['ZKFC - Available'].hosts ?= []
          options.services['ZKFC - Available'].hosts.push clustername
          options.services['ZKFC - Available'].servicegroups ?= ['hdfs_zkfc']
          options.services['ZKFC - Available'].use ?= 'bp-service'
          options.services['ZKFC - Available'].check_command ?= bp_has_all 'ZKFC - TCP', '$HOSTNAME$'
          create_dependency 'ZKFC - Available', 'Zookeeper Server - Available', clustername
        if 'hdfs_jn' in options.hosts[clustername].modules
          options.services['HDFS JN - Available'] ?= {}
          options.services['HDFS JN - Available'].hosts ?= []
          options.services['HDFS JN - Available'].hosts.push clustername
          options.services['HDFS JN - Available'].servicegroups ?= ['hdfs_jn']
          options.services['HDFS JN - Available'].use ?= 'bp-service'
          options.services['HDFS JN - Available'].check_command ?= bp_has_quorum 'HDFS JN - TCP SSL', '$HOSTNAME$'
        if 'hdfs_dn' in options.hosts[clustername].modules
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
        if 'httpfs' in options.hosts[clustername].modules
          options.services['HttpFS - Available'] ?= {}
          options.services['HttpFS - Available'].hosts ?= []
          options.services['HttpFS - Available'].hosts.push clustername
          options.services['HttpFS - Available'].servicegroups ?= ['httpfs']
          options.services['HttpFS - Available'].use ?= 'bp-service'
          options.services['HttpFS - Available'].check_command ?= bp_has_one 'HttpFS - WebService', '$HOSTNAME$'
        if 'yarn_rm' in options.hosts[clustername].modules
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
        if 'yarn_nm' in options.hosts[clustername].modules
          options.services['YARN NM - Available'] ?= {}
          options.services['YARN NM - Available'].hosts ?= []
          options.services['YARN NM - Available'].hosts.push clustername
          options.services['YARN NM - Available'].servicegroups ?= ['yarn_nm']
          options.services['YARN NM - Available'].use ?= 'bp-service'
          options.services['YARN NM - Available'].check_command ?= bp_miss 3, 'YARN NM - TCP', '$HOSTNAME$'
        if 'mapred_jhs' in options.hosts[clustername].modules
          options.services['MapReduce JHS - Available'] ?= {}
          options.services['MapReduce JHS - Available'].hosts ?= []
          options.services['MapReduce JHS - Available'].hosts.push clustername
          options.services['MapReduce JHS - Available'].servicegroups ?= ['mapred_jhs']
          options.services['MapReduce JHS - Available'].use ?= 'bp-service'
          options.services['MapReduce JHS - Available'].check_command ?= bp_has_one 'MapReduce JHS - TCP', '$HOSTNAME$'
        if 'yarn_ts' in options.hosts[clustername].modules
          options.services['YARN TS - Available'] ?= {}
          options.services['YARN TS - Available'].hosts ?= []
          options.services['YARN TS - Available'].hosts.push clustername
          options.services['YARN TS - Available'].servicegroups ?= ['yarn_ts']
          options.services['YARN TS - Available'].use ?= 'bp-service'
          options.services['YARN TS - Available'].check_command ?= bp_has_one 'YARN TS - TCP', '$HOSTNAME$'
        if 'hbase_master' in options.hosts[clustername].modules
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
          create_dependency 'HBase - Unavailable Regions', 'HBase Master - Active Node', clustername
          options.services['HBase - Replication logs'] ?= {}
          options.services['HBase - Replication logs'].hosts ?= []
          options.services['HBase - Replication logs'].hosts.push clustername
          options.services['HBase - Replication logs'].servicegroups ?= ['hbase']
          options.services['HBase - Replication logs'].use ?= 'functional-service'
          options.services['HBase - Replication logs'].check_command ?= 'check_hdfs_content_summary!50470!/apps/hbase/data/oldWALs!spaceConsumed!824633720832!1099511627776!-S' # 768GiB | 1TiB
          create_dependency 'HBase - Replication logs', 'HDFS NN - Active Node', clustername
        if 'hbase_regionserver' in options.hosts[clustername].modules
          options.services['HBase RegionServer - Available'] ?= {}
          options.services['HBase RegionServer - Available'].hosts ?= []
          options.services['HBase RegionServer - Available'].hosts.push clustername
          options.services['HBase RegionServer - Available'].servicegroups ?= ['hbase_regionserver']
          options.services['HBase RegionServer - Available'].use ?= 'bp-service'
          options.services['HBase RegionServer - Available'].check_command ?= bp_miss '20%', 'HBase RegionServer - TCP', '$HOSTNAME$'
          create_dependency 'HBase RegionServer - Available', 'Zookeeper Server - Available', clustername
        if 'hbase_rest' in options.hosts[clustername].modules
          options.services['HBase REST - Available'] ?= {}
          options.services['HBase REST - Available'].hosts ?= []
          options.services['HBase REST - Available'].hosts.push clustername
          options.services['HBase REST - Available'].servicegroups ?= ['hbase_rest']
          options.services['HBase REST - Available'].use ?= 'bp-service'
          options.services['HBase REST - Available'].check_command ?= bp_has_one 'HBase REST - WebService', '$HOSTNAME$'
        if 'hbase_thrift' in options.hosts[clustername].modules
          options.services['HBase Thrift - Available'] ?= {}
          options.services['HBase Thrift - Available'].hosts ?= []
          options.services['HBase Thrift - Available'].hosts.push clustername
          options.services['HBase Thrift - Available'].servicegroups ?= ['hbase_thrift']
          options.services['HBase Thrift - Available'].use ?= 'bp-service'
          options.services['HBase Thrift - Available'].check_command ?= bp_has_one 'HBase Thrift - TCP SSL', '$HOSTNAME$'
        if 'hcatalog' in options.hosts[clustername].modules
          options.services['HCatalog - Available'] ?= {}
          options.services['HCatalog - Available'].hosts ?= []
          options.services['HCatalog - Available'].hosts.push clustername
          options.services['HCatalog - Available'].servicegroups ?= ['hcatalog']
          options.services['HCatalog - Available'].use ?= 'bp-service'
          options.services['HCatalog - Available'].check_command ?= bp_has_one 'HCatalog - TCP', '$HOSTNAME$'
        if 'hiveserver2' in options.hosts[clustername].modules
          options.services['Hiveserver2 - Available'] ?= {}
          options.services['Hiveserver2 - Available'].hosts ?= []
          options.services['Hiveserver2 - Available'].hosts.push clustername
          options.services['Hiveserver2 - Available'].servicegroups ?= ['hiveserver2']
          options.services['Hiveserver2 - Available'].use ?= 'bp-service'
          options.services['Hiveserver2 - Available'].check_command ?= bp_has_one 'Hiveserver2 - TCP SSL', '$HOSTNAME$'
        if 'webhcat' in options.hosts[clustername].modules
          options.services['WebHCat - Available'] ?= {}
          options.services['WebHCat - Available'].hosts ?= []
          options.services['WebHCat - Available'].hosts.push clustername
          options.services['WebHCat - Available'].servicegroups ?= ['webhcat']
          options.services['WebHCat - Available'].use ?= 'bp-service'
          options.services['WebHCat - Available'].check_command ?= bp_has_one 'WebHCat - WebService', '$HOSTNAME$'
        if 'oozie_server' in options.hosts[clustername].modules
          options.services['Oozie Server - Available'] ?= {}
          options.services['Oozie Server - Available'].hosts ?= []
          options.services['Oozie Server - Available'].hosts.push clustername
          options.services['Oozie Server - Available'].servicegroups ?= ['oozie_server']
          options.services['Oozie Server - Available'].use ?= 'bp-service'
          options.services['Oozie Server - Available'].check_command ?= bp_has_one 'Oozie Server - WebUI', '$HOSTNAME$'
        if 'kafka_broker' in options.hosts[clustername].modules
          options.services['Kafka Broker - Available'] ?= {}
          options.services['Kafka Broker - Available'].hosts ?= []
          options.services['Kafka Broker - Available'].hosts.push clustername
          options.services['Kafka Broker - Available'].servicegroups ?= ['kafka_broker']
          options.services['Kafka Broker - Available'].use ?= 'bp-service'
          options.services['Kafka Broker - Available'].check_command ?= bp_has_one 'Kafka Broker - TCPs', '$HOSTNAME$'
          create_dependency 'Kafka Broker - Available', 'Zookeeper Server - Available', clustername
        if 'opentsdb' in options.hosts[clustername].modules
          options.services['OpenTSDB - Available'] ?= {}
          options.services['OpenTSDB - Available'].hosts ?= []
          options.services['OpenTSDB - Available'].hosts.push clustername
          options.services['OpenTSDB - Available'].servicegroups ?= ['opentsdb']
          options.services['OpenTSDB - Available'].use ?= 'bp-service'
          options.services['OpenTSDB - Available'].check_command ?= bp_has_one 'OpenTSDB - WebService', '$HOSTNAME$'
          create_dependency 'OpenTSDB - Available', 'HBase - Available', clustername
        if 'phoenix_qs' in options.hosts[clustername].modules
          options.services['Phoenix QueryServer - Available'] ?= {}
          options.services['Phoenix QueryServer - Available'].hosts ?= []
          options.services['Phoenix QueryServer - Available'].hosts.push clustername
          options.services['Phoenix QueryServer - Available'].servicegroups ?= ['phoenix_qs']
          options.services['Phoenix QueryServer - Available'].use ?= 'bp-service'
          options.services['Phoenix QueryServer - Available'].check_command ?= bp_has_one 'Phoenix QueryServer - TCP', '$HOSTNAME$'
          create_dependency 'Phoenix QueryServer - Available', 'HBase - Available', clustername
        if 'spark_hs' in options.hosts[clustername].modules
          options.services['Spark HistoryServer - Available'] ?= {}
          options.services['Spark HistoryServer - Available'].hosts ?= []
          options.services['Spark HistoryServer - Available'].hosts.push clustername
          options.services['Spark HistoryServer - Available'].servicegroups ?= ['spark_qs']
          options.services['Spark HistoryServer - Available'].use ?= 'bp-service'
          options.services['Spark HistoryServer - Available'].check_command ?= bp_has_one 'Spark HistoryServer - WebUI', '$HOSTNAME$'
        if 'spark_ls' in options.hosts[clustername].modules
          options.services['Spark LivyServer - Available'] ?= {}
          options.services['Spark LivyServer - Available'].hosts ?= []
          options.services['Spark LivyServer - Available'].hosts.push clustername
          options.services['Spark LivyServer - Available'].servicegroups ?= ['spark_ls']
          options.services['Spark LivyServer - Available'].use ?= 'bp-service'
          options.services['Spark LivyServer - Available'].check_command ?= bp_has_one 'Spark LivyServer - TCP', '$HOSTNAME$'  
        if 'elasticsearch' in options.hosts[clustername].modules
          options.services['ElasticSearch - Available'] ?= {}
          options.services['ElasticSearch - Available'].hosts ?= []
          options.services['ElasticSearch - Available'].hosts.push clustername
          options.services['ElasticSearch - Available'].servicegroups ?= ['elasticsearch']
          options.services['ElasticSearch - Available'].use ?= 'bp-service'
          options.services['ElasticSearch - Available'].check_command ?= bp_has_quorum 'ElasticSearch - TCP', '$HOSTNAME$'
        if 'atlas' in options.hosts[clustername].modules
          options.services['Atlas - Available'] ?= {}
          options.services['Atlas - Available'].hosts ?= []
          options.services['Atlas - Available'].hosts.push clustername
          options.services['Atlas - Available'].servicegroups ?= ['atlas']
          options.services['Atlas - Available'].use ?= 'bp-service'
          options.services['Atlas - Available'].check_command ?= bp_has_one 'Atlas - WebUI', '$HOSTNAME$'
        if 'ranger' in options.hosts[clustername].modules
          options.services['Ranger - Available'] ?= {}
          options.services['Ranger - Available'].hosts ?= []
          options.services['Ranger - Available'].hosts.push clustername
          options.services['Ranger - Available'].servicegroups ?= ['ranger']
          options.services['Ranger - Available'].use ?= 'bp-service'
          options.services['Ranger - Available'].check_command ?= bp_has_one 'Ranger - WebUI', '$HOSTNAME$'
        if 'knox' in options.hosts[clustername].modules
          options.services['Knox - Available'] ?= {}
          options.services['Knox - Available'].hosts ?= []
          options.services['Knox - Available'].hosts.push clustername
          options.services['Knox - Available'].servicegroups ?= ['knox']
          options.services['Knox - Available'].use ?= 'bp-service'
          options.services['Knox - Available'].check_command ?= bp_has_one 'Knox - WebService', '$HOSTNAME$'
        if 'hue' in options.hosts[clustername].modules
          options.services['Hue - Available'] ?= {}
          options.services['Hue - Available'].hosts ?= []
          options.services['Hue - Available'].hosts.push clustername
          options.services['Hue - Available'].servicegroups ?= ['hue']
          options.services['Hue - Available'].use ?= 'bp-service'
          options.services['Hue - Available'].check_command ?= bp_has_one 'Hue - WebUI', '$HOSTNAME$'
        if 'nifi' in options.hosts[clustername].modules
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
      for  clustername, cluster of options.clusters
        from_nodes normalize(cluster.config).nodes, clustername, cluster.config
        # console.log store(cluster.config).nodes()[0]
      # for clustername, cluster of options.clusters
      #   from_nodes cluster.config, clustername
      # lucasbak: 17122017
      # no require on configure
      # pass directly as argument config file containing clusters layout
      # if options.clusters?
      #   for clustername, config of options.clusters
      #     from_contexts glob.sync("#{ctx_dir}/*").map((f) -> require f), clustername
      # else
      #   from_contexts @contexts '**'
      # console.log service if service.node.fqdn is 'master01.metal.ryba'

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
    normalize = require 'masson/lib/config/normalize'
    store = require 'masson/lib/config/store'
    
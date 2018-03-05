
# Grafana Configure
  
    module.exports = (service) ->
      options = service.options

## Access

      options.iptables ?= !!service.deps.iptables and service.deps.iptables?.options?.action is 'start'

## Identities

      # Group
      options.group ?= {}
      options.group = name: options.group if typeof options.group is 'string'
      options.group.name ?= 'grafana'
      options.group.system ?= true
      # User
      options.user ?= {}
      options.user = name: options.user if typeof options.user is 'string'
      options.user.name ?= 'grafana'
      options.user.home ?= "/var/lib/#{options.user.name}"
      options.user.system ?= true
      options.user.comment ?= 'Grafana User'
      options.user.groups ?= 'hadoop'
      options.user.gid ?= options.group.name
      options.user.limits ?= {}
      options.user.limits.nofile ?= 64000
      options.user.limits.nproc ?= true

## Configure Database

Note, at the moment, only MariaDB, PostgreSQL and MySQL are supported.

      options.db ?= {}
      options.db.engine ?= service.deps.db_admin.options.engine
      options.db = merge {}, service.deps.db_admin.options[options.db.engine], options.db
      options.db.database ?= 'grafana'
      options.db.username ?= 'grafana'
      throw Error "Required Option: db.password" unless options.db.password

## Configuration
      
      # options.source ?= 'https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana-4.5.2-1.x86_64.rpm'
      # options.download ?= service.deps.grafana_webui[0].node.fqdn is service.node.fqdn
      options.log_dir ?= '/var/log/grafana'
      options.conf_dir ?= '/etc/grafana/conf'
      options.run_dir ?= '/var/run/grafana'
      # Misc
      options.fqdn ?= service.node.fqdn

## Environment

      options.env ?= {}
      options.env['GRAFANA_USER'] ?= options.user.name
      options.env['GRAFANA_GROUP'] ?= options.group.name
      options.env['GRAFANA_HOME'] ?= options.user.home
      options.env['LOG_DIR'] ?= options.log_dir
      options.env['PID_FILE_DIR'] ?= options.run_dir
      options.env['DATA_DIR'] ?= "#{options.user.home}/data"
      options.env['CONF_DIR'] ?= options.conf_dir
      options.env['CONF_FILE'] ?= "#{options.conf_dir}/grafana.ini"
      options.env['MAX_OPEN_FILES'] ?= options.user.limits.nofile
      options.env['PLUGINS_DIR'] ?= "#{options.user.home}/plugins"
      options.env['RESTART_ON_UPGRADE'] ?= 'true'

## SSL

      options.ssl = merge {}, service.deps.ssl?.options, options.ssl
      options.ssl.enabled ?= !!service.deps.ssl
      if options.ssl.enabled
        throw Error "Required Option: ssl.cert" if  not options.ssl.cert
        throw Error "Required Option: ssl.key" if not options.ssl.key

## Server Properties

      options.ini ?= {}
      #webui
      options.ini['server'] ?= {}
      options.ini['server']['protocol'] ?= if options.ssl.enabled then 'https' else 'http'
      options.ini['server']['http_port'] ?= '3000'
      options.ini['server']['domain'] ?= service.node.fqdn
      options.ini['server']['cert_file'] ?= "#{options.conf_dir}/cert.pem"
      options.ini['server']['cert_key'] ?= "#{options.conf_dir}/key.pem"
      #database
      options.ini['database'] ?= {}
      options.ini['database']['type'] ?= 'mysql' if options.db.engine in ['mysql','mariadb']
      options.ini['database']['host'] ?= "#{options.db.host}:#{options.db.port}"
      options.ini['database']['name'] ?= options.db.database
      options.ini['database']['user'] ?= options.db.username
      options.ini['database']['password'] ?= options.db.password
      #security
      options.ini['security'] ?= {}
      options.ini['security']['admin_user'] ?= 'admin'
      options.ini['security']['admin_password'] ?= 'admin'
      throw Error 'Missing Grafana webui password options.ini.security.admin_password' unless options.ini['security']['admin_password']?

## URLs

      options.url ?= "#{options.ini['server']['protocol']}://#{service.node.fqdn}:#{options.ini['server']['http_port']}"
      if service.deps.hdfs_jn
        protocol = if service.deps.hdfs_jn[0].options.hdfs_site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
        port = service.deps.hdfs_jn[0].options.hdfs_site["dfs.journalnode.#{protocol}-address"].split(':')[1]
        options.jn_url ?= "#{protocol}://#{service.deps.hdfs_jn[0].node.fqdn}:#{port}"

## Datasources

      options.datasource ?= 'prometheus' if service.deps.prometheus_monitor
      options.datasources ?= {}
      if options.datasource is 'prometheus'
        options.datasources['prometheus'] ?=
          datasource_url: "http://#{service.deps.prometheus_monitor[0].node.fqdn}:#{service.deps.prometheus_monitor[0].options.port}"
          name: 'prometheus'
          datasource: 'prometheus'

## Dashboards
Load default template for Grafana with prometheus datasource.
This templates, will work out of the box on every cluster deployed by Ryba.
Nonetheless you can use it, just besure that in your jMX exporter the property
toLowerCase is enabled, as metrics are in lowercase in grafana dashboard.

Dashboard and panels are based on prometheus queries and as a consequence,
do not depend on cluster or host names.

      options.templates ?= {}
      #needed options when rendering templates
      options.cluster_name ?= 'ryba-env-metal'
      if service.deps.zookeeper_server
        options.templates['zookeeper-server'] ?=
          source: "#{__dirname}/../resources/prometheus-zookeeper.json.j2"
          local: true
          title: 'Zookeeper Server'
          slug: 'zookeeper-server'
          cluster_name: options.cluster_name
          datasource: options.datasource
      if service.deps.hdfs_dn
        options.templates['hdfs-datanodes'] ?=
          source: "#{__dirname}/../resources/prometheus-datanodes.json.j2"
          local: true
          title: 'HDFS Datanodes'
          slug: 'hdfs-datanodes'
          cluster_name: options.cluster_name
          datasource: options.datasource
          #TODO percentage of disks used
          # options.templates['hdfs-datadisks'] ?=
          #   source: "#{__dirname}/../resources/prometheus-hdfs-datadisks.json.j2"
          #   local: true
          #   title: 'HDFS Data Disks'
          #   slug: 'hdfs-datadisks'
          #   cluster_name: options.cluster_name
          #   datasource: options.datasource
      if service.deps.hdfs_jn
        options.templates['hdfs-journalnodes'] ?=
          source: "#{__dirname}/../resources/prometheus-journalnodes.json.j2"
          local: true
          title: 'HDFS Journalnodes'
          slug: 'hdfs-journalnodes'
          cluster_name: options.cluster_name
          datasource: options.datasource
      if service.deps.hdfs_nn
        options.templates['hdfs-namenodes'] ?=
          source: "#{__dirname}/../resources/prometheus-namenodes.json.j2"
          local: true
          title: 'HDFS Namenodes'
          slug: 'hdfs-namenodes'
          cluster_name: options.cluster_name
          datasource: options.datasource
      if service.deps.yarn_nm
        options.templates['yarn-nodemanagers'] ?=
          source: "#{__dirname}/../resources/prometheus-nodemanagers.json.j2"
          local: true
          title: 'YARN NodeManagers'
          slug: 'yarn-nodemanagers'
          cluster_name: options.cluster_name
          datasource: options.datasource
      if service.deps.yarn_rm
        options.templates['yarn-resourcemanagers'] ?=
          source: "#{__dirname}/../resources/prometheus-resourcemanagers.json.j2"
          local: true
          title: 'YARN ResourceManagers'
          slug: 'yarn-resourcemanagers'
          cluster_name: options.cluster_name
          datasource: options.datasource
        options.templates['yarn-queues'] ?=
          source: "#{__dirname}/../resources/prometheus-queues.json.j2"
          local: true
          title: 'YARN Queues'
          slug: 'yarn-queues'
          cluster_name: options.cluster_name
          datasource: options.datasource
      if service.deps.collectd_exporter
        options.templates['system-activity'] ?=
          source: "#{__dirname}/../resources/prometheus-system-activity.json.j2"
          local: true
          title: 'System Activity'
          slug: 'system-activity'
      if service.deps.hbase_master
        options.templates['hbase-home'] ?= 
          source: "#{__dirname}/../resources/prometheus-hbase-home.json.j2"
          local: true
          title: 'HBase Home'
          slug: 'hbase-home'
          cluster_name: options.cluster_name
          datasource: options.datasource
        options.templates['hbase-misc'] ?= 
          source: "#{__dirname}/../resources/prometheus-hbase-misc.json.j2"
          local: true
          title: 'HBase Misc'
          slug: 'hbase-misc'
          cluster_name: options.cluster_name
          datasource: options.datasource
        options.templates['hbase-regionservers'] ?= 
          source: "#{__dirname}/../resources/prometheus-hbase-regionservers.json.j2"
          local: true
          title: 'HBase RegionServers'
          slug: 'hbase-regionservers'
          cluster_name: options.cluster_name
          datasource: options.datasource
        options.templates['hbase-tables'] ?= 
          source: "#{__dirname}/../resources/prometheus-hbase-tables.json.j2"
          local: true
          title: 'HBase Tables'
          slug: 'hbase-tables'
          cluster_name: options.cluster_name
          datasource: options.datasource
        options.templates['hbase-users'] ?= 
          source: "#{__dirname}/../resources/prometheus-hbase-users.json.j2"
          local: true
          title: 'HBase Users'
          slug: 'hbase-users'
          cluster_name: options.cluster_name
          datasource: options.datasource

## Wait

      options.wait_db_admin = service.deps.db_admin.options.wait
      options.wait ?= {}
      options.wait.http = for srv in service.deps.grafana_webui
        host: srv.node.fqdn
        port: srv.options.ini['server']['http_port'] or options.ini['server']['http_port'] or 3000

## Dependencies

    {merge} = require 'nikita/lib/misc'

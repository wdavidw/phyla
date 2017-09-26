

    module.exports = (service) ->
      service = migration.call @, service, 'ryba/hbase/regionserver', ['ryba', 'hbase', 'regionserver'], require('nikita/lib/misc').merge require('.').use,
        iptables: key: ['iptables']
        krb5_client: key: ['krb5_client']
        java: key: ['java']
        zookeeper_server: key: ['ryba', 'zookeeper']
        hadoop_core: key: ['ryba']
        hdfs_nn: key: ['ryba', 'hdfs', 'nn']
        hdfs_dn: key: ['ryba', 'hdfs', 'dn']
        hdfs_client: key: ['ryba', 'hdfs_client']
        hbase_master: key: ['ryba', 'hbase', 'master']
        hbase_regionserver: key: ['ryba', 'hbase', 'regionserver']
        ranger_admin: key: ['ryba', 'ranger', 'admin']
        ganglia_collector: key: ['ryba', 'ganglia']
      @config.ryba ?= {}
      @config.ryba.hbase ?= {}
      options = @config.ryba.hbase.regionserver = service.options

## Kerberos

      options.krb5 ?= {}
      options.krb5.realm ?= service.use.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      throw Error 'Required Options: "realm"' unless options.krb5.realm
      options.krb5.admin ?= service.use.krb5_client.options.admin[options.krb5.realm]

## Identities

      options.hadoop_group = merge {}, service.use.hadoop_core.options.hadoop_group, options.hadoop_group
      options.group = merge service.use.hbase_master[0].options.group, options.group
      options.user = merge service.use.hbase_master[0].options.user, options.user
      options.admin = merge service.use.hbase_master[0].options.admin, options.admin

## Environment

      # Layout
      options.conf_dir ?= '/etc/hbase-regionserver/conf'
      # We could use hdfs_dn but defaultFS isnt defined
      options.hdfs_conf_dir ?= service.use.hdfs_client.options.conf_dir
      options.log_dir ?= '/var/log/hbase'
      options.pid_dir ?= '/var/run/hbase'
      # Env & Java
      options.env ?= {}
      options.env['JAVA_HOME'] ?= service.use.java.options.java_home
      # http://blog.sematext.com/2012/07/16/hbase-memstore-what-you-should-know/
      # Keep hbase.regionserver.hlog.blocksize * hbase.regionserver.maxlogs just
      # Value is a bit above hbase.regionserver.global.memstore.lowerLimit * HBASE_HEAPSIZE
      # 'HBASE_REGIONSERVER_OPTS ?= '-Xmn200m -Xms4096m -Xmx4096m' # Default in HDP companion file
      options.heapsize ?= "256m" #i.e. -Xmx256m
      options.java_opts ?= "" #rs.java_opts is build at runtime from the rs.opts object
      options.opts ?= {} #represent the java options obect
      # Misc
      options.fqdn = service.node.fqdn
      options.hostname = service.node.hostname
      options.iptables ?= service.use.iptables and service.use.iptables.options.action is 'start'
      options.clean_logs ?= false
      
## Registration

      for srv in service.use.hbase_master
        srv.options.regionservers[service.node.fqdn] ?= true

      for srv in service.use.hbase_regionserver
        srv.options.regionservers ?= {}
        srv.options.regionservers[service.node.fqdn] ?= true

## Configuration

      options.hbase_site ?= {}
      options.hbase_site['hbase.regionserver.port'] ?= '60020'
      options.hbase_site['hbase.regionserver.info.port'] ?= '60030'
      options.hbase_site['hbase.ssl.enabled'] ?= 'true'
      options.hbase_site['hbase.regionserver.handler.count'] ?= 60 # HDP default

## Security

      options.hbase_site['hbase.security.authentication'] ?= service.use.hbase_master[0].options.hbase_site['hbase.security.authentication']
      if options.hbase_site['hbase.security.authentication'] is 'kerberos'
        options.hbase_site['hbase.master.kerberos.principal'] = service.use.hbase_master[0].options.hbase_site['hbase.master.kerberos.principal']
        options.hbase_site['hbase.regionserver.kerberos.principal'] ?= service.use.hbase_master[0].options.hbase_site['hbase.regionserver.kerberos.principal']
        options.hbase_site['hbase.regionserver.keytab.file'] ?= '/etc/security/keytabs/rs.service.keytab'
        options.hbase_site['hbase.security.authentication.ui'] ?= 'kerberos'
        options.hbase_site['hbase.security.authentication.spnego.kerberos.principal'] ?= "HTTP/_HOST@#{options.krb5.realm}"
        options.hbase_site['hbase.security.authentication.spnego.kerberos.keytab'] ?= service.use.hadoop_core.options.core_site['hadoop.http.authentication.kerberos.keytab']
      options.hbase_site['hbase.regionserver.global.memstore.upperLimit'] = null # Deprecated from HDP 2.3
      options.hbase_site['hbase.regionserver.global.memstore.size'] = '0.4' # Default in HDP Companion Files
      options.hbase_site['hbase.coprocessor.region.classes'] =  service.use.hbase_master[0].options.hbase_site['hbase.coprocessor.region.classes']
      # Jaas file
      options.opts['java.security.auth.login.config'] ?= "#{options.conf_dir}/hbase-regionserver.jaas"
      # Copy the Master keytab if a colocalised Master is found and if their principals are equal.
      local_master = service.use.hbase_master.filter( (srv) -> srv.node.fqdn is service.node.fqdn)[0]
      are_principal_equal = local_master.options.hbase_site['hbase.master.kerberos.principal'] is options.hbase_site['hbase.regionserver.kerberos.principal'] if local_master
      if local_master and are_principal_equal
        options.copy_master_keytab ?= local_master.options.hbase_site['hbase.master.keytab.file']

## Configuration Distributed mode

      for property in [
        'zookeeper.znode.parent'
        'zookeeper.session.timeout'
        'hbase.cluster.distributed'
        'hbase.rootdir'
        'hbase.zookeeper.quorum'
        'hbase.zookeeper.property.clientPort'
        'dfs.domain.socket.path'
      ] then options.hbase_site[property] ?= service.use.hbase_master[0].options.hbase_site[property]

## Configuration for HA Reads

HA properties must be available to masters and regionservers.

      properties = [
        'hbase.regionserver.storefile.refresh.period'
        'hbase.regionserver.meta.storefile.refresh.period'
        'hbase.region.replica.replication.enabled'
        'hbase.master.hfilecleaner.ttl'
        'hbase.master.loadbalancer.class'
        'hbase.meta.replica.count'
        'hbase.region.replica.wait.for.primary.flush'
        'hbase.region.replica.storefile.refresh.memstore.multiplier'
      ]
      for property in properties then options.hbase_site[property] ?= service.use.hbase_master[0].options.hbase_site[property]

## Configuration for security

      options.hbase_site['hbase.security.authorization'] ?= service.use.hbase_master[0].options.hbase_site['hbase.security.authorization']
      options.hbase_site['hbase.rpc.engine'] ?= service.use.hbase_master[0].options.hbase_site['hbase.rpc.engine']
      options.hbase_site['hbase.superuser'] ?= service.use.hbase_master[0].options.hbase_site['hbase.superuser']
      options.hbase_site['hbase.bulkload.staging.dir'] ?= service.use.hbase_master[0].options.hbase_site['hbase.bulkload.staging.dir']

## Configuration Quota

      hbase.rs.site['hbase.quota.enabled'] ?= hm_ctxs[0].config.ryba.hbase.master.site['hbase.quota.enabled']
      hbase.rs.site['hbase.quota.refresh.period'] ?= hm_ctxs[0].config.ryba.hbase.master.site['hbase.quota.refresh.period']

## Ranger Plugin Configuration

      # @config.ryba.hbase_plugin_is_master = false

## Configuration for metrics

Metrics information are entirely derived from the Master.

      options.metrics ?= service.use.hbase_master[0].options.metrics

## Configuration for Log4J

      options.opts['hbase.security.log.file'] ?= 'SecurityAuth-Regional.audit'
      options.log4j ?= {}
      #HBase bin script use directly environment bariables
      options.env['HBASE_ROOT_LOGGER'] ?= 'INFO,RFA'
      options.env['HBASE_SECURITY_LOGGER'] ?= 'INFO,RFAS'
      if @config.log4j?.services?
        if @config.log4j?.remote_host? and @config.log4j?.remote_port? and ('ryba/hbase/regionserver' in @config.log4j?.services)
          # adding SOCKET appender
          options.socket_client ?= "SOCKET"
          # Root logger
          if options.env['HBASE_ROOT_LOGGER'].indexOf(options.socket_client) is -1
          then options.env['HBASE_ROOT_LOGGER'] += ",#{options.socket_client}"
          # Security Logger
          if options.env['HBASE_SECURITY_LOGGER'].indexOf(options.socket_client) is -1
          then options.env['HBASE_SECURITY_LOGGER']+= ",#{options.socket_client}"

          options.opts['hbase.log.application'] = 'hbase-regionserver'
          options.opts['hbase.log.remote_host'] = @config.log4j.remote_host
          options.opts['hbase.log.remote_port'] = @config.log4j.remote_port

          options.socket_opts ?=
            Application: '${hbase.log.application}'
            RemoteHost: '${hbase.log.remote_host}'
            Port: '${hbase.log.remote_port}'
            ReconnectionDelay: '10000'

          options.log4j = merge options.log4j, appender
            type: 'org.apache.log4j.net.SocketAppender'
            name: options.socket_client
            logj4: options.log4j
            properties: options.socket_opts

## Wait

      options.wait_krb5_client = service.use.krb5_client.options.wait
      options.wait_zookeeper_server = service.use.zookeeper_server[0].options.wait
      options.wait_hdfs_nn = service.use.hdfs_nn[0].options.wait
      options.wait_hbase_master = service.use.hbase_master[0].options.wait
      options.wait = {}
      for srv in service.use.hbase_regionserver
        srv.options.hbase_site ?= {}
        srv.options.hbase_site['hbase.regionserver.port'] ?= '60000'
        srv.options.hbase_site['hbase.regionserver.info.port'] ?= '60010'
      options.wait.rpc = for srv in service.use.hbase_regionserver
        host: srv.node.fqdn
        port: srv.options.hbase_site['hbase.regionserver.port']
      options.wait.info = for srv in service.use.hbase_regionserver
        host: srv.node.fqdn
        port: srv.options.hbase_site['hbase.regionserver.info.port']

## Dependencies

    appender = require '../../lib/appender'
    {merge} = require 'nikita/lib/misc'
    migration = require 'masson/lib/migration'

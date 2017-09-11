
# HBase Client Configuration

    module.exports = (service) ->
      service = migration.call @, service, 'ryba/hbase/client', ['ryba', 'hbase', 'client'], require('nikita/lib/misc').merge require('.').use,
        java: key: ['java']
        test_user: key: ['ryba', 'test_user']
        mapred_client: key: ['ryba', 'mapred']
        hbase_master: key: ['ryba', 'hbase', 'master']
        hbase_regionserver: key: ['ryba', 'hbase', 'regionserver']
        ranger_admin: key: ['ryba', 'ranger', 'admin']
        ranger_hbase: key: ['ryba', 'ranger', 'hbase']
      @config.ryba ?= {}
      @config.ryba.hbase ?= {}
      options = @config.ryba.hbase.client = service.options

# Identities

      options.group = merge service.use.hbase_master[0].options.group, options.group
      options.user = merge service.use.hbase_master[0].options.user, options.user
      # Krb5 admin user
      options.admin = merge service.use.hbase_master[0].options.admin, options.admin
      options.ranger_admin ?= service.use.ranger_admin.options.admin if service.use.ranger_admin

## Environment

      # Layout
      options.conf_dir ?= '/etc/hbase/conf'
      options.log_dir ?= '/var/log/hbase'
      # Java
      options.env ?=  {}
      options.env['JAVA_HOME'] ?= "#{service.use.java.options.java_home}"
      options.env['HBASE_LOG_DIR'] ?= "#{options.log_dir}"
      options.env['HBASE_OPTS'] ?= '-ea -XX:+UseConcMarkSweepGC -XX:+CMSIncrementalMode' # Default in HDP companion file
      # Misc
      options.hostname ?= service.node.hostname
      options.force_check ?= true
      options.is_ha ?= service.use.hbase_master.length

## Test

      options.ranger_install = service.use.ranger_hbase[0].options.install if service.use.ranger_hbase
      options.test = merge {}, service.use.test_user.options, options.test
      options.test.namespace ?= "ryba_check_client_#{service.node.hostname}"
      options.test.table ?= 'a_table'

## Configuration

      options.hbase_site ?= {}

## Configure Security

      options.hbase_site['hbase.security.authentication'] = service.use.hbase_master[0].options.hbase_site['hbase.security.authentication']
      options.hbase_site['hbase.security.authorization'] = service.use.hbase_master[0].options.hbase_site['hbase.security.authorization']
      options.hbase_site['hbase.superuser'] = service.use.hbase_master[0].options.hbase_site['hbase.superuser']
      options.hbase_site['hbase.rpc.engine'] ?= service.use.hbase_master[0].options.hbase_site['hbase.rpc.engine']
      options.hbase_site['hbase.bulkload.staging.dir'] = service.use.hbase_master[0].options.hbase_site['hbase.bulkload.staging.dir']
      options.hbase_site['hbase.master.kerberos.principal'] = service.use.hbase_master[0].options.hbase_site['hbase.master.kerberos.principal']
      options.hbase_site['hbase.regionserver.kerberos.principal'] = service.use.hbase_master[0].options.hbase_site['hbase.regionserver.kerberos.principal']

## HBase Replication

      options.hbase_site['hbase.replication'] ?= service.use.hbase_master[0].options.hbase_site['hbase.replication']

## Client Configuration HA Reads

      if parseInt(service.use.hbase_master[0].options.hbase_site['hbase.meta.replica.count']) > 1
        options.hbase_site['hbase.ipc.client.specificThreadForWriting'] ?= 'true'
        options.hbase_site['hbase.client.primaryCallTimeout.get'] ?= '10000'
        options.hbase_site['hbase.client.primaryCallTimeout.multiget'] ?= '10000'
        options.hbase_site['hbase.client.primaryCallTimeout.scan'] ?= '1000000'
        options.hbase_site['hbase.meta.replicas.use'] ?= 'true'

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

## Wait

      options.wait_hbase_master = service.use.hbase_master[0].options.wait
      options.wait_hbase_regionserver = service.use.hbase_regionserver[0].options.wait
      options.wait_ranger_admin = service.use.ranger_admin.options.wait if service.use.ranger_admin

## Configuration Quota

      hbase.site['hbase.quota.enabled'] ?= hm_ctxs[0].config.ryba.hbase.master.site['hbase.quota.enabled']
      hbase.site['hbase.quota.refresh.period'] ?= hm_ctxs[0].config.ryba.hbase.master.site['hbase.quota.refresh.period']

## Dependencies

    {merge} = require 'nikita/lib/misc'
    migration = require 'masson/lib/migration'

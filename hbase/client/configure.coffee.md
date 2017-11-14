
# HBase Client Configuration

    module.exports = (service) ->
      options = service.options

# Identities

      options.group = merge service.deps.hbase_master[0].options.group, options.group
      options.user = merge service.deps.hbase_master[0].options.user, options.user
      # Krb5 admin user
      options.admin = merge service.deps.hbase_master[0].options.admin, options.admin
      options.ranger_admin ?= service.deps.ranger_admin.options.admin if service.deps.ranger_admin
      # Kerberos Test Principal
      options.test_krb5_user ?= service.deps.test_user.options.krb5.user

## Environment

      # Layout
      options.conf_dir ?= '/etc/hbase/conf'
      options.log_dir ?= '/var/log/hbase'
      # Java
      options.env ?=  {}
      options.env['JAVA_HOME'] ?= "#{service.deps.java.options.java_home}"
      options.env['HBASE_LOG_DIR'] ?= "#{options.log_dir}"
      options.env['HBASE_OPTS'] ?= '-ea -XX:+UseConcMarkSweepGC -XX:+CMSIncrementalMode' # Default in HDP companion file
      # Misc
      options.hostname ?= service.node.hostname
      options.force_check ?= true
      options.is_ha ?= service.deps.hbase_master.length

## Test

      options.ranger_install = service.deps.ranger_hbase[0].options.install if service.deps.ranger_hbase
      options.test = merge {}, service.deps.test_user.options, options.test
      options.test.namespace ?= "ryba_check_client_#{service.node.hostname}"
      options.test.table ?= 'a_table'

## Configuration

      options.hbase_site ?= {}

## Configure Security

      options.hbase_site['hbase.security.authentication'] = service.deps.hbase_master[0].options.hbase_site['hbase.security.authentication']
      options.hbase_site['hbase.security.authorization'] = service.deps.hbase_master[0].options.hbase_site['hbase.security.authorization']
      options.hbase_site['hbase.superuser'] = service.deps.hbase_master[0].options.hbase_site['hbase.superuser']
      options.hbase_site['hbase.rpc.engine'] ?= service.deps.hbase_master[0].options.hbase_site['hbase.rpc.engine']
      options.hbase_site['hbase.bulkload.staging.dir'] = service.deps.hbase_master[0].options.hbase_site['hbase.bulkload.staging.dir']
      options.hbase_site['hbase.master.kerberos.principal'] = service.deps.hbase_master[0].options.hbase_site['hbase.master.kerberos.principal']
      options.hbase_site['hbase.regionserver.kerberos.principal'] = service.deps.hbase_master[0].options.hbase_site['hbase.regionserver.kerberos.principal']

## HBase Replication

      options.hbase_site['hbase.replication'] ?= service.deps.hbase_master[0].options.hbase_site['hbase.replication']

## Client Configuration HA Reads

      if parseInt(service.deps.hbase_master[0].options.hbase_site['hbase.meta.replica.count']) > 1
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
      ] then options.hbase_site[property] ?= service.deps.hbase_master[0].options.hbase_site[property]

## Configuration Quota

      options.hbase_site['hbase.quota.enabled'] ?= service.deps.hbase_master[0].options.hbase_site['hbase.quota.enabled']
      options.hbase_site['hbase.quota.refresh.period'] ?= service.deps.hbase_master[0].options.hbase_site['hbase.quota.refresh.period']

## Wait

      options.wait_hbase_master = service.deps.hbase_master[0].options.wait
      options.wait_hbase_regionserver = service.deps.hbase_regionserver[0].options.wait
      options.wait_ranger_admin = service.deps.ranger_admin.options.wait if service.deps.ranger_admin

## Dependencies

    {merge} = require 'nikita/lib/misc'

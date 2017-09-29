
# Oozie Client Configuration

    module.exports =  ->
      service = migration.call @, service, 'ryba/oozie/client', ['ryba', 'oozie', 'client'], require('nikita/lib/misc').merge require('.').use,
        ssl: key: ['ssl']
        krb5_client: key: ['krb5_client']
        java: key: ['java']
        test_user: key: ['ryba', 'test_user']
        ranger_admin: key: ['ryba', 'ranger', 'admin']
        ranger_hive: key: ['ryba', 'ranger', 'hive']
        hdfs_dn: key: ['ryba', 'hdfs', 'dn']
        hdfs_client: key: ['ryba', 'hdfs_client']
        yarn_rm: key: ['ryba', 'yarn', 'rm']
        yarn_client: key: ['ryba', 'yarn_client']
        mapred_client: key: ['ryba', 'mapred']
        hive_server2: key: ['ryba', 'hive', 'server2']
        oozie_server: key: ['ryba', 'oozie', 'server']
      @config.ryba ?= {}
      @config.ryba.oozie ?= {}
      options = @config.ryba.oozie.client = service.options

## Identities

      options.group = merge {}, service.use.oozie_server[0].options.group, options.group
      options.user = merge {}, service.use.oozie_server[0].options.user, options.user

## Environment

      # Layout
      options.conf_dir ?= '/etc/oozie/conf'
      # Java
      options.java_home ?= service.use.java.options.java_home
      options.jre_home ?= service.use.java.options.jre_home
      # Misc
      options.hostname = service.use.hostname
      options.force_check ?= false
      options.hdfs_defaultfs ?= service.use.hdfs_client.options.core_site['fs.defaultFS']

## Configuration

      options.oozie_site ?= {}
      options.oozie_site['oozie.base.url'] = service.use.oozie_server[0].options.oozie_site['oozie.base.url']
      options.oozie_site['oozie.service.HadoopAccessorService.kerberos.principal'] = service.use.oozie_server[0].options.oozie_site['oozie.service.HadoopAccessorService.kerberos.principal']

## SSL

      options.ssl = merge {}, service.use.ssl?.options, options.ssl
      options.ssl.enabled ?= !!service.use.ssl

## Test

      options.ranger_admin ?= service.use.ranger_admin.options.admin if service.use.ranger_admin
      options.ranger_install = service.use.ranger_hive[0].options.install if service.use.ranger_hive
      options.test = merge {}, service.use.test_user.options, options.test
      # Hive Server2
      options.hive_server2 = for srv in service.use.hive_server2
        fqdn: srv.options.fqdn
        hostname: srv.options.hostname
        hive_site: srv.options.hive_site
      options.ssl_client = service.use.hdfs_dn[0].options.ssl_client
      shortname = if service.use.yarn_rm.length > 1
      then ".#{service.use.yarn_rm[0].options.yarn_site['yarn.resourcemanager.ha.id']}"
      else shortname = ''
      options.jobtracker = service.use.yarn_rm[0].options.yarn_site["yarn.resourcemanager.address#{shortname}"]

## Wait

      options.wait_oozie_server = service.use.oozie_server[0].options.wait
      options.wait_ranger_admin = service.use.ranger_admin.options.wait
      # options.wait_oozie_server = for srv in service.use.oozie_server
      #   for test, config of srv.options.wait
      #     options.wait_oozie_server[test] ?= []
      #     options.wait_oozie_server[test].push config

## Dependencies

    {merge} = require 'nikita/lib/misc'
    migration = require 'masson/lib/migration'

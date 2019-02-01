
# Oozie Client Configuration

    module.exports = (service) ->
      options = service.options

## Identities

      options.group = merge {}, service.deps.oozie_server[0].options.group, options.group
      options.user = merge {}, service.deps.oozie_server[0].options.user, options.user

## Kerberos

      # Kerberos Test Principal
      options.test_krb5_user ?= service.deps.test_user.options.krb5.user

## Environment

      # Layout
      options.conf_dir ?= '/etc/oozie/conf'
      # Java
      options.java_home ?= service.deps.java.options.java_home
      options.jre_home ?= service.deps.java.options.jre_home
      # Misc
      options.hostname = service.node.hostname
      options.fqdn = service.node.fqdn
      options.force_check ?= false
      options.hdfs_defaultfs ?= service.deps.hdfs_client.options.core_site['fs.defaultFS']

## Configuration

      options.oozie_site ?= {}
      options.oozie_site['oozie.base.url'] = service.deps.oozie_server[0].options.oozie_site['oozie.base.url']
      options.oozie_site['oozie.service.HadoopAccessorService.kerberos.principal'] = service.deps.oozie_server[0].options.oozie_site['oozie.service.HadoopAccessorService.kerberos.principal']

## SSL

      options.ssl = merge {}, service.deps.ssl?.options, options.ssl
      options.ssl.enabled ?= !!service.deps.ssl

## Test

      options.ranger_admin ?= service.deps.ranger_admin.options.admin if service.deps.ranger_admin
      options.ranger_install = service.deps.ranger_hive[0].options.install if service.deps.ranger_hive
      options.test = merge {}, service.deps.test_user.options, options.test
      #hive client properties for hcat check
      if service.deps.hive_hcatalog?.length > 0 and service.deps.hive_client?
        options.test.hive_hcat ?= true
        options.hive_hcat_principal ?= service.deps.hive_hcatalog[0].options.hive_site['hive.metastore.kerberos.principal']
        options.hive_hcat_uris ?= service.deps.hive_hcatalog[0].options.hive_site['hive.metastore.uris']
      # Hive Server2
      if service.deps.hive_server2
        options.hive_server2 = for srv in service.deps.hive_server2
          fqdn: srv.options.fqdn
          hostname: srv.options.hostname
          hive_site: srv.options.hive_site
      options.ssl_client = service.deps.hdfs_dn[0].options.ssl_client
      shortname = if service.deps.yarn_rm.length > 1
      then ".#{service.deps.yarn_rm[0].options.yarn_site['yarn.resourcemanager.ha.id']}"
      else shortname = ''
      options.jobtracker = service.deps.yarn_rm[0].options.yarn_site["yarn.resourcemanager.address#{shortname}"]

## Wait

      options.wait_oozie_server = service.deps.oozie_server[0].options.wait
      options.wait_ranger_admin = service.deps.ranger_admin.options.wait if service.deps.ranger_admin
      # options.wait_oozie_server = for srv in service.deps.oozie_server
      #   for test, config of srv.options.wait
      #     options.wait_oozie_server[test] ?= []
      #     options.wait_oozie_server[test].push config

## Dependencies

    {merge} = require '@nikita/core/lib/misc'

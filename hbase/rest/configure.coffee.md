

## Configuration

See [REST Gateway Impersonation Configuration][impersonation].

[impersonation]: http://hbase.apache.org/book.html#security.rest.gateway

    module.exports = (service) ->
      options = service.options

## Identities

      options.group = merge service.deps.hbase_master[0].options.group, options.group
      options.user = merge service.deps.hbase_master[0].options.user, options.user
      options.admin = merge service.deps.hbase_master[0].options.admin, options.admin
      options.ranger_admin ?= service.deps.ranger_admin.options.admin if service.deps.ranger_admin

## Kerberos

      options.krb5 ?= {}
      options.krb5.realm ?= service.deps.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      throw Error 'Required Options: "realm"' unless options.krb5.realm
      options.krb5.admin ?= service.deps.krb5_client.options.admin[options.krb5.realm]
      # Kerberos Test Principal
      options.test_krb5_user ?= service.deps.test_user.options.krb5.user
      options.clean_logs ?= false

## Environment

      # Layout
      options.conf_dir ?= '/etc/hbase-rest/conf'
      options.log_dir ?= '/var/log/hbase'
      options.pid_dir ?= '/var/run/hbase'
      # Env & Java
      options.env ?= {}
      options.env['JAVA_HOME'] ?= service.deps.java.options.java_home
      # Misc
      options.hostname = service.node.hostname
      options.fqdn = service.node.fqdn
      options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'
      options.force_check ?= false

## Rest Server Configuration

      options.hbase_site ?= {}
      options.hbase_site['hbase.rest.port'] ?= '60080' # Default to "8080"
      options.hbase_site['hbase.rest.info.port'] ?= '60085' # Default to "8085"
      options.hbase_site['hbase.rest.ssl.enabled'] ?= 'true'
      options.hbase_site['hbase.rest.ssl.keystore.store'] ?= service.deps.hadoop_core.options.ssl_server['ssl.server.keystore.location']
      options.hbase_site['hbase.rest.ssl.keystore.password'] ?= service.deps.hadoop_core.options.ssl_server['ssl.server.keystore.password']
      options.hbase_site['hbase.rest.ssl.keystore.keypassword'] ?= service.deps.hadoop_core.options.ssl_server['ssl.server.keystore.keypassword']
      options.hbase_site['hbase.rest.kerberos.principal'] ?= "hbase_rest/_HOST@#{options.krb5.realm}" # Dont forget `grant 'rest_server', 'RWCA'`
      options.hbase_site['hbase.rest.keytab.file'] ?= '/etc/security/keytabs/hbase_rest.service.keytab'
      options.hbase_site['hbase.rest.authentication.type'] ?= 'kerberos'
      options.hbase_site['hbase.rest.support.proxyuser'] ?= 'true'
      options.hbase_site['hbase.rest.authentication.kerberos.principal'] ?= "HTTP/_HOST@#{options.krb5.realm}"
      # options.hbase_site['hbase.rest.authentication.kerberos.keytab'] ?= "#{hbase.conf_dir}/hbase.service.keytab"
      options.hbase_site['hbase.rest.authentication.kerberos.keytab'] ?= service.deps.hadoop_core.options.core_site['hadoop.http.authentication.kerberos.keytab']
      options.hbase_site['hbase.security.authentication'] ?= service.deps.hbase_master[0].options.hbase_site['hbase.security.authentication']
      options.hbase_site['hbase.security.authorization'] ?= service.deps.hbase_master[0].options.hbase_site['hbase.security.authorization']
      options.hbase_site['hbase.master.kerberos.principal'] ?= service.deps.hbase_master[0].options.hbase_site['hbase.master.kerberos.principal']
      options.hbase_site['hbase.regionserver.kerberos.principal'] ?= service.deps.hbase_master[0].options.hbase_site['hbase.regionserver.kerberos.principal']
      options.hbase_site['hbase.rpc.engine'] ?= service.deps.hbase_master[0].options.hbase_site['hbase.rpc.engine']

## Proxy Users

      krb5_username = /^(.+?)[@\/]/.exec(options.hbase_site['hbase.rest.kerberos.principal'])?[1]
      throw Error 'Invalid HBase Rest principal' unless krb5_username
      for srv in [service.deps.hbase_master..., service.deps.hbase_regionserver...]
        srv.options.hbase_site["hadoop.proxyuser.#{krb5_username}.groups"] ?= '*'
        srv.options.hbase_site["hadoop.proxyuser.#{krb5_username}.hosts"] ?= '*'

## Distributed mode

      for property in [
        'zookeeper.znode.parent'
        'hbase.cluster.distributed'
        'hbase.rootdir'
        'hbase.zookeeper.quorum'
        'hbase.zookeeper.property.clientPort'
        'dfs.domain.socket.path'
      ] then options.hbase_site[property] ?= service.deps.hbase_master[0].options.hbase_site[property]

## Test


      options.ranger_install = service.deps.ranger_hbase[0].options.install if service.deps.ranger_hbase
      options.test = merge {}, service.deps.test_user.options, options.test
      options.test.namespace ?= "ryba_check_rest_#{service.node.hostname}"
      options.test.table ?= 'a_table'

## Wait

      options.wait_krb5_client = service.deps.krb5_client.options.wait
      options.wait_hbase_master = service.deps.hbase_master[0].options.wait
      options.wait_ranger_admin = service.deps.ranger_admin.options.wait if service.deps.ranger_admin
      for srv in service.deps.hbase_rest
        srv.options.hbase_site ?= {}
        srv.options.hbase_site['hbase.rest.port'] ?= '60080'
        srv.options.hbase_site['hbase.rest.info.port'] ?= '60085'
      options.wait = {}
      options.wait.http = for srv in service.deps.hbase_rest
        host: srv.node.fqdn
        port: srv.options.hbase_site['hbase.rest.port']
      options.wait.http_info = for srv in service.deps.hbase_rest
        host: srv.node.fqdn
        port: srv.options.hbase_site['hbase.rest.info.port']

## Dependencies

    {merge} = require 'nikita/lib/misc'

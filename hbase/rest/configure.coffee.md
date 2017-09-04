

## Configuration

See [REST Gateway Impersonation Configuration][impersonation].

[impersonation]: http://hbase.apache.org/book.html#security.rest.gateway

    module.exports = (service) ->
      service = migration.call @, service, 'ryba/hbase/rest', ['ryba', 'hbase', 'rest'], require('nikita/lib/misc').merge require('.').use,
        iptables: key: ['iptables']
        krb5_client: key: ['krb5_client']
        java: key: ['java']
        hadoop_core: key: ['ryba']
        hdfs_dn: key: ['ryba', 'hdfs', 'dn']
        hdfs_client: key: ['ryba', 'hdfs_client']
        hbase_master: key: ['ryba', 'hbase', 'master']
        hbase_regionserver: key: ['ryba', 'hbase', 'regionserver']
        hbase_client: key: ['ryba', 'hbase', 'client']
        hbase_rest: key: ['ryba', 'hbase', 'rest']
      @config.ryba ?= {}
      @config.ryba.hbase ?= {}
      options = @config.ryba.hbase.rest = service.options

## Kerberos

      options.krb5 ?= {}
      options.krb5.realm ?= service.use.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      throw Error 'Required Options: "realm"' unless options.krb5.realm
      options.krb5.admin ?= service.use.krb5_client.options.admin[options.krb5.realm]

## Identities

      options.group = merge service.use.hbase_master[0].options.group, options.group
      options.user = merge service.use.hbase_master[0].options.user, options.user
      options.admin = merge service.use.hbase_master[0].options.admin, options.admin
      options.ranger_admin ?= service.use.ranger_admin.options.admin if service.use.ranger_admin

## Environnment

      # Layout
      options.conf_dir ?= '/etc/hbase-rest/conf'
      options.log_dir ?= '/var/log/hbase'
      options.pid_dir ?= '/var/run/hbase'
      # Env & Java
      options.env ?= {}
      options.env['JAVA_HOME'] ?= service.use.java.options.java_home
      # Misc
      options.fqdn = service.node.fqdn
      options.iptables ?= service.use.iptables and service.use.iptables.options.action is 'start'
      options.force_check ?= false

## Rest Server Configuration

      options.hbase_site ?= {}
      options.hbase_site['hbase.rest.port'] ?= '60080' # Default to "8080"
      options.hbase_site['hbase.rest.info.port'] ?= '60085' # Default to "8085"
      options.hbase_site['hbase.rest.ssl.enabled'] ?= 'true'
      options.hbase_site['hbase.rest.ssl.keystore.store'] ?= service.use.hadoop_core.options.ssl_server['ssl.server.keystore.location']
      options.hbase_site['hbase.rest.ssl.keystore.password'] ?= service.use.hadoop_core.options.ssl_server['ssl.server.keystore.password']
      options.hbase_site['hbase.rest.ssl.keystore.keypassword'] ?= service.use.hadoop_core.options.ssl_server['ssl.server.keystore.keypassword']
      options.hbase_site['hbase.rest.kerberos.principal'] ?= "hbase_rest/_HOST@#{options.krb5.realm}" # Dont forget `grant 'rest_server', 'RWCA'`
      options.hbase_site['hbase.rest.keytab.file'] ?= '/etc/security/keytabs/hbase_rest.service.keytab'
      options.hbase_site['hbase.rest.authentication.type'] ?= 'kerberos'
      options.hbase_site['hbase.rest.support.proxyuser'] ?= 'true'
      options.hbase_site['hbase.rest.authentication.kerberos.principal'] ?= "HTTP/_HOST@#{options.krb5.realm}"
      # options.hbase_site['hbase.rest.authentication.kerberos.keytab'] ?= "#{hbase.conf_dir}/hbase.service.keytab"
      options.hbase_site['hbase.rest.authentication.kerberos.keytab'] ?= service.use.hadoop_core.options.core_site['hadoop.http.authentication.kerberos.keytab']
      options.hbase_site['hbase.security.authentication'] ?= service.use.hbase_master[0].options.hbase_site['hbase.security.authentication']
      options.hbase_site['hbase.security.authorization'] ?= service.use.hbase_master[0].options.hbase_site['hbase.security.authorization']
      options.hbase_site['hbase.master.kerberos.principal'] ?= service.use.hbase_master[0].options.hbase_site['hbase.master.kerberos.principal']
      options.hbase_site['hbase.regionserver.kerberos.principal'] ?= service.use.hbase_master[0].options.hbase_site['hbase.regionserver.kerberos.principal']
      options.hbase_site['hbase.rpc.engine'] ?= service.use.hbase_master[0].options.hbase_site['hbase.rpc.engine']

## Proxy Users

      krb5_username = /^(.+?)[@\/]/.exec(options.hbase_site['hbase.rest.kerberos.principal'])?[1]
      throw Error 'Invalid HBase Rest principal' unless krb5_username
      for srv in [service.use.hbase_master..., service.use.hbase_regionserver...]
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
      ] then options.hbase_site[property] ?= service.use.hbase_master[0].options.hbase_site[property]

## Test

      options.test ?= {}
      options.test.namespace ?= "ryba_check_rest_#{@config.shortname}"
      options.test.table ?= 'a_table'

## Wait

      options.wait_krb5_client = service.use.krb5_client
      options.wait_zookeeper_server = service.use.zookeeper_server
      options.wait_hdfs_nn = service.use.hdfs_nn
      options.wait_hbase_master = service.use.hbase_master
      for srv in service.use.hbase_rest
        srv.options.hbase_site ?= {}
        srv.options.hbase_site['hbase.rest.port'] ?= '9090'
        srv.options.hbase_site['hbase.rest.infot.port'] ?= '9095'
      options.wait = {}
      options.wait.http = for srv in service.use.hbase_rest
        host: srv.node.fqdn
        port: srv.options.hbase_site['hbase.rest.port']
      options.wait.http_info = for srv in service.use.hbase_rest
        host: srv.node.fqdn
        port: srv.options.hbase_site['hbase.rest.info.port']

## Dependencies

    {merge} = require 'nikita/lib/misc'
    migration = require 'masson/lib/migration'


# HBase Thrit Server Configuration

    module.exports = (service) ->
      service = migration.call @, service, 'ryba/hbase/thrift', ['ryba', 'hbase', 'thrift'], require('nikita/lib/misc').merge require('.').use,
        iptables: key: ['iptables']
        krb5_client: key: ['krb5_client']
        java: key: ['java']
        hadoop_core: key: ['ryba']
        hdfs_dn: key: ['ryba', 'hdfs', 'dn']
        hdfs_client: key: ['ryba', 'hdfs_client']
        hbase_master: key: ['ryba', 'hbase', 'master']
        hbase_regionserver: key: ['ryba', 'hbase', 'regionserver']
        hbase_client: key: ['ryba', 'hbase', 'client']
        hbase_thrift: key: ['ryba', 'hbase', 'thrift']
      @config.ryba ?= {}
      @config.ryba.hbase ?= {}
      options = @config.ryba.hbase.thrift = service.options

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
      options.conf_dir ?= '/etc/hbase-thrift/conf'
      options.log_dir ?= '/var/log/hbase'
      options.pid_dir ?= '/var/run/hbase'
      # Env & Java
      options.env ?= {}
      options.env['JAVA_HOME'] ?= service.use.java.options.java_home
      # Misc
      options.fqdn = service.node.fqdn
      options.iptables ?= service.use.iptables and service.use.iptables.options.action is 'start'

# Thrift Server Configuration  

      options.hbase_site ?= {}
      options.hbase_site['hbase.thrift.port'] ?= '9090' # Default to "8080"
      options.hbase_site['hbase.thrift.info.port'] ?= '9095' # Default to "8085"
      options.hbase_site['hbase.thrift.ssl.enabled'] ?= 'true'
      options.hbase_site['hbase.thrift.ssl.keystore.store'] ?= service.use.hadoop_core.options.ssl_server['ssl.server.keystore.location']
      options.hbase_site['hbase.thrift.ssl.keystore.password'] ?= service.use.hadoop_core.options.ssl_server['ssl.server.keystore.password']
      options.hbase_site['hbase.thrift.ssl.keystore.keypassword'] ?= service.use.hadoop_core.options.ssl_server['ssl.server.keystore.keypassword']
      # Type of HBase thrift server
      options.hbase_site['hbase.regionserver.thrift.server.type'] ?= 'TThreadPoolServer'
      # The value for the property hbase.thrift.security.qop can be one of the following values:
      # auth-conf - authentication, integrity, and confidentiality checking
      # auth-int - authentication and integrity checking
      # auth - authentication checking only
      options.hbase_site['hbase.thrift.security.qop'] ?= "auth"

## Security

*   [HBase docs enables impersonation][hbase-impersonation-mode]
*   [HBaseThrift configuration for hue][hue-thrift-impersonation]
*   [Cloudera docs for Enabling HBase Thrift Impersonation][hbase-configuration-cloudera]


[hue-thrift-impersonation]:http://gethue.com/hbase-browsing-with-doas-impersonation-and-kerberos/
[hbase-impersonation-mode]: http://hbase.apache.org/book.html#security.gateway.thrift
[hbase-configuration-cloudera]:(http://www.cloudera.com/content/www/en-us/documentation/enterprise/latest/topics/cdh_sg_hbase_authentication.html/)

      options.hbase_site['hbase.security.authentication'] ?= service.use.hbase_master[0].options.hbase_site['hbase.security.authentication']
      options.hbase_site['hbase.security.authorization'] ?= service.use.hbase_master[0].options.hbase_site['hbase.security.authorization']
      options.hbase_site['hbase.rpc.engine'] ?= service.use.hbase_master[0].options.hbase_site['hbase.rpc.engine']
      options.hbase_site['hbase.thrift.authentication.type'] = options.hbase_site['hbase.security.authentication'] ?= 'kerberos'
      options.hbase_site['hbase.master.kerberos.principal'] = service.use.hbase_master[0].options.hbase_site['hbase.master.kerberos.principal']
      options.hbase_site['hbase.regionserver.kerberos.principal'] = service.use.hbase_master[0].options.hbase_site['hbase.regionserver.kerberos.principal']
      # hbase.site['hbase.thrift.kerberos.principal'] ?= "hbase/_HOST@#{options.krb5.realm}" # Dont forget `grant 'thrift_server', 'RWCA'`
      # hbase.site['hbase.thrift.keytab.file'] ?= "#{hbase.conf_dir}/thrift.service.keytab"
      # Principal changed to http by default in order to enable impersonation and make it work with hue
      options.hbase_site['hbase.thrift.kerberos.principal'] ?= "HTTP/#{@config.host}@#{options.krb5.realm}" # was hbase_thrift/_HOST
      options.hbase_site['hbase.thrift.keytab.file'] ?= service.use.hadoop_core.options.core_site['hadoop.http.authentication.kerberos.keytab']

## Impersonation

      # Enables impersonation
      # For now thrift server does not support impersonation for framed transport: check cloudera setup warning
      options.hbase_site['hbase.regionserver.thrift.http'] ?= 'true'
      options.hbase_site['hbase.thrift.support.proxyuser'] ?= 'true'
      options.hbase_site['hbase.regionserver.thrift.framed'] ?= if options.hbase_site['hbase.regionserver.thrift.http'] then 'buffered' else 'framed'

## Proxy Users

      krb5_username = /^(.+?)[@\/]/.exec(options.hbase_site['hbase.thrift.kerberos.principal'])?[1]
      throw Error 'Invalid HBase Thrift principal' unless krb5_username
      for srv in [service.use.hbase_master..., service.use.hbase_regionserver...]
        srv.options.hbase_site["hadoop.proxyuser.#{krb5_username}.groups"] ?= '*'
        srv.options.hbase_site["hadoop.proxyuser.#{krb5_username}.hosts"] ?= '*'

## Distributed Mode

      for property in [
        'zookeeper.znode.parent'
        'hbase.cluster.distributed'
        'hbase.rootdir'
        'hbase.zookeeper.quorum'
        'hbase.zookeeper.property.clientPort'
        'dfs.domain.socket.path'
      ] then options.hbase_site[property] ?= service.use.hbase_master[0].options.hbase_site[property]

## Wait

      options.wait_krb5_client = service.use.krb5_client
      options.wait_zookeeper_server = service.use.zookeeper_server
      options.wait_hdfs_nn = service.use.hdfs_nn
      options.wait_hbase_master = service.use.hbase_master
      for srv in service.use.hbase_thrift
        srv.options.hbase_site ?= {}
        srv.options.hbase_site['hbase.thrift.port'] ?= '9090'
        srv.options.hbase_site['hbase.thrift.infot.port'] ?= '9095'
      options.wait = {}
      options.wait.http = for srv in service.use.hbase_thrift
        host: srv.node.fqdn
        port: srv.options.hbase_site['hbase.thrift.port']
      options.wait.http_info = for srv in service.use.hbase_thrift
        host: srv.node.fqdn
        port: srv.options.hbase_site['hbase.thrift.info.port']

## Dependencies

    {merge} = require 'nikita/lib/misc'
    migration = require 'masson/lib/migration'

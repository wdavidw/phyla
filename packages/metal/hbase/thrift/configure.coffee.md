
# HBase Thrit Server Configuration

    module.exports = (service) ->
      options = service.options

## Kerberos

      options.krb5 ?= {}
      options.krb5.realm ?= service.deps.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      throw Error 'Required Options: "realm"' unless options.krb5.realm
      options.krb5.admin ?= service.deps.krb5_client.options.admin[options.krb5.realm]

## Identities

      options.group = mixme service.deps.hbase_master[0].options.group, options.group
      options.user = mixme service.deps.hbase_master[0].options.user, options.user
      options.admin = mixme service.deps.hbase_master[0].options.admin, options.admin
      options.ranger_admin ?= service.deps.ranger_admin.options.admin if service.deps.ranger_admin

## Environment

      # Layout
      options.conf_dir ?= '/etc/hbase-thrift/conf'
      options.log_dir ?= '/var/log/hbase'
      options.pid_dir ?= '/var/run/hbase'
      # Env & Java
      options.env ?= {}
      options.java_home ?= "#{service.deps.java.options.java_home}"
      options.heapsize ?= '1024m'
      options.newsize ?= '200m'
      # Misc
      options.fqdn = service.node.fqdn
      options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'
      options.clean_logs ?= false

## System Options

      options.opts ?= {}
      options.opts.base ?= ''
      options.opts.java_properties ?= {}
      options.opts.jvm ?= {}
      options.opts.jvm['-Xms'] ?= options.heapsize
      options.opts.jvm['-Xmx'] ?= options.heapsize
      options.opts.jvm['-XX:NewSize='] ?= options.newsize #should be 1/8 of hbase regionserver heapsize
      options.opts.jvm['-XX:MaxNewSize='] ?= options.newsize #should be 1/8 of hbase regionserver heapsize

# Thrift Server Configuration

      options.hbase_site ?= {}
      options.hbase_site['hbase.thrift.port'] ?= '9090' # Default to "8080"
      options.hbase_site['hbase.thrift.info.port'] ?= '9095' # Default to "8085"
      options.hbase_site['hbase.thrift.ssl.enabled'] ?= 'true'
      options.hbase_site['hbase.thrift.ssl.keystore.store'] ?= service.deps.hadoop_core.options.ssl_server['ssl.server.keystore.location']
      options.hbase_site['hbase.thrift.ssl.keystore.password'] ?= service.deps.hadoop_core.options.ssl_server['ssl.server.keystore.password']
      options.hbase_site['hbase.thrift.ssl.keystore.keypassword'] ?= service.deps.hadoop_core.options.ssl_server['ssl.server.keystore.keypassword']
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

      options.hbase_site['hbase.security.authentication'] ?= service.deps.hbase_master[0].options.hbase_site['hbase.security.authentication']
      options.hbase_site['hbase.security.authorization'] ?= service.deps.hbase_master[0].options.hbase_site['hbase.security.authorization']
      options.hbase_site['hbase.rpc.engine'] ?= service.deps.hbase_master[0].options.hbase_site['hbase.rpc.engine']
      options.hbase_site['hbase.thrift.authentication.type'] = options.hbase_site['hbase.security.authentication'] ?= 'kerberos'
      options.hbase_site['hbase.master.kerberos.principal'] = service.deps.hbase_master[0].options.hbase_site['hbase.master.kerberos.principal']
      options.hbase_site['hbase.regionserver.kerberos.principal'] = service.deps.hbase_master[0].options.hbase_site['hbase.regionserver.kerberos.principal']
      # hbase.site['hbase.thrift.kerberos.principal'] ?= "hbase/_HOST@#{options.krb5.realm}" # Dont forget `grant 'thrift_server', 'RWCA'`
      # hbase.site['hbase.thrift.keytab.file'] ?= "#{hbase.conf_dir}/thrift.service.keytab"
      # Principal changed to http by default in order to enable impersonation and make it work with hue
      options.hbase_site['hbase.thrift.kerberos.principal'] ?= "HTTP/#{service.node.fqdn}@#{options.krb5.realm}" # was hbase_thrift/_HOST
      options.hbase_site['hbase.thrift.keytab.file'] ?= service.deps.hadoop_core.options.core_site['hadoop.http.authentication.kerberos.keytab']

## Impersonation

      # Enables impersonation
      # For now thrift server does not support impersonation for framed transport: check cloudera setup warning
      options.hbase_site['hbase.regionserver.thrift.http'] ?= 'true'
      options.hbase_site['hbase.thrift.support.proxyuser'] ?= 'true'
      options.hbase_site['hbase.regionserver.thrift.framed'] ?= if options.hbase_site['hbase.regionserver.thrift.http'] then 'buffered' else 'framed'

## Proxy Users

      krb5_username = /^(.+?)[@\/]/.exec(options.hbase_site['hbase.thrift.kerberos.principal'])?[1]
      throw Error 'Invalid HBase Thrift principal' unless krb5_username
      for srv in [service.deps.hbase_master..., service.deps.hbase_regionserver...]
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
      ] then options.hbase_site[property] ?= service.deps.hbase_master[0].options.hbase_site[property]

## Wait

      options.wait_krb5_client = service.deps.krb5_client.options.wait
      options.wait_hbase_master = service.deps.hbase_master[0].options.wait
      for srv in service.deps.hbase_thrift
        srv.options.hbase_site ?= {}
        srv.options.hbase_site['hbase.thrift.port'] ?= '9090'
        srv.options.hbase_site['hbase.thrift.info.port'] ?= '9095'
      options.wait = {}
      options.wait.http = for srv in service.deps.hbase_thrift
        host: srv.node.fqdn
        port: srv.options.hbase_site['hbase.thrift.port']
      options.wait.http_info = for srv in service.deps.hbase_thrift
        host: srv.node.fqdn
        port: srv.options.hbase_site['hbase.thrift.info.port']

## Dependencies

    mixme = require 'mixme'

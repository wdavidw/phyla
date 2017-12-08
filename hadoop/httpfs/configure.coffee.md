
# HDFS HttpFS Configure

The default configuration is located inside the source code in the location
"hadoop-hdfs-project/hadoop-hdfs-httpfs/src/main/resources/httpfs-default.xml".

    module.exports = (service) ->
      options = service.options

## Environment

      # layout
      options.pid_dir ?= '/var/run/httpfs'
      options.conf_dir ?= '/etc/hadoop-httpfs/conf'
      options.hdfs_conf_dir ?= service.deps.hdfs_client.options.conf_dir
      options.log_dir ?= '/var/log/hadoop-httpfs'
      options.tmp_dir ?= '/var/tmp/hadoop-httpfs'
      # Environment
      options.http_port ?= '14000'
      options.http_admin_port ?= '14001'
      options.catalina ?= {}
      options.catalina_home ?= '/etc/hadoop-httpfs/tomcat-deployment'
      # migration: wdavidw 170828, should we really have 2 options ?
      # probably but we should document why
      options.catalina_opts ?= ''
      options.catalina.opts ?= {}
      # Misc
      options.fqdn ?= service.node.fqdn
      options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'

## Identities

      # Group
      options.group = name: options.group if typeof options.group is 'string'
      options.group ?= {}
      options.group.name ?= 'httpfs'
      options.group.system ?= true
      # User
      options.user ?= {}
      options.user = name: options.user if typeof options.user is 'string'
      options.user.name ?= options.group.name
      options.user.system ?= true
      options.user.comment ?= 'HttpFS User'
      options.user.home = "/var/lib/#{options.user.name}"
      options.user.gid = options.group.name
      options.user.groups ?= 'hadoop'
      # Kerberos Test Principal
      options.test_krb5_user ?= service.deps.test_user.options.krb5.user

## Kerberos

      options.krb5 ?= {}
      options.krb5.realm ?= service.deps.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      throw Error 'Required Options: "realm"' unless options.krb5.realm
      options.krb5.admin ?= service.deps.krb5_client.options.admin[options.krb5.realm]

## Configuration

      # Hadoop core "core-site.xml"
      options.core_site = merge {}, service.deps.hdfs_client.options.core_site, options.core_site or {}
      options.java_home ?= service.deps.java.options.java_home or '/usr/java/default'
      # Env
      options.env ?= {}
      options.env.HTTPFS_SSL_ENABLED ?= 'true' # Default is "false"
      options.env.HTTPFS_SSL_KEYSTORE_FILE ?= "#{options.conf_dir}/keystore" # Default is "${HOME}/.keystore"
      options.env.HTTPFS_SSL_KEYSTORE_PASS ?= 'ryba123' # Default to "password"
      # Site
      options.httpfs_site ?= {}
      options.httpfs_site['dfs.http.policy'] ?= 'HTTPS_ONLY' # HTTP_ONLY or HTTPS_ONLY or HTTP_AND_HTTPS
      options.httpfs_site['httpfs.hadoop.config.dir'] ?= '/etc/hadoop/conf'
      options.httpfs_site['kerberos.realm'] ?= "#{options.krb5.realm}"
      options.httpfs_site['httpfs.hostname'] ?= "#{service.node.fqdn}"
      options.httpfs_site['httpfs.authentication.type'] ?= 'kerberos'
      options.httpfs_site['httpfs.authentication.kerberos.principal'] ?= "HTTP/#{service.node.fqdn}@#{options.krb5.realm}" # Default to "HTTP/${service.node.fqdn}@${kerberos.realm}"
      options.httpfs_site['httpfs.authentication.kerberos.keytab'] ?= '/etc/security/keytabs/spnego.service.keytab' # Default to "${user.home}/httpfs.keytab"
      options.httpfs_site['httpfs.hadoop.authentication.type'] ?= 'kerberos'
      options.httpfs_site['httpfs.hadoop.authentication.kerberos.keytab'] ?= '/etc/security/keytabs/httpfs.service.keytab' # Default to "${user.home}/httpfs.keytab"
      options.httpfs_site['httpfs.hadoop.authentication.kerberos.principal'] ?= "#{options.user.name}/#{service.node.fqdn}@#{options.krb5.realm}" # Default to "${user.name}/${httpfs.hostname}@${kerberos.realm}"
      options.httpfs_site['httpfs.authentication.kerberos.name.rules'] ?= service.deps.hadoop_core.options.core_site['hadoop.security.auth_to_local']

## SSL

      options.ssl = merge {}, service.deps.hadoop_core.options.ssl, options.ssl

## Log4J

      options.log4j = merge {}, service.deps.log4j?.options, options.log4j
      options.log4j.properties ?= {}
      if options.log4j.remote_host? && options.log4j.remote_port?
        options.catalina.opts['httpfs.log.server.logger'] = 'INFO,httpfs,socket'
        options.catalina.opts['httpfs.log.audit.logger'] = 'INFO,httpfsaudit,socket'
        options.catalina.opts['httpfs.log.remote_host'] = options.log4j.remote_host
        options.catalina.opts['httpfs.log.remote_port'] = options.log4j.remote_port

## Export

Export the proxy user to all DataNodes and NameNodes

      for srv in [service.deps.hdfs_dn..., service.deps.hdfs_nn..., service.deps.hdfs_client]
        srv.options.core_site ?= {}
        srv.options.core_site["hadoop.proxyuser.#{options.user.name}.hosts"] ?= service.deps.httpfs.map((srv) -> srv.node.fqdn).join ','
        srv.options.core_site["hadoop.proxyuser.#{options.user.name}.groups"] ?= '*'

## Wait

      options.wait_krb5_client = service.deps.krb5_client.options.wait
      options.wait_hdfs_nn = service.deps.hdfs_nn[0].options.wait
      options.wait = {}
      options.wait.http = for srv in service.deps.httpfs
        host: srv.node.fqdn
        port: srv.options.http_port or '14000'

## Dependencies

    {merge} = require 'nikita/lib/misc'

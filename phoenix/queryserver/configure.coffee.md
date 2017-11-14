
# Phoenix QueryServer Configuration

    module.exports = (service) ->
      options = service.options

## Users and Groups

      options.user ?= {}
      options.user = name: options.user if typeof options.user is 'string'
      options.user.name ?= 'phoenix'
      options.user.system ?= true
      options.user.comment ?= 'Phoenix User'
      options.user.home ?= '/var/lib/phoenix'
      options.user.groups ?= 'hadoop'
      # Group
      options.group ?= {}
      options.group = name: options.group if typeof options.group is 'string'
      options.group.name ?= 'phoenix'
      options.group.system ?= true
      options.user.gid = options.group.name

## Environment

      # Layout
      options.conf_dir ?= '/etc/phoenix/conf'
      options.log_dir ?= '/var/log/phoenix'
      options.pid_dir ?= '/var/run/phoenix'
      # Misc
      options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'

## QueryServer Configuration

      qs = options.queryserver ?= {}
      qs.site ?= {}
      qs.site['phoenix.queryserver.http.port'] ?= '8765'
      qs.site['phoenix.queryserver.metafactory.class'] ?= 'org.apache.phoenix.queryserver.server.PhoenixMetaFactoryImpl'
      qs.site['phoenix.queryserver.serialization'] ?= 'PROTOBUF'
      qs.site['phoenix.queryserver.keytab.file'] ?= '/etc/security/keytabs/spnego.service.keytab'
      qs.site['phoenix.queryserver.kerberos.principal'] ?= "HTTP/_HOST@#{service.deps.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm}"
      qs.site['avatica.connectioncache.concurrency'] ?= '10'
      qs.site['avatica.connectioncache.initialcapacity'] ?= '100'
      qs.site['avatica.connectioncache.maxcapacity'] ?= '1000'
      qs.site['avatica.connectioncache.expiryduration'] ?= '10'
      qs.site['avatica.connectioncache.expiryunit'] ?= 'MINUTES'
      qs.site['avatica.statementcache.concurrency'] ?= '100'
      qs.site['avatica.statementcache.initialcapacity'] ?= '1000'
      qs.site['avatica.statementcache.maxcapacity'] ?= '10000'
      qs.site['avatica.statementcache.expiryduration'] ?= '5'
      qs.site['avatica.statementcache.expiryunit'] ?= 'MINUTES'
      qs.site[k] ?= v for k, v of service.deps.hbase_client[0].options.hbase_site
      
## Other Configurations

      options.host = service.node.fqdn
      options.java_home = service.deps.java.options.java_home

## Dependencies

    string = require 'nikita/lib/misc/string'
    {merge} = require 'nikita/lib/misc'
    appender = require '../../lib/appender'

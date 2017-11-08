
# Phoenix QueryServer Configuration

    module.exports = (service) ->
      service = migration.call @, service, 'ryba/phoenix/queryserver', ['ryba', 'phoenix', 'queryserver'], require('nikita/lib/misc').merge require('.').use,
        java: key: ['java']
        krb5_client: key: ['krb5_client']
        hadoop_core: key: ['ryba']
        hbase_client: key: ['ryba', 'hbase', 'client']
        phoenix_client: key: ['ryba', 'phoenix', 'client']
      @config.ryba ?= {}
      options = @config.ryba.phoenix_queryserver = service.options

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

## Layout

      options.conf_dir ?= '/etc/phoenix/conf'
      options.log_dir ?= '/var/log/phoenix'
      options.pid_dir ?= '/var/run/phoenix'

## QueryServer Configuration

      qs = options.queryserver ?= {}
      qs.site ?= {}
      qs.site['phoenix.queryserver.http.port'] ?= '8765'
      qs.site['phoenix.queryserver.metafactory.class'] ?= 'org.apache.phoenix.queryserver.server.PhoenixMetaFactoryImpl'
      qs.site['phoenix.queryserver.serialization'] ?= 'PROTOBUF'
      qs.site['phoenix.queryserver.keytab.file'] ?= '/etc/security/keytabs/spnego.service.keytab'
      qs.site['phoenix.queryserver.kerberos.principal'] ?= "HTTP/_HOST@#{service.use.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm}"
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
      qs.site[k] ?= v for k, v of service.use.hbase_client[0].options.hbase_site
      
## Other Configurations

      options.host = service.node.fqdn
      options.java_home = service.use.java.options.java_home

## Dependencies

    string = require 'nikita/lib/misc/string'
    {merge} = require 'nikita/lib/misc'
    appender = require '../../lib/appender'
    migration = require 'masson/lib/migration'


# Configure webhcat server

    module.exports = ->
      [hcat_ctx] = @contexts 'ryba/hive/hcatalog'
      {ryba} = @config
      throw Error "No Hive HCatalog Server Found" unless hcat_ctx
      options = @config.ryba.webhcat ?= {}

## Environment

      options.conf_dir ?= '/etc/hive-webhcat/conf'
      options.log_dir ?= '/var/log/webhcat'
      options.pid_dir ?= '/var/run/webhcat'

## Identities

      options.group = merge hcat_ctx.config.ryba.hive.group, options.group
      options.user = merge hcat_ctx.config.ryba.hive.user, options.user

## Configuration

      options.site ?= {}
      options.site['templeton.storage.class'] ?= 'org.apache.hive.hcatalog.templeton.tool.ZooKeeperStorage' # Fix default value distributed in companion files
      options.site['templeton.jar'] ?= '/usr/lib/hive-hcatalog/share/options/svr/lib/hive-webhcat-0.13.0.2.1.2.0-402.jar' # Fix default value distributed in companion files
      options.site['templeton.hive.properties'] ?= [
        'hive.metastore.local=false'
        "hive.metastore.uris=#{hcat_ctx.config.ryba.hive.hcatalog.site['hive.metastore.uris'] }"
        'hive.metastore.sasl.enabled=yes'
        'hive.metastore.execute.setugi=true'
        'hive.metastore.warehouse.dir=/apps/hive/warehouse'
        "hive.metastore.kerberos.principal=#{hcat_ctx.config.ryba.hive.hcatalog.site['hive.metastore.kerberos.principal']}"
      ].join ','
      options.site['templeton.zookeeper.hosts'] ?= hcat_ctx.config.ryba.hive.hcatalog.site['templeton.zookeeper.hosts']
      options.site['templeton.kerberos.principal'] ?= "HTTP/#{@config.host}@#{ryba.realm}"
      options.site['templeton.kerberos.keytab'] ?= ryba.core_site['hadoop.http.authentication.kerberos.keytab']
      options.site['templeton.kerberos.secret'] ?= 'secret'
      options.site['webhcat.proxyuser.hue.groups'] ?= '*'
      options.site['webhcat.proxyuser.hue.hosts'] ?= '*'
      options.site['webhcat.proxyuser.knox.groups'] ?= '*'
      options.site['webhcat.proxyuser.knox.hosts'] ?= '*'
      options.site['templeton.port'] ?= 50111
      options.site['templeton.controller.map.mem'] = 1600 # Total virtual memory available to map tasks.

## Java Options

      options.java_opts ?= ''
      options.opts ?= {}

## Logj4 Properties

      options.log4j ?= {}
      options.log4j[k] ?= v for k, v of @config.log4j
      if @config.log4j?.services?
        options.opts['webhcat.root.logger'] ?= 'INFO,RFA'
        if @config.log4j?.remote_host? and @config.log4j?.remote_port? and ('ryba/hive/webhcat' in @config.log4j?.services)
          # adding SOCKET appender
          options.socket_client ?= "SOCKET"
          # Root logger
          if options.opts['webhcat.root.logger'].indexOf(options.socket_client) is -1
          then options.opts['webhcat.root.logger'] += ",#{options.socket_client}"

          options.opts['webhcat.log.application'] ?= 'hive-webhcat'
          options.opts['webhcat.log.remote_host'] ?= @config.log4j.remote_host
          options.opts['webhcat.log.remote_port'] ?= @config.log4j.remote_port

          options.socket_opts ?=
            Application: '${options.log.application}'
            RemoteHost: '${options.log.remote_host}'
            Port: '${options.log.remote_port}'
            ReconnectionDelay: '10000'

          appender
            type: 'org.apache.log4j.net.SocketAppender'
            name: options.socket_client
            logj4: options.log4j
            properties: options.socket_opts
      else
        options.opts['webhcat.root.logger'] ?= 'INFO,RFA'

## Dependencies

    appender = require '../../lib/appender'
    {merge} = require 'nikita/lib/misc'
    migration = require 'masson/lib/migration'

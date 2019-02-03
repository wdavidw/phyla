
# Ambari NiFi Configure

    module.exports = ->
      service = migration.call @, service, 'ryba/ambari/server', ['ryba', 'ambari', 'nifi'], require('nikita/lib/misc').merge require('.').use,
        ssl: key: ['ssl']
        hdf: key: ['ryba', 'hdf']
      options = @config.ryba.ambari.nifi = service.options

## Environment

      options.conf_dir ?= '/etc/nifi/conf'
      options.log_dir ?= '/var/log/nifi'
      options.toolkit ?= {}
      options.toolkit.source ?= 'http://www-eu.apache.org/dist/nifi/1.2.0/nifi-toolkit-1.2.0-bin.zip'
      options.toolkit.target ?= '/etc/nifi/conf/nifi-toolkit'

## User and Groups

      # Group
      options.group = name: options.group if typeof options.group is 'string'
      options.group ?= {}
      options.group.name ?= 'nifi'
      options.group.system ?= true
      # User
      options.user = name: options.user if typeof options.user is 'string'
      options.user ?= {}
      options.user.name ?= 'nifi'
      options.user.gid = options.group.name
      options.user.system ?= true
      options.user.comment ?= 'NiFi User'
      options.user.home ?= '/var/lib/nifi'
      options.user.limits ?= {}
      options.user.limits.nofile ?= 64000
      options.user.limits.nproc ?= 10000

## SSL

https://community.hortonworks.com/articles/81184/understanding-the-initial-admin-identity-access-po.html

      options.ssl = merge {}, service.use.ssl?[0]?.options, options.ssl
      options.ssl.enabled ?= !!service.use.ssl
      options.ssl.certs = {}
      # options.ssl.truststore ?= {}
      # options.ssl.keystore ?= {}
      if options.ssl.enabled
        # options.ssl.cert = @config.ssl.cert
        # options.ssl.key = @config.ssl.key
        # options.ssl.cacert = @config.ssl.cacert
        for srv in service.use.ssl
          options.ssl.certs[srv.node.hostname] ?= {}
          options.ssl.certs[srv.node.hostname] = srv.options.cert
        options.ssl.truststore.target = "#{options.conf_dir}/truststore.jks"
        throw Error 'Required Property: truststore.password' unless options.ssl.truststore.password
        options.ssl.truststore.caname ?= 'hadoop_root_ca'
        options.ssl.truststore.type ?= 'jks'
        throw Error "Invalid Truststore Type: #{truststore.type}" unless options.ssl.truststore.type in ['jks', 'jceks', 'pkcs12']
        options.ssl.keystore.target = "#{options.conf_dir}/keystore.jks"
        throw Error 'Required Property: keystore.password' unless options.ssl.keystore.password
        throw Error 'Required Property: keystore.keypass' unless options.ssl.keystore.keypass

## Dependencies

    {merge} = require '@nikitajs/core/lib/misc'
    migration = require 'masson/lib/migration'

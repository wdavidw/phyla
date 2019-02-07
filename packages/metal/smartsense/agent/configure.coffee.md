
# Hortonworks Smartsense Agent Configuration

    module.exports = (service) ->
      service = migration.call @, service, '@rybajs/metal/smartsense/agent', ['ryba', 'smartsense', 'agent'], require('@nikitajs/core/lib/misc').merge require('.').use,
        java: key: ['java']
        iptables: key: ['iptables']
        smartsense_servers: key: ['ryba','smartsense','server']
      @config.ryba ?= {}
      @config.ryba.smartsense ?= {}
      options = @config.ryba.smartsense.agent = service.options

## Identities

By default, merge group and user from the Ranger admin configuration.

      options.group = merge service.use.smartsense_servers[0].options.group, options.group
      options.user = merge service.use.smartsense_servers[0].options.user, options.user

## Environment
      
      options.conf_dir ?= '/etc/hst/conf'
      options.source ?= "#{__dirname}/../resources/smartsense-hst-1.3.0.0-1.x86_64.rpm"
      options.tmp_dir ?= '/tmp'
      options.pid_dir ?= '/var/run/hst'
      options.log_dir ?= '/var/log/hst'
      options.server_host ?= service.use.smartsense_servers[0].node.fqdn

## Source

      options.source ?= "#{__dirname}/../resources/smartsense-hst-1.3.0.0-1.x86_64.rpm"

## Configuration

      options.ini ?= {}
      options.ini['server'] ?= {}
      options.ini['server']['url_port'] ?= service.use.smartsense_servers[0].options.ini['security']['server.one_way_ssl.port']
      options.ini['server']['secured_url_port'] ?= service.use.smartsense_servers[0].options.ini['security']['server.two_way_ssl.port']
      options.ini['server']['ssl_enabled'] ?= service.use.smartsense_servers[0].options.ini['security']['ssl_enabled']
      # note: enabline auto-apply lead to hst-options.ini file to be change every time server's conf changes
      # we do not want this behaviour because we manage configuration with ryba
      options.ini['management'] ?= {}
      options.ini['management']['patch.auto.apply.enabled'] ?= false

## Dependencies

    migration = require 'masson/lib/migration'
    {merge} = require '@nikitajs/core/lib/misc'

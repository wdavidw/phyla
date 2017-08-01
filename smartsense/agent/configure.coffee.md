
# Hortonworks Smartsense Agent Configuration

    module.exports = ->
      {java, ryba} = @config
      {hadoop_conf_dir, core_site,realm} = ryba
      {smartsense} = ryba ?= {}
      [srv_ctx] = @contexts 'ryba/smartsense/server'
      agent = smartsense.agent ?= {}

## Identities

By default, merge group and user from the Ranger admin configuration.

      smartsense.group = merge ks_ctxs[0].config.ryba.smartsense.group, smartsense.group
      smartsense.user = merge ks_ctxs[0].config.ryba.smartsense.user, smartsense.user

## Environment
      
      agent.conf_dir ?= '/etc/hst/conf'
      agent.source ?= "#{__dirname}/../resources/smartsense-hst-1.3.0.0-1.x86_64.rpm"
      agent.tmp_dir ?= '/tmp'
      agent.pid_dir ?= '/var/run/hst'
      agent.log_dir ?= '/var/log/hst'
      agent.server_host ?= srv_ctx.config.host

## Source

      smartsense.source ?= "#{__dirname}/../resources/smartsense-hst-1.3.0.0-1.x86_64.rpm"

## Configuration

      agent.ini ?= {}
      agent.ini['server'] ?= {}
      agent.ini['server']['url_port'] ?= srv_ctx.config.ryba.smartsense.server.ini['security']['server.one_way_ssl.port']
      agent.ini['server']['secured_url_port'] ?= srv_ctx.config.ryba.smartsense.server.ini['security']['server.two_way_ssl.port']
      agent.ini['server']['ssl_enabled'] ?= srv_ctx.config.ryba.smartsense.server.ini['security']['ssl_enabled']
      # note: enabline auto-apply lead to hst-agent.ini file to be change every time server's conf changes
      # we do not want this behaviour because we manage configuration with ryba
      agent.ini['management'] ?= {}
      agent.ini['management']['patch.auto.apply.enabled'] ?= false

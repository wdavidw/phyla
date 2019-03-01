
# Ambari Agent Configuration

    module.exports = (service) ->
      options = service.options

## Environment

      options.fqdn = service.node.fqdn
      options.sudo ?= false
      options.conf_dir ?= '/etc/ambari-agent/conf'

## Identities

      options.hadoop_group = mixme service.use.ambari_server[0].options.hadoop_group, options.hadoop_group
      options.group = mixme service.use.ambari_server[0].options.group, options.group
      options.user = mixme service.use.ambari_server[0].options.user, options.user

## Configuration

      options.config ?= {}
      options.config.server ?= {}
      options.config.server['hostname'] ?= "#{service.use.ambari_server[0].node.fqdn}"
      options.config.server['url_port'] = service.use.ambari_server[0].options.config['server.url_port']
      options.config.server['secured_url_port'] = service.use.ambari_server[0].options.config['server.secured_url_port']
      options.config.agent ?= {}
      options.config.agent['hostname_script'] ?= "#{options.conf_dir}/hostname.sh"

## Dependencies

    mixme = require 'mixme'

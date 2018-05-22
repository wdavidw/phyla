
# Ambari Agent Configuration

    module.exports = (service) ->
      options = service.options

## Environment

      options.fqdn = service.node.fqdn
      options.sudo ?= false
      options.conf_dir ?= '/etc/ambari-agent/conf'

## Identities

      options.hadoop_group = merge {}, service.deps.ambari_server[0].options.hadoop_group, options.hadoop_group
      options.group = merge service.deps.ambari_server[0].options.group, options.group
      options.user = merge service.deps.ambari_server[0].options.user, options.user
      options.test_group = merge service.deps.ambari_server[0].options.test_group, options.test_group
      options.test_user = merge service.deps.ambari_server[0].options.test_user, options.test_user

## Configuration

      options.config ?= {}
      options.config.server ?= {}
      options.config.server['hostname'] ?= "#{service.deps.ambari_server[0].node.fqdn}"
      options.config.server['url_port'] = service.deps.ambari_server[0].options.config['server.url_port']
      options.config.server['secured_url_port'] = service.deps.ambari_server[0].options.config['server.secured_url_port']
      options.config.agent ?= {}
      options.config.agent['hostname_script'] ?= "#{options.conf_dir}/hostname.sh"

## Ambari Rest Api URL

      options.ambari_url ?= service.deps.ambari_server[0].options.ambari_url
      options.ambari_admin_password ?= service.deps.ambari_server[0].options.admin_password
      options.cluster_name ?= service.deps.ambari_server[0].options.cluster_name

## Cluster Provisionning

      options.provision_cluster ?= service.deps.ambari_server[0].options.provision_cluster

### User Provisionning
Contains object of user that ambari-agent should create on all hosts. By default
Ambari needs to all user on all node even if the service is not installed on a host.

The components should register their user to ambari agents

      options.users ?= {}
      options.groups ?= {}

## Config Groups
      
      options.config_groups ?= []
      for srv in service.deps.ambari_server
        for name in options.config_groups
          srv.options.config_groups ?= {}
          srv.options.config_groups[name] ?= {}
          srv.options.config_groups[name]['hosts'] ?= []
          srv.options.config_groups[name]['hosts'].push service.node.fqdn unless srv.options.config_groups[name]['hosts'].indexOf(service.node.fqdn) > -1
          
## Wait Ambari

      options.wait_ambari_rest = service.deps.ambari_server[0].options.wait.rest


## Dependencies

    {merge} = require 'nikita/lib/misc'


# Logstash Configuration

    module.exports  = (service) ->
      options = service.options

## Environment

      options.version ?= '6.1.1'
      options.log_dir ?= '/var/log/logstash'
      options.conf_dir ?= '/etc/logstash'
      options.install_dir ?= '/usr/share'
      options.solr_client_source ?= service.deps.solr_client.options.source if service.deps.solr_client
      options.solr_client_source = if options.solr_client_source is 'HDP'
      then '/opt/lucidworks-hdpsearch/solr'
      else '/usr/solr/current'
      options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'

## Identities

      # Group
      options.group ?= {}
      options.group = name: options.group if typeof options.group is 'string'
      options.group.name ?= 'logstash'
      options.group.system ?= true
      # User
      options.user ?= {}
      options.user = name: options.user if typeof options.user is 'string'
      options.user.name ?= 'logstash'
      options.user.system ?= true
      options.user.comment ?= 'Logstash User'
      options.user.home ?= "/var/lib/#{options.user.name}"
      options.user.gid ?= options.group.name
      options.user.groups ?= 'logstash'

## Solr

      options.solr ?= {}
      options.solr.cluster_config ?= {}
      options.solr.logstash_logs_collection_conf_dir ?= "/tmp"
      options.solr_client_source ?= "/usr"

## Pipelines

      options.pipelines ?= {}

## Source

      options.source ?= "https://artifacts.elastic.co/downloads/logstash/logstash-#{options.version}.rpm"

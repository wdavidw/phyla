
# Titan Configuration

    module.exports = (service) ->
      {options} = service

## Kerberos

      # Kerberos Test Principal
      options.test_krb5_user ?= service.deps.test_user.options.krb5.user

## Environment

      # Layout
      options.install_dir ?= '/opt/titan'
      options.home ?= path.join options.install_dir, 'current'
      # Package
      options.version ?= '1.0.0'
      # Note, Titan 1.0.0 can be found [here](http://s3.thinkaurelius.com/downloads/titan/titan-#{options.version}-hadoop2.zip)
      options.source ?= "http://s3.thinkaurelius.com/downloads/titan/titan-#{options.version}-hadoop2.zip"
      # Misc
      options.force_check ?= false

## Configuration

      options.config ?= {}

## Storage Backend

      options.config['storage.backend'] ?= 'hbase'
      if options.config['storage.backend'] is 'hbase'
        zk_hosts = @contexts('@rybajs/metal/zookeeper/server').map( (ctx)-> ctx.config.host)
        options.config['storage.hostname'] ?= zk_hosts.join ','
        options.config['storage.hbase.table'] ?= 'titan'
        options.config['storage.hbase.short-cf-names'] ?= true

## Indexation backend (mandatory even if it should not be)

      options.config['index.search.backend'] ?= 'elasticsearch'
      if options.config['index.search.backend'] is 'elasticsearch'
        es_ctxs = @contexts '@rybajs/metal/elasticsearch', require('../elasticsearch/configure').handler
        if es_ctxs.length > 0
          options.config['index.search.hostname'] ?= es_ctxs[0].config.host
          options.config['index.search.elasticsearch.client-only'] ?= true
          options.config['index.search.elasticsearch.cluster-name'] ?= es_ctxs[0].config.ryba.elasticsearch.cluster.name
        unless options.config['index.search.hostname']? and options.config['index.search.elasticsearch.cluster-name']?
          throw Error "Cannot autoconfigure elasticsearch. Provide manual config or install elasticsearch"
      else if options.config['index.search.backend'] is 'solr'
        zk_ctxs = @contexts '@rybajs/metal/zookeeper/server'
        solr_ctxs = @contexts '@rybajs/metal/solr'
        if solr_ctxs.length > 0
          options.config['index.seach.solr.mode'] ?= solr_ctxs[0].config.ryba.solr.mode
          options.config['index.search.solr.zookeeper-url'] ?= "#{zk_ctxs[0].config.host}:#{zk_ctxs[0].config.ryba.zookeeper.port}"
        unless options.config['index.seach.solr.mode']? and options.config['index.search.solr.zookeeper-url']?
          throw Error "Cannot autoconfigure solr. Provide manual config or install solr"
      else throw Error "Invalid search.backend '#{options.config['index.search.backend']}', 'solr' or 'elasticsearch' expected"

## Cache configuration

      options.config['cache.db-cache'] ?= true
      options.config['cache.db-cache-clean-wait'] ?= 20
      options.config['cache.db-cache-time'] ?= 180000
      options.config['cache.db-cache-size'] ?= 0.5

## Dependencies

    path = require 'path'

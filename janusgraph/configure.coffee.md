
# JanusGraph Configure

    module.exports = ->
      janus = @config.ryba.janusgraph ?= {}
      # Layout
      janus.install_dir ?= '/opt/janusgraph'
      janus.home ?= path.join janus.install_dir, 'current'
      janus.version ?= '0.1.1'
      janus.source ?= "https://github.com/JanusGraph/janusgraph/releases/download/v#{janus.version}/janusgraph-#{janus.version}-hadoop2.zip"
      # Configuration
      janus.config ?= {}

Storage Backend

      janus.config['storage.backend'] ?= 'hbase'
      if janus.config['storage.backend'] is 'hbase'
        zk_hosts = @contexts('ryba/zookeeper/server').map( (ctx)-> ctx.config.host)
        janus.config['storage.hostname'] ?= zk_hosts.join ','
        janus.config['storage.hbase.table'] ?= 'janus'
        janus.config['storage.hbase.short-cf-names'] ?= true

Indexation backend (mandatory even if it should not be)

      janus.config['index.search.backend'] ?= 'elasticsearch'
      if janus.config['index.search.backend'] is 'elasticsearch'
        es_ctxs = @contexts 'ryba/elasticsearch'
        if es_ctxs.length > 0
          janus.config['index.search.hostname'] ?= es_ctxs[0].config.host
          janus.config['index.search.elasticsearch.client-only'] ?= true
          janus.config['index.search.elasticsearch.cluster-name'] ?= es_ctxs[0].config.ryba.elasticsearch.cluster.name
        unless janus.config['index.search.hostname']? and janus.config['index.search.elasticsearch.cluster-name']?
          throw Error "Cannot autoconfigure elasticsearch. Provide manual config or install elasticsearch"
      else if janus.config['index.search.backend'] is 'solr'
        zk_ctxs = @contexts 'ryba/zookeeper/server'
        solr_ctxs = @contexts 'ryba/solr'
        if solr_ctxs.length > 0
          janus.config['index.seach.solr.mode'] ?= solr_ctxs[0].config.ryba.solr.mode
          janus.config['index.search.solr.zookeeper-url'] ?= "#{zk_ctxs[0].config.host}:#{zk_ctxs[0].config.ryba.zookeeper.port}"
        unless janus.config['index.seach.solr.mode']? and janus.config['index.search.solr.zookeeper-url']?
          throw Error "Cannot autoconfigure solr. Provide manual config or install solr"
      else throw Error "Invalid search.backend '#{janus.config['index.search.backend']}', 'solr' or 'elasticsearch' expected"

Cache configuration

      janus.config['cache.db-cache'] ?= true
      janus.config['cache.db-cache-clean-wait'] ?= 20
      janus.config['cache.db-cache-time'] ?= 180000
      janus.config['cache.db-cache-size'] ?= 0.5

## Dependencies

    path = require 'path'


# Elasticsearch Prepared

    module.exports = header: 'ES Prepared', handler: ->
      {elasticsearch, realm} = @config.ryba
      @file.cache
        ssh: false
        source: elasticsearch.source
        # target: "/var/tmp/elasticsearch-#{elasticsearch.version}.noarch.rpm"

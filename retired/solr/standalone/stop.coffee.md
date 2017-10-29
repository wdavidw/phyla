
# Solr Stop

    module.exports = header: 'Solr Stop', handler: ->
      @service.stop
        name: 'solr'
        if_exists: '/etc/init.d/solr'

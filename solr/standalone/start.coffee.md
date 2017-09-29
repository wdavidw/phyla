
# Solr Start

    module.exports =  header: 'Solr Start', handler: ->
      @service.start
        name: 'solr'

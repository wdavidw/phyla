
# Solr Stop

    module.exports = header: 'Solr Cloud Stop', handler: ->
      @system.execute
        cmd: 'service solr stop'
        code_skipped: 1
        if_exists: '/etc/init.d/solr'

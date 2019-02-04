
# Shinken Arbiter Wait

    module.exports = header: 'Solr Cloud Wait', handler: (options) ->
      @connection.wait options.tcp

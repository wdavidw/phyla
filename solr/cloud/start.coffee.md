
# Solr Start

    module.exports =  header: 'Solr Cloud Start', header: 'STARTED', handler: (options) ->

## Dependencies

      @call 'masson/core/krb5_client/wait', once: true, options.wait_krb5_client
      @call 'ryba/zookeeper/server/wait', once: true, options.wait_zookeeper_server

      @service.start 'solr'

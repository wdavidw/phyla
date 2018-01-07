
# Cloudera Manager Parcels

Syncronize Cloudera parcels locally and setup an HTTP server.


    module.exports =
      commands:
        'prepare': ->
          @call
            if: -> @contexts('ryba/cloudera_manager/server')[0]?.config.host is @config.host
            ssh: false
            distrib: @config.cloudera_manager.distrib
            services: @config.cloudera_manager.distrib
          , 'ryba/cloudera-manager/server/prepare'

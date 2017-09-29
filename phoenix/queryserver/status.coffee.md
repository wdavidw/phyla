
# Phoenix QueryServer Status

    module.exports = header: 'Phoenix QueryServer Status', handler: ->
      @service.status
        name: 'phoenix-queryserver'


# Phoenix QueryServer Stop

    module.exports = header: 'Phoenix QueryServer Stop', handler: ->
      @service.stop name: 'phoenix-queryserver'


# Phoenix QueryServer Start

    module.exports = header: 'Phoenix QueryServer Start', handler: ->
      @service.start name: 'phoenix-queryserver'


# Shinken Arbiter Start

    module.exports = header: 'Shinken Arbiter Start', handler: ->
      @service.start name: 'shinken-arbiter'

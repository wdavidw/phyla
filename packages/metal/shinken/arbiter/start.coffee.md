
# Shinken Arbiter Start

    module.exports = header: 'Shinken Arbiter Start', handler: (options) ->
      @service.start name: 'shinken-arbiter'

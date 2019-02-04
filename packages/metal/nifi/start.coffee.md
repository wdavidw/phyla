
# NiFi Start

    module.exports = header: 'NiFi Start', handler: ->
      @service.start name: 'nifi'

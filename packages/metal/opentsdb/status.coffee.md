
# OpenTSDB Status

    module.exports = header: 'OpenTSDB Status', handler: ->
      @service.status name: 'opentsdb'


# NiFi Status

    module.exports = header: 'NiFi Status', handler: ->
      @service.status
        name: 'nifi'
        code_stopped: 1

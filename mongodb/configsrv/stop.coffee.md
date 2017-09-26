
# MongoDB Config Server Stop

    module.exports = header: 'MongoDB Config Server Stop', label_true: 'STOPPED', handler: (options) ->
      {configsrv} = @config.ryba.mongodb

## Stop

Stop the MongoDB Config Server service.

      @service.stop
        header: 'Stop service'
        name: 'mongod-config-server'

## Clean Logs

      @call
        if:  options.clean_logs
        header: 'Clean Logs'
        label_true: 'CLEANED'
      , ->
        @system.execute
          cmd: "rm #{options.config.systemLog.path}"
          code_skipped: 1

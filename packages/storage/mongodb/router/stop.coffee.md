
# MongoDB Routing Server Stop

    module.exports = header: 'MongoDB Routing Server Stop', handler: ({options})->

## Stop

Stop the MongoDB Routing Server service.

      @service.stop
        header: 'Stop service'
        name: 'mongod-router-server'

## Clean Logs

      @call ->
        header: 'Clean Logs'
        if: options.clean_logs
      , ->
        @system.execute
          cmd: "rm #{options.config.logpath}"
          code_skipped: 1

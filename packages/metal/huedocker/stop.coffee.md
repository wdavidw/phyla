
# Hue Stop

    module.exports = header: 'Hue Docker Stop', handler: (options) ->

Stops the Hue 'hue_server' container. You can also stop the server manually with the following
command:

```
docker stop hue_server
```

      @service.stop
        name: options.service

## Clean Logs dir

      @call
        header: 'Stop Clean Logs'
        if: -> options.clean_logs
        handler: ->
          @system.execute
            cmd: "rm #{options.log_dir}/*.log"
            code_skipped: 1

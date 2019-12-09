
# Hue Stop

Stop the Hue server. You can also stop the server manually with the following
command:

```
service hue stop
```

    module.exports = header: 'Hue Stop', handler: ->
      {hue} = @config.ryba
      @service.stop
        header: 'Stop service'
        name: 'hue'

## Stop Clean Logs

      @system.execute
        header: 'Clean Logs'
        if: -> @config.ryba.clean_logs
        cmd: "rm #{hue.log_dir}/*"
        code_skipped: 1

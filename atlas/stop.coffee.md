
# Altas Metadata Server Stop

    module.exports = header: 'Atlas Stop', handler: ->

You can stop the service with the following commands.
* Centos/REHL 6
```
  service atlas-metadata-server stop
```
* Centos/REHL 6
```
  systemctl stop atlas-metadata-server
```

      @service.stop
        name: 'atlas-metadata-server'

## Stop Clean Logs

      @call
        header: 'Stop Clean Logs'
        if: -> @config.ryba.clean_logs
      , ->
        @system.execute
          cmd: "rm -f #{@config.ryba.atlas.log_dir}/*"
          code_skipped: 1


# Altas Metadata Server Stop

    module.exports = header: 'Atlas Stop', handler: (options) ->

You can stop the service with the following commands.

```
# Centos/REHL 6
service atlas-metadata-server stop
# Centos/REHL 7
systemctl stop atlas-metadata-server
```

      @service.stop
        name: 'atlas-metadata-server'

## Stop Clean Logs

Remove all the log files if the property "clean_logs" is
activated.

      @system.execute
        header: 'Stop Clean Logs'
        if: options.clean_logs
        cmd: "rm -f #{options.log_dir}/*"
        code_skipped: 1

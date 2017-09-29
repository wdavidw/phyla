
# Falcon Server Stop

Stop the Falcon service. You can also stop the server manually with the
following command:

```
su -l falcon -c "/usr/hdp/current/falcon-server/bin/service-stop.sh falcon"
```

    module.exports = header: 'Falcon Server Stop', handler: ->
      {clean_logs, falcon} = @config.ryba
      throw Error "Invalid log dir" unless falcon.log_dir

      @service.stop
        name: 'falcon'
        if_exists: '/etc/init.d/falcon'

## Clean Logs

      @system.execute
        header: 'Clean Logs'
        if: -> clean_logs
        cmd: "rm #{falcon.log_dir}/*"
        code_skipped: 1

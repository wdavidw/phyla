
# MongoDB Config Server Stop

Run the command `./bin/ryba stop -m ryba/mongodb/configsrv` to stop the 
MongoDB Config server using Ryba.

    module.exports = header: 'MongoDB Config Server Stop', label_true: 'STOPPED', handler: (options) ->
      {configsrv} = @config.ryba.mongodb

## Service

Stop the MongDB Config server. You can also stop the server manually with one of the
following commands:

```
service mongod-config-server stop
systemctl stop mongod-config-server
# todo, find the stop command
```

The file storing the PID is "/var/run/webhcat/webhcat.pid".

      @service.stop
        header: 'Stop service'
        name: 'mongod-config-server'

## Clean Logs

Remove the "mongod-config-server-{hostname}.log" log files if the property 
"clean_logs" is activated.

      @system.execute
        header: 'Clean Logs'
        if:  options.clean_logs
        cmd: "rm #{options.config.systemLog.path}"
        code_skipped: 1

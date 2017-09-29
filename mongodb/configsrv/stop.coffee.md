
# MongoDB router Server Stop

Run the command `./bin/ryba stop -m ryba/mongodb/routersrv` to stop the 
MongoDB router server using Ryba.

    module.exports = header: 'MongoDB Router Server Stop', label_true: 'STOPPED', handler: (options) ->

## Service

Stop the MongDB router server. You can also stop the server manually with one of the
following commands:

```
service mongod-router-server stop
systemctl stop mongod-router-server
# todo, find the stop command
```

The file storing the PID is "/var/run/webhcat/webhcat.pid".

      @service.stop
        header: 'Stop service'
        name: 'mongod-router-server'

## Clean Logs

Remove the "mongod-router-server-{hostname}.log" log files if the property 
"clean_logs" is activated.

      @system.execute
        header: 'Clean Logs'
        if:  options.clean_logs
        cmd: "rm #{options.router.systemLog.path}"
        code_skipped: 1

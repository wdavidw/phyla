
# Hive Server2 Stop

Run the command `./bin/ryba stop -m ryba/hive/server2` to stop the Hive Server2
server using Ryba.

    module.exports = header: 'Hive Server2 Stop', label_true: 'STOPPED', handler: (options) ->

## System

You can also stop the server manually with one of the following two commands:

```
service hive-server2 stop
systemctl stop hive-server2
su -l hive -c "kill `cat /var/run/hive-server2/hive-server2.pid`"
```

      @service.stop
        name: 'hive-server2'

## Clean Logs

Remove the "*" log file if the property "clean_logs" is
activated.

      @system.execute
        header: 'Stop Clean Logs'
        if: -> options.clean_logs
        cmd: "rm #{options.log_dir}/*"
        code_skipped: 1


# Hive HCatalog Stop

Stop the Hive HCatalog server.

The file storing the PID is "/var/run/hive-server2/hive-server2.pid".

    module.exports = header: 'Hive HCatalog Stop', label_true: 'STOPPED', handler: (options) ->

## Service

You can also stop the server manually with one of
the following two commands:

```
service hive-hcatalog-server stop
systemctl stop hive-hcatalog-server
su -l hive -c "kill `cat /var/lib/hive-hcatalog/hcat.pid`"
```

      @service.stop
        name: 'hive-hcatalog-server'

## Clean Logs

Remove the "*" log file if the property "clean_logs" is
activated.

      @system.execute
        header: 'Clean Logs'
        if: options.clean_logs
        cmd: "rm #{options.log_dir}/*"
        code_skipped: 1

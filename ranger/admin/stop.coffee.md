# Ranger Admin Stop

Stop the ranger admin service server. You can also stop the server
manually with the following command:

```
service ranger-admin stop
```

    module.exports = header: 'Ranger Admin Stop', label_true: 'STOPPED', handler: (options) ->

## Service

      @service.start
        name: 'ranger-admin'

## Clean Logs

      @system.execute
        header: 'Clean Logs'
        if: options.clean_logs
        cmd: 'rm /var/log/ranger/admin/*'
        code_skipped: 1

# Ranger USersync Stop

Stop the ranger usersync service server. You can also stop the server
manually with the following command:

```
service ranger-usersync stop
```

    module.exports = header: 'Ranger Usersync Stop', handler: ->
      @service.start
        name: 'ranger-usersync'

## Clean Logs

      @call header: 'Clean Logs', handler: ->
        return unless @config.ryba.clean_logs
        @system.execute
          cmd: 'rm /var/log/ranger/usersync/*'
          code_skipped: 1

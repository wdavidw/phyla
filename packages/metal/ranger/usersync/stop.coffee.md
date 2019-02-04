# Ranger USersync Stop

Stop the ranger usersync service server. You can also stop the server
manually with the following command:

```
service ranger-usersync stop
```

    module.exports = header: 'Ranger Usersync Stop', handler: ({options}) ->
      @service.start
        name: 'ranger-usersync'

## Clean Logs

      @call header: 'Clean Logs', handler: ->
        @system.execute
          cmd: 'rm /var/log/ranger/usersync/*'
          code_skipped: 1

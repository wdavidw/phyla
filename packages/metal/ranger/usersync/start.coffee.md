
# Ranger Usersync Start

Start the ranger usersync service server. You can also start the server
manually with the following command:

```
service ranger-usersync start
```

    module.exports = header: 'Ranger Usersync Start', handler: ->
      @service.start
        name: 'ranger-usersync'

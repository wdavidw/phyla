
# Ranger Admin Start

Start the ranger admin service server. You can also start the server
manually with the following command:

```
service ranger-admin start
systemctl start ranger-admin
```

    module.exports = header: 'Ranger Admin Start', handler: ->
      @service.start
        header: 'Ranger Admin Start'
        name: 'ranger-admin'

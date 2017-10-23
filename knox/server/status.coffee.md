
# Knox Status

You can also manually get the server status with the following command:

```
service knox-server status
su -l knox -c "/usr/hdp/current/knox-server/bin/gateway.sh status"
```

    module.exports = header: 'Knox Status', handler: ->
      @service.status name: 'knox-server'

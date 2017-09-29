
# Knox Stop

    module.exports = header: 'Knox Stop', label_true: 'STOPPED', handler: ->

## Service

You can also stop the server manually with the following command:

```
service knox-server stop
su -l knox -c "/usr/hdp/current/knox-server/bin/gateway.sh stop"
```

      @service.stop name: 'knox-server'

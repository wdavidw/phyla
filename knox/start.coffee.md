
# Knox Start

    module.exports = header: 'Knox Start', handler: ->

## Service

You can also start the server manually with the following command:

```
service knox-server start
systemctl start knox-server
su -l knox -c "/usr/hdp/current/knox-server/bin/gateway.sh start"
```

      @service.start name: 'knox-server'

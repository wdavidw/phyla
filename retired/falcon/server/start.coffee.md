
# Falcon Server Start

Start the Falcon server. You can also start the server manually with the
following command:

```
su -l falcon -c "/usr/hdp/current/falcon-server/bin/service-start.sh falcon"
```

    module.exports = header: 'Falcon Server Start', handler: ->
      @call once: true, 'masson/core/krb5_client/wait'
      @service.start name: 'falcon'

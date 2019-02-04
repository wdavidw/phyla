
# Falcon Server Status

Run the command `su -l falcon -c '/usr/lib/falcon/bin/falcon-status'` to
retrieve the status of the Falcon server using Ryba.

Discover the server status.

```
su -l falcon -c '/usr/hdp/current/falcon-server/bin/service-status.sh falcon'; [ $? -eq 254 ]
```

    module.exports = header: 'Falcon Server Status', handler: ->
      @service.status
        name: 'falcon'
        code_skipped: [1, 3]
        if_exists: '/etc/init.d/falcon'

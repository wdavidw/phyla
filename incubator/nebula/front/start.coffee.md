
# Open Nebula Front Start

OpenNebula server and Sunstone (Web UI) is started with the service's syntax command.

    module.exports = header: 'OpenNebula Front Start', handler: (options) ->

## OpenNebula Cloud Controller Daemon

      @service.start
        header: 'Cloud Controller'
        name: 'opennebula'

## OpenNebula Web UI Server (Sunstone)

You can also start the server manually with the following two commands:

```
su -l oneadmin -c '/usr/bin/ruby /usr/lib/one/sunstone/sunstone-server.rb'
```

      @service.start
        header: 'Web UI'
        name: 'opennebula-sunstone'

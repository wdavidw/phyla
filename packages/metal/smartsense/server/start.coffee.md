
# Hortonworks Smartsense Start

Run the command `./bin/ryba start -m @rybajs/metal/smartsense/server` to start the 
Hortonworks SmartSense server using Ryba.

    module.exports = header: 'HST Server Start', handler: (options) ->

## Service

Start the MongDB Config server. You can also start the server manually with one of the
following commands:

```
service hst-server start
systemctl start hst-server
```

      @service.start
        header: 'HST Server Start'
        name: 'hst-server'

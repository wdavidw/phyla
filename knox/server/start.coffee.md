
# Knox Start

    module.exports = header: 'Knox Server Start', handler: ({options}) ->

## Wait
Knox doesn't seem to re-sync when ranger-admin is not available. Add wait to ensure plugin
does not stop syncing.

      @call 'ryba/ranger/admin/wait', once: true, options.wait_ranger_admin if options.wait_ranger_admin

## Service

You can also start the server manually with the following command:

```
service knox-server start
systemctl start knox-server
su -l knox -c "/usr/hdp/current/knox-server/bin/gateway.sh start"
```
      
      @service.start name: 'knox-server'

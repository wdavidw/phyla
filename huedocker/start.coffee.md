
# Hue Start

    module.exports = header: 'Hue Docker Start', handler: (options) ->

## Wait

      @call 'ryba/commons/db_admin/wait', once: true, options.wait_db_admin

## Start

Start the Hue 'hue_server' container as a service. It ensures that docker is running and start hue_server container.
You can start the server manually with the following
command:

```
service hue-server-docker start
```

      @service.start
        name: options.service

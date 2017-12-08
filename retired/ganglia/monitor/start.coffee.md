
# Ganglia Monitor Start

Start the Ganglia Monitor server. You can also start the server manually with
the following command:

```
service hdp-gmond start
```

    module.exports = header: 'Ganglia Monitor Start', handler: ->
      @service.start
        name: 'hdp-gmond'
        code_stopped: 1
      # On error, it is often necessary to remove pid files
      # this hasnt been tested yet:
      # .execute
      #   cmd: "rm -rf /var/run/ganglia/hdp/*/*.pid"
      #   if: @retry

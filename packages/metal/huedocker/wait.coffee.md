
# Wait hue server

Wait for hue server to have executed all start up script, and container running.
This script has been written to be able to wait several hue server. hue HA will
be released soon.

    module.exports = header: 'Hue Docker Wait', handler: (options) ->
      @connection.wait options.wait.http

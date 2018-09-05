# Ranger Admin Wait

Wait for Ranger Admin Policy Manager to start.

    module.exports = header: 'Ranger Admin Wait', handler: ({options}) ->

## HTTP

Wait for the Ranger Admin server to accept HTTP connections.

      @wait.execute
        cmd: """
        curl --fail -H "Content-Type: application/json" -k -X GET \
          -u #{options.http.username}:#{options.http.password} \
          "#{options.http.url}"
        """
        code_skipped: [1,7,22]

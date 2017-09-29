
# Rexster Status

Run the command `./bin/ryba status -m ryba/titan/rexster` to retrieve the status
of the Titan server using Ryba.

    module.exports = header: 'Rexster Status', handler: ->
      @system.execute
        cmd: "ps aux | grep 'com.tinkerpop.rexster.Application'"
        code_skipped: 1

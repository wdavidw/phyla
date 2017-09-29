
# Druid Historical Stop

Run the command `./bin/ryba stop -m ryba/druid/overlord` to stop the Druid 
Historical server using Ryba.

    module.exports = header: 'Druid Historical Stop', handler: (options) ->

## Service

      @service.stop
        name: 'druid-historical'
        if_exists: '/etc/init.d/druid-historical'

## Clean Logs

Remove the "historical.log" log file if the property "clean_logs" is
activated.

      @system.execute
        header: 'Clean Logs'
        if: options.clean_logs
        cmd: "rm #{options.log_dir}/historical.log"
        code_skipped: 1

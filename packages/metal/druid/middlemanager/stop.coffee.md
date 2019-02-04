
# Druid MiddleManager Stop

Run the command `./bin/ryba stop -m @rybajs/metal/druid/overlord` to stop the Druid 
MiddleManager server using Ryba.

    module.exports = header: 'Druid MiddleManager Stop', handler: (options) ->

## Options

      @service.stop
        name: 'druid-middlemanager'
        if_exists: '/etc/init.d/druid-middlemanager'

## Clean Logs

Remove the "middleManager.log" log file if the property "clean_logs" is
activated.

      @system.execute
        header: 'Clean Logs'
        if: options.clean_logs
        cmd: "rm #{options.log_dir}/middleManager.log"
        code_skipped: 1

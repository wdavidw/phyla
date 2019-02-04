
# Druid Broker Stop

Run the command `./bin/ryba stop -m @rybajs/metal/druid/overlord` to stop the Druid 
Broker server using Ryba.

    module.exports = header: 'Druid Broker Stop', handler: (options) ->

## Service

      @service.stop
        name: 'druid-broker'
        if_exists: '/etc/init.d/druid-broker'

## Clean Logs

Remove the "broker.log" log file if the property "clean_logs" is
activated.

      @system.execute
        header: 'Clean Logs'
        if: -> options.clean_logs
        cmd: "rm #{options.log_dir}/broker.log"
        code_skipped: 1

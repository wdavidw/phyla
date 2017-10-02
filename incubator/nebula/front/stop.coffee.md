
# Open OpenNebula Front Stop

OpenNebula server and Sunstone (Web UI) is stopped with the service's syntax command.

    module.exports = header: 'OpenNebula Front Stop', handler: (options) ->

## Service

      @service.stop
        name: 'opennebula-sunstone'
      @service.stop
        name: 'opennebula'

## Clean Logs

Remove the core log file, "oned.log" and the scheduler logs, "sched.log". 
"oned.log-*" log file if the property "clean_logs" is activated.

      @system.execute
        header: 'Clean Logs'
        if: options.clean_logs
        cmd: """
        rm #{options.log_dir}/oned.log
        rm #{options.log_dir}/oned.log-*
        rm #{options.log_dir}/sched.log
        rm #{options.log_dir}/sched.log-*
        """
        code_skipped: 1

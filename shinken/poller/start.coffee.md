
# Shinken Poller Start

Start the Shinken Poller service.

    module.exports = header: 'Shinken Poller Start', handler: (options) ->
      @service.start name: 'shinken-poller'

## Start Executor

Start the docker executors (normal and admin)

      @call header: 'Docker Executor', ->
        @docker.start
          container: 'poller-executor'
        @docker.exec
          container: 'poller-executor'
          cmd: "kinit #{options.krb5_principal} -kt #{options.krb5_keytab}"
          shy: true

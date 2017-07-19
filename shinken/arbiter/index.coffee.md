
# Shinken Arbiter

Loads the configuration files and dispatches the host and service objects to the
scheduler(s). Watchdog for all other processes and responsible for initiating
failovers if an error is detected. Can route check result events from a Receiver
to its associated Scheduler.

    module.exports =
      use:
        commons: implicit: true, module: 'ryba/shinken/commons'
        monitoring: implicit: true, module: 'ryba/commons/monitoring'
        reactionner: 'ryba/shinken/poller'
        receiver: 'ryba/shinken/poller'
        scheduler: 'ryba/shinken/poller'
        broker: 'ryba/shinken/broker'
        poller: 'ryba/shinken/poller'
      configure:
        'ryba/shinken/arbiter/configure'
      commands:
        'check':
          'ryba/shinken/arbiter/check'
        'install': [
          'ryba/shinken/arbiter/install'
          'ryba/shinken/arbiter/start'
          'ryba/shinken/arbiter/check'
        ]
        'prepare':
          'ryba/shinken/arbiter/prepare'
        'start':
          'ryba/shinken/arbiter/start'
        'status':
          'ryba/shinken/arbiter/status'
        'stop':
          'ryba/shinken/arbiter/stop'


# Shinken Arbiter

Loads the configuration files and dispatches the host and service objects to the
scheduler(s). Watchdog for all other processes and responsible for initiating
failovers if an error is detected. Can route check result events from a Receiver
to its associated Scheduler.

    module.exports =
      deps:
        ssl : module: 'masson/core/ssl', local: true
        iptables: module: 'masson/core/iptables', local: true
        commons:  module: 'ryba/shinken/commons', local: true, required: true
        monitoring: module: 'ryba/commons/monitoring', local: true, required: true
        arbiter: module: 'ryba/shinken/arbiter'
        reactionner: module: 'ryba/shinken/reactionner'
        receiver: module: 'ryba/shinken/receiver'
        scheduler: module: 'ryba/shinken/scheduler'
        broker: module: 'ryba/shinken/broker'
        poller: module: 'ryba/shinken/poller'
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

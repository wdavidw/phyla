
# Shinken Arbiter

Loads the configuration files and dispatches the host and service objects to the
scheduler(s). Watchdog for all other processes and responsible for initiating
failovers if an error is detected. Can route check result events from a Receiver
to its associated Scheduler.

    module.exports =
      deps:
        ssl : module: 'masson/core/ssl', local: true
        iptables: module: 'masson/core/iptables', local: true
        commons:  module: '@rybajs/metal/shinken/commons', local: true, required: true
        monitoring: module: '@rybajs/metal/commons/monitoring', local: true, required: true
        arbiter: module: '@rybajs/metal/shinken/arbiter'
        reactionner: module: '@rybajs/metal/shinken/reactionner'
        receiver: module: '@rybajs/metal/shinken/receiver'
        scheduler: module: '@rybajs/metal/shinken/scheduler'
        broker: module: '@rybajs/metal/shinken/broker'
        poller: module: '@rybajs/metal/shinken/poller'
      configure:
        '@rybajs/metal/shinken/arbiter/configure'
      commands:
        'check':
          '@rybajs/metal/shinken/arbiter/check'
        'install': [
          '@rybajs/metal/shinken/arbiter/install'
          '@rybajs/metal/shinken/arbiter/start'
          '@rybajs/metal/shinken/arbiter/check'
        ]
        'prepare':
          '@rybajs/metal/shinken/arbiter/prepare'
        'start':
          '@rybajs/metal/shinken/arbiter/start'
        'status':
          '@rybajs/metal/shinken/arbiter/status'
        'stop':
          '@rybajs/metal/shinken/arbiter/stop'

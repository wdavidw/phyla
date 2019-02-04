
# Shinken Scheduler

Plans the next run of host and service checks
Dispatches checks to the poller(s)
Calculates state and dependencies
Applies KPI triggers
Raises Notifications and dispatches them to the reactionner(s)
Updates the retention file (or other retention backends)
Sends broks (internal events of any kind) to the broker(s)

    module.exports =
      deps:
        ssl : module: 'masson/core/ssl', local: true
        iptables: module: 'masson/core/iptables', local: true
        commons: implicit: true, module: '@rybajs/metal/shinken/commons', local: true
        scheduler: module: '@rybajs/metal/shinken/scheduler'
      configure:
        '@rybajs/metal/shinken/scheduler/configure'
      commands:
        'check':
          '@rybajs/metal/shinken/scheduler/check'
        'install': [
          '@rybajs/metal/shinken/scheduler/install'
          '@rybajs/metal/shinken/scheduler/start'
          '@rybajs/metal/shinken/scheduler/check'
        ]
        'prepare':
          '@rybajs/metal/shinken/scheduler/prepare'
        'start':
          '@rybajs/metal/shinken/scheduler/start'
        'status':
          '@rybajs/metal/shinken/scheduler/status'
        'stop':
          '@rybajs/metal/shinken/scheduler/stop'

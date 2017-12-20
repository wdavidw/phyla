
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
        commons: implicit: true, module: 'ryba/shinken/commons', local: true
        scheduler: module: 'ryba/shinken/scheduler'
      configure:
        'ryba/shinken/scheduler/configure'
      commands:
        'check':
          'ryba/shinken/scheduler/check'
        'install': [
          'ryba/shinken/scheduler/install'
          'ryba/shinken/scheduler/start'
          'ryba/shinken/scheduler/check'
        ]
        'prepare':
          'ryba/shinken/scheduler/prepare'
        'start':
          'ryba/shinken/scheduler/start'
        'status':
          'ryba/shinken/scheduler/status'
        'stop':
          'ryba/shinken/scheduler/stop'

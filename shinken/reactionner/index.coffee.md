
# Shinken Reactionner

Gets notifications and eventhandlers from the scheduler, executes plugins/scripts
and sends the results to the scheduler.

    module.exports =
      deps:
        ssl : module: 'masson/core/ssl', local: true
        iptables: module: 'masson/core/iptables', local: true
        commons: implicit: true, module: 'ryba/shinken/commons', local: true
        reactionner: module: 'ryba/shinken/reactionner'
      configure:
        'ryba/shinken/reactionner/configure'
      commands:
        'check':
          'ryba/shinken/reactionner/check'
        'install': [
          'ryba/shinken/reactionner/install'
          'ryba/shinken/reactionner/start'
          'ryba/shinken/reactionner/check'
        ]
        'prepare':
          'ryba/shinken/reactionner/prepare'
        'start':
          'ryba/shinken/reactionner/start'
        'status':
          'ryba/shinken/reactionner/status'
        'stop':
          'ryba/shinken/reactionner/stop'

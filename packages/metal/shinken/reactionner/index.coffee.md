
# Shinken Reactionner

Gets notifications and eventhandlers from the scheduler, executes plugins/scripts
and sends the results to the scheduler.

    module.exports =
      deps:
        ssl : module: 'masson/core/ssl', local: true
        iptables: module: 'masson/core/iptables', local: true
        commons: implicit: true, module: '@rybajs/metal/shinken/commons', local: true
        reactionner: module: '@rybajs/metal/shinken/reactionner'
      configure:
        '@rybajs/metal/shinken/reactionner/configure'
      commands:
        'check':
          '@rybajs/metal/shinken/reactionner/check'
        'install': [
          '@rybajs/metal/shinken/reactionner/install'
          '@rybajs/metal/shinken/reactionner/start'
          '@rybajs/metal/shinken/reactionner/check'
        ]
        'prepare':
          '@rybajs/metal/shinken/reactionner/prepare'
        'start':
          '@rybajs/metal/shinken/reactionner/start'
        'status':
          '@rybajs/metal/shinken/reactionner/status'
        'stop':
          '@rybajs/metal/shinken/reactionner/stop'

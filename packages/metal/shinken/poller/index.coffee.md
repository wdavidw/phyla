
# Shinken Poller

Gets checks from the scheduler, execute plugins or integrated poller modules and
send the results to the scheduler
Poller modules:

*   NRPE - Executes active data acquisition for Nagios Remote Plugin Executor agents
*   SNMP - Executes active data acquisition for SNMP enabled agents
*   CommandPipe - Receives passive status and performance data from check_mk script,
will not process commands

.
This module consumes proportionally to the cluster size. The limit for one poller
is approximatively 1000 checks/s

    module.exports =
      deps:
        ssl : module: 'masson/core/ssl', local: true
        iptables: module: 'masson/core/iptables', local: true
        docker: module: 'masson/commons/docker', local: true, auto: true
        krb5_client: module: 'masson/core/krb5_client', local: true
        commons: implicit: true, module: '@rybajs/metal/shinken/commons', local: true
        monitoring: module: '@rybajs/metal/commons/monitoring'
        poller: module: '@rybajs/metal/shinken/poller'
      configure:
        '@rybajs/metal/shinken/poller/configure'
      commands:
        'check':
          '@rybajs/metal/shinken/poller/check'
        'install': [
          '@rybajs/metal/shinken/poller/install'
          '@rybajs/metal/shinken/poller/start'
          '@rybajs/metal/shinken/poller/check'
        ]
        'start':
          '@rybajs/metal/shinken/poller/start'
        'stop':
          '@rybajs/metal/shinken/poller/stop'
        'prepare':
          '@rybajs/metal/shinken/poller/prepare'

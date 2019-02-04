
# Shinken Receiver (optional)

Receives data passively from local or remote protocols. Passive data reception
that is buffered before forwarding to the appropriate Scheduler (or receiver for global commands).
Allows to set up a "farm" of Receivers to handle a high rate of incoming events.
Modules for receivers:

* NSCA - NSCA protocol receiver
* Collectd - Receive performance data from collectd via the network
* CommandPipe - Receive commands, status updates and performance data
* TSCA - Apache Thrift interface to send check results using a high rate buffered TCP connection directly from programs
* Web Service - A web service that accepts http posts of check results (beta)

This module is only needed when enabling passive checks

    module.exports =
      deps:
        ssl: module: 'masson/core/ssl', local: true
        iptables: module: 'masson/core/iptables', local: true
        commons: module: '@rybajs/metal/shinken/commons', local: true
        receiver: module: '@rybajs/metal/shinken/receiver'
      configure:
        '@rybajs/metal/shinken/receiver/configure'
      commands:
        'check':
          '@rybajs/metal/shinken/receiver/check'
        'install': [
          '@rybajs/metal/shinken/receiver/install'
          '@rybajs/metal/shinken/receiver/start'
          '@rybajs/metal/shinken/receiver/check'
        ]
        'prepare':
          '@rybajs/metal/shinken/receiver/prepare'
        'start':
          '@rybajs/metal/shinken/receiver/start'
        'status':
          '@rybajs/metal/shinken/receiver/status'
        'stop':
          '@rybajs/metal/shinken/receiver/stop'

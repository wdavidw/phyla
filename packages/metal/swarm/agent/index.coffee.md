
# Docker Swarm Agent

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        ssl: 'masson/core/ssl'
        docker: implicit:true, module: 'masson/commons/docker', local: true
        swarm_manager: module: '@rybajs/metal/swarm/manager'
      configure:
        '@rybajs/metal/swarm/agent/configure'
      commands:
        install: [
          '@rybajs/metal/swarm/agent/install'
          '@rybajs/metal/swarm/agent/start'
        ]
        start:
          '@rybajs/metal/swarm/agent/start'
        stop:
          '@rybajs/metal/swarm/agent/stop'

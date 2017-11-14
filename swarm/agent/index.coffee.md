
# Docker Swarm Agent

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        ssl: 'masson/core/ssl'
        docker: implicit:true, module: 'masson/commons/docker', local: true
        swarm_manager: module: 'ryba/swarm/manager'
      configure:
        'ryba/swarm/agent/configure'
      commands:
        install: [
          'ryba/swarm/agent/install'
          'ryba/swarm/agent/start'
        ]
        start:
          'ryba/swarm/agent/start'
        stop:
          'ryba/swarm/agent/stop'


# Docker Swarm Agent

    module.exports =
      use:
        iptables: module: 'masson/core/iptables', local: true
        ssl: 'masson/core/ssl'
        docker: implicit:true, module: 'masson/commons/docker', local: true
        swarm_manager: module: 'ryba/swarm/manager'
      configure:
        'ryba/swarm/agent/configure'
      commands:
        install: ->
          options = @config.ryba.swarm.agent
          @call 'ryba/swarm/agent/install', options
          @call 'ryba/swarm/agent/start', options
        start: ->
          options = @config.ryba.swarm.agent
          @call 'ryba/swarm/agent/start', options
        stop: ->
          options = @config.ryba.swarm.agent
          @call 'ryba/swarm/agent/stop', options

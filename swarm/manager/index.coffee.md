
# Docker Swarm Manager
Docker Swarm brings clustering support to docker enabled hosts.
To provide swarm, special containers must be runned on server where docker  is instaled.

Swarm Manager is one of those container. It is runned from the [official](https://hub.docker.com/_/swarm/).
Docker could be installed with or without `masson/commons/docker`. See configuration
to check how to configure it

Once a machine is added to the swarm cluster (manager or agent), it will be configured
to communicate by default with the `ryba/swarm/manager`.

    module.exports =
      deps:
        docker: module: 'masson/commons/docker', local: true, required: true, auto: true
        zookeeper_server: module: 'ryba/zookeeper/server'
        swarm_manager: 'ryba/swarm/manager'
        iptables: module: 'masson/core/iptables', local: true
      configure:
        'ryba/swarm/manager/configure'
      commands:
        install: [
          'ryba/swarm/manager/install'
          'ryba/swarm/manager/start'
        ]
        stop:
          'ryba/swarm/manager/stop'
        start:
          'ryba/swarm/manager/start'

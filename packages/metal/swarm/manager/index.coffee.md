
# Docker Swarm Manager
Docker Swarm brings clustering support to docker enabled hosts.
To provide swarm, special containers must be runned on server where docker  is instaled.

Swarm Manager is one of those container. It is runned from the [official](https://hub.docker.com/_/swarm/).
Docker could be installed with or without `masson/commons/docker`. See configuration
to check how to configure it

Once a machine is added to the swarm cluster (manager or agent), it will be configured
to communicate by default with the `@rybajs/metal/swarm/manager`.

    module.exports =
      deps:
        docker: module: 'masson/commons/docker', local: true, required: true, auto: true
        zookeeper_server: module: '@rybajs/metal/zookeeper/server'
        swarm_manager: '@rybajs/metal/swarm/manager'
        iptables: module: 'masson/core/iptables', local: true
      configure:
        '@rybajs/metal/swarm/manager/configure'
      commands:
        install: [
          '@rybajs/metal/swarm/manager/install'
          '@rybajs/metal/swarm/manager/start'
        ]
        stop:
          '@rybajs/metal/swarm/manager/stop'
        start:
          '@rybajs/metal/swarm/manager/start'


# Configure Swarm Manager hosts

Use the `ryba.swarm_primary` for setting which host should be the primary swarm manager.
This host will be used when rendering default DOCKER_HOST ENV variable on swarm nodes.

    module.exports = (service) ->
      service = migration.call @, service, 'ryba/solr/cloud_docker', ['ryba', 'solr', 'cloud_docker'], require('nikita/lib/misc').merge require('.').use,
        iptables: key: ['iptables']
        docker: key: ['docker']
        zookeeper_server: key: ['ryba', 'zookeeper']
        swarm_manager: key: ['ryba', 'swarm', 'manager']
      options = @config.ryba.swarm.manager = service.options

## Docker Daemon options
      
      options.docker ?= {}
      options.docker[opt] ?= service.use.docker.options[opt] for opt in [
        'host'
        'default_port'
        'tlscacert'
        'tlscert'
        'tlskey'
        'tlsverify'
        'conf_dir'
      ]
      options.fqdn ?= service.node.fqdn

## Swarm Image

      options.image ?= 'swarm'
      options.tag ?= 'latest'
      options.conf_dir ?= '/etc/docker-swarm'
      options.iptables ?= service.use.iptables and service.use.iptables.options.action is 'start'

## Service Discovery

Configures the docker daemon engine start options for swarm.
For now only zookeeper is supported for discovery backend.

Note: The listen address and advertise adress are different:
  - the advertise address configures which address CLI should use to communicate
with the swarm manager's docker engine
  - the listen address configures the docker engine to listen to all interfaces of the machine.

      options.cluster ?= {}
      options.cluster.discovery ?= 'zookeeper'
      options ?= {}
      options.name ?= 'swarm_manager'
      options.advertise_host ?= service.node.ip
      options.advertise_port ?= options.docker.default_port
      options.listen_host ?= '0.0.0.0'
      options.listen_port ?= 3376
      switch options.cluster.discovery
        #TODO add etcd
        when 'zookeeper'
          options.cluster.zk_node ?= '/swarm-nodes'
          options.cluster.zk_urls ?= service.use.zookeeper_server
            .filter( (srv) -> srv.options.config['peerType'] is 'participant')
            .map( (srv) -> "#{srv.node.fqdn}:#{srv.options.config['clientPort']}").join ','
          options.cluster.zk_store ?= "zk://#{options.cluster.zk_urls}#{options.cluster.zk_node}"
        else
          throw Error "Ryba does not support service discovery backend #{options.cluster.discovery} for swarm"

## Docker Deamon Configuration

Pass docker start option to docker daemon to use it with swarm.

### TCP Socket

Swarm manager uses the advertise address to communicate. It must be specified
in the start option of the local daemon engine to enable it.

      tcp_socket = "#{service.node.fqdn}:#{options.advertise_port}"
      if service.use.docker?.options.sockets.tcp.indexOf(tcp_socket) is -1
      then service.use.docker.options.sockets.tcp.push tcp_socket

### Swarm Cluster

This starting options should be injected to serivce.use.docker variable. For now 
`ryba/swarm/manager` modify the starting options and restart docker engine.

      # @config.docker.other_args['cluster-store'] ?= options.cluster.zk_store
      # @config.docker.other_args['cluster-advertise'] ?= "#{options.advertise_host}:#{options.advertise_port}"
      options.other_args ?= []
      options.other_args['cluster-store'] ?= options.cluster.zk_store
      options.other_args['cluster-advertise'] ?= "#{options.advertise_host}:#{options.advertise_port}"
      service.use.docker.options.other_args = merge service.use.docker.options.other_args, options.other_args if service.use.docker?

### SSL
Inherits properties from local docker daemon
      
      options.ssl ?= merge {}, service.use.docker.options.ssl
      options.other_args['tlscacert'] ?= service.use.docker.options.other_args['tlscacert']
      options.other_args['tlscert'] ?= service.use.docker.options.other_args['tlscert']
      options.other_args['tlskey'] ?= service.use.docker.options.other_args['tlskey']


### Wait

      options.wait ?= {}
      options.wait.tcp ?= for srv in service.use.swarm_manager
        host: srv.node.fqdn
        port: srv.options.advertise_port or options.advertise_port
      options.wait_zookeeper ?= service.use.zookeeper_server[0].options.wait

## Dependencies

    {merge} = require 'nikita/lib/misc'
    migration = require 'masson/lib/migration'

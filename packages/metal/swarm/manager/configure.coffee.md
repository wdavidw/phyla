
# Configure Swarm Manager hosts

Use the `ryba.swarm_primary` for setting which host should be the primary swarm manager.
This host will be used when rendering default DOCKER_HOST ENV variable on swarm nodes.

    module.exports = (service) ->
      options = service.options

## Docker Daemon options
      
      options.docker ?= {}
      options.docker[opt] ?= service.deps.docker.options[opt] for opt in [
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
      options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'

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
          options.cluster.zk_urls ?= if service.deps.zookeeper_server
          then service.deps.zookeeper_server.filter( (srv) -> srv.options.config['peerType'] is 'participant').map( (srv) -> "#{srv.node.fqdn}:#{srv.options.config['clientPort']}").join ','
          else options.cluster.zk_urls
          throw Error 'Missing options.cluster.zk_urls for discovery mode as zookeeper' unless options.cluster.zk_urls
          options.cluster.zk_store ?= "zk://#{options.cluster.zk_urls}#{options.cluster.zk_node}"
        else
          throw Error "Ryba does not support service discovery backend #{options.cluster.discovery} for swarm"

## Docker Deamon Configuration

Pass docker start option to docker daemon to use it with swarm.

### TCP Socket

Swarm manager uses the advertise address to communicate. It must be specified
in the start option of the local daemon engine to enable it.

      tcp_socket = "#{service.node.fqdn}:#{options.advertise_port}"
      if service.deps.docker?.options.sockets.tcp.indexOf(tcp_socket) is -1
      then service.deps.docker.options.sockets.tcp.push tcp_socket

### Swarm Cluster

This starting options should be injected to serivce.use.docker variable. For now 
`@rybajs/metal/swarm/manager` modify the starting options and restart docker engine.

      # @config.docker.other_args['cluster-store'] ?= options.cluster.zk_store
      # @config.docker.other_args['cluster-advertise'] ?= "#{options.advertise_host}:#{options.advertise_port}"
      options.other_args ?= { }
      options.other_args['cluster-store'] ?= options.cluster.zk_store
      options.other_args['cluster-advertise'] ?= "#{options.advertise_host}:#{options.advertise_port}"
      service.deps.docker.options.other_args = merge service.deps.docker.options.other_args, options.other_args if service.deps.docker?

### SSL
Inherits properties from local docker daemon
      
      options.ssl ?= merge service.deps.docker.options.ssl
      if options.ssl.enabled
        options.other_args['tlscacert'] ?= service.deps.docker.options.other_args['tlscacert']
        options.other_args['tlscert'] ?= service.deps.docker.options.other_args['tlscert']
        options.other_args['tlskey'] ?= service.deps.docker.options.other_args['tlskey']
      service.deps.docker.options.daemon ?= {}
      service.deps.docker.options.daemon['cluster-advertise'] ?= options.other_args['cluster-advertise']
      service.deps.docker.options.daemon['cluster-store'] ?= options.other_args['cluster-store']

### Wait

      options.wait ?= {}
      options.wait.tcp ?= for srv in service.deps.swarm_manager
        host: srv.node.fqdn
        port: srv.options.advertise_port or options.advertise_port
      options.wait_zookeeper ?=  if service.deps.zookeeper_server
      then service.deps.zookeeper_server?[0].options.wait
      else tcp: options.cluster.zk_urls.split(',').map (config) ->
        [server,port] = config.split(':')
        host: server
        port : port or 2181

## Dependencies

    {merge} = require 'mixme'

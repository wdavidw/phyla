
# Configure Swarm Manager hosts

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
      options.name ?= 'swarm_agent'
      options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'
      
## Cluster discovery from manager

      #Note for docker to be able to start the ip address must be set (instead of hostname)
      options.advertise_host ?= service.node.fqdn
      options.advertise_port ?= options.docker.default_port
      options.swarm_manager_host ?= "#{service.deps.swarm_manager[0].node.fqdn}:3376"

## Docker Deamon Configuration

Pass docker start option to docker daemon to use it with swarm.

### TCP Socket

Swarm nodes use the advertise address to communicate. It must be specified
in the start option of the local daemon engine to enable it.

      tcp_socket = "#{service.node.fqdn}:#{options.advertise_port}"
      if service.deps.docker?.options.sockets.tcp.indexOf(tcp_socket) is -1
      then service.deps.docker.options.sockets.tcp.push tcp_socket

### SSL
Inherits properties from local docker daemon
      
      options.ssl ?= merge {}, service.deps.docker.options.ssl
      options.other_args ?= {}
      options.other_args['tlscacert'] ?= service.deps.docker.options.other_args['tlscacert']
      options.other_args['tlscert'] ?= service.deps.docker.options.other_args['tlscert']
      options.other_args['tlskey'] ?= service.deps.docker.options.other_args['tlskey']


### Swarm Cluster & Discovery

This starting options should be injected to @config.docker variable. For now 
`ryba/swarm/agent` modify the starting options and restart docker engine.

      options.cluster ?= {}
      options.cluster =  merge service.deps.swarm_manager[0].options.cluster, options.cluster
      # @config.docker.other_args['cluster-store'] ?= swarm.cluster.zk_store
      # @config.docker.other_args['cluster-advertise'] ?= "#{swarm.manager.advertise_host}:#{swarm.manager.advertise_port}"
      options.other_args['cluster-store'] ?= options.cluster.zk_store
      options.other_args['cluster-advertise'] ?= "#{service.node.ip}:#{options.advertise_port}"
      service.deps.docker.options.other_args = merge service.deps.docker.options.other_args, options.other_args if service.deps.docker?
      service.deps.docker.options.daemon ?= {}
      service.deps.docker.options.daemon['cluster-advertise'] ?= options.other_args['cluster-advertise']
      service.deps.docker.options.daemon['cluster-store'] ?= options.other_args['cluster-store']

### Wait

      options.wait_manager ?= service.deps.swarm_manager[0].options.wait

## Dependencies

    {merge} = require 'nikita/lib/misc'

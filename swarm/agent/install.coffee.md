
# Install Swarm Manager Node

    module.exports = header: 'Swarm Manager Install', handler: ->
      {swarm} = @config.ryba
      tmp_dir  = swarm.tmp_dir ?= "/var/tmp/ryba/swarm"
      swarm_ctxs = @contexts 'ryba/swarm/manager'
      [primary_ctx] = swarm_ctxs.filter( (ctx) -> ctx.config.ryba.swarm_primary is true)

## Wait dependencies

      @call 'ryba/zookeeper/server/wait'

## IPTables

| Service               | Port  | Proto       | Parameter          |
|-----------------------|-------|-------------|--------------------|
| Swarm Agent Engine    | 2375  | tcp         | port               |
| Swarm Agent Engine    | 2376  | tcp - TLS   | port               |

      @tools.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: swarm.agent.advertise_port, protocol: 'tcp', state: 'NEW', comment: "Docker Engine Port" }
        ]
        if: @config.iptables.action is 'start'

## Container
Ryba install official docker/swarm image.
Try to pull the image first, or upload from cache if not pull possible.

      @call header: 'Download Container', ->
        exists = false
        @docker.checksum
          image: swarm.image
          tag: swarm.tag
        , (err, status, checksum) ->
          throw err if err
          exists = checksum
        @docker.pull
          header: 'from registry'
          if: -> not exists
          tag: swarm.image
          code_skipped: 1
        @file.download
          unless: -> @status(-1) or @status(-2)
          binary: true
          header: 'from cache'
          source: "#{@config.nikita.cache_dir}/swarm.tar"
          target: "#{tmp_dir}/swarm.tar"
        @docker.load
          header: 'Load'
          unless: -> @status(-3)
          if_exists: "#{tmp_dir}/swarm.tar"
          source: "#{tmp_dir}/swarm.tar"

## Run Container
Run the swarm agent container. Pass host option to null to run the container
on the local engine daemon (before configuring swarm).

      @connection.wait
        header: 'Wait Manager'
        host: primary_ctx.config.host
        port: primary_ctx.config.ryba.swarm.manager.advertise_port
      @call =>
        args = []
        args.push [
          "--advertise=#{swarm.agent.advertise_host}:#{swarm.agent.advertise_port}"
          "#{swarm.cluster.zk_store}"
          ]...
        @docker.service
          header: 'Run Container'
          force: -> @status -1
          name: swarm.agent.name
          image: swarm.image
          docker: @config.docker
          volume: [
            "#{@config.docker.conf_dir}/certs.d/:/certs:ro"
          ]
          cmd: "join #{args.join ' '}"
          args: args
          net: if swarm.host_mode then 'host' else null

## Configure Environment

Write file in profile.d to be able to communicate with swarm master. 
- DOCKER_HOST: used to designated the docker daemon to communicate with.
- DOCKER_CERT_PATH: used when TLS is enabled
- DOCKER_TLS_VERIFY: enable TLS verification

        @file
          target: '/etc/profile.d/docker.sh'
          write: [
            match: /^export DOCKER_HOST=.*$/mg
            replace: "export DOCKER_HOST=tcp://#{primary_ctx.config.host}:#{primary_ctx.config.ryba.swarm.manager.listen_port}"
            append: true
          ,
            match: /^export DOCKER_CERT_PATH=.*$/mg
            replace: "export DOCKER_CERT_PATH=#{@config.docker.conf_dir}/certs.d"
            append: true
          ,
            match: /^export DOCKER_TLS_VERIFY=.*$/mg
            replace: "export DOCKER_TLS_VERIFY=#{if @config.docker.ssl.enabled then 1 else 0}"
            append: true
          ]
          backup: true
          mode: 0o750
          eof: true

## Dependencies

    path = require 'path'

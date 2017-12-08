
# Install Swarm Manager Node

    module.exports = header: 'Swarm Manager Install', handler: ->
      {swarm} = @config.ryba
      tmp_dir  = swarm.tmp_dir ?= "/var/tmp/ryba/swarm"
      swarm_ctxs = @contexts 'ryba/swarm/manager'
      [primary_ctx] = swarm_ctxs.filter( (ctx) -> ctx.config.ryba.swarm_primary is true)
      machine = @config.nikita.machine

## Wait dependencies

      @call 'ryba/zookeeper/server/wait'

## IPTables

| Service                 | Port  | Proto       | Parameter          |
|-------------------------|-------|-------------|--------------------|
| Swarm Manager Engine    | 2375  | tcp         | port               |
| Swarm Manager Engine    | 2376  | tcp - TLS   | port               |
| Swarm Manager Advertise | 3376  | tcp         | port               |

      @tools.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: swarm.manager.listen_port, protocol: 'tcp', state: 'NEW', comment: "Docker Engine Port" },
          { chain: 'INPUT', jump: 'ACCEPT', dport: swarm.manager.advertise_port, protocol: 'tcp', state: 'NEW', comment: "Swarm Manager Advertise Port" }
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
Run the swarm manager container. Pass host option to null to run the container
on the local engine daemon (before configuring swarm).

      @connection.wait
        header: 'Wait Primary Manager'
        unless: @config.ryba.swarm_primary
        host: primary_ctx.config.host
        port: primary_ctx.config.ryba.swarm.manager.advertise_port
      @call =>
        args = []
        if @config.docker.ssl.enabled
         args.push [
            '--tlsverify'
            "--tlskey=/certs/#{path.basename @config.docker.ssl.key}"
            "--tlscert=/certs/#{path.basename @config.docker.ssl.cert}"
            "--tlscacert=/certs/#{path.basename @config.docker.ssl.cacert}"
          ]...
        args.push [
          "--host #{swarm.manager.listen_host}:#{swarm.manager.listen_port}"
          '--replication'
          "--advertise #{swarm.other_args['cluster-advertise']}"
          "#{swarm.cluster.zk_store}"
          ]...
        @docker.service
          header: 'Run Container'
          force: -> @status -1
          docker: @config.docker
          name: swarm.manager.name
          net: if swarm.host_mode then 'host' else null
          image: swarm.image
          volume: [
            "#{@config.docker.conf_dir}/certs.d/:/certs:ro"
          ]
          cmd: "manage #{args.join ' '}"
          port: [
            "#{swarm.manager.listen_port}:#{swarm.manager.listen_port}"
          ]

## Configure Environment
Write file in profile.d to be able to communicate with swarm master.
- DOCKER_HOST: used to designated the docker daemon to communicate with.
- DOCKER_CERT_PATH: used when TLS is enabled
- DOCKER_TLS_VERIFY: enable TLS verification
The port is set to the manager listen_port, to be able to type docker command
on the swarm cluster level

        @file
          target: '/etc/profile.d/docker.sh'
          write: [
            match: /^export DOCKER_HOST=.*$/mg
            replace: "export DOCKER_HOST=tcp://#{@config.host}:#{@config.docker.default_port}"
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
          eof: true
          mode: 0o750

## Dependencies

    path = require 'path'

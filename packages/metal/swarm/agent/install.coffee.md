
# Install Swarm Agent Node

    module.exports = header: 'Swarm Agent Install', handler: (options) ->
      tmp_dir  = options.tmp_dir ?= "/var/tmp/@rybajs/metal/swarm"

## Wait dependencies

      @connection.wait options.wait_manager.tcp

## IPTables

| Service               | Port  | Proto       | Parameter          |
|-----------------------|-------|-------------|--------------------|
| Swarm Agent Engine    | 2375  | tcp         | port               |
| Swarm Agent Engine    | 2376  | tcp - TLS   | port               |

      @tools.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.advertise_port, protocol: 'tcp', state: 'NEW', comment: "Docker Engine Port" }
        ]
        if: options.iptables

## Container
Ryba install official docker/swarm image.
Try to pull the image first, or upload from cache if not pull possible.

      @call header: 'Download Container', ->
        exists = false
        @docker.checksum
          image: options.image
          tag: options.tag
        , (err, status, checksum) ->
          throw err if err
          exists = checksum
        @docker.pull
          header: 'from registry'
          if: -> not exists
          tag: options.image
          code_skipped: 1
        @file.download
          unless: -> @status(-1) or @status(-2)
          binary: true
          header: 'from cache'
          source: "#{options.cache_dir}/swarm.tar"
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
      , options.wait_manager
      @call =>
        args = []
        args.push [
          "--advertise=#{options.advertise_host}:#{options.advertise_port}"
          "#{options.cluster.zk_store}"
          ]...
        @docker.service
          header: 'Run Container'
          force: -> @status -1
          name: options.name
          image: options.image
          docker: options.docker
          volume: [
            "#{options.docker.conf_dir}/certs.d/:/certs:ro"
          ]
          cmd: "join #{args.join ' '}"
          args: args
          net: if options.host_mode then 'host' else null

## Configure Environment

Write file in profile.d to be able to communicate with swarm master. 
- DOCKER_HOST: used to designated the docker daemon to communicate with.
- DOCKER_CERT_PATH: used when TLS is enabled
- DOCKER_TLS_VERIFY: enable TLS verification

        @file
          target: '/etc/profile.d/docker.sh'
          write: [
            match: /^export DOCKER_HOST=.*$/mg
            replace: "export DOCKER_HOST=#{options.swarm_manager_host}"
            append: true
          ,
            match: /^export DOCKER_CERT_PATH=.*$/mg
            replace: "export DOCKER_CERT_PATH=#{options.docker.conf_dir}/certs.d"
            append: true
          ,
            match: /^export DOCKER_TLS_VERIFY=.*$/mg
            replace: "export DOCKER_TLS_VERIFY=#{if options.ssl.enabled then 1 else 0}"
            append: true
          ]
          backup: true
          mode: 0o750
          eof: true

## Dependencies

    path = require 'path'

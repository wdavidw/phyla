# Elasticsearch (Docker) Install

    module.exports =  header: 'Docker ES Install', handler: (options) ->

## Identities

      @system.group options.group
      @system.user options.user

## Limits

      @system.limits
        header: 'Ulimit'
        user: options.user.name
      , options.user.limits

# Kernel

Configure kernel parameters at runtime. There are no properties set by default,
here's a suggestion:

*    vm.swappiness = 10
*    vm.overcommit_memory = 1
*    vm.overcommit_ratio = 100
*    net.core.somaxconn = 4096 (default socket listen queue size 128)

Note, we might move this middleware to Masson.

      @tools.sysctl
        header: 'Kernel'
        properties: options.sysctl
        merge: true
        comment: true

## SSL Certificate

      @file.download
        header: 'SSL CAcert'
        source: options.ssl.cacert.source
        local: options.ssl.cacert.local
        target: options.ssl.dest_cacert
        mode: 0o0640
      @file.download
        header: 'SSL cert'
        source: options.ssl.cert.source
        local: options.ssl.cert.local
        target: options.ssl.dest_cert
        mode: 0o0640
      @file.download
        header: 'SSL key'
        source: options.ssl.key.source
        local: options.ssl.key.local
        target: options.ssl.dest_key
        mode: 0o0640

## Write YAML Files
The write can be done ne two ways:
- multiple container / host
  configuration file are written as many as services present in docker-compose.
- one container / host


      for es_name,es of options.clusters then do (es_name,es) =>
        docker_services = {}
        docker_networks = {}
        @call header: "#{es_name}: ", ->
          # single_node mode
          @file.yaml
            unless: es.multiple_node
            header: 'elasticsearch config file'
            target: "/etc/elasticsearch/#{es_name}/conf/elasticsearch.yml"
            content: es.config
            backup: true
          @file.render
            unless: es.multiple_node
            target: "/etc/elasticsearch/#{es_name}/conf/java.policy"
            source: "#{__dirname}/resources/java.policy.j2"
            local: true
            context: {es: logs_path: "#{es.logs_path}/#{es_name}"}
            backup: true
          @file
            unless: es.multiple_node
            target: "/etc/elasticsearch/#{es_name}/conf/log4j2.properties"
            source: "#{__dirname}/resources/log4j2.properties"
            local: true
            backup: true
          @file.render
            if: es.multiple_node
            target: "/etc/elasticsearch/#{es_name}/common/java.policy"
            source: "#{__dirname}/resources/java.policy.j2"
            local: true
            context: {es: logs_path: "#{es.logs_path}/#{es_name}"}
            backup: true
          @file
            if: "/etc/elasticsearch/#{es_name}/common/log4j2.properties"
            source: "#{__dirname}/resources/log4j2.properties"
            local: true
            backup: true
          # multiple_node mode
          @each es.nodes, (opts, cb) ->
            service_name = opts.key
            @file.yaml
              if: es.multiple_node
              header: 'elasticsearch config file'
              target: "/etc/elasticsearch/#{es_name}/#{service_name}/conf/elasticsearch.yml"
              content: opts.value.config
              backup: true
            @system.mkdir
              if: es.multiple_node
              target: "#{es.logs_path}/#{es_name}/#{service_name}"
              uid: options.user.name
              gid: options.user.name
            @tools.iptables
              header: 'IPTables'
              rules: [
                { chain: 'INPUT', jump: 'ACCEPT', dport: opts.value.http_port, protocol: 'tcp', state: 'NEW', comment: "#{service_name} HTTP Port" }
                { chain: 'INPUT', jump: 'ACCEPT', dport: opts.value.tcp_port, protocol: 'tcp', state: 'NEW', comment: "#{service_name} TCP Port" }
              ]
              if: options.iptables
            @next cb

          @system.mkdir directory:"#{path}/#{es_name}" ,uid: options.user.name, gid: options.user.name for path in es.data_path
          @system.mkdir directory:"#{es.plugins_path}",uid: options.user.name, gid: options.user.name
          @system.mkdir directory:"#{es.plugins_path}/#{es.es_version}",uid: options.user.name, gid: options.user.name
          @system.mkdir
            unless: options.multiple_node
            target: "#{es.logs_path}/#{es_name}"
            uid: options.user.name
            gid: options.user.name
          @system.mkdir
            unless: options.multiple_node
            target: "#{es.logs_path}/#{es_name}/logstash"
            uid: options.user.name
            gid: options.user.name
          @system.mkdir
            target: "/etc/elasticsearch/#{es_name}/scripts"
            uid: options.user.name
            gid: options.user.name
          @system.mkdir
            target: "/etc/elasticsearch/keytabs"
            uid: options.user.name
            gid: options.user.name

          @each es.plugins_urls, (opts, callback) ->
            extract_target  = if opts.value.indexOf("github") != -1  then "#{es.plugins_path}/#{es.es_version}/" else "#{es.plugins_path}/#{es.es_version}/#{opts.key}"
            @call header: "Plugin #{opts.key} installation...", ->
              @each opts.value, (plugins_options, callback) ->
                es.volumes.push "#{es.plugins_path}/#{es.es_version}/#{opts.key}/elasticsearch:/usr/share/elasticsearch/plugins/#{opts.key}"
                @file.download
                  source: plugins_options.key
                  target: "#{es.plugins_path}/#{es.es_version}/#{node_path.basename plugins_options.key}"
                  uid: options.user.name
                  gid: options.user.name
                  shy: true
                @tools.extract
                  format: "zip"
                  source: "#{es.plugins_path}/#{es.es_version}/#{node_path.basename plugins_options.key}"
                  target: extract_target
                  shy: true
                @system.remove
                  target: "#{es.plugins_path}/#{es.es_version}/#{node_path.basename plugins_options.key}"
                  shy: true
                @next callback
            @next callback


## Generate compose file
Run some configuration on environment and network
TODO lucasbak 24012018: move configuration part to configure
let docker-compose generation only


### Elasticsearch services definition generation
generate services based on configuration

          if options.fqdn is options.hosts[options.hosts.length-1]
            #TODO create overlay network if the network does not exist
            docker_networks["#{es.network.name}"] = external: es.network.external unless es.net is 'host'
            master_node = if es.master_nodes > 0
              "#{es.normalized_name}_master"
            else if es.master_data_nodes > 0
              "#{es.normalized_name}_master_data"
            # es.volumes.push "#{es.plugins_path}/#{es.es_version}/#{plugin}:/usr/share/elasticsearch/plugins/#{plugin}" for plugin in es.plugins
            for type,es_node of es.nodes
              command = switch type
                when "master" then "elasticsearch -Enode.master=true -Enode.data=false"
                when "master_data" then "elasticsearch -Enode.master=true -Enode.data=true"
                when "data" then "elasticsearch -Enode.master=false -Enode.data=true"
              es.environment.push "constraint:node==#{es_node.filter}" if es_node.filter != "" and es.environment.indexOf("constraint:node==#{es_node.filter}") is -1
              docker_services[type] = {'environment' : [].concat.apply([],[es.environment,"ES_JAVA_OPTS=-Xms#{es_node.heap_size} -Xmx#{es_node.heap_size} -Djava.security.policy=/usr/share/elasticsearch/config/java.policy","bootstrap.memory_lock=true"]) }
              es_node.volumes ?= es.volumes
              service_def_multiple =
                image : es.docker_es_image
                restart: "always"
                command: command
                network_mode: es.net
                user: "elasticsearch"
                volumes: es_node.volumes
                mem_limit: if es_node.mem_limit? then es_node.mem_limit else es.default_mem
                ulimits:  es.ulimits
                cap_add:  es.cap_add
              service_def_bridge =
                  image : es.docker_es_image
                  restart: "always"
                  command: command
                  networks: [es.network.name]
                  user: "elasticsearch"
                  volumes: es_node.volumes
                  ports: es_node.ports
                  mem_limit: if es_node.mem_limit? then es_node.mem_limit else es.default_mem
                  ulimits:  es.ulimits
                  cap_add:  es.cap_add
              service_def = if es.multiple_node then service_def_multiple else service_def_bridge
              if es_node.cpuset?
                service_def["cpuset"] = es_node.cpuset
              else
                service_def["cpu_quota"] = if es_node.cpu_quota? then es_node.cpu_quota * 1000 else es.default_cpu_quota
              misc.merge docker_services[type], service_def

### Kibana services definition generation
generate services based on configuration

            if es.kibana?
              if es.multiple_node
                docker_services["#{es_name}_kibana"] =
                  image: es.docker_kibana_image
                  container_name: "#{es_name}_kibana"
                  environment: ["ELASTICSEARCH_URL=http://#{master_node}_1:9200"]
                  network_mode: [es.net]
              else
                docker_services["#{es_name}_kibana"] =
                  image: es.docker_kibana_image
                  container_name: "#{es_name}_kibana"
                  environment: ["ELASTICSEARCH_URL=http://#{master_node}_1:9200"]
                  ports: ["#{es.kibana.port}:5601"]
                  networks: [es.network.name]

### Write Docker-compose file

            @file.yaml
              header: 'docker-compose'
              target: "/etc/elasticsearch/#{es_name}/docker-compose.yml"
              content:
                version: '2'
                services: docker_services
                networks: if Object.keys(docker_networks).length > 0 then docker_networks else null
              backup: true

## Run docker compose file

            docker_args =
                host: if options.swarm_manager then options.swarm_manager else ''
                tlsverify:" "
                tlscacert: options.ssl.dest_cacert
                tlscert: options.ssl.dest_cert
                tlskey:options.ssl.dest_key
            export_vars = 
              "export DOCKER_HOST=#{options.swarm_manager};export DOCKER_CERT_PATH=#{options.ssl.dest_dir};export DOCKER_TLS_VERIFY=1"

            # for service, node of es.nodes then do (service, node) =>
            #   @system.execute
            #     cmd:"""
            #     #{export_vars}
            #     pushd /etc/elasticsearch/#{es_name}
            #     docker-compose --verbose scale #{service}=#{node.number}
            #     """

            @system.execute
              cmd:"""
              #{export_vars}
              pushd /etc/elasticsearch/#{es_name}
              docker-compose --verbose up -d #{es_name}_kibana
              """
              if: -> es.kibana is true

## Dependencies

    misc = require 'nikita/lib/misc'
    node_path = require 'path'

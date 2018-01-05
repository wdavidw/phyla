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

      for es_name,es of options.clusters then do (es_name,es) =>
        docker_services = {}
        docker_networks = {}
        @call header: "#{es_name}: ", ->
          @file.yaml
            header: 'elasticsearch config file'
            target: "/etc/elasticsearch/#{es_name}/conf/elasticsearch.yml"
            content:es.config
            backup: true


          @file.render
            header: 'elasticsearch java policy'
            target: "/etc/elasticsearch/#{es_name}/conf/java.policy"
            source: "#{__dirname}/resources/java.policy.j2"
            local: true
            context: {es: logs_path: "#{es.logs_path}/#{es_name}"}
            backup: true

          @file
            header: 'elasticsearch logging'
            target: "/etc/elasticsearch/#{es_name}/conf/log4j2.properties"
            source: "#{__dirname}/resources/log4j2.properties"
            local: true
            backup: true

          @system.mkdir directory:"#{path}/#{es_name}" ,uid: options.user.name, gid: options.user.name for path in es.data_path
          @system.mkdir directory:"#{es.plugins_path}",uid: options.user.name, gid: options.user.name
          @system.mkdir directory:"#{es.plugins_path}/#{es.es_version}",uid: options.user.name, gid: options.user.name
          @system.mkdir directory:"#{es.logs_path}/#{es_name}", uid: options.user.name, gid: options.user.name
          @system.mkdir directory:"#{es.logs_path}/#{es_name}/logstash",uid: options.user.name, gid: options.user.name
          @system.mkdir directory:"/etc/elasticsearch/#{es_name}/scripts",uid: options.user.name, gid: options.user.name
          @system.mkdir directory:"/etc/elasticsearch/keytabs",uid: options.user.name, gid: options.user.name

          @each es.downloaded_urls, (opts,callback) ->
            extract_target  = if opts.value.indexOf("github") != -1  then "#{es.plugins_path}/#{es.es_version}/" else "#{es.plugins_path}/#{es.es_version}/#{opts.key}"
            @call header: "Plugin #{opts.key} installation...", ->
              @file.download
                cache_file: "./#{opts.key}.zip"
                source: opts.value
                target: "#{es.plugins_path}/#{es.es_version}/#{opts.key}.zip"
                uid: options.user.name
                gid: options.user.name
                shy: true
              @tools.extract
                format: "zip"
                source: "#{es.plugins_path}/#{es.es_version}/#{opts.key}.zip"
                target: extract_target
                shy: true
              es.volumes.push "#{es.plugins_path}/#{es.es_version}/#{options.key}/elasticsearch:/usr/share/elasticsearch/plugins/#{options.key}"
              @system.remove "#{es.plugins_path}/#{es.es_version}/#{options.key}.zip", shy: true
            @next callback


## Generate compose file

          if options.fqdn is options.hosts[options.hosts.length-1]
            #TODO create overlay network if the network does not exist
            docker_networks["#{es.network.name}"] = external: es.network.external
            master_node = if es.master_nodes > 0
              "#{es.normalized_name}_master"
            else if es.master_data_nodes > 0
              "#{es.normalized_name}_master_data"
            es.volumes = [
              "/etc/elasticsearch/#{es_name}/conf/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml",
              "/etc/elasticsearch/#{es_name}/conf/log4j2.properties:/usr/share/elasticsearch/config/log4j2.properties",
              "/etc/elasticsearch/#{es_name}/scripts:/usr/share/elasticsearch/config/scripts",
              "#{es.logs_path}/#{es_name}:#{es.config['path.logs']}",
              "/etc/elasticsearch/#{es_name}/conf/java.policy:/usr/share/elasticsearch/config/java.policy"

            ].concat es.volumes
            es.volumes.push "#{path}/#{es_name}/:#{path}" for path in es.data_path
            # es.volumes.push "#{es.plugins_path}/#{es.es_version}/#{plugin}:/usr/share/elasticsearch/plugins/#{plugin}" for plugin in es.plugins
            for type,es_node of es.nodes
              command = switch type
                when "master" then "elasticsearch -Enode.master=true -Enode.data=false"
                when "master_data" then "elasticsearch -Enode.master=true -Enode.data=true"
                when "data" then "elasticsearch -Enode.master=false -Enode.data=true"
              es.environment.push "constraint:node==#{es_node.filter}" if es_node.filter != ""
              docker_services[type] = {'environment' : [].concat.apply([],[es.environment,"ES_JAVA_OPTS=-Xms#{es_node.heap_size} -Xmx#{es_node.heap_size} -Djava.security.policy=/usr/share/elasticsearch/config/java.policy","bootstrap.memory_lock=true"]) }

              service_def =
                image : es.docker_es_image
                restart: "always"
                command: command
                networks: [es.network.name]
                user: "elasticsearch"
                volumes: es.volumes
                ports: es.ports
                mem_limit: if es_node.mem_limit? then es_node.mem_limit else es.default_mem
                ulimits:  es.ulimits
                cap_add:  es.cap_add

              if es_node.cpuset?
                service_def["cpuset"] = es_node.cpuset
              else
                service_def["cpu_quota"] = if es_node.cpu_quota? then es_node.cpu_quota * 1000 else es.default_cpu_quota
              misc.merge docker_services[type], service_def
            if es.kibana?
              docker_services["#{es_name}_kibana"] =
                image: es.docker_kibana_image
                container_name: "#{es_name}_kibana"
                environment: ["ELASTICSEARCH_URL=http://#{master_node}_1:9200"]
                ports: ["#{es.kibana.port}:5601"]
                networks: [es.network.name]

            @file.yaml
              header: 'docker-compose'
              target: "/etc/elasticsearch/#{es_name}/docker-compose.yml"
              content: {version:'2',services:docker_services,networks:docker_networks}
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

            for service, node of es.nodes then do (service, node) =>
              @system.execute
                cmd:"""
                #{export_vars}
                pushd /etc/elasticsearch/#{es_name}
                docker-compose --verbose scale #{service}=#{node.number}
                """

            @system.execute
              cmd:"""
              #{export_vars}
              pushd /etc/elasticsearch/#{es_name}
              docker-compose --verbose up -d #{es_name}_kibana
              """
              if: -> es.kibana is true

## Dependencies

    misc = require 'nikita/lib/misc'

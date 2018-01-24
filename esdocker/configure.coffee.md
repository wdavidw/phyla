
# Elasticsearch (Docker) Configuration

## Example

```
    es_docker:
      swarm_manager: "tcp://noeyy6vf.noe.edf.fr:3376"
      graphite:
        host: "noeyy6z1.noe.edf.fr"
        port: 2003
        every: "10s"
      clusters:
        "es_re7":
          es_version: "2.3.3"
          number_of_shards: 1
          number_of_replicas: 1
          number_of_containers: 1
          data_path: ["/data/1","/data/2","/data/3","/data/4","/data/5","/data/6"]
          logs_path: "/var/hadoop_log/docker/es"
          plugins_path: "/etc/elasticsearch/plugins"
          ports: ["9200:9200","9200:9300"]
          nodes:
            master_data:
              number: 2
              cpuset: "1-8",
              mem_limit: '56g'
              heap_size: '20g'
            data:
              number: 3
              cpuset: "1-8",
              mem_limit: '56g'
              heap_size: '20g'
            master:
              number: 2
              cpuset: "1-8",
              mem_limit: '56g'
              heap_size: '20g'
          network:
            name: "dsp_re7"

```

## Source Code

    module.exports = (service) ->
      options = service.options

## Identities

      # User
      options.user = name: options.user if typeof options.user is 'string'
      options.user ?= {}
      options.user.name ?= 'elasticsearch'
      options.user.system ?= true
      options.user.comment ?= 'elasticsearch User'
      options.user.home ?= '/var/lib/elasticsearch'
      # Group
      options.group = name: options.group if typeof options.group is 'string'
      options.group ?= {}
      options.group.name ?= 'elasticsearch'
      options.group.system ?= true
      options.user.limits ?= {}
      options.user.limits.nofile ?= 65536
      options.user.limits.nproc ?= 10000
      options.user.gid = options.group.name

## IPTables

      options.iptables ?= !!service.iptables and service.iptables?.action in ['start','START']

## Docker configuration
configure docker object to communicate with `ryba/swarm/manager` (if configured),

      if service.deps.swarm_manager?.length > 0
        options.swarm_manager ?= "tcp://#{service.deps.swarm_manager[0].node.fqdn}:#{service.deps.swarm_manager[0].options.listen_port}"
      else
        options.swarm_manager ?= "tcp://#{service.deps.docker.node.fqdn}:#{service.deps.docker.port}"
      
## Elastic config

      options.clusters ?= {}
      options.ssl = merge {}, service.deps.ssl.options, options.ssl
      throw Error 'Required property "ssl.cacert" or "ryba.options.ssl.cacert"' unless options.ssl.cacert?
      throw Error 'Required property "ssl.cert"' unless options.ssl.cert?
      throw Error 'Required property "ssl.key"' unless options.ssl.key?
      options.ssl.dest_dir ?= "/etc/docker/certs.d"
      options.ssl.dest_cacert = "#{options.ssl.dest_dir}/ca.pem"
      options.ssl.dest_cert = "#{options.ssl.dest_dir}/cert.pem"
      options.ssl.dest_key = "#{options.ssl.dest_dir}/key.pem"
      options.fqdn ?= service.node.fqdn
      options.hosts ?= service.deps.esdocker.map (srv) -> srv.node.fqdn

## Kernel

      options.prepare = service.deps.esdocker[0].node.fqdn is service.node.fqdn
      options.sysctl ?= {}
      options.sysctl["vm.max_map_count"] = 262144

## Installed Cluster
Filter cluster which will be set up based on config

Note lucasbak 24012018:
- migth remove `only` option.
  But need to find strong way to check if cluster already runing.
- Setup discovery mode base on cluster configuration
goes through each type of service and glob pattern on filter and type to build
the `discovery.zen.ping.unicast.hosts` configuration.


      for es_name,es of options.clusters
        delete options.clusters[es_name] unless es.only

      for es_name,es of options.clusters
        #ES Config file
        es.config = {}
        es.config["network.host"] = "0.0.0.0"
        es.config["cluster.name"] = "#{es_name}"
        es.config["path.data"] = "#{es.data_path}"
        es.config["path.logs"] = "/var/log/elasticsearch"
        es.config["script.engine.painless.inline"] = true
        es.config["xpack.security.enabled"] = false
        es.config["cluster.routing.allocation.node_concurrent_recoveries"] = 8
        es.config["indices.recovery.max_bytes_per_sec"] = "250mb"
        es.normalized_name = "#{es_name.replace(/_/g,"")}"
        #Docker:
        es.es_version ?= "5.3.1"
        es.docker_es_image = "dc-registry-bigdata.noe.edf.fr/elasticsearch:#{es.es_version}"
        es.docker_kibana_image ?= "dc-registry-bigdata.noe.edf.fr/kibana:4.5"
        es.docker_logstash_image ?= "logstash"
        #Cluster
        es.number_of_containers ?= options.hosts.length
        es.number_of_shards ?= es.number_of_containers
        es.number_of_replicas ?= 1
        es.data_path ?= ["/data/1","/data/2","/data/3","/data/4","/data/5","/data/6","/data/7","/data/8"]
        es.logs_path ?= "/var/hadoop_log/docker/es"
        es.plugins_path ?= "/etc/elasticsearch/plugins"
        # es.scripts_path ?= "/etc/elasticsearch/plugins"
        # es.plugins ?= ["royrusso/elasticsearch-HQ","mobz/elasticsearch-head","karmi/elasticsearch-paramedic/2.0"]
        es.plugins ?= []
        es.volumes ?= []
        es.downloaded_urls = {}
        es.default_mem = '2g'
        # cpu quota 100%
        es.default_cpu_quota = 100000

        nofile = {}
        nofile.soft = 65536
        nofile.hard = 65536

        memlock = {}
        memlock.soft = 9999999999
        memlock.hard = 9999999999

        es.ulimits ?= {}
        es.ulimits.nofile = nofile
        es.ulimits.memlock = memlock

        es.cap_add ?= ["IPC_LOCK"]

        es.environment = ["affinity:container!=*#{es.normalized_name}_*"]
        # check configuration
        if not es.multiple_node
          throw Error 'Required property "ports"' unless es.ports?
          if es.ports instanceof Array
            port_mapping = port.split(":").length > 1 for port in es.ports
            throw Error 'property "ports" must be an array of ports mapping ["9200:port1","9300:port2"]' unless port_mapping is true
          else
            throw Error 'property "ports" must be an array of ports mapping ["9200:port1","9300:port2"]'
          throw Error 'Required property "nodes"' unless es.nodes?
          throw Error 'Required property "network" and network.external' unless es.network?
        if es.kibana?
          throw Error 'Required property "kibana.port"' unless es.kibana.port?
        #TODO create overlay network if the network does not exist
        #For now We assume that the network is already created by docker network create
        es.network ?= {}
        es.network.external = true
        if es.logstash?
          throw Error 'Required property "logstash.port"' unless es.logstash.port?
          throw Error 'Required property "logstash.index"' unless es.logstash.index?
          throw Error 'Required property "logstash.doc_type"' unless es.logstash.doc_type?
          es.logstash.tag ?= 'TAG1'
          es.logstash.event_type ?= 'app_logs'
        es.total_nodes = 0
        es.master_nodes = 0
        es.data_nodes = 0
        es.master_data_nodes = 0

## Network mode

        if options.multiple_node
          throw Error "cluster #{es.normalized_name} not in host mode (multiple_node)" unless es.net is 'host'

## Discovery configuration
`discovery.zen.ping.unicast.hosts` configuration should be an array containing
all master's node_name in network host mode or container's name in network mapped mode.

        es.master_hosts ?= []
        if es.multiple_node
          #do dicsover based on filter
          for type, node of es.nodes
            switch type
              when 'master' then es.master_nodes++
              when 'master_data' then es.master_data_nodes++
              else  es.data_nodes++
            if type is 'master' or 'master_data'
              for host in options.hosts
                throw Error "filter must be specified to configure `discovery.zen.ping.unicast.hosts` in host mode (multiple_node)" unless node['filter']?
                if minimatch(host, node['filter'])
                  es.master_hosts.push host if es.master_hosts.indexOf(host) is -1 
          es.config["discovery.zen.ping.unicast.hosts"] ?= es.master_hosts if es.master_hosts.length > 0
        else
          for type, node of es.nodes
            node.filter ?= ""
            throw Error 'Please specify number property for each node type under nodes property' unless node.number?
            node.mem_limit ?= es.default_mem
            heap_size =  if node.mem_limit is '1g' then '512mb' else Math.floor(parseInt(node.mem_limit.replace(/(g|mb)/i,'')) / 2 )
            node.heap_size ?= if node.mem_limit.indexOf('g') > -1 then heap_size+'g' else heap_size+'mb'
            node.cpu_quota ?= es.default_cpu_quota
            switch type
              when "master"
                es.master_nodes = node.number
                for number in [1..es.master_nodes] then es.master_hosts.push "#{es.normalized_name}_#{type}_#{number}"
              when "data" then es.data_nodes =  node.number
              when "master_data"
                es.master_data_nodes = node.number
                for number in [1..es.master_data_nodes] then es.master_hosts.push "#{es.normalized_name}_#{type}_#{number}"
              else
                es.data_nodes =  node.number
        es.total_nodes = es.master_nodes + es.data_nodes + es.master_data_nodes
        es.config["discovery.zen.minimum_master_nodes"] = Math.floor((es.master_data_nodes+es.master_nodes) / 2) + 1
        es.config["discovery.zen.master_election.ignore_non_master_pings"] = true
        es.config["gateway.expected_nodes"] = es.total_nodes
        es.config["gateway.recover_after_nodes"] = es.total_nodes - 1 
        es.config["discovery.zen.ping.unicast.hosts"] ?= es.master_hosts.join()

## Node Custom Confguration

## Volumes
Configure mount points for services

### Data paths
Configure data diks and mount points where es will write.

        for type, node of es.nodes
          ## mount points where elasticsearch can write (data paths)
          node.config ?= es.config
          node.config.logs_path ?= es.logs_path
          node.data_path ?= es.data_path
          node.config['path.data'] = node.data_path
          node.ports ?= es.ports
          node.volumes ?= node.data_path.map( (data) -> 
            if options.multiple_node
              "#{data}/#{es_name}/#{type}/:#{data}" 
            else
              "#{data}/#{es_name}/#{type}/:#{data}" 
          )

### Config paths
Configure configuration file es will read to run.

          for file in ['elasticsearch.yml']
            mount_path = if es.multiple_node
            then "/etc/elasticsearch/#{es_name}/#{type}/conf/#{file}:/usr/share/elasticsearch/config/#{file}"
            else "/etc/elasticsearch/#{es_name}/conf/#{file}:/usr/share/elasticsearch/config/#{file}"
            node.volumes.push mount_path unless node.volumes.indexOf(mount_path) isnt -1
        
          for file in ['scripts', 'java.policy', 'log4j2.properties']
            mount_path = "/etc/elasticsearch/#{es_name}/common/#{file}:/usr/share/elasticsearch/config/#{file}"
            node.volumes.push mount_path unless node.volumes.indexOf(mount_path) isnt -1

            
### Logging path         

          mount_path = if es.multiple_node
          then "#{es.logs_path}/#{es_name}/#{type}:#{es.config['path.logs']}"
          else "#{es.logs_path}/#{es_name}:#{es.config['path.logs']}"
          node.volumes.push mount_path unless node.volumes.indexOf(mount_path) isnt -1

## Ports
        
        node.config['http.port'] ?= node.http_port
        node.config['transport.tcp.port'] ?= node.tcp_port

## Plugins

        es.plugins_urls = {}
        official_plugins = [
          "analysis-icu",
          "analysis-kuromoji",
          "delete-by-query",
          "analysis-phonetic",
          "analysis-smartcn",
          "analysis-stempel",
          "cloud-aws",
          "cloud-azure",
          "cloud-gce",
          "discovery-multicast",
          "lang-javascript",
          "lang-python",
          "mapper-attachments",
          "mapper-murmur3",
          "repository-s3",
          "mapper-size"
        ]
        for name in es.plugins
          elements = name.split("/")
          [user,repo,version] = if elements.length == 1
            # plugin form: pluginName
            [null,elements[0],null]
          else if elements.length == 2
            #plugin form: userName/pluginName
            [elements[0],elements[1],null]
          else if elements.length == 3
            #plugin form: userName/pluginName/version
            [elements[0],elements[1],elements[2]]
          es.plugins_urls["#{repo}"] = []
          if version is null && user is null && repo != null
            throw Error " #{repo} is not an official plugin so you should install it using elasticsearch/#{repo}/latest naming form." unless repo in official_plugins
            version = es.es_version
          if version != null
            if user is null
              # es.plugins_urls["#{repo}"].push "https://download.elastic.co/elasticsearch/release/org/elasticsearch/plugin/#{repo}/#{version}/#{repo}-#{version}.zip"
              es.plugins_urls["#{repo}"].push "https://artifacts.elastic.co/downloads/elasticsearch-plugins/#{repo}/#{repo}-#{version}.zip"
            else
              es.plugins_urls["#{repo}"].push "https://download.elastic.co/#{user}/#{repo}/#{repo}-#{version}.zip"
              es.plugins_urls["#{repo}"].push "https://search.maven.org/remotecontent?filepath=#{user.replace('.','/')}/#{repo}/#{version}/#{repo}-#{version}.zip"
              es.plugins_urls["#{repo}"].push "https://oss.sonatype.org/service/local/repositories/releases/content/#{user.replace('.','/')}/#{repo}/#{version}/#{repo}-#{version}.zip"
              es.plugins_urls["#{repo}"].push "https://github.com/#{user}/#{repo}/archive/#{version}.zip"
          if user != null
            es.plugins_urls["#{repo}"].push "https://github.com/#{user}/#{repo}/archive/master.zip"

## Dependencies

    {merge} = require 'nikita/lib/misc'
    minimatch = require("minimatch")
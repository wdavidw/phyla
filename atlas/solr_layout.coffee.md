
# SolrCloud Layout

    module.exports = headler: 'SolrCloud Atlas Layout', handler: (options) ->
      atlas =  @contexts('ryba/atlas')[0].config.ryba.atlas
      @file.download
        source: "#{__dirname}/resources/solr/lang/stopwords_en.txt"
        target: "#{options.atlas_collection_dir}/lang/stopwords_en.txt"
      @file.download
        source: "#{__dirname}/resources/solr/currency.xml"
        target: "#{options.atlas_collection_dir}/currency.xml"
      @file.download
        source: "#{__dirname}/resources/solr/protwords.txt"
        target: "#{options.atlas_collection_dir}/protwords.txt"
      @file.download
        source: "#{__dirname}/resources/solr/schema.xml"
        target: "#{options.atlas_collection_dir}/schema.xml"
      @file.download
        source: "#{__dirname}/resources/solr/solrconfig.xml"
        target: "#{options.atlas_collection_dir}/solrconfig.xml"
      @file.download
        source: "#{__dirname}/resources/solr/stopwords.txt"
        target: "#{options.atlas_collection_dir}/stopwords.txt"
      @file.download
        source: "#{__dirname}/resources/solr/synonyms.txt"
        target: "#{options.atlas_collection_dir}/synonyms.txt"

## Create Atlas Collection in Solr

      @call
        if: [
          @config.host is options.master
          atlas.solr_type is 'cloud_docker'
        ]
        header:'Atlas Collection (cloud_docker)'
      , (options) ->
          container = null
          @wait.execute
            if: @contexts('ryba/swarm/manager').length isnt 0
            cmd: docker.wrap options, "ps | grep #{atlas.solr_cluster_name.split('_').join('')} | grep #{options['master']} | awk '{print $1}'"
          @system.execute
            if: @contexts('ryba/swarm/manager').length isnt 0
            cmd: docker.wrap options, "ps | grep #{atlas.solr_cluster_name.split('_').join('')} | grep #{options['master']} | awk '{print $1}'"
          , (err, status, stdout) ->
            throw err if err
            container = stdout?.trim()
          @call ->
            @docker.exec
              container: "#{container or options.master_container_runtime_name}"
              cmd: "/usr/solr-cloud/current/bin/solr healthcheck -c vertex_index"
              code_skipped: [1,126]
            @docker.exec
              unless: -> @status -1
              header: 'Create vertex_index collection'
              container: "#{container or options.master_container_runtime_name}"
              cmd: """
              /usr/solr-cloud/current/bin/solr create_collection -c vertex_index \
              -shards #{options.hosts.length}  \
              -replicationFactor #{options.hosts.length-1} \
              -d /atlas_solr
              """
            @docker.exec
              container: "#{container or options.master_container_runtime_name}"
              cmd: "/usr/solr-cloud/current/bin/solr healthcheck -c edge_index"
              code_skipped: [1,126]
            @docker.exec
              unless: -> @status -1
              header: 'Create edge_index collection'
              container: "#{container or options.master_container_runtime_name}"
              cmd: """
              /usr/solr-cloud/current/bin/solr create_collection -c edge_index \
              -shards #{options.hosts.length}  \
              -replicationFactor #{options.hosts.length-1} \
              -d /atlas_solr
              """
            @docker.exec
              container: "#{container or options.master_container_runtime_name}"
              cmd: "/usr/solr-cloud/current/bin/solr healthcheck -c fulltext_index"
              code_skipped: [1,126]
            @docker.exec
              unless: -> @status -1
              header: 'Create fulltext_index collection'
              container: "#{container or options.master_container_runtime_name}"
              cmd: """
              /usr/solr-cloud/current/bin/solr create_collection -c fulltext_index \
              -shards #{options.hosts.length}  \
              -replicationFactor #{options.hosts.length-1} \
              -d /atlas_solr
              """
      @call
        if: [
          @config.host is options.master
          atlas.solr_type is 'cloud' and options.hosts[0] is @config.host
        ]
        header:'Atlas Collection (cloud)'
      , ->
        @connection.wait
          servers: for host in options.hosts
            host: host
            port: @contexts('ryba/solr/cloud')[0].config.ryba.solr.cloud.port
        @system.execute
          unless_exec: "/usr/solr-cloud/current/bin/solr healthcheck -c vertex_index"
          cmd: """
          /usr/solr-cloud/current/bin/solr create_collection -c vertex_index \
          -shards #{options.hosts.length}  \
          -replicationFactor #{options.hosts.length} \
          -d #{options.atlas_collection_dir}
          """
        @system.execute
          unless_exec: "/usr/solr-cloud/current/bin/solr healthcheck -c edge_index"
          cmd: """
          /usr/solr-cloud/current/bin/solr create_collection -c edge_index \
          -shards #{options.hosts.length}  \
          -replicationFactor #{options.hosts.length} \
          -d #{options.atlas_collection_dir}
          """
        @system.execute
          unless_exec: "/usr/solr-cloud/current/bin/solr healthcheck -c fulltext_index"
          cmd: """
          /usr/solr-cloud/current/bin/solr create_collection -c fulltext_index \
          -shards #{options.hosts.length}  \
          -replicationFactor #{options.hosts.length} \
          -d #{options.atlas_collection_dir}
          """

## Dependecies

    docker = require '@nikitajs/core/lib/misc/docker'


# Atlas Solr Collection Bootstrap

    module.exports = headler: 'SolrCloud Atlas Layout', handler: (options) ->
      protocol = if options.solr.ssl?.enabled or options.solr.cluster_config.is_ssl_enabled then 'https' else 'http'

## Wait
      
      @connection.wait options.wait_solr

## Collection Layout

      @file.download
        source: "#{__dirname}/resources/solr/lang/stopwords_en.txt"
        target: "#{options.solr.cluster_config.atlas_collection_dir}/lang/stopwords_en.txt"
      @file.download
        source: "#{__dirname}/resources/solr/currency.xml"
        target: "#{options.solr.cluster_config.atlas_collection_dir}/currency.xml"
      @file.download
        source: "#{__dirname}/resources/solr/protwords.txt"
        target: "#{options.solr.cluster_config.atlas_collection_dir}/protwords.txt"
      @file.download
        source: "#{__dirname}/resources/solr/schema.xml"
        target: "#{options.solr.cluster_config.atlas_collection_dir}/schema.xml"
      @file.download
        source: "#{__dirname}/resources/solr/solrconfig.xml"
        target: "#{options.solr.cluster_config.atlas_collection_dir}/solrconfig.xml"
      @file.download
        source: "#{__dirname}/resources/solr/stopwords.txt"
        target: "#{options.solr.cluster_config.atlas_collection_dir}/stopwords.txt"
      @file.download
        source: "#{__dirname}/resources/solr/synonyms.txt"
        target: "#{options.solr.cluster_config.atlas_collection_dir}/synonyms.txt"

## Create Atlas Collection in Solr

      @each options.solr.collections, (opts, callback) ->
        {key, value} = opts
        @call
          header: "Create #{key} collection"
          unless_exec: mkcmd.solr options.solr.cluster_config, """
            curl --fail --negotiate -k -u : \
            "#{protocol}://#{options.solr.cluster_config['master']}:#{options.solr.cluster_config['port']}/solr/admin/collections?action=LIST" | grep #{key}
          """
        , ->
          @system.execute
            cmd: mkcmd.solr options.solr.cluster_config, """
            #{options.solr_client_source}/server/scripts/cloud-scripts/zkcli.sh  \
            -zkhost #{options.solr.cluster_config.zk_urls} \
            -cmd upconfig \
            -confdir #{options.solr.cluster_config.atlas_collection_dir} \
            -confname #{key}
          """
          @system.execute
            cmd: mkcmd.solr options.solr.cluster_config, """
              curl --fail --negotiate -k -u : "#{protocol}://#{options.solr.cluster_config['master']}:#{options.solr.cluster_config['port']}/solr/#{getPath(value)}"
            """
        @next callback

    getPath = (opts) ->
      path = "admin/collections?action=CREATE"
      path += "&#{param}=#{opts[param]}" for param in [
        'name'
        'numShards'
        'replicationFactor'
        'collection.configName'
        'maxShardsPerNode'
        # 'createNodeSet'
      ]
      return path
    
## Dependencies

    mkcmd = require '../lib/mkcmd'

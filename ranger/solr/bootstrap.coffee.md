
# Atlas Solr Collection Bootstrap

    module.exports = headler: 'SolrCloud Ranger Layout', handler: (options) ->
      # migration: lucasbak 02112017
      # use this bootstrap scripts for every type
      return unless options.solr_type is 'external'
      protocol = if options.solr.cluster_config.ssl_enabled then 'https' else 'http'

## Wait

      @connection.wait options.wait_solr

## Collection Layout

      @file.download
        source: "#{__dirname}/../resources/solr/managed-schema"
        target: "#{options.solr.cluster_config.ranger_collection_dir}/managed-schema"
      @file.render
        source: "#{__dirname}/../resources/solr/solrconfig.xml.j2"
        target: "#{options.solr.cluster_config.ranger_collection_dir}/solrconfig.xml"
        local: true
        context: retention_period: options.audit_retention_period
      @file.download
        source: "#{__dirname}/../resources/solr/elevate.xml"
        target: "#{options.solr.cluster_config.ranger_collection_dir}/elevate.xml"
      @file.download
        source: "#{__dirname}/../resources/solr/elevate.xml"
        target: "#{options.solr.cluster_config.ranger_collection_dir}/elevate.xml"

## Create Atlas Collection in Solr

      @call
        header: "Create ranger_audits collection"
        unless_exec: mkcmd.solr options.solr.cluster_config, """
          curl --fail --negotiate -k -u : \
          "#{protocol}://#{options.solr.cluster_config['master']}:#{options.solr.cluster_config['port']}/solr/admin/collections?action=LIST" | grep ranger_audits
        """
      , ->
        @system.execute
          cmd: mkcmd.solr options.solr.cluster_config, """
          #{options.solr_client_source}/server/scripts/cloud-scripts/zkcli.sh  \
          -zkhost #{options.solr.cluster_config.zk_connect} \
          -cmd upconfig \
          -confdir #{options.solr.cluster_config.ranger_collection_dir} \
          -confname ranger_audits
        """
        @system.execute
          cmd: mkcmd.solr options.solr.cluster_config, """
            curl --fail --negotiate -k -u : "#{protocol}://#{options.solr.cluster_config['master']}:#{options.solr.cluster_config['port']}/solr/#{getPath(options.solr.cluster_config.collection)}"
          """

# ## Zookeeper Znode ACL
# 
#       @system.execute
#         unless: mode is 'standalone'
#         header: 'Zookeeper SolrCloud Znode ACL'
#         unless_exec: mkcmd.solr @, """
#         zookeeper-client -server #{zk_connect} \
#           getAcl /#{zk_node} | grep \"'sasl,'#{solr.user.name}\"
#         """
#         cmd: mkcmd.solr @, """
#         zookeeper-client -server #{zk_connect} \
#           setAcl /#{zk_node} sasl:#{solr.user.name}:cdrwa
#         """

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

    mkcmd = require '../../lib/mkcmd'

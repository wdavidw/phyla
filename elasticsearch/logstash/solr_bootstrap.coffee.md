
# Logtash Solr Collection Bootstrap

    module.exports = headler: 'SolrCloud Logstash Layout', handler: (options) ->
      return unless options.solr.solr_type is 'external'
      protocol = if options.solr.cluster_config.ssl_enabled then 'https' else 'http'

## Wait
      
      @connection.wait options.wait_solr

## Collection Layout
  
      @file.download
        source: "#{__dirname}/../resources/logstash_logs.tar.gz"
        target: "#{options.solr.logstash_logs_collection_conf_dir}"
      @tools.extract
        source: "#{options.solr.logstash_logs_collection_conf_dir}/logstash_logs.tar.gz"
        target: "#{options.solr.logstash_logs_collection_conf_dir}"

## Create Logstash Collection in Solr

      @call
        header: "Create logstash_logs collection"
        unless_exec: """
          curl -u #{options.solr.cluster_config.admin}:#{options.solr.cluster_config.password} \
          "#{protocol}://#{options.solr.cluster_config.master}:#{options.solr.cluster_config.port}/solr/admin/collections?action=LIST" | grep logstash_logs
        """
      , ->
        @system.execute
          cmd: mkcmd.solr, """
          #{options.solr_client_source}/server/scripts/cloud-scripts/zkcli.sh  \
          -zkhost #{options.solr.cluster_config.zk_connect} \
          -cmd upconfig \
          -confdir #{options.solr.logstash_logs_collection_conf_dir}/logstash_logs/conf \
          -confname logstash_logs
        """
        @system.execute
          cmd: """
            curl -u #{options.solr.cluster_config.admin}:#{options.solr.cluster_config.password} "#{protocol}://#{options.solr.cluster_config.master}:#{options.solr.cluster_config.port}/solr/admin/collections?action=CREATE&name=logstash_logs&numShards=3&replicationFactor=2&collection.configName=logstash_logs&maxShardsPerNode=2"
          """

# ## Zookeeper Znode ACL

      # @system.execute
      #   unless: mode is 'standalone'
      #   header: 'Zookeeper SolrCloud Znode ACL'
      #   unless_exec: """
      #   zookeeper-client -server #{zk_connect} \
      #     getAcl /#{zk_node} | grep \"'sasl,'#{solr.user.name}\"
      #   """
      #   cmd: """
      #   zookeeper-client -server #{zk_connect} \
      #     setAcl /#{zk_node} sasl:#{solr.user.name}:cdrwa
      #   """

## Dependencies

    mkcmd = require '../../lib/mkcmd'


# Filebeat Configuration

    module.exports  = (service) ->
      options = service.options

## Environment

      options.conf_dir ?= '/etc/filebeat'
      options.version ?= '6.1.1'
      options.logstash_url ?= service.deps.logstash[0].node.fqdn
      options.logstash_port ?= '5043'
      options.paths ?= ''
      options.env ?= service.cluster

## Log Paths

      options.log_paths ?= []
      if service.deps.hdfs_nn? then options.log_paths.push "#{service.deps.hdfs_nn.options.log_dir}/*.log"
      if service.deps.hdfs_dn? then options.log_paths.push "#{service.deps.hdfs_dn.options.log_dir}/*.log"
      if service.deps.yarn_rm? then options.log_paths.push "#{service.deps.yarn_rm.options.log_dir}/*.log"
      if service.deps.yarn_nm? then options.log_paths.push "#{service.deps.yarn_nm.options.log_dir}/*.log"
      if service.deps.hive_server2? then options.log_paths.push "#{service.deps.hive_server2.options.log_dir}/*.log"
      if service.deps.hive_webhcat? then options.log_paths.push "#{service.deps.hive_webhcat.options.log_dir}/*.log"
      if service.deps.oozie_server? then options.log_paths.push "#{service.deps.oozie_server.options.log_dir}/*.log"
      if service.deps.hbase_rest then options.log_paths.push "#{service.deps.hbase_rest.options.log_dir}/*.log"
      if service.deps.hbase_master? then options.log_paths.push "#{service.deps.hbase_master.options.log_dir}/*.log"
      if service.deps.hbase_regionserver? then options.log_paths.push "#{service.deps.hbase_regionserver.options.log_dir}/*.log"
      if service.deps.nifi? then options.log_paths.push "#{service.deps.nifi.options.log_dir}/*.log"
      if service.deps.kafka? then options.log_paths.push "#{service.deps.kafka.options.log_dir}/*.log"
      if service.deps.ranger_admin? then options.log_paths.push "#{service.deps.ranger_admin.options.log_dir}/*.log"
      if service.deps.knox? then options.log_paths.push "#{service.deps.knox.options.log_dir}/*.log"

## Properties

      options.close_inactive ?= '5m'
      options.scan_frequency ?= '30s'

## Source

      options.source ?= "https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-#{options.version}-x86_64.rpm"

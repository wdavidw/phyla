
# HDFS NN Install

    module.exports = header: 'HDFS NN Takeover', handler: (options) ->

## Register
      
      # hdfs -site
      # cmd = ['/usr/bin/python', '/var/lib/ambari-agent/cache/stacks/HDP/2.0.6/hooks/before-ANY/scripts/hook.py', 'ANY', '/var/lib/ambari-agent/data/command-204.json', '/var/lib/ambari-agent/cache/stacks/HDP/2.0.6/hooks/before-ANY', '/var/lib/ambari-agent/data/structured-out-204.json', 'INFO', '/var/lib/ambari-agent/tmp', 'PROTOCOL_TLSv1', '']
      # @system.execute
      #   cmd: cmd.join(' ')

      # newProperties =
      #   Clusters:
      #     desired_configs:
      #       type: 'hdfs-site'
      #       tag: 'version8'
      #       properties: options.hdfs_site_merged
      #       properties_attributes:
      #         "final" :
      #           "dfs.webhdfs.enabled" : "true"
      #           "dfs.namenode.http-address" : "true"
      #           "dfs.support.append" : "true"
      #           "dfs.namenode.name.dir" : "true"
      #           "dfs.datanode.failed.volumes.tolerated" : "true"
      #           "dfs.datanode.data.dir" : "true"
      # 
      # @file
      #   content: JSON.stringify newProperties
      #   target: "/tmp/toto.json"
      # @system.execute
      #   cmd: """
      #     curl -k -u admin:admin123 -X PUT -H "X-Requested-By: ambari" https://master01.metal.ryba:8442/api/v1/clusters/mycluster \
      #     -d @/tmp/toto.json
      #   """
      ## core site
      # newProperties =
      #   Clusters:
      #     desired_configs:
      #       type: 'core-site'
      #       tag: 'version2'
      #       properties: options.core_site
      # @file
      #   content: JSON.stringify newProperties
      #   target: "/tmp/toto.json"
      # @system.execute
      #   cmd: """
      #     curl -k -u admin:admin123 -X PUT -H "X-Requested-By: ambari" https://master01.metal.ryba:8442/api/v1/clusters/mycluster \
      #     -d @/tmp/toto.json
      #   """
      #hadoop env
      
      # fs.readFile options.ssh, '/etc/hadoop-hdfs-namenode/conf/hadoop-env.sh', 'utf8', (err, content) =>
      #   newProperties =
      #     Clusters:
      #       desired_configs:
      #         type: 'hadoop-env'
      #         tag: 'version4'
      #         properties: 
      #           content: content
      #           "dtnode_heapsize" : "1024m"
      #           "hadoop_heapsize" : "1024"
      #           "hadoop_pid_dir_prefix" : "/var/run/hadoop"
      #           "hadoop_root_logger" : "INFO,RFA"
      #           "hdfs_log_dir_prefix" : "/var/log/hadoop"
      #           "hdfs_tmp_dir" : "/tmp"
      #           "hdfs_user" : "hdfs"
      #           "hdfs_user_nofile_limit" : "128000"
      #           "hdfs_user_nproc_limit" : "65536"
      #           "keyserver_host" : " "
      #           "keyserver_port" : ""
      #           "namenode_backup_dir" : "/tmp/upgrades"
      #           "namenode_heapsize" : "1024m"
      #           "namenode_opt_maxnewsize" : "128m"
      #           "namenode_opt_maxpermsize" : "256m"
      #           "namenode_opt_newsize" : "128m"
      #           "namenode_opt_permsize" : "128m"
      #           "nfsgateway_heapsize" : "1024"
      #           "proxyuser_group" : "users"
      #   # console.log content
      #   @file
      #     content: JSON.stringify newProperties
      #     target: "/tmp/toto.json"
      #   @system.execute
      #     cmd: """
      #       curl -k -u admin:admin123 -X PUT -H "X-Requested-By: ambari" https://master01.metal.ryba:8442/api/v1/clusters/mycluster \
      #       -d @/tmp/toto.json
      #     """
      
      # newProperties =
      #   Clusters:
      #     desired_configs:
      #       type: 'ssl-client'
      #       tag: 'version2'
      #       properties: options.ssl_client
      #       # properties_attributes:
      #       #   "final" :
      #       #     "dfs.webhdfs.enabled" : "true"
      #       #     "dfs.namenode.http-address" : "true"
      #       #     "dfs.support.append" : "true"
      #       #     "dfs.namenode.name.dir" : "true"
      #       #     "dfs.datanode.failed.volumes.tolerated" : "true"
      #       #     "dfs.datanode.data.dir" : "true"
      # 
      # @file
      #   content: JSON.stringify newProperties
      #   target: "/tmp/toto.json"
      # @system.execute
      #   cmd: """
      #     curl -k -u admin:admin123 -X PUT -H "X-Requested-By: ambari" https://master01.metal.ryba:8442/api/v1/clusters/mycluster \
      #     -d @/tmp/toto.json
      #   """
      
      newProperties =
        Clusters:
          desired_configs:
            type: 'ssl-server'
            tag: 'version2'
            properties: options.ssl_server
            # properties_attributes:
            #   "final" :
            #     "dfs.webhdfs.enabled" : "true"
            #     "dfs.namenode.http-address" : "true"
            #     "dfs.support.append" : "true"
            #     "dfs.namenode.name.dir" : "true"
            #     "dfs.datanode.failed.volumes.tolerated" : "true"
            #     "dfs.datanode.data.dir" : "true"
      
      @file
        content: JSON.stringify newProperties
        target: "/tmp/toto.json"
      @system.execute
        cmd: """
          curl -k -u admin:admin123 -X PUT -H "X-Requested-By: ambari" https://master01.metal.ryba:8442/api/v1/clusters/mycluster \
          -d @/tmp/toto.json
        """
      
    fs = require 'ssh2-fs'
                # options.hdfs_site['hadoop.security.group.mapping'] ?= 'org.apache.hadoop.security.JniBasedUnixGroupsMappingWithFallback'
                # options.hdfs_site_merged = merge {}, service.use.hdfs_dn[0].options.hdfs_site, service.use.hdfs_jn[0].options.hdfs_site, options.hdfs_site
          # @call 'ryba/hadoop/hdfs_nn/takeover', options


# Capacity Planning for Hadoop Cluster

## Parameters

*   `config` (array|string)
    One or multiple configuration files and directories.
*   `total_memory` (int|string)
    Total Memory available on the server.
*   `memory_system` (int|string)
    Total Memory allocated to the system.
*   `memory_hbase` (int|string)
    Total Memory allocated to the HBase RegionServers.
*   `memory_yarn` (int|string)
    Total Memory allocated to the Yarn NodeManagers.
*   `cores` (int)
    Number of available cores to the Yarn NodeManagers.
*   `disks` (array)
    List of disk partitions available to the HDFS DataNodes and YARN NodeManagers.
*   `module` (String|Array)
    List of target services based on ryba available modules

```bash
node node_modules/@rybajs/metal/bin/capacity \
  -c ./conf \
  --partitions /data/1,/data/2 \
  -o ./conf/capacity.coffee -w
```

    params =
      name: 'capacity'
      description: 'Export cluster\' capacity planning in file'
      load: require 'masson/lib/utils/load'
      run: '@rybajs/metal/lib/capacity'
      options: [
        name: 'output', shortcut: 'o', type: 'string'
        description: 'output file'
      ,
        name: 'config', shortcut: 'c', type: 'array'
        description: 'config files'
      ,
        name: 'clusters', type: 'boolean'
        description: 'Print list of cluster names'
      ,
        name: 'format', shortcut: 'f', type: 'string'
        description: 'Format of the output files: [json, cson, js, coffee]'
      ,
        name: 'overwrite', shortcut: 'w', type: 'boolean' # default: 'text'
        description: 'Overwrite any existing file.'
      ,
        name: 'nodes', shortcut: 'n', type: 'boolean'
        description: 'Print configuration of nodes'
      # ,
      #   name: 'cluster', shortcut: 'c', type: 'string'
      #   description: 'Print configuration of clusters'
      # ,
      ,
        name: 'service', shortcut: 's', type: 'string'
        description: 'Print configuration of a services (format cluster:service)'
      ,
        name: 'service_names', type: 'boolean'
        description: 'Print list of service names'
      ,
        name: 'partitions', shortcut: 'p', type: 'array'
        description: 'List of disk partitions unless discovered.'
      ,
        name: 'hdfs_nn_name_dir' # default: './hdfs/name'
        description: 'Absolute path to a single directory or relative path to the HDFS NameNode directories.'
      ,
        name: 'hdfs_dn_data_dir' # default: './hdfs/data', eg '/mydata/1/hdfs/dn,/mydata/2/hdfs/dn'
        description: 'List of absolute paths or a relative path for HDFS DataNode directories.'
      ,
        name: 'yarn_nm_local_dir' # default: './yarn/local', eg '/mydata/1/yarn/local,/mydata/2/yarn/local'
        description: 'List of absolute paths or a relative path for YARN NodeManager directories.'
      ,
        name: 'yarn_nm_log_dir' # default: './yarn/log', eg '/mydata/1/yarn/log,/mydata/2/yarn/log'
        description: 'List of absolute paths or a relative path for YARN NodeManager directories.'
      ,
        name: 'kafka_data_dir' # default: './kafka', eg '/mydata/1/kafka,/mydata/2/kafka'
        description: 'List of absolute paths or a relative path for Kafka Broker directories.'
      ,
        name: 'total_memory_gb'
        description: " the total memory available per server in GB"
      ,
        name: 'reserved_memory_gb'
        description: " the reserved memory for the OS in GB"
      ,
        name: 'nodemanager_memory_gb'
        description: "the memory allocated for yarn nodemanager process"
      ,
        name: 'datanode_memory_gb'
        description: "the memory allocated for hdfs nodemanager process"
      ,
        name: 'regionserver_memory_gb'
        description: "the memory allocated for hbase regionserver process"
      ,
        name: 'yarn_memory_gb'
        description: "the memory dedicated for running containers. Should not be overrided"
      ]

## Read configuration

Taken from masson/lib/index.coffee


    module.exports = ->
      orgparams = parameters(params, main: name: 'main').parse()
      load orgparams.config, (err, config) ->
        # Normalize coniguration
        config = normalize config
        # config.params = parameters(params).parse()
        capacity orgparams, config, (err) ->
          if err
            throw err
          else
            process.exit 0

## Dependencies

    parameters = require 'parameters'
    load = require 'masson/lib/config/load'
    normalize = require 'masson/lib/config/normalize'
    merge = require 'masson/lib/utils/merge'
    capacity = require './'

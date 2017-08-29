
# MapReduce Client

MapReduce is the key algorithm that the Hadoop MapReduce engine uses to distribute work around a cluster.
The key aspect of the MapReduce algorithm is that if every Map and Reduce is independent of all other ongoing Maps and Reduces,
then the operation can be run in parallel on different keys and lists of data. On a large cluster of machines, you can go one step further, and run the Map operations on servers where the data lives.
Rather than copy the data over the network to the program, you push out the program to the machines.
The output list can then be saved to the distributed filesystem, and the reducers run to merge the results. Again, it may be possible to run these in parallel, each reducing different keys.

    module.exports =
      use:
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true
        hadoop_core: module: 'ryba/hadoop/core', local: true, required: true
        hdfs_client: module: 'ryba/hadoop/hdfs_client', required: true
        yarn_client: module: 'ryba/hadoop/yarn_client', required: true
        yarn_nm: module: 'ryba/hadoop/yarn_nm', required: true
        yarn_rm: module: 'ryba/hadoop/yarn_rm', required: true
        yarn_ts: module: 'ryba/hadoop/yarn_ts', required: true, single: true
        mapred_jhs: module: 'ryba/hadoop/mapred_jhs', single: true
      configure:
        'ryba/hadoop/mapred_client/configure'
      plugin: (contexts)->
        # for srv in service.use.yarn_nm
        #   srv
        #   .after
        #     type: ['hconfigure']
        #     target: "#{nm_ctx.config.ryba.yarn.nm.conf_dir}/yarn-site.xml"
        #   , (options, callback) ->
        #     @tools.iptables
        #       ssh: options.ssh
        #       header: 'Hadoop Mapred Ranger openging'
        #       rules: [
        #         { chain: 'INPUT', jump: 'ACCEPT', dport: options.mapred_site['yarn.app.mapreduce.am.job.client.port-range'].replace('-',':'), protocol: 'tcp', state: 'NEW', comment: "Mapred client Port Range" }
        #       ]
        #       if: nm_ctx.config.iptables.action is 'start'
        #     @then callback
      commands:
        'check': ->
          options = @config.ryba.mapred
          @call 'ryba/hadoop/mapred_client/check', options
        'report': ->
          options = @config.ryba.mapred
          @call 'masson/bootstrap/report'
          @call 'ryba/hadoop/mapred_client/report', options
        'install': ->
          options = @config.ryba.mapred
          @call 'ryba/hadoop/mapred_client/install', options
          @call 'ryba/hadoop/mapred_client/check', options

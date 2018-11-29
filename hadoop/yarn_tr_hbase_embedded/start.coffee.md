
# Hadoop YARN Timeline Reader HBase Embedded Backend Start

Starts the Yarn Application HBase Embedded Backend.
It is compose of and hbase-master and hbase-regionserver service

    module.exports = header: 'YARN TR Start', handler: ({options}) ->

## Wait

Wait for Kerberos and the HDFS NameNode.

      @call 'masson/core/krb5_client/wait', once: true, options.wait_krb5_client
      @call 'ryba/hadoop/hdfs_nn/wait', once: true, options.wait_hdfs_nn, conf_dir: options.conf_dir

## Run

Start the service.

      @service.start
        name: 'hadoop-yarn-hbase-master'
      
      @service.start
        name: 'hadoop-yarn-hbase-regionserver'
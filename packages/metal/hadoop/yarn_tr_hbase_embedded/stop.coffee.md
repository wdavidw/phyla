
# Hadoop YARN Timeline Reader HBase Embedded Backend Stop

Stops the Yarn Application HBase Embedded Backend.
It is compose of and hbase-master and hbase-regionserver service

    module.exports = header: 'YARN TR Stop', handler: ({options}) ->

## Run

Stop the service.

      @service.start
        name: 'hadoop-yarn-hbase-master'
      
      @service.start
        name: 'hadoop-yarn-hbase-regionserver'
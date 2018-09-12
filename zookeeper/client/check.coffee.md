
# Zookeeper Client Check

TODO: Cloudera provides some interesting [tests](http://www.cloudera.com/content/cloudera/en/documentation/cloudera-manager/v5-latest/Cloudera-Manager-Health-Tests/ht_zookeeper.html).

    module.exports = header: 'Zookeeper Client Check', handler: ({options}) ->

## Wait

      @call 'ryba/zookeeper/server/wait', once: true, options.wait_zookeeper_server

## Telnet
  
      @system.execute
        header: 'Shell'
        cmd: """
        zookeeper-client \
          -server #{options.zookeeper_quorum} <<< 'ls /' \
        | egrep '\\[.*zookeeper.*\\]'
        """
        retry: 3

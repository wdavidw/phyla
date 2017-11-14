
# Druid Broker Check

Todo: move to a druid client module. Here because the broker service is the latest
service to be started.

    module.exports = header: 'Druid Broker Check', handler: (options) ->

## Register

      @registry.register 'hdfs_upload', 'ryba/lib/hdfs_upload'

## Load from HDFS

      @call
        header: 'Load from HDFS'
        unless_exec: unless options.force_check then """
        echo #{options.krb5_user.password} | kinit #{options.krb5_user.principal} && {
          hdfs dfs -test -f quickstart/#{options.hostname}.success
        }
        """
      , ->
        @file.json
          header: 'Enrich Index'
          target: "#{options.dir}/quickstart/wikiticker-index.json"
          transform: (data) ->
            return data if data['hadoopDependencyCoordinates'] and "org.apache.hadoop:hadoop-client:2.7.3" in data['hadoopDependencyCoordinates']
            data['hadoopDependencyCoordinates'] = ["org.apache.hadoop:hadoop-client:2.7.3"]
            data
          merge: true
          pretty: true
          backup: true
        @system.execute
          header: 'Decompress'
          cmd: """
          if [ ! -f quickstart/wikiticker-2015-09-12-sampled.json  ]; then
            gunzip quickstart/wikiticker-2015-09-12-sampled.json.gz
          fi
          """
          cwd: options.dir
        @hdfs_upload
          header: 'Upload sample'
          target: "/user/#{options.user.name}/quickstart/wikiticker-2015-09-12-sampled.json"
          source: "quickstart/wikiticker-2015-09-12-sampled.json"
          cwd: options.dir
          owner: options.user.name
          krb5_user: options.hdfs_krb5_user
        @system.execute
          header: 'Index'
          cmd: """
          job=`curl -L -XPOST -H 'Content-Type:application/json' \
            -d @quickstart/wikiticker-index.json \
            #{options.overlord_fqdn}:#{options.overlord_runtime['druid.port']}/druid/indexer/v1/task \
            | sed 's/.*"task":"\\(.*\\)".*/\\1/'`
          echo "Current job is $job"
          sleep 5
          while [ "RUNNING" == `curl -L -s #{options.overlord_fqdn}:#{options.overlord_runtime['druid.port']}/druid/indexer/v1/task/${job}/status | sed 's/.*"status":"\\([^"]*\\)".*/\\1/'` ]; do
            echo -n '.'
            sleep 5
          done
          [ 'SUCCESS' == `curl -L -s #{options.overlord_fqdn}:#{options.overlord_runtime['druid.port']}/druid/indexer/v1/task/${job}/status | sed 's/.*"status":"\\([^"]*\\)".*/\\1/'` ]
          """
          cwd: options.dir
          trap: true
        @system.execute
          header: 'Query'
          cmd: """
          count=`curl -L -XPOST -H 'Content-Type:application/json' \
            -d @quickstart/wikiticker-top-pages.json \
            #{options.fqdn}:#{options.runtime['druid.port']}/druid/v2/?pretty \
            2>/dev/null \
            | wc -l`
          if [ $count -lt 50 ]; then sleep 10; fi
          if [ $count -lt 50 ]; then exit 1; fi
          echo "Got $count results"
          echo #{options.krb5_user.password} | kinit #{options.krb5_user.principal} && {
            hdfs dfs -touchz quickstart/#{options.hostname}.success
          }
          """
          cwd: options.dir
          trap: true
      # http://worker1.ryba:8090/console.html
      # curl  -L -XPOST -H 'Content-Type:application/json' --data-binary quickstart/wikiticker-top-pages.json http://master3.ryba:8082/druid/v2/?pretty -v
      # Broker
      # http://master1.ryba:8082/druid/v2/datasources
      # Coordinator
      # http://worker2.ryba:8081/#/

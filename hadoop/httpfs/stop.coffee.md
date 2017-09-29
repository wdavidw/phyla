
# HDFS HttpFS Stop

Stop the HDFS HttpFS service. You can also stop the server manually with one of
the following two commands:

```
service hadoop-httpfs start
su -l httpfs -c '/usr/hdp/current/hadoop-httpfs/sbin/httpfs.sh stop'
```

    module.exports = header: 'HDFS HttpFS Stop', handler: ->
      @service.stop
        header: 'Stop service'
        name: 'hadoop-httpfs'

    # module.exports.push header: 'Clean Logs', handler: ->
    #   {clean_logs, yarn} = @config.ryba
    #   return unless clean_logs
    #   @system.execute
    #     cmd: 'rm #{yarn.log_dir}/*/*-nodemanager-*'
    #     code_skipped: 1

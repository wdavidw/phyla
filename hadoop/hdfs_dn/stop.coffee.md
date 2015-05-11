
# Hadoop HDFS DataNode Stop

Stop the DataNode service. It is recommended to stop a DataNode before its
associated the NameNodes.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure

## Stop Service

    module.exports.push name: 'HDFS DN # Stop Service', label_true: 'STOPPED', handler: (ctx, next) ->
      ctx.execute
        cmd: "service hadoop-hdfs-datanode stop"
        code_skipped: 3
      , next

## Stop Clean Logs

    module.exports.push name: 'HDFS DN # Stop Clean Logs', label_true: 'CLEANED', handler: (ctx, next) ->
      return next() unless ctx.config.ryba.clean_logs
      ctx.execute
        cmd: 'rm /var/log/hadoop-hdfs/*/*-datanode-*'
        code_skipped: 1
      , next

## Module Dependencies

    lifecycle = require '../../lib/lifecycle'
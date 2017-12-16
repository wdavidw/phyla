
# Upgrade from HDP 2.3 to 2.4

## Procedure in pseudo-code

```
# on all nodes
./bin/ryba -c ./conf/env/offline.coffee install -m 'masson/**' -f
# on nn1 or nn2
kinit hdfs
hdfs dfsadmin -rollingUpgrade prepare
# wait until
hdfs dfsadmin -rollingUpgrade query | grep 'Proceed with rolling upgrade'
# on all zookeeper nodes, sequencially
hdp-select set zookeeper-server 2.3.4.0-3485
service zookeeper-server restart
# on all journal nodes, sequencially
hdp-select set hadoop-hdfs-journalnode 2.3.4.0-3485
service hadoop-hdfs-journalnode restart
# on all zkfc nodes, sequencially
hdp-select set hadoop-hdfs-namenode 2.3.4.0-3485
service hadoop-hdfs-zkfc restart
# on nn2
service hadoop-hdfs-namenode stop
su -l hdfs -c "/usr/hdp/current/hadoop-hdfs-namenode/../hadoop/sbin/hadoop-daemon.sh --config /etc/hadoop/conf --script hdfs start namenode -rollingUpgrade started"
hdfs haadmin -failover master1 master2
# on nn1
service hadoop-hdfs-namenode stop
su -l hdfs -c "/usr/hdp/current/hadoop-hdfs-namenode/../hadoop/sbin/hadoop-daemon.sh --config /etc/hadoop/conf --script hdfs start namenode -rollingUpgrade started"
# on each datanode
hdfs dfsadmin -shutdownDatanode `hostname`:50020 upgrade
while hdfs dfsadmin -D ipc.client.connect.max.retries=1 -getDatanodeInfo `hostname`:50020; do sleep 1; done
hdp-select set hadoop-hdfs-datanode 2.3.4.0-3485
HADOOP_SECURE_DN_USER=hdfs /usr/hdp/current/hadoop-hdfs-datanode/../hadoop/sbin/hadoop-daemon.sh --config /etc/hadoop/conf --script hdfs start datanode
# somewhere
hdfs dfsadmin -rollingUpgrade finalize
```

## Source code

Follow official instruction from [Hortonworks HDP 2.2 Manual Upgrade][upgrade]

    exports = module.exports = (params, config, callback) ->
      params.easy_download
      config.directory = '/var/ryba/upgrade'
      exports.contexts params, config, (err, contexts) ->
        return callback err if err
        each exports.steps
        .call (middleware, i, next) ->
          return next() if params.start? and i < params.start
          process.stdout.write "[#{i}] #{middleware.header}\n"
          each contexts
          .call (context, j, next) ->
            sign = if j+1 < contexts.length then '├' else '└'
            process.stdout.write " #{sign}  #{context.config.host}: "
            context.call middleware, (err, changed) ->
              if err
                process.stdout.write " ERROR: #{err.message or JSON.stringify err}\n"
                if err.errors
                  for err in err.errors
                    process.stdout.write "   #{err.message}\n"
              else if changed is false or changed is 0
                process.stdout.write " OK"
              else if not changed?
                process.stdout.write " SKIPPED"
              else
                process.stdout.write " CHANGED"
              process.stdout.write '\n'
              next err
          .next next
        .next (err) ->
          process.stdout.write "Disconnecting: "
          context.emit 'end' for context in contexts
          process.stdout.write if err then " ERROR" else ' OK'
          process.stdout.write '\n'
          callback err

## Contexts

    exports.contexts = (params, config, callback) ->
      contexts = []
      params = merge {}, params
      params.end = false
      params.modules = [
        'masson/bootstrap/connection'
        'masson/bootstrap/nikita'
        'masson/bootstrap/log'
        'masson/core/yum'
      ]
      run params, config
      .on 'context', (context) ->
        contexts.push context
      .on 'error', callback
      .on 'end', -> callback null, contexts

## Steps

    exports.steps = []

    exports.steps.push
      header: 'Prepare Rolling Upgrade'
      if: -> @config.ryba.active_nn_host is @config.host
    , ->
      @system.execute
        cmd: mkcmd.hdfs @, 'hdfs dfsadmin -rollingUpgrade query | grep "Proceed with rolling upgrade"'
        code_skipped: 1
      @call
        unless: -> @status -1
      , ->
        @registry.register 'kexecute', require '../kexecute'
        # @kexecute
        #   krb5_user: @config.ryba.hdfs.krb5_user
        #   cmd: "hdfs dfsadmin -rollingUpgrade prepare"
        @system.execute
          cmd: mkcmd.hdfs @, 'hdfs dfsadmin -rollingUpgrade prepare'
        @wait.execute
          cmd: mkcmd.hdfs @, 'hdfs dfsadmin -rollingUpgrade query | grep "Proceed with rolling upgrade"'

    exports.steps.push
      header: 'Upgrade Zookeeper'
      if: -> @has_module 'ryba/zookeeper/server'
    , ->
      @system.execute
        cmd: """
        hdp-select set zookeeper-server 2.4.0.0-169
        service zookeeper-server restart
        """
        trap: true
      @connection.wait
        host: @config.host
        port: @config.ryba.zookeeper?.port

    exports.steps.push
      header: 'Upgrade JournalNode'
      if: -> @has_module 'ryba/hadoop/hdfs_jn'
    , ->
      @system.execute
        cmd: """
        hdp-select set hadoop-hdfs-journalnode 2.4.0.0-169
        service hadoop-hdfs-journalnode restart
        """
        trap: true
      @connection.wait
        host: @config.host
        port: @config.ryba.hdfs.site['dfs.journalnode.rpc-address']?.split(':')[1]
      @call (_, callback) ->
        setTimeout callback, 10000

    exports.steps.push
      header: 'Upgrade ZKFC'
      if: -> @has_module 'ryba/hadoop/hdfs_zkfc'
    , ->
      @system.execute
        cmd: """
        hdp-select set hadoop-hdfs-zkfc 2.4.0.0-169
        service hadoop-hdfs-zkfc restart
        """
        trap: true

    exports.steps.push
      header: 'Upgrade standby NameNode'
      if: -> @has_module('ryba/hadoop/hdfs_nn') and @config.ryba.active_nn_host isnt @config.host
    , ->
      nn_ctxs = @contexts 'ryba/hadoop/hdfs_nn'
      for nn_ctx in nn_ctxs
        if nn_ctx.config.host is nn_ctx.config.ryba.active_nn_host
        then active = nn_ctx.config.shortname
        else standby = nn_ctx.config.shortname
      @system.execute
        cmd: mkcmd.hdfs @, """
        service hadoop-hdfs-namenode stop
        hdp-select set hadoop-hdfs-namenode 2.4.0.0-169
        su -l hdfs -c "/usr/hdp/current/hadoop-hdfs-namenode/../hadoop/sbin/hadoop-daemon.sh --config #{@config.ryba.hdfs.nn.conf_dir}  --script hdfs start namenode -rollingUpgrade started"
        hdfs haadmin -ns #{@config.ryba.nameservice} -failover #{active} #{standby}
        """
        trap: true

    exports.steps.push
      header: 'Upgrade active NameNode'
      if: -> @has_module('ryba/hadoop/hdfs_nn') and @config.ryba.active_nn_host is @config.host
    , ->
      nn_ctxs = @contexts 'ryba/hadoop/hdfs_nn'
      for nn_ctx in nn_ctxs
        if nn_ctx.config.host is nn_ctx.config.ryba.active_nn_host
        then active = nn_ctx.config.shortname
        else standby = nn_ctx.config.shortname
      @system.execute
        cmd: mkcmd.hdfs @, """
        service hadoop-hdfs-namenode stop
        hdp-select set hadoop-hdfs-namenode 2.4.0.0-169
        su -l hdfs -c "/usr/hdp/current/hadoop-hdfs-namenode/../hadoop/sbin/hadoop-daemon.sh --config #{@config.ryba.hdfs.nn.conf_dir} --script hdfs start namenode -rollingUpgrade started"
        hdfs --config #{@config.ryba.hdfs.nn.conf_dir} haadmin -ns #{@config.ryba.nameservice} -failover #{standby} #{active}
        """
        trap: true

    exports.steps.push
      header: 'Upgrade DataNode'
      if: -> @has_module 'ryba/hadoop/hdfs_dn'
    , ->
      @system.execute
        cmd: mkcmd.hdfs @, """
        hdfs dfsadmin -shutdownDatanode `hostname`:50020 upgrade
        while hdfs dfsadmin -D ipc.client.connect.max.retries=1 -getDatanodeInfo `hostname`:50020; do sleep 1; done
        hdp-select set hadoop-hdfs-datanode 2.4.0.0-169
        HADOOP_SECURE_DN_USER=hdfs /usr/hdp/current/hadoop-hdfs-datanode/../hadoop/sbin/hadoop-daemon.sh --config #{@config.ryba.hdfs.dn.conf_dir} --script hdfs start datanode
        """
        trap: true

    exports.steps.push
      header: 'Finalize'
      if: -> @config.ryba.active_nn_host is @config.host
    , ->
      @wait.execute
        cmd: mkcmd.hdfs @, 'hdfs dfsadmin -safemode get | grep OFF'
        interval: 3000
      @system.execute
        cmd: mkcmd.hdfs @, "hdfs dfsadmin -rollingUpgrade finalize"

## Dependencies

    util = require 'util'
    each = require 'each'
    {merge} = require 'nikita/lib/misc'
    run = require 'masson/lib/run'
    mkcmd = require '../mkcmd'


# Druid MiddleManager Install

    module.exports = header: 'Druid MiddleManager Install', handler: ->
      {druid} = @config.ryba

## IPTables

| Service             | Port | Proto    | Parameter                   |
|---------------------|------|----------|-----------------------------|
| Druid MiddleManager | 8091, 8100–8199 | tcp/http |                  |

      @tools.iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: druid.middlemanager.runtime['druid.port'], protocol: 'tcp', state: 'NEW', comment: "Druid MiddleManager" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: '8100–8199', protocol: 'tcp', state: 'NEW', comment: "Druid MiddleManager" }
        ]
        if: @config.iptables.action is 'start'

## Configuration

      @service.init
        header: 'rc.d'
        target: "/etc/init.d/druid-middlemanager"
        source: "#{__dirname}/../resources/druid-middlemanager.j2"
        context: @config
        local: true
        backup: true
        mode: 0o0755
      @call ->
        @system.execute
          cmd:  "hdp-select versions | tail -1"
        , (err, executed, stdout, stderr) ->
          return err if err
          hdp_current_version = stdout.trim() if executed
          druid.middlemanager.runtime['druid.indexer.runner.javaOpts'] = "-server -Xmx2g -Duser.timezone=#{druid.timezone} -Dfile.encoding=UTF-8 -Djava.util.logging.manager=org.apache.logging.log4j.jul.LogManager -Dhadoop.mapreduce.job.classloader=true -Dhdp.version=#{hdp_current_version}"
      @file.properties
        target: "/opt/druid-#{druid.version}/conf/druid/middleManager/runtime.properties"
        content: druid.middlemanager.runtime
        backup: true
      @file
        target: "#{druid.dir}/conf/druid/middleManager/jvm.config"
        write: [
          match: /^-Xms.*$/m
          replace: "-Xms#{druid.middlemanager.jvm.xms}"
        ,
          match: /^-Xmx.*$/m
          replace: "-Xmx#{druid.middlemanager.jvm.xmx}"
        ,
          match: /^-Duser.timezone=.*$/m
          replace: "-Duser.timezone=#{druid.timezone}"
        ]
      @system.mkdir
        target: "#{druid.middlemanager.runtime['druid.indexer.task.baseTaskDir']}"
        uid: "#{druid.user.name}"
        gid: "#{druid.group.name}"
        mode: 0o0750

## Hadoop client library

Detect the current Hadoop version and import its client jars. See the 
documentation [Working with different versions of Hadoop](https://github.com/druid-io/druid/blob/master/docs/content/operations/other-hadoop.md).

      @system.execute
        cmd: """
        version=`ls #{druid.hadoop_mapreduce_dir}/hadoop-mapreduce-client-core-*.jar | sed 's/.*client-core-\\([0-9]\\.[0-9]\\.[0-9]\\).*/\\1/g'`
        target=/opt/druid-#{druid.version}/hadoop-dependencies/hadoop-client/${version}
        signal=3
        if [ ! -d ${target} ]; then
          mkdir ${target}
        fi
        for file in `ls #{druid.hadoop_mapreduce_dir}/*.jar`; do
          if [ -f $file ] && [ ! -f $target/`basename $file` ]; then
            echo "Import jar to  $target/`basename $file`"
            cp -rp $file $target/`basename $file`
            signal=0
          fi
        done
        exit $signal
        """
        code_skipped: 3

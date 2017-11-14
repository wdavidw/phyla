
# Tez Check

    module.exports = header: 'Tez Check', handler: (options) ->

## Check HDFS

      remote_dir = "check-#{options.hostname}-tez-hdfs"
      @system.execute
        header: 'Check HDFS'
        cmd: mkcmd.test options.test_krb5_user, """
        hdfs dfs -rm -r -skipTrash #{remote_dir} 2>/dev/null
        hdfs dfs -mkdir #{remote_dir}
        echo -e 'foo\\nbar\\nfoo\\nbar\\nfoo' | hadoop fs -put - #{remote_dir}/test.txt
        hadoop jar /usr/hdp/current/tez-client/tez-examples-*.jar orderedwordcount #{remote_dir}/test.txt #{remote_dir}/output
        hadoop fs -cat #{remote_dir}/output/*
        """
        unless_exec: unless options.force_check then mkcmd.test options.test_krb5_user, "hdfs dfs -test -d #{remote_dir}/output"
      , (err, executed, stdout) ->
        throw Error "Invalid output" if executed and stdout?.trim().split('\n').slice(-2).join('\n') isnt 'bar\t2\nfoo\t3'

## Dependencies

    mkcmd = require '../lib/mkcmd'

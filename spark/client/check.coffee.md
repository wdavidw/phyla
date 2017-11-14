
# Apache Spark Check

Run twice "[Spark Pi][Spark-Pi]" example for validating installation . The configuration is a 10 stages run.
[Spark on YARN][Spark-yarn] cluster can turn into two different mode :  yarn-client mode and yarn-cluster mode.
Spark programs are divided into a driver part and executors part.
The driver program manages the executors task.

    module.exports = header: 'Spark Client Check', handler: (options) ->

## Register

      @registry.register 'ranger_policy', 'ryba/ranger/actions/ranger_policy'

## Wait

      @call 'ryba/hadoop/yarn_rm/wait', once: true, options.wait_yarn_rm

## Check Cluster Mode

Validate Spark installation with Pi-example in yarn-cluster mode.

The YARN cluster mode makes the driver part of the spark submitted program to run inside YARN.
In this mode the driver is the YARN application master (running inside YARN).

      @call header: 'YARN Cluster', ->
        applicationId = null
        @system.execute
          cmd: mkcmd.test options.test_krb5_user, """
            spark-submit \
              --class org.apache.spark.examples.SparkPi \
              --master yarn-cluster --num-executors 2 --driver-memory 512m \
              --executor-memory 512m --executor-cores 1 \
              #{options.client_dir}/lib/spark-examples*.jar 10 2>&1 /dev/null \
            | grep -m 1 "proxy\/application_";
          """
          unless_exec : unless options.force_check then mkcmd.test options.test_krb5_user, """
          hdfs dfs -test \
            -f check-#{options.hostname}-spark-cluster
          """
        , (err, status, stdout, stderr) ->
          throw err if err
          return unless status
          tracking_url_result = stdout.trim().split("/")
          applicationId = tracking_url_result[tracking_url_result.length - 2]
        @call
          if: -> @status -1
        ,->
          @system.execute
            cmd: mkcmd.test options.test_krb5_user, """
            yarn logs -applicationId #{applicationId} 2>&1 /dev/null | grep -m 1 "Pi is roughly";
            """
          , (err, status, stdout, stderr) ->
            throw err if err
            return unless status
            log_result = stdout.split(" ")
            pi = parseFloat(log_result[log_result.length - 1])
            throw Error 'Invalid Output' unless pi > 3.00 and pi < 3.20
        @system.execute
          cmd: mkcmd.test options.test_krb5_user, """
          hdfs dfs -touchz check-#{options.hostname}-spark-cluster
          """
          if: -> @status -2

## Check Client Mode

Validate Spark installation with Pi-example in yarn-client mode.

The YARN client mode makes the driver part of program to run on the local machine.
The local machine is the one from which the job has been submitted (called the client).
In this mode the driver is the spark master running outside yarn.

      @call header: 'YARN Client', ->
        file_check = "check-#{options.hostname}-spark-client"
        applicationId = null
        @system.execute
          cmd: mkcmd.test options.test_krb5_user, """
            spark-submit \
              --class org.apache.spark.examples.SparkPi \
              --master yarn-client --num-executors 2 --driver-memory 512m \
              --executor-memory 512m --executor-cores 1 \
              #{options.client_dir}/lib/spark-examples*.jar 10 2>&1 /dev/null \
            | grep -m 1 "Pi is roughly";
          """
          unless_exec : unless options.force_check then mkcmd.test options.test_krb5_user, "hdfs dfs -test -f #{file_check}"
        , (err, executed, stdout, stderr) ->
          return err if err
          return unless executed
          log_result = stdout.split(" ")
          pi = parseFloat(log_result[log_result.length - 1])
          return Error 'Invalid Output' unless pi > 3.00 and pi < 3.20
          return
        @system.execute
          cmd: mkcmd.test options.test_krb5_user, """
          hdfs dfs -touchz #{file_check}
          """
          if: -> @status -1

## Spark Shell (no hive)

Test spark-shell, in yarn-client mode. Spark-shell supports onyl local[*] mode and
yarn-client mode, not yarn-cluster.

      @call header: 'Shell (No SQL)', ->
        file_check = "check-#{options.hostname}-spark-shell-scala"
        directory = "check-#{options.hostname}-spark_shell_scala"
        db = "check_#{options.hostname}_spark_shell_scala"
        @system.execute
          cmd: mkcmd.test options.test_krb5_user, """
          echo 'println(\"spark_shell_scala\")' | spark-shell --master yarn-client 2>/dev/null | grep ^spark_shell_scala$
          """
          unless_exec : unless options.force_check then mkcmd.test options.test_krb5_user, "hdfs dfs -test -f #{file_check}"
        , (err, executed, stdout) ->
          return err if err
          return unless executed
          return Error 'Invalid Output' unless stdout.indexOf 'spark_shell_scala' > -1
        @system.execute
          cmd: mkcmd.test options.test_krb5_user, """
          hdfs dfs -touchz #{file_check}
          """
          if: -> @status -1

## Ranger Policy

      @call
        header: 'Ranger Policy'
        if: !!options.ranger_admin
      , ->
        # Wait for Ranger admin to be started
        @call 'ryba/ranger/admin/wait', once: true, options.wait_ranger_admin
        # Prepare the list of databases
        dbs = ["check_#{options.hostname}_spark_shell_hive"]
        @wait.execute
          header: 'Wait Service'
          cmd: """
          curl --fail -H "Content-Type: application/json" -k -X GET  \
            -u #{options.ranger_admin.username}:#{options.ranger_admin.password} \
            "#{options.ranger_install['POLICY_MGR_URL']}/service/public/v2/api/service/name/#{options.ranger_install['REPOSITORY_NAME']}"
          """
          code_skipped: [1, 7, 22] # 22 is for 404 not found, 7 is for not connected to host
        @ranger_policy
          header: 'Create'
          username: options.ranger_admin.username
          password: options.ranger_admin.password
          url: options.ranger_install['POLICY_MGR_URL']
          policy:
            'name': "ryba-check-#{options.hostname}-spark"
            'description': 'Ryba policy used to check the beeline service'
            'service': options.ranger_install['REPOSITORY_NAME']
            'isEnabled': true
            'isAuditEnabled': true
            'resources':
              'database':
                'values': dbs
                'isExcludes': false
                'isRecursive': false
              'table':
                'values': ['*']
                'isExcludes': false
                'isRecursive': false
              'column':
                'values': ['*']
                'isExcludes': false
                'isRecursive': false
            'policyItems': [
              'accesses': [
                'type': 'all'
                'isAllowed': true
              ]
              'users': [options.test.user.name]
              'groups': []
              'conditions': []
              'delegateAdmin': false
          ]

## Spark Shell (no hive)

Executes hive queries to check communication with Hive.
Creating database from SparkSql is not supported for now.

      @call
        header: 'Shell (Hive SQL)'
        if: !!options.hive_server2
      , ->
        dir_check = "check-#{options.hostname}-spark-shell-scala-sql"
        directory = "check-#{options.hostname}-spark_shell_scala-sql"
        db = "check_#{options.hostname}_spark_shell_hive"
        current = null
        urls = options.hive_server2
        .map (hive_server2) ->
          quorum = hive_server2.hive_site['hive.zookeeper.quorum']
          namespace = hive_server2.hive_site['hive.server2.zookeeper.namespace']
          principal = hive_server2.hive_site['hive.server2.authentication.kerberos.principal']
          url = "jdbc:hive2://#{quorum}/;principal=#{principal};serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=#{namespace}"
          if hive_server2.hive_site['hive.server2.use.SSL'] is 'true'
            url += ";ssl=true"
            url += ";sslTrustStore=#{options.conf['spark.ssl.trustStore']}"
            url += ";trustStorePassword=#{options.conf['spark.ssl.trustStorePassword']}"
          if hive_server2.hive_site['hive.server2.transport.mode'] is 'http'
            url += ";transportMode=#{hive_server2.hive_site['hive.server2.transport.mode']}"
            url += ";httpPath=#{hive_server2.hive_site['hive.server2.thrift.http.path']}"
          url
        .sort()
        .filter (c) ->
          p = current; current = c; p isnt c
        for url in urls
          beeline = "beeline -u \"#{url}\" --silent=true "
          @system.execute
            unless_exec: unless options.force_check then mkcmd.test options.test_krb5_user, "hdfs dfs -test -f #{dir_check}/_SUCCESS"
            cmd: mkcmd.test options.test_krb5_user, """
            hdfs dfs -rm -r -skipTrash #{directory} || true
            hdfs dfs -rm -r -skipTrash #{dir_check} || true
            hdfs dfs -mkdir -p #{directory}/my_db/spark_sql_test
            echo -e 'a,1\\nb,2\\nc,3' > /var/tmp/spark_sql_test
            #{beeline} \
              -e "DROP DATABASE IF EXISTS #{db};" \
              -e "CREATE DATABASE #{db} LOCATION '/user/#{options.test.user.name}/#{directory}/my_db/';"
            spark-shell --master yarn-client 2>/dev/null <<SPARKSHELL
            sqlContext.sql("USE #{db}");
            sqlContext.sql("DROP TABLE IF EXISTS spark_sql_test");
            sqlContext.sql("CREATE TABLE IF NOT EXISTS spark_sql_test (key STRING, value INT)");
            sqlContext.sql("LOAD DATA LOCAL INPATH '/var/tmp/spark_sql_test' INTO TABLE spark_sql_test");
            sqlContext.sql("FROM spark_sql_test SELECT key, value").collect().foreach(println)
            sqlContext.sql("FROM spark_sql_test SELECT key, value").rdd.saveAsTextFile("/user/#{options.test.user.name}/#{dir_check}")
            SPARKSHELL
            #{beeline} \
              -e "DROP TABLE #{db}.spark_sql_test; DROP DATABASE #{db};"
            if hdfs dfs -test -f /user/#{options.test.user.name}/#{dir_check}/_SUCCESS; then exit 0; else exit 1;fi
            """
            trap: true

## Spark Shell Python

      @call header: 'Shell (PySpark)', ->
        file_check = "check-#{options.hostname}-spark-shell-python"
        directory = "check-#{options.hostname}-spark_shell_python"
        db = "check_#{options.hostname}_spark_shell_python"
        @system.execute
          cmd: mkcmd.test options.test_krb5_user, """
          echo 'print \"spark_shell_python\"' | pyspark  --master yarn-client 2>/dev/null | grep ^spark_shell_python$
          """
          unless_exec : unless options.force_check then mkcmd.test options.test_krb5_user, "hdfs dfs -test -f #{file_check}"
        , (err, executed, stdout) ->
          return err if err
          return unless executed
          return Error 'Invalid Output' unless stdout.indexOf 'spark_shell_python' > -1
        @system.execute
          cmd: mkcmd.test options.test_krb5_user, """
          hdfs dfs -touchz #{file_check}
          """
          if: -> @status -1

## Running Streaming Example

Original source code: https://github.com/apache/spark/blob/master/examples/src/main/scala/org/apache/spark/examples/streaming/KafkaWordCount.scala
Good introduction: http://www.michael-noll.com/blog/2014/10/01/kafka-spark-streaming-integration-example-tutorial/
Here's how to run the Kafka WordCount example:

```
spark-submit \
  --class org.apache.spark.examples.streaming.KafkaWordCount \
  --queue default \
  --master yarn-cluster  --num-executors 2 --driver-memory 512m \
  --executor-memory 512m --executor-cores 1 \
  /usr/hdp/current/spark-client/lib/spark-examples*.jar \
  master1.ryba:2181,master2.ryba:2181,master3.ryba:2181 \
  my-consumer-group topic1,topic2 1
```

## Dependencies

    mkcmd = require '../../lib/mkcmd'

[Spark-Pi]:http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.2.4/Apache_Spark_Quickstart_v224/content/run_spark_pi.html
[Spark-yarn]:http://blog.cloudera.com/blog/2014/05/apache-spark-resource-management-and-yarn-app-models/

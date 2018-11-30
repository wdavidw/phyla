
# Apache Spark

Altiscale describes Spark usage in its [Tips and Tricks for Running Spark][tips]
article. Here's an extract from the original article.

Once installed, Spark can be run in three modes: local, yarn-client or
yarn-cluster.

*   Local mode: this launches a single Spark shell with all Spark components
    running within the same JVM. This is good for debugging on your laptop or on
    a workbench. Here’s how you’d invoke Spark in local mode:   
    ```
    cd $SPARK_HOME
    ./bin/spark-shell
    ```

*   Yarn-cluster: the Spark driver runs within the Hadoop cluster as a YARN
    Application Master and spins up Spark executors within YARN containers. This
    allows Spark applications to run within the Hadoop cluster and be completely
    decoupled from the workbench, which is used only for job submission. An
    example:   
    ```
    cd $SPARK_HOME
    ./bin/spark-submit --class org.apache.spark.examples.SparkPi --master yarn –deploy-mode cluster --num-executors 3 --driver-memory 1g --executor-memory 2g --executor-cores 1 --queue thequeue $SPARK_HOME/examples/target/spark-examples_*-1.2.1.jar`   
    ```
    Note that in the example above, the –queue option is used to specify the Hadoop queue to which the application is submitted.

*   Yarn-client: the Spark driver runs on the workbench itself with the
    Application Master operating in a reduced role. It only requests resources
    from YARN to ensure the Spark workers reside in the Hadoop cluster within
    YARN containers. This provides an interactive environment with distributed
    operations. Here’s an example of invoking Spark in this mode while ensuring
    it picks up the Hadoop LZO codec:   
    ```
    cd $SPARK_HOME
    bin/spark-shell --master yarn --deploy-mode client --queue research --driver-memory 512M --driver-class-path /opt/hadoop/share/hadoop/mapreduce/lib/hadoop-lzo-0.4.18-201409171947.jar
    ```

The three Spark modes have different use cases. Local and yarn-client modes are
both “shells,” allow initial, exploratory development, local mode restricted to
the computing power of your laptop, client mode able to leverage the full power
of your cluster.

    module.exports =
      deps:
        ssl: module: 'masson/core/ssl', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        test_user: module: 'ryba/commons/test_user', local: true, auto: true
        ranger_admin: module: 'ryba/ranger/admin', single: true
        ranger_hive: module: 'ryba/ranger/plugins/hiveserver2'
        hadoop_core: module: 'ryba/hadoop/core', local: true, required: true
        hdfs_nn: module: 'ryba/hadoop/hdfs_nn'
        yarn_nm: module: 'ryba/hadoop/yarn_nm'
        yarn_rm: module: 'ryba/hadoop/yarn_rm'
        hive_hcatalog: module: 'ryba/hive/hcatalog'
        hive_server2: module: 'ryba/hive/server2'
        tez: module: 'ryba/tez', local: true
        ganglia_collector: module: 'ryba/retired/ganglia/collector'
        graphite: module: 'ryba/graphite/carbon'
      configure:
        'ryba/spark2/client/configure'
      commands:
        'install': [
          'ryba/spark2/client/install'
          'ryba/spark2/client/check'
        ]
        'check':
          'ryba/spark2/client/check'

[tips]: https://www.altiscale.com/hadoop-blog/spark-on-hadoop/

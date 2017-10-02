
# Zeppelin Configure

    module.exports = (service) ->
      service = migration.call @, service, 'ryba/zeppelin', ['ryba', 'zeppelin'], require('nikita/lib/misc').merge require('.').use,
        # krb5_client: key: ['krb5_client']
        # java: key: ['java']
        docker: key: ['docker']
        # test_user: key: ['ryba', 'test_user']
        # hadoop_core: key: ['ryba']
        hdfs_client: key: ['ryba', 'hdfs_client']
        # yarn_client: key: ['ryba', 'yarn_client']
        # mapred_client: key: ['ryba', 'mapred']
        spark_client: key: ['ryba', 'spark', 'client']
        hive_client: key: ['ryba', 'hive', 'client']
      @config.ryba ?= {}
      options = @config.ryba.zeppelin = service.options

## Prepare

      options.repository = 'https://github.com/apache/incubator-zeppelin.git'
      options.source = "#{__dirname}/../resources/zeppelin-build.tar.gz"

## Identities

      # Group
      options.group ?= {}
      options.group = name: options.group if typeof options.group is 'string'
      options.group.name ?= 'zeppelin'
      options.group.system ?= true
      # User
      options.user ?= {}
      options.user = name: options.user if typeof options.user is 'string'
      options.user.name ?= 'zeppelin'
      options.user.gid = options.group.name
      options.user.system ?= true
      options.user.groups ?= 'hadoop'
      options.user.comment ?= 'Zeppelin User'
      options.user.home ?= '/var/lib/zeppelin'

## Environment

      options.conf_dir ?= '/var/lib/zeppelin/conf'
      options.log_dir ?= '/var/log/zeppelin'
      options.hadoop_conf_dir ?= service.use.hdfs_client.options.conf_dir
      # Misc
      options.hdfs_defaultfs = service.use.hdfs_client.options.core_site['fs.defaultFS']
      options.cache_dir ?= '/tmp'

## Build & Prod

      options.build ?= {}
      options.build.cwd ?= "#{__dirname}/resources/build"
      options.build.tag ?= 'ryba/zeppelin-build'
      options.prod ?= {}
      options.prod.cwd ?= "#{__dirname}/resources/prod"
      options.prod.tag ?= 'ryba/zeppelin:0.1'

## Configuration

      options.zeppelin_site ?= {}
      options.zeppelin_site['zeppelin.server.addr'] ?= '0.0.0.0'
      options.zeppelin_site['zeppelin.server.port'] ?= '9090'
      options.zeppelin_site['zeppelin.notebook.dir'] ?= '/var/lib/zeppelin/notebook'
      options.zeppelin_site['zeppelin.websocket.addr'] ?= '0.0.0.0'
      #If the port value is negative, then it'll default to the server port + 1
      options.zeppelin_site['zeppelin.websocket.port'] ?= '-1'
      options.zeppelin_site['zeppelin.notebook.storage'] ?= 'org.apache.zeppelin.notebook.repo.VFSNotebookRepo'
      options.zeppelin_site['zeppelin.interpreter.dir'] ?= 'interpreter'
      #list of interpreters, the first is the default 
      options.zeppelin_site['zeppelin.interpreters'] ?= [
        'org.apache.zeppelin.spark.SparkInterpreter'
        'org.apache.zeppelin.spark.PySparkInterpreter'
        'org.apache.zeppelin.spark.SparkSqlInterpreter'
        'org.apache.zeppelin.spark.DepInterpreter'
        'org.apache.zeppelin.markdown.Markdown'
        'org.apache.zeppelin.angular.AngularInterpreter'
        'org.apache.zeppelin.shell.ShellInterpreter'
        'org.apache.zeppelin.hive.HiveInterpreter'
        'org.apache.zeppelin.tajo.TajoInterpreter'
        'org.apache.zeppelin.flink.FlinkInterpreter'
        'org.apache.zeppelin.lens.LensInterpreter'
        'org.apache.zeppelin.ignite.IgniteInterprete'
        'org.apache.zeppelin.ignite.IgniteSqlInterpreter'
      ]
      options.zeppelin_site['zeppelin.interpreter.connect.timeout'] ?= '30000'
      #for now ryba does not install zepplin with SSL
      #putting properties for further installation
      #will be made soon
      options.zeppelin_site['zeppelin.ssl'] ?= 'false'
      options.zeppelin_site['zeppelin.ssl.client.auth'] ?= 'false'
      options.zeppelin_site['zeppelin.ssl.keystore.path'] ?= 'keystore'
      options.zeppelin_site['zeppelin.ssl.keystore.type'] ?= 'JKS'
      options.zeppelin_site['zeppelin.ssl.keystore.password'] ?= 'password'
      options.zeppelin_site['zeppelin.ssl.key.manager.password'] ?= 'password'
      options.zeppelin_site['zeppelin.ssl.truststore.path'] ?= 'truststore'
      options.zeppelin_site['zeppelin.ssl.truststore.type'] ?= 'JKS'
      options.zeppelin_site['zeppelin.ssl.truststore.password'] ?= 'password'

## Env

      options.env ?= {}
      options.env['HADOOP_CONF_DIR'] = service.use.hdfs_client.options.conf_dir
      options.env['ZEPPELIN_LOG_DIR'] ?= '/var/log/zeppelin'
      options.env['ZEPPELIN_PID_DIR'] ?= '/var/run/zeppelin'
      options.env['ZEPPELIN_PORT'] ?= options.zeppelin_site['zeppelin.server.port']
      options.env['ZEPPELIN_INTERPRETER_DIR'] ?= 'interpreter'
      options.env['MASTER'] ?= 'yarn-client'
      options.env['ZEPPELIN_SPARK_USEHIVECONTEXT'] ?= 'false'
      options.env['SPARK_HOME'] ?= '/usr/hdp/current/spark-client'
      options.env['ZEPPELIN_JAVA_OPTS'] ?= '-Dhdp.version=2.3.0.0-2557'
      #options.env['SPARK_YARN_JAR'] ?= 'file:///var/lib/zeppelin/interpreter/spark/zeppelin-spark-0.6.0-incubating-SNAPSHOT.jar'
      # options.env['SPARK_YARN_JAR'] ?= 'hdfs:///user/spark/share/lib/spark-assembly-1.3.1.2.3.0.0-2557-hadoop2.7.1.2.3.0.0-2557.jar'
      options.env['HADOOP_HOME'] ?= '/usr/hdp/current/hadoop-client'

# Module Dependencies

    # {merge} = require 'nikita/lib/misc'
    migration = require 'masson/lib/migration'

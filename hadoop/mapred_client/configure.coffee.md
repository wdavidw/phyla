
# MapReduce Configure

    module.exports = (service) ->
      options = service.options

## Identities

      options.hadoop_group = merge {}, service.deps.hadoop_core.options.hadoop_group, options.hadoop_group
      options.group = merge {}, service.deps.hadoop_core.options.mapred.group, options.group
      options.user = merge {}, service.deps.hadoop_core.options.mapred.user, options.user

## Kerberos

      # Kerberos HDFS Admin
      options.hdfs_krb5_user = service.deps.hadoop_core.options.hdfs.krb5_user
      # Kerberos Test Principal
      options.test_krb5_user ?= service.deps.test_user.options.krb5.user

## Environment

      # Layout
      options.log_dir ?= '/var/log/hadoop-mapreduce' # Default to "/var/log/hadoop-mapreduce/$USER"
      options.pid_dir ?= '/var/run/hadoop-mapreduce'  # /etc/hadoop/conf/hadoop-env.sh#94
      options.conf_dir ?= service.deps.hadoop_core.options.conf_dir
      # Misc
      options.force_check ?= false
      options.hostname ?= service.node.hostname
      options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'
      options.nn_url = service.deps.hdfs_client[0].options.nn_url

## Configuration

      options.mapred_site ?= {}
      options.mapred_site['mapreduce.job.counters.max'] ?= 120
      options.mapred_site['mapreduce.reduce.shuffle.parallelcopies'] ?= '50' #  Higher number of parallel copies run by reduces to fetch outputs from very large number of maps.
      # http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.6.0/bk_installing_manually_book/content/rpm_chap3.html
      # Optional: Configure MapReduce to use Snappy Compression
      # Complement core-site.xml configuration
      # options.mapred_site['mapreduce.admin.map.child.java.opts'] ?= "-server -XX:NewRatio=8 -Djava.library.path=/usr/lib/hadoop/lib/native/ -Djava.net.preferIPv4Stack=true"
      options.mapred_site['mapreduce.admin.map.child.java.opts'] ?= "-server -Djava.net.preferIPv4Stack=true -Dhdp.version=${hdp.version}"
      options.mapred_site['mapreduce.admin.reduce.child.java.opts'] ?= null
      options.mapred_site['mapreduce.task.io.sort.factor'] ?= 100 # Default to "TODO..." inside HPD and 100 inside ambari and 10 inside mapred-default.xml
      # options.mapred_site['mapreduce.admin.reduce.child.java.opts'] ?= "-server -XX:NewRatio=8 -Djava.library.path=/usr/lib/hadoop/lib/native/ -Djava.net.preferIPv4Stack=true"
      options.mapred_site['mapreduce.admin.user.env'] ?= "LD_LIBRARY_PATH=/usr/hdp/${hdp.version}/hadoop/lib/native:/usr/hdp/${hdp.version}/hadoop/lib/native/Linux-amd64-64"
      # [Configurations for MapReduce JobHistory Server](http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/ClusterSetup.html#Configuring_the_Hadoop_Daemons_in_Non-Secure_Mode)
      options.mapred_site['mapreduce.application.framework.path'] ?= "/hdp/apps/${hdp.version}/mapreduce/mapreduce.tar.gz#mr-framework"
      options.mapred_site['mapreduce.application.classpath'] ?= "$PWD/mr-framework/hadoop/share/hadoop/mapreduce/*:$PWD/mr-framework/hadoop/share/hadoop/mapreduce/lib/*:$PWD/mr-framework/hadoop/share/hadoop/common/*:$PWD/mr-framework/hadoop/share/hadoop/common/lib/*:$PWD/mr-framework/hadoop/share/hadoop/yarn/*:$PWD/mr-framework/hadoop/share/hadoop/yarn/lib/*:$PWD/mr-framework/hadoop/share/hadoop/hdfs/*:$PWD/mr-framework/hadoop/share/hadoop/hdfs/lib/*:/usr/hdp/current/share/lzo/0.6.0/lib/hadoop-lzo-0.6.0.jar:/usr/hdp/current/hadoop-client/lib/*:/etc/hadoop/conf/secure"
      for property in [
        'yarn.app.mapreduce.am.staging-dir'
        'mapreduce.jobhistory.address'
        'mapreduce.jobhistory.webapp.address'
        'mapreduce.jobhistory.webapp.https.address'
        'mapreduce.jobhistory.done-dir'
        'mapreduce.jobhistory.intermediate-done-dir'
        'mapreduce.jobhistory.principal'
      ]
        options.mapred_site[property] ?= if service.deps.mapred_jhs then service.deps.mapred_jhs.options.mapred_site[property] else null
      # The value is set by the client app and the iptables are enforced on the worker nodes
      options.mapred_site['yarn.app.mapreduce.am.job.client.port-range'] ?= '59100-59200'
      options.mapred_site['mapreduce.framework.name'] ?= 'yarn' # Execution framework set to Hadoop YARN.
      # Deprecated properties
      options.mapred_site['mapreduce.cluster.local.dir'] = null # Now "yarn.nodemanager.local-dirs"
      options.mapred_site['mapreduce.jobtracker.system.dir'] = null # JobTracker no longer used
      # The replication level for submitted job files should be around the square root of the number of nodes.
      # see https://issues.apache.org/jira/browse/MAPREDUCE-2845
      options.mapred_site['mapreduce.client.submit.file.replication'] ?= Math.min (Math.round Math.sqrt service.deps.yarn_nm.length), 10

# Configuration for Resource Allocation

There are three aspects to consider:
*   Physical RAM limit for each Map And Reduce task
*   The JVM heap size limit for each task
*   The amount of virtual memory each task will get

The total size of the memory given to the JVM available to each map/reduce
container is defined by the properties "mapreduce.map.memory.mb" and
"mapreduce.reduce.memory.mb" in megabytes (MB). This includes both heap memory
(which many of us Java developers always are thinking about) and non-heap
memory. Non-heap memory includes the stack and the PermGen space. It should be
at least equal to or more than the YARN minimum Container allocation.

For this reason, the maximum size of the heap (Java -Xmx parameter) is set to an
inferior value, commonly 80% of the maximum available memory. The heap size
parameter is defined inside the "mapreduce.map.java.opts" and
"mapreduce.reduce.java.opts" properties.

Resources:
*   [Understanding YARN MapReduce Memory Allocation](http://beadooper.com/?p=165)

      memory_per_container = 512
      rm_memory_min_mb = service.deps.yarn_rm[0].options.yarn_site['yarn.scheduler.minimum-allocation-mb']
      rm_memory_max_mb = service.deps.yarn_rm[0].options.yarn_site['yarn.scheduler.maximum-allocation-mb']
      rm_cpu_min = service.deps.yarn_rm[0].options.yarn_site['yarn.scheduler.minimum-allocation-vcores']
      rm_cpu_max = service.deps.yarn_rm[0].options.yarn_site['yarn.scheduler.maximum-allocation-mb']
      yarn_mapred_am_memory_mb = options.mapred_site['yarn.app.mapreduce.am.resource.mb'] or if memory_per_container > 1024 then 2 * memory_per_container else memory_per_container
      yarn_mapred_am_memory_mb = Math.min rm_memory_max_mb, yarn_mapred_am_memory_mb
      options.mapred_site['yarn.app.mapreduce.am.resource.mb'] = "#{yarn_mapred_am_memory_mb}"

      yarn_mapred_opts = /-Xmx(.*?)m/.exec(options.mapred_site['yarn.app.mapreduce.am.command-opts'])?[1] or Math.floor(.8 * yarn_mapred_am_memory_mb)
      yarn_mapred_opts = Math.min rm_memory_max_mb, yarn_mapred_opts
      options.mapred_site['yarn.app.mapreduce.am.command-opts'] = "-Xmx#{yarn_mapred_opts}m"

      map_memory_mb = options.mapred_site['mapreduce.map.memory.mb'] or memory_per_container
      map_memory_mb = Math.min rm_memory_max_mb, map_memory_mb
      map_memory_mb = Math.max rm_memory_min_mb, map_memory_mb
      options.mapred_site['mapreduce.map.memory.mb'] = "#{map_memory_mb}"

      reduce_memory_mb = options.mapred_site['mapreduce.reduce.memory.mb'] or memory_per_container #2 * memory_per_container
      reduce_memory_mb = Math.min rm_memory_max_mb, reduce_memory_mb
      reduce_memory_mb = Math.max rm_memory_min_mb, reduce_memory_mb
      options.mapred_site['mapreduce.reduce.memory.mb'] = "#{reduce_memory_mb}"

      map_memory_xmx = /-Xmx(.*?)m/.exec(options.mapred_site['mapreduce.map.java.opts'])?[1] or Math.floor .8 * map_memory_mb
      map_memory_xmx = Math.min rm_memory_max_mb, map_memory_xmx
      options.mapred_site['mapreduce.map.java.opts'] ?= "-Xmx#{map_memory_xmx}m"

      reduce_memory_xmx = /-Xmx(.*?)m/.exec(options.mapred_site['mapreduce.reduce.java.opts'])?[1] or Math.floor .8 * reduce_memory_mb
      reduce_memory_xmx = Math.min rm_memory_max_mb, reduce_memory_xmx
      options.mapred_site['mapreduce.reduce.java.opts'] ?= "-Xmx#{reduce_memory_xmx}m"

      options.mapred_site['mapreduce.task.io.sort.mb'] ?= "#{Math.floor .4 * memory_per_container}"

      map_cpu = options.mapred_site['mapreduce.map.cpu.vcores'] or 1
      map_cpu = Math.min rm_cpu_max, map_cpu
      map_cpu = Math.max rm_cpu_min, map_cpu
      options.mapred_site['mapreduce.map.cpu.vcores'] = "#{map_cpu}"

      reduce_cpu = options.mapred_site['mapreduce.reduce.cpu.vcores'] or 1
      reduce_cpu = Math.min rm_cpu_max, reduce_cpu
      reduce_cpu = Math.max rm_cpu_min, reduce_cpu
      options.mapred_site['mapreduce.reduce.cpu.vcores'] = "#{reduce_cpu}"

## Write Data To YARN TimelineV2
      
      if service.deps.yarn_tr?[0].options.yarn_site['yarn.timeline-service.version'] is '2.0'
        options.mapred_site['mapreduce.job.emit-timeline-data'] ?= 'true'

## Wait

      options.wait_mapred_jhs = service.deps.mapred_jhs.options.wait
      options.wait_yarn_ts = service.deps.yarn_ts?.options?.wait if service.deps.yarn_ts
      options.wait_yarn_tr = service.deps.yarn_tr?.options?.wait if service.deps.yarn_tr
      options.wait_yarn_nm = service.deps.yarn_nm[0].options.wait
      options.wait_yarn_rm = service.deps.yarn_rm[0].options.wait

## Dependencies

    {merge} = require 'nikita/lib/misc'

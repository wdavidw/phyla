
# Hadoop YARN Timeline Reader Setup

Setup hbase backend and set ACL for timeLineReader to read/write to ead

    module.exports = header: 'YARN TR Setup', handler: ({options}) ->

## Registry

      @registry.register ['yarn','service', 'create'], 'ryba/lib/actions/yarn/service_create'
      @registry.register ['yarn','service', 'get'], 'ryba/lib/actions/yarn/service_get'

## Wait

      if options.yarn_hbase_embedded
        @call 'ryba/hadoop/yarn_tr_hbase_embedded/wait', once: true, options.wait_hbase_embedded

## yarn-ats service render

      @file.render
        if: options.post_service and options.yarn_hbase_service
        header: 'yarn hbase-ats service file'
        target: "#{options.conf_dir}/yarn_hbase_service.json"
        source: "#{__dirname}/../resources/yarn_hbase_secure.yarnfile.j2"
        local: true
        context:
          java64_home: options.ats_yarn_service.java_home 
          service_queue_name: options.ats_yarn_service.service_queue_name
          app_hdfs_path: options.ats_yarn_service.app_hdfs_path
          user_version_home: options.ats_yarn_service.user_version_home
          number_of_containers_master: options.ats_yarn_service.number_of_containers_master
          number_of_containers_rs: options.ats_yarn_service.number_of_containers_rs
          number_of_containers_client: options.ats_yarn_service.number_of_containers_client
          number_of_cpus_master: options.ats_yarn_service.number_of_cpus_master
          number_of_cpus_rs: options.ats_yarn_service.number_of_cpus_rs
          number_of_cpus_client: options.ats_yarn_service.number_of_cpus_client
          memory_mb_master: options.ats_yarn_service.memory_mb_master
          memory_mb_rs: options.ats_yarn_service.memory_mb_rs
          memory_mb_client: options.ats_yarn_service.memory_mb_client
          master_heapsize: options.ats_yarn_service.master_heapsize
          master_jaas_file: "#{options.conf_dir}/yarn_hbase_master_jaas.conf"
          regionserver_heapsize: options.ats_yarn_service.rs_heapsize
          regionserver_jaas_file: "#{options.conf_dir}/yarn_hbase_regionserver_jaas.conf"
          yarn_ats_hbase_principal_name: options.ats_yarn_service.yarn_ats_hbase_principal
          yarn_ats_hbase_keytab: options.ats_yarn_service.yarn_ats_hbase_keytab
          # yarn_ats_hbase_principal_name: options.yarn_ats_user.principal
          # yarn_ats_hbase_keytab: options.yarn_ats_user.keytab
        uid: options.ats_user.name
        gid: options.hadoop_group.name
        mode: 0o750
        backup: true
        eof: true
      @hdfs.put
        header: 'Upload ATS Keytab'
        if: options.post_service and options.yarn_hbase_service
        source: options.yarn_site['yarn.timeline-service.keytab']
        target: '/atsv2/yarn-ats.hbase-master.service.keytab'
        nn_url: options.nn_url
        owner: 'yarn-ats'
        group: options.hadoop_group.name
        krb5_user: options.hdfs_krb5_user

## yarn-ats service post

      @yarn.service.create
        if: options.post_service and options.yarn_hbase_service
        header: 'Yarn HBase Service'
        name: 'ats-hbase'
        yarn_url: options.yarn_url
        yarn_user:
          principal: options.yarn_ats_user.principal
          password: options.yarn_ats_user.password
        source: "#{options.conf_dir}/yarn_hbase_service.json"
        user: options.ats_user.name
        group: options.hadoop_group.name
      #TODO: wait for service to be running


## HBase Backend Schema
Need to use org.apache.hadoop.yarn.server.timelineservice.storage.TimelineSchemaCreator.
It will 5 table inside hbase. The jars contaning the classes can be found inside 
the /usr/hdp/current/hadoop-yarn-timelinereader/yimelinservice folder.
The class can be run with hadoop or hbase command. Incase you want to run it with hadoop,
you need to add hbase jars in the classpath or it will not be able to communicate with hbase.

      @wait.execute
        header: 'Wait HBase Shell'
        if: options.post_service
        cmd: mkcmd.hbase options.yarn_ats_user, """
          export HBASE_CLASSPATH_PREFIX=/usr/hdp/current/hadoop-yarn-timelinereader/timelineservice/*
          echo list | hbase --config #{options.ats2_hbase_conf_dir} shell 
        """
      @system.execute
        header: 'Init Schema'
        if: options.post_service
        cmd: mkcmd.hbase options.yarn_ats_user, """
          export HBASE_CLASSPATH_PREFIX=/usr/hdp/current/hadoop-yarn-timelinereader/timelineservice/*
          hbase --config #{options.ats2_hbase_conf_dir} org.apache.hadoop.yarn.server.timelineservice.storage.TimelineSchemaCreator -create -s
        """
        unless_exec: mkcmd.hbase options.yarn_ats_user, """
          hbase --config #{options.ats2_hbase_conf_dir} shell 2>/dev/null <<< \"list \" | egrep '(flowactivity)+'
        """
    
## Dependencies

    path = require 'path'
    mkcmd = require '../../lib/mkcmd'

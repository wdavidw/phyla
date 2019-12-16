
# Hadoop YARN Timeline Reader Install

The Timeline Reader is a stand-alone server daemon and doesn't need to be
co-located with any other service.

    module.exports = header: 'YARN TR HBase Service RM Install', handler: ({options}) ->
      tmp_dir = "/tmp/hbase_tarball_#{Date.now()}"

## Register

      @registry.register 'hdp_select', '@rybajs/metal/lib/hdp_select'
      @registry.register ['file', 'jaas'], '@rybajs/metal/lib/file_jaas'
      @registry.register ['yarn','service', 'create'], '@rybajs/metal/lib/actions/yarn/service_create'
      @registry.register ['hdfs','put'], '@rybajs/metal/lib/actions/hdfs/put'
      @registry.register ['hdfs','chown'], '@rybajs/metal/lib/actions/hdfs/chown'
      @registry.register ['hdfs','mkdir'], '@rybajs/metal/lib/actions/hdfs/mkdir'      
      @registry.register 'ranger_policy', '@rybajs/metal/ranger/actions/ranger_policy'

## Identities

By default, the "hadoop-yarn-timelineserver" package create the following entries:

```bash
cat /etc/passwd | grep yarn
yarn:x:2403:2403:Hadoop YARN User:/var/lib/hadoop-yarn:/bin/bash
cat /etc/group | grep hadoop
hadoop:x:499:hdfs
```

      @system.group header: 'Hadoop Group', options.hadoop_group
      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user

## Wait

      @call once: true, 'masson/core/krb5_client/wait', options.wait_krb5_client
      @call once: true, '@rybajs/metal/hadoop/hdfs_nn/wait', options.wait_hdfs_nn, conf_dir: '/etc/hadoop/conf'


## Configuration

Update the "hbase-site.xml" and "hbase-env.sh" configuration file.

      @file.types.hfile
        header: 'HBase Site'
        target: "#{options.conf_dir}/hbase-site.xml"
        properties: options.hbase_site
        backup: true
        user: options.ats_user.name
        group: options.hadoop_group.name
      @file.types.hfile
        header: 'HBase Policy'
        target: "#{options.conf_dir}/hbase-policy.xml"
        properties: options.hbase_policy
        backup: true
        user: options.ats_user.name
        group: options.hadoop_group.name
      @file
        header: 'HBase Log4j'
        target: "#{options.conf_dir}/log4j.properties"
        source: "#{__dirname}/../resources/hbase-log4j.properties"
        local: true

# HDFS Layout

      @call
        header: 'HDFS Layout'
        if: options.post_service
      , ->
        @hdfs.mkdir
          header: 'Mkdir HBase root dir'
          nn_url: options.nn_url
          target: "#{options.hbase_site['hbase.rootdir']}"
          owner: 'yarn-ats'
          group: options.hadoop_group.name
          krb5_user: options.hdfs_krb5_user 
          mode: '755'
        @hdfs.put
          header: 'Upload HBase Policy'
          source: "#{options.conf_dir}/hbase-policy.xml"
          target: "/atsv2/hbase-policy.xml"
          nn_url: options.nn_url
          owner: 'yarn-ats'
          group: options.hadoop_group.name
          krb5_user: options.hdfs_krb5_user
        @hdfs.put
          header: 'Upload HBase Site'
          source: "#{options.conf_dir}/hbase-site.xml"
          target: "/atsv2/hbase-site.xml"
          nn_url: options.nn_url
          owner: 'yarn-ats'
          group: options.hadoop_group.name
          krb5_user: options.hdfs_krb5_user
        @hdfs.put
          header: 'Upload HBase Log4j'
          source: "#{options.conf_dir}/log4j.properties"
          target: "/atsv2/log4j.properties"
          nn_url: options.nn_url
          owner: 'yarn-ats'
          group: options.hadoop_group.name
          krb5_user: options.hdfs_krb5_user
        @hdfs.put
          header: 'Upload Core Site'
          source: "/etc/hadoop/conf/core-site.xml"
          target: "/atsv2/core-site.xml"
          nn_url: options.nn_url
          owner: 'yarn-ats'
          group: options.hadoop_group.name
          krb5_user: options.hdfs_krb5_user
    

## YARN ATS kerberos Client Keytab

      @krb5.addprinc options.krb5.admin,
        header: 'Yarn HBase ATS Client Principal'
        principal: options.yarn_ats_user.principal
        password: options.yarn_ats_user.password
        unless: options.hbase_local

      @krb5.ktutil.add options.krb5.admin,
        unless: options.hbase_local
        header: 'Yarn HBase ATS Client Keytab'
        principal: options.yarn_ats_user.principal
        password: options.yarn_ats_user.password
        keytab: options.yarn_ats_user.keytab
        kadmin_server: options.krb5.admin.admin_server
        mode: 0o0640
        uid: options.ats_user.name      
        gid: options.hadoop_group.name      

## Prepare HBase TarBall

      @call
        header: 'HBase TarBall'
        if: options.post_service
        unless_exec: mkcmd.hdfs options.hdfs_krb5_user, "hdfs hdfs -test -f /atsv2/hbase.tar.gz"
      , ->
        @system.mkdir
          target: tmp_dir
        @system.execute
          cmd: """
              version=`hdp-select versions | tail -1`
              #hbase
              cp -rf /usr/hdp/$version/hbase #{tmp_dir}/
              echo yes | mv #{tmp_dir}/hbase/bin/hbase.distro #{tmp_dir}/hbase/bin/hbase
              rm -rf #{tmp_dir}/hbase/conf
              rm -rf #{tmp_dir}/hbase/logs
              rm -rf #{tmp_dir}/hbase/pids
              rm -rf #{tmp_dir}/hbase/lib/zookeeper*.jar
              cp -rf /usr/hdp/$version/zookeeper/zookeeper-*.jar #{tmp_dir}/hbase/lib
              #mapreduce
              cp -rf /usr/hdp/$version/hadoop/mapreduce.tar.gz #{tmp_dir}/
              cd #{tmp_dir}
              tar -xzf mapreduce.tar.gz
              rm -rf mapreduce.tar.gz
              tar -czf hbase.tar.gz hbase hadoop && echo "`date` HBase package created in path $yarn_hbase_user_tmp"
              chmod 644 hbase.tar.gz && echo "`date` hbase.tar.gz has set with ugo=644"
              rm -rf hbase
              rm -rf hadoop
            """
        @hdfs.put
          header: 'Upload HBase TarBall'
          source: "#{tmp_dir}/hbase.tar.gz"
          target: "/atsv2/hbase.tar.gz"
          nn_url: options.nn_url
          krb5_user: options.hdfs_krb5_user

## Dependencies

    mkcmd = require '../../lib/mkcmd'

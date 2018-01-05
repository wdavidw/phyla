
# Oozie Client Check

    module.exports = header: 'Oozie Client Check', handler: (options) ->

## Register

      @registry.register 'ranger_policy', 'ryba/ranger/actions/ranger_policy'

## Wait

      @call 'ryba/oozie/server/wait', once: true, options.wait_oozie_server

## Check Client

      @system.execute
        header: 'Check Client'
        cmd: mkcmd.test options.test_krb5_user, """
        oozie admin -oozie #{options.oozie_site['oozie.base.url']} -status
        """
      , (err, executed, stdout) ->
        throw err if err
        throw new Error "Oozie not ready, got: #{JSON.stringify stdout}" if stdout.trim() isnt 'System mode: NORMAL'

## Check REST

      @system.execute
        header: 'Check REST'
        cmd: mkcmd.test options.test_krb5_user, """
        curl -s -k --negotiate -u : #{options.oozie_site['oozie.base.url']}/v1/admin/status
        """
      , (err, executed, stdout) ->
        throw err if err
        throw new Error "Oozie not ready" if stdout.trim() isnt '{"systemMode":"NORMAL"}'

## Check HDFS Workflow

      @call header: 'Check HDFS Workflow', ->
        @file
          content: """
          nameNode=#{options.hdfs_defaultfs}
          jobTracker=#{options.jobtracker}
          queueName=default
          basedir=${nameNode}/user/#{options.test.user.name}/check-#{options.fqdn}-oozie-fs
          oozie.wf.application.path=${basedir}
          """
          target: "#{options.test.user.home}/check_oozie_fs/job.properties"
          uid: options.test.user.name
          gid: options.test.group.name
          eof: true
        @file
          content: """
          <workflow-app xmlns="uri:oozie:workflow:0.2" name="test-oozie-wf">
            <start to="move"/>
            <action name="move">
              <fs>
                <move source='${basedir}/source' target='${basedir}/target'/>
              </fs>
              <ok to="end"/>
              <error to="fail"/>
            </action>
            <kill name="fail">
                <message>Error message[${wf:errorMessage(wf:lastErrorNode())}]</message>
            </kill>
            <end name="end"/>
          </workflow-app>
          """
          target: "#{options.test.user.home}/check_oozie_fs/workflow.xml"
          uid: options.test.user.name
          gid: options.test.group.name
          eof: true
        @system.execute
          cmd: mkcmd.test options.test_krb5_user, """
          hdfs dfs -rm -r -skipTrash check-#{options.fqdn}-oozie-fs 2>/dev/null
          hdfs dfs -mkdir -p check-#{options.fqdn}-oozie-fs
          hdfs dfs -touchz check-#{options.fqdn}-oozie-fs/source
          hdfs dfs -put -f #{options.test.user.home}/check_oozie_fs/job.properties check-#{options.fqdn}-oozie-fs
          hdfs dfs -put -f #{options.test.user.home}/check_oozie_fs/workflow.xml check-#{options.fqdn}-oozie-fs
          export OOZIE_URL=#{options.oozie_site['oozie.base.url']}
          oozie job -dryrun -config #{options.test.user.home}/check_oozie_fs/job.properties
          jobid=`oozie job -run -config #{options.test.user.home}/check_oozie_fs/job.properties | grep job: | sed 's/job: \\(.*\\)/\\1/'`
          i=0
          while [[ $i -lt 1000 ]] && [[ `oozie job -info $jobid | grep -e '^Status' | sed 's/^Status\\s\\+:\\s\\+\\(.*\\)$/\\1/'` == 'RUNNING' ]]
          do ((i++)); sleep 1; done
          oozie job -info $jobid | grep -e '^Status\\s\\+:\\s\\+SUCCEEDED'
          """
          code_skipped: 2
          unless_exec: unless options.force_check then mkcmd.test options.test_krb5_user, "hdfs dfs -test -f check-#{options.fqdn}-oozie-fs/target"

## Check MapReduce Workflow

      @call header: 'Check MapReduce', ->
        @file
          content: """
          nameNode=#{options.hdfs_defaultfs}
          jobTracker=#{options.jobtracker}
          oozie.libpath=/user/#{options.test.user.name}/share/lib
          queueName=default
          basedir=${nameNode}/user/#{options.test.user.name}/check-#{options.fqdn}-oozie-mr
          oozie.wf.application.path=${basedir}
          oozie.use.system.libpath=true
          """
          target: "#{options.test.user.home}/check_oozie_mr/job.properties"
          uid: options.test.user.name
          gid: options.test.group.name
          eof: true
        @file
          content: """
          <workflow-app name='check-#{options.fqdn}-oozie-mr' xmlns='uri:oozie:workflow:0.4'>
            <start to='test-mr' />
            <action name='test-mr'>
              <map-reduce>
                <job-tracker>${jobTracker}</job-tracker>
                <name-node>${nameNode}</name-node>
                <configuration>
                  <property>
                    <name>mapred.job.queue.name</name>
                    <value>${queueName}</value>
                  </property>
                  <property>
                    <name>mapred.mapper.class</name>
                    <value>org.apache.oozie.example.SampleMapper</value>
                  </property>
                  <property>
                    <name>mapred.reducer.class</name>
                    <value>org.apache.oozie.example.SampleReducer</value>
                  </property>
                  <property>
                    <name>mapred.map.tasks</name>
                    <value>1</value>
                  </property>
                  <property>
                    <name>mapred.input.dir</name>
                    <value>/user/${wf:user()}/check-#{options.fqdn}-oozie-mr/input</value>
                  </property>
                  <property>
                    <name>mapred.output.dir</name>
                    <value>/user/${wf:user()}/check-#{options.fqdn}-oozie-mr/output</value>
                  </property>
                </configuration>
              </map-reduce>
              <ok to="end" />
              <error to="fail" />
            </action>
            <kill name="fail">
              <message>MapReduce failed, error message[${wf:errorMessage(wf:lastErrorNode())}]</message>
            </kill>
            <end name='end' />
          </workflow-app>
          """
          target: "#{options.test.user.home}/check_oozie_mr/workflow.xml"
          uid: options.test.user.name
          gid: options.test.group.name
          eof: true
        @system.execute
          cmd: mkcmd.test options.test_krb5_user, """
          # Prepare HDFS
          hdfs dfs -rm -r -skipTrash check-#{options.fqdn}-oozie-mr 2>/dev/null
          hdfs dfs -mkdir -p check-#{options.fqdn}-oozie-mr/input
          echo -e 'a,1\\nb,2\\nc,3' | hdfs dfs -put - check-#{options.fqdn}-oozie-mr/input/data
          hdfs dfs -put -f #{options.test.user.home}/check_oozie_mr/workflow.xml check-#{options.fqdn}-oozie-mr
          # Extract Examples
          if [ ! -d /var/tmp/oozie-examples ]; then
            mkdir /var/tmp/oozie-examples
            tar xzf /usr/hdp/current/oozie-client/doc/oozie-examples.tar.gz -C /var/tmp/oozie-examples
          fi
          hdfs dfs -put /var/tmp/oozie-examples/examples/apps/map-reduce/lib check-#{options.fqdn}-oozie-mr
          # Run Oozie
          export OOZIE_URL=#{options.oozie_site['oozie.base.url']}
          oozie job -dryrun -config #{options.test.user.home}/check_oozie_mr/job.properties
          jobid=`oozie job -run -config #{options.test.user.home}/check_oozie_mr/job.properties | grep job: | sed 's/job: \\(.*\\)/\\1/'`
          # Check Job
          i=0
          echo $jobid
          while [[ $i -lt 1000 ]] && [[ `oozie job -info $jobid | grep -e '^Status' | sed 's/^Status\\s\\+:\\s\\+\\(.*\\)$/\\1/'` == 'RUNNING' ]]
          do ((i++)); sleep 1; done
          oozie job -info $jobid | grep -e '^Status\\s\\+:\\s\\+SUCCEEDED'
          """
          trap: false # or while loop will exit on first run
          unless_exec: unless options.force_check then mkcmd.test options.test_krb5_user, "hdfs dfs -test -f check-#{options.fqdn}-oozie-mr/output/_SUCCESS"

## Check Pig Workflow

      @call header: 'Check Pig Workflow', ->
        @file
          content: """
          nameNode=#{options.hdfs_defaultfs}
          jobTracker=#{options.jobtracker}
          oozie.libpath=/user/#{options.test.user.name}/share/lib
          queueName=default
          basedir=${nameNode}/user/#{options.test.user.name}/check-#{options.fqdn}-oozie-pig
          oozie.wf.application.path=${basedir}
          oozie.use.system.libpath=true
          """
          target: "#{options.test.user.home}/check_oozie_pig/job.properties"
          uid: options.test.user.name
          gid: options.test.group.name
          eof: true
        @file
          content: """
          <workflow-app name='check-#{options.fqdn}-oozie-pig' xmlns='uri:oozie:workflow:0.4'>
            <start to='test-pig' />
            <action name='test-pig'>
              <pig>
                <job-tracker>${jobTracker}</job-tracker>
                <name-node>${nameNode}</name-node>
                <configuration>
                  <property>
                    <name>mapred.compress.map.output</name>
                    <value>true</value>
                  </property>
                  <property>
                    <name>mapred.job.queue.name</name>
                    <value>${queueName}</value>
                  </property>
                </configuration>
                <script>wordcount.pig</script>
                <param>INPUT=/user/${wf:user()}/check-#{options.fqdn}-oozie-pig/input</param>
                <param>OUTPUT=/user/${wf:user()}/check-#{options.fqdn}-oozie-pig/output</param>
              </pig>
              <ok to="end" />
              <error to="fail" />
            </action>
            <kill name="fail">
              <message>Pig failed, error message[${wf:errorMessage(wf:lastErrorNode())}]</message>
            </kill>
            <end name='end' />
          </workflow-app>
          """
          target: "#{options.test.user.home}/check_oozie_pig/workflow.xml"
          uid: options.test.user.name
          gid: options.test.group.name
          eof: true
        @file
          content: """
          A = load '$INPUT';
          B = foreach A generate flatten(TOKENIZE((chararray)$0)) as word;
          C = group B by word;
          D = foreach C generate COUNT(B), group;
          store D into '$OUTPUT' USING PigStorage();
          """
          target: "#{options.test.user.home}/check_oozie_pig/wordcount.pig"
          uid: options.test.user.name
          gid: options.test.group.name
          eof: true
        @system.execute
          cmd: mkcmd.test options.test_krb5_user, """
          hdfs dfs -rm -r -skipTrash check-#{options.fqdn}-oozie-pig 2>/dev/null
          hdfs dfs -mkdir -p check-#{options.fqdn}-oozie-pig/input
          echo -e 'a,1\\nb,2\\nc,3' | hdfs dfs -put - check-#{options.fqdn}-oozie-pig/input/data
          hdfs dfs -put -f #{options.test.user.home}/check_oozie_pig/workflow.xml check-#{options.fqdn}-oozie-pig
          hdfs dfs -put -f #{options.test.user.home}/check_oozie_pig/wordcount.pig check-#{options.fqdn}-oozie-pig
          export OOZIE_URL=#{options.oozie_site['oozie.base.url']}
          oozie job -dryrun -config #{options.test.user.home}/check_oozie_pig/job.properties
          jobid=`oozie job -run -config #{options.test.user.home}/check_oozie_pig/job.properties | grep job: | sed 's/job: \\(.*\\)/\\1/'`
          i=0
          echo $jobid
          while [[ $i -lt 1000 ]] && [[ `oozie job -info $jobid | grep -e '^Status' | sed 's/^Status\\s\\+:\\s\\+\\(.*\\)$/\\1/'` == 'RUNNING' ]]
          do ((i++)); sleep 1; done
          oozie job -info $jobid | grep -e '^Status\\s\\+:\\s\\+SUCCEEDED'
          """
          trap: false # or while loop will exit on first run
          unless_exec: unless options.force_check then mkcmd.test options.test_krb5_user, "hdfs dfs -test -f check-#{options.fqdn}-oozie-pig/output/_SUCCESS"

## Check HCat Workflow

      @call header: 'Check HCat Workflow', if: options.test.hive_hcat, ->
        @file
          content: """
          nameNode=#{options.hdfs_defaultfs}
          jobTracker=#{options.jobtracker}
          oozie.libpath=/user/#{options.test.user.name}/share/lib
          queueName=default
          basedir=${nameNode}/user/#{options.test.user.name}/check-#{options.fqdn}-oozie-pig-hcat
          oozie.wf.application.path=${basedir}
          oozie.use.system.libpath=true
          """
          target: "#{options.test.user.home}/check_oozie_hcat/job.properties"
          uid: options.test.user.name
          gid: options.test.group.name
          eof: true
        @file
          content: """
          <workflow-app name='check-#{options.fqdn}-oozie-pig-hcat' xmlns='uri:oozie:workflow:0.4'>
            <credentials>
              <credential name='hive_credentials' type='hcat'>
                <property>
                  <name>hcat.metastore.uri</name>
                  <value>#{options.hive_hcat_uris}</value>
                </property>
                <property>
                  <name>hcat.metastore.principal</name>
                  <value>#{options.hive_hcat_principal}</value>
                </property>
              </credential>
            </credentials>
            <start to='test-pig-hcat' />
            <action name='test-pig-hcat' cred="hive_credentials">
              <pig>
                <job-tracker>${jobTracker}</job-tracker>
                <name-node>${nameNode}</name-node>
                <configuration>
                  <property>
                    <name>mapred.compress.map.output</name>
                    <value>true</value>
                  </property>
                  <property>
                    <name>mapred.job.queue.name</name>
                    <value>${queueName}</value>
                  </property>
                </configuration>
                <script>wordcount.pig</script>
                <param>INPUT=/user/${wf:user()}/check-#{options.fqdn}-oozie-pig-hcat/input</param>
                <param>OUTPUT=/user/${wf:user()}/check-#{options.fqdn}-oozie-pig-hcat/output</param>
              </pig>
              <ok to="end" />
              <error to="fail" />
            </action>
            <kill name="fail">
              <message>Pig failed, error message[${wf:errorMessage(wf:lastErrorNode())}]</message>
            </kill>
            <end name='end' />
          </workflow-app>
          """
          target: "#{options.test.user.home}/check_oozie_hcat/workflow.xml"
          uid: options.test.user.name
          gid: options.test.group.name
          eof: true
        @file
          content: """
          A = load '$INPUT';
          B = foreach A generate flatten(TOKENIZE((chararray)$0)) as word;
          C = group B by word;
          D = foreach C generate COUNT(B), group;
          store D into '$OUTPUT' USING PigStorage();
          """
          target: "#{options.test.user.home}/check_oozie_hcat/wordcount.pig"
          uid: options.test.user.name
          gid: options.test.group.name
          eof: true
        @system.execute
          cmd: mkcmd.test options.test_krb5_user, """
          hdfs dfs -rm -r -skipTrash check-#{options.fqdn}-oozie-pig-hcat 2>/dev/null
          hdfs dfs -mkdir -p check-#{options.fqdn}-oozie-pig-hcat/input
          echo -e 'a,1\\nb,2\\nc,3' | hdfs dfs -put - check-#{options.fqdn}-oozie-pig-hcat/input/data
          hdfs dfs -put -f #{options.test.user.home}/check_oozie_hcat/workflow.xml check-#{options.fqdn}-oozie-pig-hcat
          hdfs dfs -put -f #{options.test.user.home}/check_oozie_hcat/wordcount.pig check-#{options.fqdn}-oozie-pig-hcat
          export OOZIE_URL=#{options.oozie_site['oozie.base.url']}
          oozie job -dryrun -config #{options.test.user.home}/check_oozie_hcat/job.properties
          jobid=`oozie job -run -config #{options.test.user.home}/check_oozie_hcat/job.properties | grep job: | sed 's/job: \\(.*\\)/\\1/'`
          i=0
          echo $jobid
          while [[ $i -lt 1000 ]] && [[ `oozie job -info $jobid | grep -e '^Status' | sed 's/^Status\\s\\+:\\s\\+\\(.*\\)$/\\1/'` == 'RUNNING' ]]
          do ((i++)); sleep 1; done
          oozie job -info $jobid | grep -e '^Status\\s\\+:\\s\\+SUCCEEDED'
          """
          trap: false # or while loop will exit on first run
          unless_exec: unless options.force_check then mkcmd.test options.test_krb5_user, "hdfs dfs -test -d check-#{options.fqdn}-oozie-pig-hcat/output"

## Check Hive2 Workflow
From HDP 2.5 Hive action becomes deprecated against hive2 actions. As hive2 action use jdbc connection to communicate
with hiveserver2. It enables Ranger policies to be applied same way whatever the client.

      @call
        header: 'Ranger Policy'
        if: !!options.ranger_admin
      , ->
        # Wait for Ranger admin to be started
        @call 'ryba/ranger/admin/wait', once: true, options.wait_ranger_admin
        # Prepare the list of databases
        dbs = []
        for hive_server2 in options.hive_server2
          dbs.push "check_#{options.fqdn}_server2_#{hive_server2.hostname}"
          dbs.push "check_#{options.fqdn}_oozie_hs2_nozk_#{hive_server2.hostname}"
        @wait.execute
          header: 'Wait Service'
          cmd: """
          curl --fail -H \"Content-Type: application/json\" -k -X GET  \
            -u #{options.ranger_admin.username}:#{options.ranger_admin.password} \
            \"#{options.ranger_install['POLICY_MGR_URL']}/service/public/v2/api/service/name/#{options.ranger_install['REPOSITORY_NAME']}\"
          """
          code_skipped: [1, 7, 22] # 22 is for 404 not found, 7 is for not connected to host
        @ranger_policy
          header: 'Create'
          username: options.ranger_admin.username
          password: options.ranger_admin.password
          url: options.ranger_install['POLICY_MGR_URL']
          policy:
            'name': "ryba-check-oozie-#{options.fqdn}"
            'description': 'Ryba policy used to check the Oozie client service'
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

      @call header: 'Check Hive2 Workflow (No ZK)', ->
        # Constructs Hiveserver2 jdbc url
        for hive_server2 in options.hive_server2
          db = "check_#{options.fqdn}_oozie_hs2_nozk_#{hive_server2.hostname}"
          port = if hive_server2.hive_site['hive.server2.transport.mode'] is 'http'
          then hive_server2.hive_site['hive.server2.thrift.http.port']
          else hive_server2.hive_site['hive.server2.thrift.port']
          principal = hive_server2.hive_site['hive.server2.authentication.kerberos.principal']
          url = "jdbc:hive2://#{hive_server2.fqdn}:#{port}/default"
          if hive_server2.hive_site['hive.server2.use.SSL'] is 'true'
            url += ";ssl=true"
            url += ";sslTrustStore=#{options.ssl_client['ssl.client.truststore.location']}"
            url += ";trustStorePassword=#{options.ssl_client['ssl.client.truststore.password']}"
          if hive_server2.hive_site['hive.server2.transport.mode'] is 'http'
            url += ";transportMode=#{hive_server2.hive_site['hive.server2.transport.mode']}"
            url += ";httpPath=#{hive_server2.hive_site['hive.server2.thrift.http.path']}"
          workflow_dir = "check-#{options.fqdn}-oozie-hive2-#{hive_server2.hostname}"
          app_name = "check-#{options.fqdn}-oozie-hive2-#{hive_server2.hostname}"
          @file
            content: """
            nameNode=#{options.hdfs_defaultfs}
            jobTracker=#{options.jobtracker}
            oozie.libpath=/user/#{options.test.user.name}/share/lib
            queueName=default
            basedir=${nameNode}/user/#{options.test.user.name}/#{workflow_dir}
            oozie.wf.application.path=${basedir}
            oozie.use.system.libpath=true
            jdbcURL=#{url}
            principal=#{principal}
            """
            target: "#{options.test.user.home}/#{workflow_dir}/job.properties"
            uid: options.test.user.name
            gid: options.test.group.name
            eof: true
          @file
            content: """
            <workflow-app name='#{app_name}' xmlns='uri:oozie:workflow:0.4'>
              <credentials>
                <credential name='hive2_credentials' type='hive2'>
                  <property>
                    <name>hive2.jdbc.url</name>
                    <value>${jdbcURL}</value>
                  </property>
                  <property>
                    <name>hive2.server.principal</name>
                    <value>${principal}</value>
                  </property>
                </credential>
              </credentials>
              <start to='test-hive2' />
              <action name='test-hive2' cred="hive2_credentials">
                <hive2 xmlns="uri:oozie:hive2-action:0.1">
                  <job-tracker>${jobTracker}</job-tracker>
                  <name-node>${nameNode}</name-node>
                  <prepare>
                    <delete path="${nameNode}/user/${wf:user()}/#{workflow_dir}/second_table"/>
                  </prepare>
                  <configuration>
                    <property>
                      <name>mapred.job.queue.name</name>
                      <value>${queueName}</value>
                    </property>
                  </configuration>
                  <jdbc-url>${jdbcURL}</jdbc-url>
                  <script>hive.q</script>
                  <param>INPUT=/user/${wf:user()}/#{db}/first_table</param>
                  <param>OUTPUT=/user/${wf:user()}/#{db}/second_table</param>
                  <file>/user/ryba/#{workflow_dir}/truststore#truststore</file>
                </hive2>
                <ok to="end" />
                <error to="fail" />
              </action>
              <kill name="fail">
                <message>Hive2 (Beeline) action failed, error message[${wf:errorMessage(wf:lastErrorNode())}]</message>
              </kill>
              <end name='end' />
            </workflow-app>
            """
            target: "#{options.test.user.home}/#{workflow_dir}/workflow.xml"
            uid: options.test.user.name
            gid: options.test.group.name
            eof: true
          @file
            content: """
            DROP TABLE IF EXISTS #{db}.first_table;
            DROP DATABASE IF EXISTS #{db};
            CREATE DATABASE IF NOT EXISTS #{db} LOCATION '/user/#{options.test.user.name}/#{db}';
            USE #{db};
            CREATE EXTERNAL TABLE first_table (mynumber INT) STORED AS TEXTFILE LOCATION '${INPUT}';
            select SUM(mynumber) from first_table;
            INSERT OVERWRITE DIRECTORY '${OUTPUT}' SELECT * FROM first_table;
            """
            target: "#{options.test.user.home}/#{workflow_dir}/hive.q"
            uid: options.test.user.name
            gid: options.test.group.name
            eof: true
          @system.execute
            cmd: mkcmd.test options.test_krb5_user, """
            hdfs dfs -rm -r -skipTrash #{workflow_dir} 2>/dev/null
            hdfs dfs -mkdir -p #{workflow_dir}/first_table
            echo -e '1\\n2\\n3' | hdfs dfs -put - #{db}/first_table/data
            hdfs dfs -put -f #{options.test.user.home}/#{workflow_dir}/workflow.xml #{workflow_dir}
            hdfs dfs -put -f #{options.test.user.home}/#{workflow_dir}/hive.q #{workflow_dir}
            hdfs dfs -put -f /etc/hive/conf/truststore #{workflow_dir}
            echo "Run job"
            export OOZIE_URL=#{options.oozie_site['oozie.base.url']}
            oozie job -dryrun -config #{options.test.user.home}/#{workflow_dir}/job.properties
            jobid=`oozie job -run -config #{options.test.user.home}/#{workflow_dir}/job.properties | grep job: | sed 's/job: \\(.*\\)/\\1/'`
            i=0
            echo "Job ID: $jobid"
            echo "Wait"
            while [[ $i -lt 1000 ]] && [[ `oozie job -info $jobid | grep -e '^Status' | sed 's/^Status\\s\\+:\\s\\+\\(.*\\)$/\\1/'` == 'RUNNING' ]]
            do ((i++)); sleep 1; done
            echo "Print Status"
            oozie job -info $jobid | grep -e '^Status\\s\\+:\\s\\+SUCCEEDED'
            """
            retry: 3
            trap: false # or while loop will exit on first run
            unless_exec: unless options.force_check then mkcmd.test options.test_krb5_user, "hdfs dfs -test -d /user/#{options.test.user.name}/#{db}/first_table"

## Check Spark Workflow

      @call header: 'Check Spark', ->
        @file
          content: """
          nameNode=#{options.hdfs_defaultfs}
          jobTracker=#{options.jobtracker}
          oozie.libpath=/user/#{options.test.user.name}/share/lib
          queueName=default
          basedir=${nameNode}/user/#{options.test.user.name}/check-#{options.fqdn}-oozie-spark
          oozie.wf.application.path=${basedir}
          oozie.use.system.libpath=true
          master=yarn-cluster
          """
          target: "#{options.test.user.home}/check_oozie_spark/job.properties"
          uid: options.test.user.name
          gid: options.test.group.name
          eof: true
        @file
          content: """
          <workflow-app name='check-#{options.fqdn}-oozie-spark' xmlns='uri:oozie:workflow:0.4'>
            <start to='test-spark' />
            <action name='test-spark'>
              <spark xmlns="uri:oozie:spark-action:0.1">
                <job-tracker>${jobTracker}</job-tracker>
                <name-node>${nameNode}</name-node>
                <prepare>
                  <delete path="${nameNode}/user/${wf:user()}/check-#{options.fqdn}-oozie-spark/output"/>
                </prepare>
                <master>${master}</master>
                <mode>cluster</mode>
                <name>Spark-FileCopy</name>
                <class>org.apache.oozie.example.SparkFileCopy</class>
                <jar>${nameNode}/user/${wf:user()}/check-#{options.fqdn}-oozie-spark/lib/oozie-examples.jar</jar>
                <spark-opts>--conf spark.ui.view.acls=* --executor-memory 512m --num-executors 1 --executor-cores 1 --driver-memory 512m</spark-opts>
                <arg>${nameNode}/user/${wf:user()}/check-#{options.fqdn}-oozie-spark/input/data.txt</arg>
                <arg>${nameNode}/user/${wf:user()}/check-#{options.fqdn}-oozie-spark/output</arg>
              </spark>
              <ok to="end" />
              <error to="fail" />
            </action>
            <kill name="fail">
              <message>Spark failed, error message[${wf:errorMessage(wf:lastErrorNode())}]</message>
            </kill>
            <end name='end' />
          </workflow-app>
          """
          target: "#{options.test.user.home}/check_oozie_spark/workflow.xml"
          uid: options.test.user.name
          gid: options.test.group.name
          eof: true
        @system.execute
          cmd: mkcmd.test options.test_krb5_user, """
          # Prepare HDFS
          hdfs dfs -rm -r -skipTrash check-#{options.fqdn}-oozie-spark 2>/dev/null
          hdfs dfs -mkdir -p check-#{options.fqdn}-oozie-spark/input
          echo -e 'a,1\\nb,2\\nc,3' | hdfs dfs -put - check-#{options.fqdn}-oozie-spark/input/data.txt
          hdfs dfs -put -f #{options.test.user.home}/check_oozie_spark/workflow.xml check-#{options.fqdn}-oozie-spark
          # Extract Examples
          if [ ! -d /var/tmp/oozie-examples ]; then
            mkdir /var/tmp/oozie-examples
            tar xzf /usr/hdp/current/oozie-client/doc/oozie-examples.tar.gz -C /var/tmp/oozie-examples
          fi
          hdfs dfs -put /var/tmp/oozie-examples/examples/apps/spark/lib check-#{options.fqdn}-oozie-spark
          # Run Oozie
          export OOZIE_URL=#{options.oozie_site['oozie.base.url']}
          oozie job -dryrun -config #{options.test.user.home}/check_oozie_spark/job.properties
          jobid=`oozie job -run -config #{options.test.user.home}/check_oozie_spark/job.properties | grep job: | sed 's/job: \\(.*\\)/\\1/'`
          # Check Job
          i=0
          echo $jobid
          while [[ $i -lt 1000 ]] && [[ `oozie job -info $jobid | grep -e '^Status' | sed 's/^Status\\s\\+:\\s\\+\\(.*\\)$/\\1/'` == 'RUNNING' ]]
          do ((i++)); sleep 1; done
          oozie job -info $jobid | grep -e '^Status\\s\\+:\\s\\+SUCCEEDED'
          """
          trap: false # or while loop will exit on first run
          unless_exec: unless options.force_check then mkcmd.test options.test_krb5_user, "hdfs dfs -test -f check-#{options.fqdn}-oozie-spark/output/_SUCCESS"

# Module Dependencies

    url = require 'url'
    mkcmd = require '../../lib/mkcmd'

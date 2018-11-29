
# Hive Beeline Check

This module check the Hive Server2 servers using the `beeline` command.

    module.exports =  header: 'Hive Beeline Check', handler: ({options}) ->

## Register

      @registry.register 'ranger_policy', 'ryba/ranger/actions/ranger_policy'

## Wait

      @call 'ryba/hive/server2/wait', once: true, options.wait_hive_server2
      @call 'ryba/spark2/thrift_server/wait', once: true, options.wait_spark_thrift_server if options.wait_spark_thrift_server

## Add Ranger Policy

Create the policy to run the checks. The policy can be accessed from the command
line with: 

```
curl --fail -k -X GET -H "Content-Type: application/json" \
-u admin:rangerAdmin123 \
"https://master03.metal.ryba:6182/service/public/v2/api/service/hadoop-ryba-hive/policy/ryba-check-edge01"
```

      @call
        header: 'Ranger Policy'
        if: !!options.ranger_admin
      , ->
        # Wait for Ranger admin to be started
        @call 'ryba/ranger/admin/wait', once: true, options.wait_ranger_admin
        # Prepare the list of databases
        dbs = []
        dirs = [] 
        for hive_server2 in options.hive_server2
          dirs.push "check-#{options.hostname}-hive_server2-#{hive_server2.hostname}"
          dirs.push "check-#{options.hostname}-hive_server2-zoo-#{hive_server2.hive_site['hive.server2.zookeeper.namespace']}"
          dbs.push "check_#{options.hostname}_server2_#{hive_server2.hostname}"
          dbs.push "check_#{options.hostname}_hs2_zoo_#{hive_server2.hive_site['hive.server2.zookeeper.namespace']}"
        for spark_thrift_server in options.spark_thrift_server
          dbs.push "check_#{options.hostname}_spark_sql_server_#{spark_thrift_server.hostname}"
        @wait.execute
          header: 'Wait Service'
          cmd: """
          curl --fail -H \"Content-Type: application/json\" -k -X GET  \
            -u #{options.ranger_admin.username}:#{options.ranger_admin.password} \
            \"#{options.ranger_hive_install['POLICY_MGR_URL']}/service/public/v2/api/service/name/#{options.ranger_hive_install['REPOSITORY_NAME']}\"
          """
          code_skipped: [1, 7, 22] # 22 is for 404 not found, 7 is for not connected to host
        @ranger_policy
          header: 'Create hive Policy'
          username: options.ranger_admin.username
          password: options.ranger_admin.password
          url: options.ranger_hive_install['POLICY_MGR_URL']
          policy:
            'name': "ryba-check-#{options.hostname}"
            'description': 'Ryba policy used to check the beeline service'
            'service': options.ranger_hive_install['REPOSITORY_NAME']
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
              'users': [options.test.user.name, options.user.name]
              'groups': []
              'conditions': []
              'delegateAdmin': false
            ]
        @ranger_policy
          header: 'Create HDFS Policy'
          username: options.ranger_admin.username
          password: options.ranger_admin.password
          url: options.ranger_hive_install['POLICY_MGR_URL']
          policy:
            'name': "ryba-check-#{options.hostname}"
            'description': 'Ryba policy used to check the beeline service'
            'service': options.ranger_hdfs_install['REPOSITORY_NAME']
            'isEnabled': true
            'isAuditEnabled': true
            'resources':
              'path':
                'isRecursive': 'true'
                'values': dirs
                'isExcludes': false
            'policyItems': [
              'users': ["#{options.user.name}"]
              'groups': []
              'delegateAdmin': true
              'accesses': [
                  "isAllowed": true
                  "type": "read"
              ,
                  "isAllowed": true
                  "type": "write"
              ,
                  "isAllowed": true
                  "type": "execute"
              ]
              'conditions': []
            ]

## Check Server2

Use the [Beeline][beeline] JDBC client to execute SQL queries.

```
/usr/bin/beeline -d "org.apache.hive.jdbc.HiveDriver" -u "jdbc:hive2://{fqdn}:10001/;principal=hive/{fqdn}@{realm}"
```

The JDBC url may be provided inside the "-u" option or after the "!connect"
directive once you enter the beeline shell.

      @call
        header: 'Server2 (no ZK)'
      , ->
        for hive_server2 in options.hive_server2
          directory = "check-#{options.hostname}-hive_server2-#{hive_server2.hostname}"
          db = "check_#{options.hostname}_server2_#{hive_server2.hostname}"
          port = if hive_server2.hive_site['hive.server2.transport.mode'] is 'http'
          then hive_server2.hive_site['hive.server2.thrift.http.port']
          else hive_server2.hive_site['hive.server2.thrift.port']
          principal = hive_server2.hive_site['hive.server2.authentication.kerberos.principal']
          url = "jdbc:hive2://#{hive_server2.fqdn}:#{port}/default;principal=#{principal}"
          if hive_server2.hive_site['hive.server2.use.SSL'] is 'true'
            url += ";ssl=true"
            url += ";sslTrustStore=#{options.truststore_location}"
            url += ";trustStorePassword=#{options.truststore_password}"
          if hive_server2.hive_site['hive.server2.transport.mode'] is 'http'
            url += ";transportMode=#{hive_server2.hive_site['hive.server2.transport.mode']}"
            url += ";httpPath=#{hive_server2.hive_site['hive.server2.thrift.http.path']}"
          beeline = "beeline -u \"#{url}\" --silent=true "
          @system.execute
            cmd: mkcmd.test options.test_krb5_user, """
            hdfs dfs -rm -r -f -skipTrash #{directory} || true
            hdfs dfs -mkdir -p #{directory}/my_db/my_table || true
            echo -e 'a,1\\nb,2\\nc,3' | hdfs dfs -put - #{directory}/my_db/my_table/data
            #{beeline} \
            -e "DROP TABLE IF EXISTS #{db}.my_table;" \
            -e "DROP DATABASE IF EXISTS #{db};" \
            -e "CREATE DATABASE IF NOT EXISTS #{db} LOCATION '/user/#{options.test.user.name}/#{directory}/my_db'" \
            -e "CREATE TABLE IF NOT EXISTS #{db}.my_table(col1 STRING, col2 INT) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',';"
            #{beeline} \
            -e "SELECT SUM(col2) FROM #{db}.my_table;" | hdfs dfs -put - #{directory}/result
            #{beeline} \
            -e "DROP TABLE #{db}.my_table;" \
            -e "DROP DATABASE #{db};"
            """
            unless_exec: unless options.force_check then mkcmd.test options.test_krb5_user, "hdfs dfs -test -f #{directory}/result"
            trap: true
            retry: 3

      @call
        header: 'Server2 (with ZK)'
        if: -> options.hive_server2.length > 1
      , ->
        urls = options.hive_server2
        .map (hive_server2) ->
          quorum = hive_server2.hive_site['hive.zookeeper.quorum']
          namespace = hive_server2.hive_site['hive.server2.zookeeper.namespace']
          principal = hive_server2.hive_site['hive.server2.authentication.kerberos.principal']
          url = "jdbc:hive2://#{quorum}/;principal=#{principal};serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=#{namespace}"
          if hive_server2.hive_site['hive.server2.use.SSL'] is 'true'
            url += ";ssl=true"
            url += ";sslTrustStore=#{options.truststore_location}"
            url += ";trustStorePassword=#{options.truststore_password}"
          if hive_server2.hive_site['hive.server2.transport.mode'] is 'http'
            url += ";transportMode=#{hive_server2.hive_site['hive.server2.transport.mode']}"
            url += ";httpPath=#{hive_server2.hive_site['hive.server2.thrift.http.path']}"
          url
        .sort()
        .filter (c) ->
          p = current; current = c; p isnt c
        for url in urls
          namespace = /zooKeeperNamespace=(.*?)(;|$)/.exec(url)[1]
          directory = "check-#{options.hostname}-hive_server2-zoo-#{namespace}"
          db = "check_#{options.hostname}_hs2_zoo_#{namespace}"
          @system.execute
            cmd: mkcmd.test options.test_krb5_user, """
            hdfs dfs -rm -r -f -skipTrash #{directory} || true
            hdfs dfs -mkdir -p #{directory}/my_db/my_table || true
            echo -e 'a,1\\nb,2\\nc,3' | hdfs dfs -put - #{directory}/my_db/my_table/data
            beeline -u \"#{url}\" --silent=true  \
            -e "DROP TABLE IF EXISTS #{db}.my_table;" \
            -e "DROP DATABASE IF EXISTS #{db};" \
            -e "CREATE DATABASE IF NOT EXISTS #{db} LOCATION '/user/#{options.test.user.name}/#{directory}/my_db'" \
            -e "CREATE TABLE IF NOT EXISTS #{db}.my_table(col1 STRING, col2 INT) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',';"
            beeline -u \"#{url}\" --silent=true  \
            -e "SELECT SUM(col2) FROM #{db}.my_table;" | hdfs dfs -put - #{directory}/result
            beeline -u \"#{url}\" --silent=true  \
            -e "DROP TABLE #{db}.my_table;" \
            -e "DROP DATABASE #{db};"
            """
            unless_exec: unless options.force_check then mkcmd.test options.test_krb5_user, "hdfs dfs -test -f #{directory}/result"
            trap: true

## Check Sparl SQL Thrift Server

      
      @call
        header: 'Spark SQL Thrift Server'
        if: options.spark_thrift_server.length
      , ->
        for spark_thrift_server in options.spark_thrift_server
          directory = "check-#{options.hostname}-spark-sql-server-#{spark_thrift_server.hostname}"
          db = "check_#{options.hostname}_spark_sql_server_#{spark_thrift_server.hostname}"
          port = if spark_thrift_server.hive_site['hive.server2.transport.mode'] is 'http'
          then spark_thrift_server.hive_site['hive.server2.thrift.http.port']
          else spark_thrift_server.hive_site['hive.server2.thrift.port']
          principal = spark_thrift_server.hive_site['hive.server2.authentication.kerberos.principal']
          url = "jdbc:hive2://#{spark_thrift_server.fqdn}:#{port}/default;principal=#{principal}"
          if spark_thrift_server.hive_site['hive.server2.use.SSL'] is 'true'
            url += ";ssl=true"
            url += ";sslTrustStore=#{options.truststore_location}"
            url += ";trustStorePassword=#{options.truststore_password}"
          if spark_thrift_server.hive_site['hive.server2.transport.mode'] is 'http'
            url += ";transportMode=#{spark_thrift_server.hive_site['hive.server2.transport.mode']}"
            url += ";httpPath=#{spark_thrift_server.hive_site['hive.server2.thrift.http.path']}"
          beeline = "beeline -u \"#{url}\" --silent=true "
          @system.execute
            cmd: mkcmd.test options.test_krb5_user, """
            hdfs dfs -rm -r -f -skipTrash #{directory} || true
            hdfs dfs -mkdir -p #{directory}/my_db/my_table || true
            echo -e 'a,1\\nb,2\\nc,3' | hdfs dfs -put - #{directory}/my_db/my_table/data
            #{beeline} \
            -e "DROP TABLE IF EXISTS #{db}.my_table;" \
            -e "DROP DATABASE IF EXISTS #{db};" \
            -e "CREATE DATABASE IF NOT EXISTS #{db} LOCATION '/user/#{options.test.user.name}/#{directory}/my_db'" \
            -e "CREATE TABLE IF NOT EXISTS #{db}.my_table(col1 STRING, col2 INT) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',';"
            #{beeline} \
            -e "SELECT SUM(col2) FROM #{db}.my_table;" | hdfs dfs -put - #{directory}/result
            #{beeline} \
            -e "DROP TABLE #{db}.my_table;" \
            -e "DROP DATABASE #{db};"
            """
            unless_exec: unless options.force_check then mkcmd.test options.test_krb5_user, "hdfs dfs -test -f #{directory}/result"
            trap: true

## Dependencies

    mkcmd = require '../../lib/mkcmd'

[hivecli]: https://cwiki.apache.org/confluence/display/Hive/LanguageManual+Cli
[beeline]: https://cwiki.apache.org/confluence/display/Hive/HiveServer2+Clients#HiveServer2Clients-Beeline%E2%80%93NewCommandLineShell

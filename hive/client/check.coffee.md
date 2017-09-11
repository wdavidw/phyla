
# Hive Client Check

This module check the HCatalog server using the `hive` command.

Debug mode in the "hive" command is activated with the "hive.root.logger"
parameter:

```
hive -hiveconf hive.root.logger=DEBUG,console
```

    module.exports =  header: 'Hive Client Check', label_true: 'CHECKED', handler: (options) ->

## Wait

      @call 'ryba/hive/hcatalog/wait', once: true, options.wait_hive_hcatalog
      @call 'ryba/ranger/admin/wait', once: true, options.wait_ranger_admin if options.wait_ranger_admin

## Add Ranger Policy 
hive client is communicating directly with hcatalog, which means that on a ranger
managed cluster, ACL must be set on HDFS an not on hive.

      @call
        header: 'HDFS Policy'
        if: !!options.ranger_admin
      , ->
        name = "Ranger-Ryba-HDFS-Policy-#{options.hostname}-client"
        dbs = []
        directories = []
        for hive_hcatalog in options.hive_hcatalog
          directories.push "check-#{options.hostname}-hive_hcatalog_mr-#{hive_hcatalog.hostname}"
          directories.push "check-#{options.hostname}-hive_hcatalog_tez-#{hive_hcatalog.hostname}"
        hdfs_policy =
          name: "#{name}"
          service: "#{options.ranger_hdfs_install['REPOSITORY_NAME']}"
          repositoryType:"hdfs"
          description: 'Hive Client Check'
          isEnabled: true
          isAuditEnabled: true
          resources:
            path:
              isRecursive: 'true'
              values: directories
              isExcludes: false
          policyItems: [{
            users: ["#{options.test.user.name}"]
            groups: []
            delegateAdmin: true
            accesses:[
                "isAllowed": true
                "type": "read"
            ,
                "isAllowed": true
                "type": "write"
            ,
                "isAllowed": true
                "type": "execute"
            ]
            conditions: []
            }]
        @system.execute
          cmd: """
          curl --fail -H "Content-Type: application/json" -k -X POST \
            -d '#{JSON.stringify hdfs_policy}' \
            -u #{options.ranger_admin.username}:#{options.ranger_admin.password} \
            \"#{options.ranger_hdfs_install['POLICY_MGR_URL']}/service/public/v2/api/policy\"
          """
          unless_exec: """
          curl --fail -H \"Content-Type: application/json\" -k -X GET  \
            -u #{options.ranger_admin.username}:#{options.ranger_admin.password} \
            \"#{options.ranger_hdfs_install['POLICY_MGR_URL']}/service/public/v2/api/service/#{options.ranger_hdfs_install['REPOSITORY_NAME']}/policy/#{hdfs_policy.name}"
          """
          code_skippe: 22

## Check HCatalog MapReduce

Use the [Hive CLI][hivecli] client to execute SQL queries using the MapReduce
engine.

      @call header: 'Check HCatalog MapReduce', label_true: 'CHECKED', ->
        for hive_hcatalog in options.hive_hcatalog
          directory = "check-#{options.hostname}-hive_hcatalog_mr-#{hive_hcatalog.hostname}"
          db = "check_#{options.hostname}_hive_hcatalog_mr_#{hive_hcatalog.hostname}"
          @system.execute
            cmd: mkcmd.test @, """
            hdfs dfs -rm -r -skipTrash #{directory} || true
            hdfs dfs -mkdir -p #{directory}/my_db/my_table
            echo -e 'a,1\\nb,2\\nc,3' | hdfs dfs -put - #{directory}/my_db/my_table/data
            hive -e "
              SET hive.execution.engine=mr;
              DROP TABLE IF EXISTS #{db}.my_table; DROP DATABASE IF EXISTS #{db};
              CREATE DATABASE #{db} LOCATION '/user/#{options.test.user.name}/#{directory}/my_db/';
              USE #{db};
              CREATE TABLE my_table(col1 STRING, col2 INT) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',';
            "
            hive -S -e "SET hive.execution.engine=mr; SELECT SUM(col2) FROM #{db}.my_table;" | hdfs dfs -put - #{directory}/result
            hive -e "DROP TABLE #{db}.my_table; DROP DATABASE #{db};"
            """
            unless_exec: unless options.force_check then mkcmd.test @, "hdfs dfs -test -f #{directory}/result"
            trap: true

## Check HCatalog Tez

Use the [Hive CLI][hivecli] client to execute SQL queries using the Tez engine.

      @call header: 'Check HCatalog Tez', label_true: 'CHECKED', ->
        for hive_hcatalog in options.hive_hcatalog
          directory = "check-#{options.hostname}-hive_hcatalog_tez-#{hive_hcatalog.hostname}"
          db = "check_#{options.hostname}_hive_hcatalog_tez_#{hive_hcatalog.hostname}"
          @system.execute
            cmd: mkcmd.test @, """
            hdfs dfs -rm -r -skipTrash #{directory} || true
            hdfs dfs -mkdir -p #{directory}/my_db/my_table
            echo -e 'a,1\\nb,2\\nc,3' | hdfs dfs -put - #{directory}/my_db/my_table/data
            hive -e "
              DROP TABLE IF EXISTS #{db}.my_table; DROP DATABASE IF EXISTS #{db};
              CREATE DATABASE #{db} LOCATION '/user/#{options.test.user.name}/#{directory}/my_db/';
              USE #{db};
              CREATE TABLE my_table(col1 STRING, col2 INT) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',';
            "
            hive -S -e "set hive.execution.engine=tez; SELECT SUM(col2) FROM #{db}.my_table;" | hdfs dfs -put - #{directory}/result
            hive -e "DROP TABLE #{db}.my_table; DROP DATABASE #{db};"
            """
            unless_exec: unless options.force_check then mkcmd.test @, "hdfs dfs -test -f #{directory}/result"
            trap: true

## Dependencies

    mkcmd = require '../../lib/mkcmd'

[hivecli]: https://cwiki.apache.org/confluence/display/Hive/LanguageManual+Cli
[beeline]: https://cwiki.apache.org/confluence/display/Hive/HiveServer2+Clients#HiveServer2Clients-Beeline%E2%80%93NewCommandLineShell

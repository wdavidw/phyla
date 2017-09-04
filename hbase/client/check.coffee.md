
# HBase Client Check

Check the HBase client installation by creating a table, inserting a cell and
scanning the table.

    module.exports =  header: 'HBase Client Check', label_true: 'CHECKED', handler: (options) ->
      {, hbase, user} = @config.ryba
      [ranger_ctx] = @contexts 'ryba/ranger/admin'

## Wait

Wait for the HBase master to be started.

      @call once: true, 'ryba/hbase/master/wait', options.wait_hbase_master
      @call once: true, 'ryba/hbase/regionserver/wait', options.wait_hbase_regionserver

## Ranger Policy
[Ranger HBase plugin][ranger-hbase] try to mimics grant/revoke by shell.

      @call
        if: -> options.ranger_admin
      , ->
        {install} = ranger_ctx.config.ryba.ranger.hbase_plugin
        policy_name = "Ranger-Ryba-HBase-Policy-#{@config.host}"
        hbase_policy =
          "name": "#{policy_name}"
          "service": "#{install['REPOSITORY_NAME']}"
          "resources":
            "column":
              "values": ["*"]
              "isExcludes": false
              "isRecursive": false
            "column-family":
              "values": ["*"]
              "isExcludes": false
              "isRecursive": false
            "table":
              "values": [
                "#{hbase.client.test.namespace}:#{hbase.client.test.table}",
                "#{hbase.client.test.namespace}:check_#{options.hostname}_test_splits",
                "#{hbase.client.test.namespace}:check_#{options.hostname}_ha"
                ]
              "isExcludes": false
              "isRecursive": false
          "repositoryName": "#{install['REPOSITORY_NAME']}"
          "repositoryType": "hbase"
          "isEnabled": "true",
          "isAuditEnabled": true,
          'tableType': 'Inclusion',
          'columnType': 'Inclusion',
          'policyItems': [
              "accesses": [
                'type': 'read'
                'isAllowed': true
              ,
                'type': 'write'
                'isAllowed': true
              ,
                'type': 'create'
                'isAllowed': true
              ,
                'type': 'admin'
                'isAllowed': true
              ],
              'users': ['hbase', "#{user.name}"]
              'groups': []
              'conditions': []
              'delegateAdmin': true
            ]
        @call once: true, 'ryba/ranger/admin/wait'
        @wait.execute
          header: 'Wait HBase Ranger repository'
          cmd: """
          curl --fail -H \"Content-Type: application/json\" -k -X GET  \
            -u admin:#{ranger_ctx.config.ryba.ranger.admin.password} \
            \"#{install['POLICY_MGR_URL']}/service/public/v2/api/service/name/#{install['REPOSITORY_NAME']}\"
          """
          code_skipped: 22
        @system.execute
          header: 'Ranger Ryba Policy'
          cmd: """
          curl --fail -H "Content-Type: application/json" -k -X POST \
            -d '#{JSON.stringify hbase_policy}' \
            -u admin:#{ranger_ctx.config.ryba.ranger.admin.password} \
            \"#{install['POLICY_MGR_URL']}/service/public/v2/api/policy\"
          """
          unless_exec: """
          curl --fail -H \"Content-Type: application/json\" -k -X GET  \
            -u admin:#{ranger_ctx.config.ryba.ranger.admin.password} \
            \"#{install['POLICY_MGR_URL']}/service/public/v2/api/service/#{install['REPOSITORY_NAME']}/policy/#{policy_name}\"
          """

## Shell

Create a "ryba" namespace and set full permission to the "ryba" user. This
namespace is used by other modules as a testing environment.  
Namespace and permissions are implemented and illustrated in [HBASE-8409].

Permissions is either zero or more letters from the set READ('R'), WRITE('W'), 
EXEC('X'), CREATE('C'), ADMIN('A'). Create and admin only apply to tables.

`grant <user|@system.group> <permissions> <table> [ <column family> [ <column qualifier> ] ]`

Groups and users access are revoked in the same way, but groups are prefixed 
with an '@' character. In the same way, tables and namespaces are specified, but
namespaces are prefixed with an '@' character.

      @system.execute
        header: 'Grant Permissions'
        cmd: mkcmd.hbase options.admin, """
        if hbase shell 2>/dev/null <<< "list_namespace_tables '#{hbase.client.test.namespace}'" | egrep '[0-9]+ row'; then
          if [ ! -z '#{options.force_check or ''}' ]; then
            echo [DEBUG] Cleanup existing table and namespace
            hbase shell 2>/dev/null << '    CMD' | sed -e 's/^    //';
              disable '#{hbase.client.test.namespace}:#{hbase.client.test.table}'
              drop '#{hbase.client.test.namespace}:#{hbase.client.test.table}'
              drop_namespace '#{hbase.client.test.namespace}'
            CMD
          else
            echo [INFO] Test is skipped
            exit 2;
          fi
        fi
        echo '[DEBUG] Namespace level'
        hbase shell 2>/dev/null <<-CMD
          create_namespace '#{hbase.client.test.namespace}'
          grant '#{user.name}', 'RWC', '@#{hbase.client.test.namespace}'
        CMD
        echo '[DEBUG] Table Level'
        hbase shell 2>/dev/null <<-CMD
          create '#{hbase.client.test.namespace}:#{hbase.client.test.table}', 'family1'
          grant '#{user.name}', 'RWC', '#{hbase.client.test.namespace}:#{hbase.client.test.table}'
        CMD
        """
        code_skipped: 2
        trap: true

## Check Shell

Note, we are re-using the namespace created above.

      @call header: 'Shell', label_true: 'CHECKED', ->
        @wait.execute
          cmd: mkcmd.test @, "hbase shell 2>/dev/null <<< \"exists '#{hbase.client.test.namespace}:#{hbase.client.test.table}'\" | grep 'Table #{hbase.client.test.namespace}:#{hbase.client.test.table} does exist'"
        @system.execute
          cmd: mkcmd.test @, """
          hbase shell 2>/dev/null <<-CMD
            alter '#{hbase.client.test.namespace}:#{hbase.client.test.table}', {NAME => '#{options.hostname}'}
            put '#{hbase.client.test.namespace}:#{hbase.client.test.table}', 'my_row', '#{options.hostname}:my_column', 10
            scan '#{hbase.client.test.namespace}:#{hbase.client.test.table}',  {COLUMNS => '#{options.hostname}'}
          CMD
          """
          unless_exec: unless options.force_check then mkcmd.test @, "hbase shell 2>/dev/null <<< \"scan '#{hbase.client.test.namespace}:#{hbase.client.test.table}', {COLUMNS => '#{options.hostname}'}\" | egrep '[0-9]+ row'"
        , (err, executed, stdout) ->
          isRowCreated = RegExp("column=#{options.hostname}:my_column, timestamp=\\d+, value=10").test stdout
          throw Error 'Invalid command output' if executed and not isRowCreated

## Check MapReduce

      @call header: 'MapReduce', label_true: 'CHECKED', ->
        @system.execute
          cmd: mkcmd.test @, """
          hdfs dfs -rm -skipTrash check-#{@config.host}-hbase-mapred
          echo -e '1,toto\\n2,tata\\n3,titi\\n4,tutu' | hdfs dfs -put -f - /user/ryba/test_import.csv
          hbase org.apache.hadoop.hbase.mapreduce.ImportTsv -Dimporttsv.separator=, -Dimporttsv.columns=HBASE_ROW_KEY,family1:value #{hbase.client.test.namespace}:#{hbase.client.test.table} /user/ryba/test_import.csv
          hdfs dfs -touchz check-#{@config.host}-hbase-mapred
          """
          unless_exec: unless options.force_check then mkcmd.test @, "hdfs dfs -test -f check-#{@config.host}-hbase-mapred"

## Check Splits

      @call header: 'Splits', label_true: 'CHECKED', ->
        table = "#{hbase.client.test.namespace}:check_#{options.hostname}_test_splits"
        @system.execute
          cmd: mkcmd.hbase options.admin, """
          if hbase shell 2>/dev/null <<< "list_namespace_tables '#{hbase.client.test.namespace}'" | grep 'test_splits'; then echo "disable '#{table}'; drop '#{table}'" | hbase shell 2>/dev/null; fi
          echo "create '#{table}', 'cf1', SPLITS => ['1', '2', '3']" | hbase shell 2>/dev/null;
          echo "scan 'hbase:meta',  {COLUMNS => 'info:regioninfo', FILTER => \\"PrefixFilter ('#{table}')\\"}" | hbase shell 2>/dev/null
          """
          unless_exec: unless options.force_check then mkcmd.test @, "hbase shell 2>/dev/null <<< \"list '#{hbase.client.test.namespace}'\" | grep -w 'test_splits'"
        , (err, executed, stdout) ->
          throw err if err
          return unless executed
          lines = string.lines stdout
          count = 0
          pattern = new RegExp "^ #{table},"
          for line in lines
            count++ if pattern.test line
          throw Error 'Invalid Splits Count' unless count is 4

      # Note: inspiration for when namespace are functional
      # cmd = mkcmd.test @, "hbase shell 2>/dev/null <<< \"list_namespace_tables 'ryba'\" | egrep '[0-9]+ row'"
      # @waitForExecution cmd, (err) ->
      #   return  err if err
      #   @system.execute
      #     cmd: mkcmd.test @, """
      #     if hbase shell 2>/dev/null <<< "list_namespace_tables 'ryba'" | egrep '[0-9]+ row'; then exit 2; fi
      #     hbase shell 2>/dev/null <<-CMD
      #       create 'ryba.#{options.hostname}', 'family1'
      #       put 'ryba.#{options.hostname}', 'my_row', 'family1:my_column', 10
      #       scan 'ryba.#{options.hostname}'
      #     CMD
      #     """
      #     code_skipped: 2
      #   , (err, executed, stdout) ->
      #     isRowCreated = /column=family1:my_column10, timestamp=\d+, value=10/.test stdout
      #     return  Error 'Invalid command output' if executed and not isRowCreated
      #     return  err, executed


## Check HA

This check is only executed if more than two HBase Master are declared.

      @call header: 'Check HA', if: options.is_ha, ->
        table = "#{hbase.client.test.namespace}:check_#{options.hostname}_ha"
        @system.execute
          cmd: mkcmd.hbase options.admin, """
          # Create new table
          echo "disable '#{table}'; drop '#{table}'" | hbase shell 2>/dev/null
          echo "create '#{table}', 'cf1', {REGION_REPLICATION => 2}" | hbase shell 2>/dev/null;
          # Insert records
          echo "put '#{table}', 'my_row', 'cf1:my_column', 10" | hbase shell 2>/dev/null
          echo "scan '#{table}',  { CONSISTENCY => 'STRONG' }" | hbase shell 2>/dev/null
          echo "scan '#{table}',  { CONSISTENCY => 'TIMELINE' }" | hbase shell 2>/dev/null
          """
          # unless_exec: unless options.force_check then mkcmd.test @, "hbase shell 2>/dev/null <<< \"list '#{table}'\" | grep -w '#{table}'"

## Dependencies

    mkcmd = require '../../lib/mkcmd'
    string = require 'nikita/lib/misc/string'


[HBASE-8409]: https://issues.apache.org/jira/browse/HBASE-8409
[ranger-hbase]: https://cwiki.apache.org/confluence/display/RANGER/HBase+Plugin#HBasePlugin-Grantandrevoke

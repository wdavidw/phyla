
# HBase Client Check

Check the HBase client installation by creating a table, inserting a cell and
scanning the table.

    module.exports =  header: 'HBase Client Check', handler: ({options}) ->

## Register

      @registry.register 'ranger_policy', 'ryba/ranger/actions/ranger_policy'

## Wait

Wait for the HBase master to be started.

      @call once: true, 'ryba/hbase/master/wait', options.wait_hbase_master
      @call once: true, 'ryba/hbase/regionserver/wait', options.wait_hbase_regionserver

## Ranger Policy

[Ranger HBase plugin][ranger-hbase] try to mimics grant/revoke by shell.

      @call
        header: 'Ranger'
        if: -> !!options.ranger_admin
      , ->
        @call 'ryba/ranger/admin/wait', once: true, options.wait_ranger_admin
        @wait.execute
          header: 'Wait Service'
          cmd: """
          curl --fail -H \"Content-Type: application/json\" -k -X GET  \
            -u #{options.ranger_admin.username}:#{options.ranger_admin.password} \
            \"#{options.ranger_install['POLICY_MGR_URL']}/service/public/v2/api/service/name/#{options.ranger_install['REPOSITORY_NAME']}\"
          """
          code_skipped: 22
        @ranger_policy
          header: 'Create Policy'
          username: options.ranger_admin.username
          password: options.ranger_admin.password
          url: options.ranger_install['POLICY_MGR_URL']
          policy:
            "name": "ryba-client-check-#{options.hostname}"
            'description': 'Ryba policy used to check the HBase client'
            "service": options.ranger_install['REPOSITORY_NAME']
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
                  "#{options.test.namespace}:#{options.test.table}",
                  "#{options.test.namespace}:check_#{options.hostname}_test_splits",
                  "#{options.test.namespace}:check_#{options.hostname}_ha"
                  ]
                "isExcludes": false
                "isRecursive": false
            "isEnabled": true
            "isAuditEnabled": true
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
                'users': [options.test.user.name]
                'groups': []
                'conditions': []
                'delegateAdmin': true
              ]

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
        force_check='#{if options.force_check then '1' else ''}'
        if hbase shell 2>/dev/null <<< "list_namespace_tables '#{options.test.namespace}'" | egrep '[0-9]+ row'; then
          if [ ! -z "$force_check" ]; then
            echo [DEBUG] Cleanup existing table and namespace
            hbase shell 2>/dev/null << '    CMD' | sed -e 's/^    //';
              disable '#{options.test.namespace}:#{options.test.table}'
              drop '#{options.test.namespace}:#{options.test.table}'
              drop_namespace '#{options.test.namespace}'
            CMD
          else
            echo [INFO] Test is skipped
            exit 2;
          fi
        fi
        echo '[DEBUG] Namespace level'
        hbase shell 2>/dev/null <<-CMD
          create_namespace '#{options.test.namespace}'
          grant '#{options.test.user.name}', 'RWC', '@#{options.test.namespace}'
        CMD
        echo '[DEBUG] Table Level'
        hbase shell 2>/dev/null <<-CMD
          create '#{options.test.namespace}:#{options.test.table}', 'family1'
          grant '#{options.test.user.name}', 'RWC', '#{options.test.namespace}:#{options.test.table}'
        CMD
        """
        code_skipped: 2
        trap: true

## Check Shell

Note, we are re-using the namespace created above.

      @call header: 'Shell', ->
        @wait.execute
          cmd: mkcmd.test options.test_krb5_user, "hbase shell 2>/dev/null <<< \"exists '#{options.test.namespace}:#{options.test.table}'\" | grep 'Table #{options.test.namespace}:#{options.test.table} does exist'"
        @system.execute
          cmd: mkcmd.test options.test_krb5_user, """
          hbase shell 2>/dev/null <<-CMD
            alter '#{options.test.namespace}:#{options.test.table}', {NAME => '#{options.hostname}'}
            put '#{options.test.namespace}:#{options.test.table}', 'my_row', '#{options.hostname}:my_column', 10
            scan '#{options.test.namespace}:#{options.test.table}',  {COLUMNS => '#{options.hostname}'}
          CMD
          """
          unless_exec: unless options.force_check then mkcmd.test options.test_krb5_user, "hbase shell 2>/dev/null <<< \"scan '#{options.test.namespace}:#{options.test.table}', {COLUMNS => '#{options.hostname}'}\" | egrep '[0-9]+ row'"
        , (err, {status, stdout}) ->
          isRowCreated = RegExp("column=#{options.hostname}:my_column, timestamp=\\d+, value=10").test stdout
          throw Error 'Invalid command output' if status and not isRowCreated

## Check MapReduce

      @call header: 'MapReduce', ->
        @system.execute
          cmd: mkcmd.test options.test_krb5_user, """
          hdfs dfs -rm -skipTrash check-#{options.hostname}-hbase-mapred
          echo -e '1,toto\\n2,tata\\n3,titi\\n4,tutu' | hdfs dfs -put -f - /user/ryba/test_import.csv
          hbase org.apache.hadoop.hbase.mapreduce.ImportTsv -Dimporttsv.separator=, -Dimporttsv.columns=HBASE_ROW_KEY,family1:value #{options.test.namespace}:#{options.test.table} /user/ryba/test_import.csv
          hdfs dfs -touchz check-#{options.hostname}-hbase-mapred
          """
          unless_exec: unless options.force_check then mkcmd.test options.test_krb5_user, "hdfs dfs -test -f check-#{options.hostname}-hbase-mapred"

## Check Splits

      @call header: 'Splits', ->
        table = "#{options.test.namespace}:check_#{options.hostname}_test_splits"
        @system.execute
          cmd: mkcmd.hbase options.admin, """
          if hbase shell 2>/dev/null <<< "list_namespace_tables '#{options.test.namespace}'" | grep 'test_splits'; then echo "disable '#{table}'; drop '#{table}'" | hbase shell 2>/dev/null; fi
          echo "create '#{table}', 'cf1', SPLITS => ['1', '2', '3']" | hbase shell 2>/dev/null;
          echo "scan 'hbase:meta',  {COLUMNS => 'info:regioninfo', FILTER => \\"PrefixFilter ('#{table}')\\"}" | hbase shell 2>/dev/null
          """
          unless_exec: unless options.force_check then mkcmd.test options.test_krb5_user, "hbase shell 2>/dev/null <<< \"list '#{options.test.namespace}'\" | grep -w 'test_splits'"
        , (err, data) ->
          throw err if err
          return unless data.executed
          lines = string.lines data.stdout
          count = 0
          pattern = new RegExp "^ #{table},"
          for line in lines
            count++ if pattern.test line
          throw Error 'Invalid Splits Count' unless count is 4

      # Note: inspiration for when namespace are functional
      # cmd = mkcmd.test options.test_krb5_user, "hbase shell 2>/dev/null <<< \"list_namespace_tables 'ryba'\" | egrep '[0-9]+ row'"
      # @waitForExecution cmd, (err) ->
      #   return  err if err
      #   @system.execute
      #     cmd: mkcmd.test options.test_krb5_user, """
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
        table = "#{options.test.namespace}:check_#{options.hostname}_ha"
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
          # unless_exec: unless options.force_check then mkcmd.test options.test_krb5_user, "hbase shell 2>/dev/null <<< \"list '#{table}'\" | grep -w '#{table}'"

## Dependencies

    mkcmd = require '../../lib/mkcmd'
    string = require '@nikita/core/lib/misc/string'


[HBASE-8409]: https://issues.apache.org/jira/browse/HBASE-8409
[ranger-hbase]: https://cwiki.apache.org/confluence/display/RANGER/HBase+Plugin#HBasePlugin-Grantandrevoke

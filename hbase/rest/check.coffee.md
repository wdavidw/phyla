
# HBase Rest Gateway Check

    module.exports =  header: 'HBase Rest Check', label_true: 'CHECKED', handler: (options) ->

## Register

      @registry.register 'ranger_policy', 'ryba/ranger/actions/ranger_policy'

## Assert HTTP Port

      @connection.assert
        header: 'HTTP'
        servers: options.wait.http.filter (server) -> server.host is options.fqdn
        retry: 3
        sleep: 3000

## Assert HTTP Info Port

      @connection.assert
        header: 'HTTP Info'
        servers: options.wait.http_info.filter (server) -> server.host is options.fqdn
        retry: 3
        sleep: 3000

## Ranger Policy

[Ranger HBase plugin][ranger-hbase] try to mimics grant/revoke by shell.

      @call
        header: 'Ranger Policy'
        if: !!options.ranger_admin
      , ->
        # Wait for Ranger admin to be started
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
          header: 'Create'
          username: options.ranger_admin.username
          password: options.ranger_admin.password
          url: options.ranger_install['POLICY_MGR_URL']
          policy:
            'name': "ryba-rest-check-#{options.hostname}"
            'description': 'Ryba policy used to check the HBase REST service'
            'service': options.ranger_install['REPOSITORY_NAME']
            'isEnabled': 'true'
            'isAuditEnabled': true
            'resources':
              'table':
                'values': [
                  "#{options.test.namespace}:#{options.test.table}"
                  ]
                'isExcludes': false
                'isRecursive': false
              'column-family':
                'values': ['*']
                'isExcludes': false
                'isRecursive': false
              'column':
                'values': ['*']
                'isExcludes': false
                'isRecursive': false
            'policyItems': [
              'accesses': [
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
              ]
              'users': [options.test.user.name]
              'groups': []
              'conditions': []
              'delegateAdmin': false
            ]

## Check Shell

      @call header: 'Scan', ->
        encode = (data) -> (new Buffer data, 'utf8').toString 'base64'
        decode = (data) -> (new Buffer data, 'base64').toString 'utf8'
        curl = 'curl -s '
        curl += '-k ' if options.hbase_site['hbase.rest.ssl.enabled'] is 'true'
        curl += '--negotiate -u: ' if options.hbase_site['hbase.rest.authentication.type'] is 'kerberos'
        curl += '-H "Accept: application/json" '
        curl += '-H "Content-Type: application/json" '
        protocol = if options.hbase_site['hbase.rest.ssl.enabled'] is 'true' then 'https' else 'http'
        port = options.hbase_site['hbase.rest.port']
        schema = JSON.stringify ColumnSchema: [name: "#{options.hostname}_rest"]
        rows = JSON.stringify Row: [ key: encode('my_row_rest'), Cell: [column: encode("#{options.hostname}_rest:my_column"), $: encode('my rest value')]]
        @system.execute
          cmd: mkcmd.hbase options.admin, """
          if hbase shell 2>/dev/null <<< "list_namespace_tables '#{options.test.namespace}'" | egrep '[0-9]+ row'; then
            if [ ! -z '#{options.force_check or ''}' ]; then
              echo [DEBUG] Cleanup existing table and namespace
              hbase shell 2>/dev/null << '    CMD' | sed -e 's/^    //';
                disable '#{options.test.namespace}:#{options.test.table}'
                drop '#{options.test.namespace}:#{options.test.table}'
                drop_namespace '#{options.test.namespace}'
              CMD
            else
              echo [INFO] Test is skipped; exit 2;
            fi
          fi
          hbase shell 2>/dev/null <<-CMD
            create_namespace '#{options.test.namespace}'
            grant '#{options.user.name}', 'RWC', '@#{options.test.namespace}'
            create '#{options.test.namespace}:#{options.test.table}', 'family1'
          CMD
          """
          code_skipped: 2
          trap: true
        @system.execute
          cmd: mkcmd.test @, """
          #{curl} -X POST --data '#{schema}' #{protocol}://#{options.fqdn}:#{port}/#{options.test.namespace}:#{options.test.table}/schema
          #{curl} --data '#{rows}' #{protocol}://#{options.fqdn}:#{port}/#{options.test.namespace}:#{options.test.table}/___false-row-key___/#{options.hostname}_rest%3A
          #{curl} #{protocol}://#{options.fqdn}:#{port}/#{options.test.namespace}:#{options.test.table}/my_row_rest
          """
          unless_exec: unless options.force_check then mkcmd.test @, "hbase shell 2>/dev/null <<< \"scan '#{options.test.namespace}:#{options.test.table}', {COLUMNS => '#{options.hostname}_rest'}\" | egrep '[0-9]+ row'"
        , (err, executed, stdout) ->
          return if err or not executed
          try
            data = JSON.parse(stdout)
          catch e then throw Error "Invalid Command Output: #{JSON.stringify stdout}"
          return throw Error "Invalid ROW Key: #{JSON.stringify stdout}" unless decode(data?.Row[0]?.key) is 'my_row_rest'

## Dependencies

    mkcmd = require '../../lib/mkcmd'

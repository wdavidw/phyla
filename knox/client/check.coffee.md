
# Knox Client Check

Execute som curl command towards knox'server rest api.
    
    module.exports = header: 'Knox Client Check', handler: ({options}) ->
      return unless options.test.user?.name? and options.test.user?.password?

## Register
      
      @registry.register 'ranger_policy', 'ryba/ranger/actions/ranger_policy'

## Wait
      
      @connection.wait options.wait_knox_server.tcp

## Add Ranger Policy

Create the policy to run the checks. The policy can be accessed from the command
line with: 

```
curl --fail -k -X GET -H "Content-Type: application/json" \
-u admin:rangerAdmin123 \
"https://master03.metal.ryba:6182/service/public/v2/api/service/hadoop-ryba-knox/policy/ryba-check-edge01"
```
      
      @call
        header: 'Ranger Policy'
        if: !!options.ranger_admin
      , ->
        # Wait for Ranger admin to be started
        @call 'ryba/ranger/admin/wait', once: true, options.wait_ranger_admin
        # Prepare the list of databases
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
            'name': "ryba-check-knox"
            'description': 'Ryba policy used to check the knox service'
            'service': options.ranger_install['REPOSITORY_NAME']
            'isEnabled': true
            'isAuditEnabled': true
            'resources':
              'topology':
                'values': Object.keys options.topologies
                'isExcludes': false
                'isRecursive': false
              'service':
                'values': ['*']
                'isExcludes': false
                'isRecursive': false
            'policyItems': [
              'accesses': [
                'type': 'allow'
                'isAllowed': true
              ]
              'users': [options.test.user.name]
              'groups': []
              'conditions': []
              'delegateAdmin': false
            ]


## Check WebHDFS Proxy

Testing WebHDFS by getting the home directory

At the gateway host, enter `curl --negotiate -ku : http://$webhdfs-host:50470/webhdfs/v1?op=GETHOMEDIRECTORY`. 
The host displays: {"Path":"/user/gopher"}
At an external client, enter `curl -ku user:password https://$gateway-host:$gateway_port/$gateway/$cluster_name/webhdfs/v1?op=GETHOMEDIRECTORY`.
The external client displays: {"Path":"/user/gopher"}

curl -fiku hdfs:hdfs123 "https://front1.ryba:8443/gateway/torval/webhdfs/v1/?op=GETHOMEDIRECTORY"

      @call header: 'WebHDFS', ->
        for gateway in options.knox_gateway
          topologies = Object.keys(gateway.topologies).filter((tp) -> gateway.topologies[tp].services.webhdfs?)
          for tp in topologies
            @system.execute
              cmd: "curl -fiku #{options.test.user.name}:#{options.test.user.password} https://#{gateway.fqdn}:#{gateway.gateway_site['gateway.port']}/#{gateway.gateway_site['gateway.path']}/#{tp}/webhdfs/v1/?op=GETHOMEDIRECTORY"

## Check WebHCat Proxy

Testing WebHCat/Templeton by getting the version

At the gateway host, enter `curl --negotiate -u : http://$webhcat-host:50111/templeton/v1/version`.
The host displays: {"supportedVersions":["v1"],"version":"v1"}
At an external client, enter `curl -ku user:password https://$gateway-host:$gateway_port/$gateway/$cluster_name/webhcat/v1/version`.
The external client displays: {"supportedVersions":["v1"],"version":"v1"}

      @call header: 'WebHCat', ->
        for gateway in options.knox_gateway
          topologies = Object.keys(gateway.topologies).filter((tp) -> gateway.topologies[tp].services.webhcat)
          for tp in topologies
            @system.execute
              cmd: "curl -fiku #{options.test.user.name}:#{options.test.user.password} https://#{gateway.fqdn}:#{gateway.gateway_site['gateway.port']}/#{gateway.gateway_site['gateway.path']}/#{tp}/templeton/v1/version"

## Check HBase REST Proxy

Testing HBase/Stargate by getting the version

At the gateway host, enter `curl --negotiate -u : http://$hbase-host:60080/version`.
The host displays:
rest 0.0.2 JVM: Oracle Corporation 1.7.0_51-24.45-b08 OS: Linux 3.8.0-29-generic amd64 Server: jetty/6.1.26 Jersey: 1.8.
At an external client, enter `curl -ku user:password http://$gateway-host:$gateway_port/$gateway/$cluster_name/hbase/version`.
The external client displays:
rest 0.0.2 JVM: Oracle Corporation 1.7.0_51-24.45-b08 OS: Linux 3.8.0-29-generic amd64 Server: jetty/6.1.26 Jersey: 1.8.

      @call header: 'WebHBase', ->
        for gateway in options.knox_gateway
          topologies = Object.keys(gateway.topologies).filter((tp) -> gateway.topologies[tp].services.webhcat)
          for tp in topologies
            @system.execute
              cmd: "curl -fiku #{options.test.user.name}:#{options.test.user.password} https://#{gateway.fqdn}:#{gateway.gateway_site['gateway.port']}/#{gateway.gateway_site['gateway.path']}/#{tp}/hbase/version"

## Check Oozie Proxy

Testing Oozie by getting the version

At the gateway host, enter `curl --negotiate -u : http://$oozie-host:11000/oozie/v1/admin/build-version`. 
The host displays:
{"buildVersion":"4.0.0.2.1.1.0-302"} 
At an external client, enter `curl -ku user:password https://$gateway-host:$gateway_port/$gateway/$cluster_name/oozie/v1/admin/build-version`.
The external client displays:
{"buildVersion":"4.0.0.2.1.1.0-302"}

      @call header: 'Oozie', ->
        for gateway in options.knox_gateway
          topologies = Object.keys(gateway.topologies).filter((tp) -> gateway.topologies[tp].services.oozie)
          for tp in topologies
            @system.execute
              cmd: "curl -fiku #{options.test.user.name}:#{options.test.user.password} https://#{gateway.fqdn}:#{gateway.gateway_site['gateway.port']}/#{gateway.gateway_site['gateway.path']}/#{tp}/oozie/v1/admin/build-version"

## Check HiveServer2 Proxy

Testing HiveServer2
Both of the following URLs return an authentication error, which users can safely ignore.

At the gateway host, enter `curl --negotiate -u : http://$hive-host:10001/cliservice`.
At an external client, enter `curl -ku user:password https://$gateway-host:$gateway_port/$gateway/$cluster_name/hive/cliservice`/

      @call header: 'HiveServer2', ->
        for gateway in options.knox_gateway
          console.log gateway.topologies['ryba_users'].services
          topologies = Object.keys(gateway.topologies).filter((tp) -> gateway.topologies[tp].services.hive)
          for tp in topologies
            @system.execute
              cmd: "curl -fiku #{options.test.user.name}:#{options.test.user.password} https://#{gateway.fqdn}:#{gateway.gateway_site['gateway.port']}/#{options.gateway_site['gateway.path']}/#{tp}/hive/cliservice"

[doc]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.2.8/bk_Knox_Gateway_Admin_Guide/content/validating_service_connectivity.html

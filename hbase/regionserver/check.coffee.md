
# HBase RegionServer Check

    module.exports = header: 'HBase RegionServer Check', handler: (options) ->

## Assert

Ensure for the server is listening for remote connections.

      @connection.assert
        header: 'RPC'
        servers: options.wait.rpc.filter (srv) -> srv.host is options.fqdn
        retry: 10
        sleep: 3000

      @connection.assert
        header: 'Info'
        servers: options.wait.info.filter (srv) -> srv.host is options.fqdn
        retry: 10
        sleep: 3000

## Check SPNEGO

Check if keytab file exists and if read permission is granted to the HBase user.

Note: The RegionServer webapp located in "/usr/lib/hbase/hbase-webapps/regionserver" is
using the hadoop conf directory to retrieve the SPNEGO keytab. The user "hbase"
is added membership to the group hadoop to gain read access.

      @system.execute
        header: 'SPNEGO'
        cmd: "su -l #{options.user.name} -c 'test -r #{options.hbase_site['hbase.security.authentication.spnego.kerberos.keytab']}'"

## Check HTTP JMX

      
      protocol = if options.hbase_site['hbase.ssl.enabled'] is 'true' then 'https' else 'http'
      port = options.hbase_site['hbase.regionserver.info.port']
      url = "#{protocol}://#{options.fqdn}:#{port}/jmx?qry=Hadoop:service=HBase,name=RegionServer,sub=Server"
      @system.execute
        header: 'HTTP JMX'
        retry: 3
        cmd: mkcmd.test @, """
        host=`curl -s -k --negotiate -u : #{url} | grep tag.Hostname | sed 's/^.*:.*"\\(.*\\)".*$/\\1/g'`
        [ "$host" == '#{options.fqdn}' ] || [ "$host" == '#{options.hostname}' ]
        """


## Dependencies

    mkcmd = require '../../lib/mkcmd'

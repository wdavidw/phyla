
# HBase Master Check

    module.exports = header: 'HBase Master Check', handler: ({options}) ->

## Assert

Ensure for the server is listening for remote connections.

      @connection.assert
        header: 'RPC'
        servers: options.wait.rpc.filter (server) -> server.host is options.fqdn
        retry: 3
        sleep: 3000

The http connection will be available once the region servers have connected to the master

      @call once: true, if: options.wait_hbase_regionserver?, '@rybajs/metal/hbase/regionserver/wait', options.wait_hbase_regionserver
      @connection.assert
        header: 'HTTP'
        servers: options.wait.http.filter (server) -> server.host is options.fqdn
        retry: 3
        sleep: 3000

## Check FSCK

It is possible that HBase fail to started because of currupted WAL files.
Corrupted blocks for removal can be found with the command: 
`hdfs fsck / | egrep -v '^\.+$' | grep -v replica | grep -v Replica`
Additionnal information may be found on the [CentOS HowTos site][corblk].

[corblk]: http://centoshowtos.org/hadoop/fix-corrupt-blocks-on-hdfs/

      @system.execute
        header: 'FSCK'
        cmd: mkcmd.hdfs options.hdfs_krb5_user, """
        hdfs fsck #{options.hbase_site['hbase.rootdir']}/WALs \
        | grep 'Status: HEALTHY'
        """
        relax: true
      , (err) ->
        throw Error "WAL Corruption detected by FSCK" if err

## Check SPNEGO

Check if keytab file exists and if read permission is granted to the HBase user.

Note: The Master webapp located in "/usr/lib/hbase/hbase-webapps/master" is
using the hadoop conf directory to retrieve the SPNEGO keytab. The user "hbase"
is added membership to the group hadoop to gain read access.

      @system.execute
        header: 'SPNEGO'
        cmd: "su -l #{options.user.name} -c 'test -r #{options.hbase_site['hbase.security.authentication.spnego.kerberos.keytab']}'"

## Check HTTP JMX

      protocol = if options.hbase_site['hbase.ssl.enabled'] is 'true' then 'https' else 'http'
      port = options.hbase_site['hbase.master.info.port']
      url = "#{protocol}://#{options.fqdn}:#{port}/jmx?qry=Hadoop:service=HBase,name=Master,sub=Server"
      @system.execute
        header: 'HTTP JMX'
        cmd: mkcmd.test options.test_krb5_user, """
        host=`curl -s -k --negotiate -u : #{url} | grep tag.Hostname | sed 's/^.*:.*"\\(.*\\)".*$/\\1/g'`
        [ "$host" == '#{options.fqdn}' ] || [ "$host" == '#{options.hostname}' ]
        """

## Dependencies

    mkcmd = require '../../lib/mkcmd'

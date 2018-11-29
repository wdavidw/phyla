
# Hadoop YARN RegistryDNS Server Start

Start the Yarn RegistryDNS Server. You can also start the server
manually with the following command:

```
service hadoop-yarn-registrydns start
su -l yarn -c "/usr/hdp/current/hadoop-yarn-timelineserver/sbin/yarn--config /etc/hadoop-yarn-registrydns/conf --deamon start timelineserver"
```


    module.exports = header: 'YARN RegistryDNS Start', handler: ({options}) ->

## Wait

Wait for Kerberos and the HDFS NameNode.

      @call 'masson/core/krb5_client/wait', once: true, options.wait_krb5_client

## Run

Start the service.

      @service.start
        name: 'hadoop-yarn-registrydns'

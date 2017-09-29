
# Hadoop HDFS NameNode Wait

Single Namenode without Kerberos:

```json
{
  "conf_dir": "/etc/hadoop-hdfs-namenode/conf",
  "hdfs_user": { "name": "hdfs" },
  "http": { "host": "master1.ryba", "port": 50470 }
}
```

HA Namenodes with Kerberos:

```json
{
  "conf_dir": "/etc/hadoop-hdfs-namenode/conf",
  "krb5_user": { "principal": "hdfs@HADOOP.RYBA", "password": "hdfs123" },
  "http": [
    { "host": "master1.ryba", "port": 50470 },
    { "host": "master2.ryba", "port": 50470 }
  ]
}
```

    module.exports = header: 'HDFS NN Wait', handler: (options) ->
      
      throw Error "Required Option: conf_dir" unless options.conf_dir
      throw Error "Required Option: krb5_user" unless options.krb5_user

## Wait IPC Ports

Port is defined in the "dfs.namenode.rpc-address" property of hdfs-site. The default
value is 8020.

      @connection.wait
        header: 'IPC'
        servers: options.ipc

## Wait HTTP ports

      @connection.wait
        header: 'HTTP'
        servers: options.http

## Wait Safemode

Wait for HDFS safemode to exit. It is not enough to start the NameNodes but the
majority of DataNodes also need to be running.

      # TODO: there are much better solutions, for exemple
      # if 'ryba/hadoop/hdfs_client', then `hdfs dfsadmin`
      # else use curl
      @wait.execute
        header: 'Safemode'
        cmd: mkcmd options.krb5_user, """
        hdfs --config '#{options.conf_dir}' dfsadmin -safemode get | grep OFF
        """
        interval: 3000

## Dependencies

    mkcmd = require '../../lib/mkcmd'

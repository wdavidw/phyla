
# Hive HCatalog Start

Start the Hive HCatalog server. 

    module.exports =  header: 'Hive HCatalog Start', handler: ({options}) ->

## Wait

The Hive HCatalog require the database server to be started. The HDFS Namenode 
need to functionnal for Hive to answer queries.

      # console.log 'options.wait_db_admin', options.wait_db_admin
      @call 'masson/core/krb5_client/wait', once: true, options.wait_krb5_client
      @call 'ryba/zookeeper/server/wait', once: true, options.wait_zookeeper_server
      @call 'ryba/hadoop/hdfs_nn/wait', once: true, options.wait_hdfs_nn, conf_dir: options.hdfs_conf_dir
      @call 'ryba/commons/db_admin/wait', once: true, options.wait_db_admin

## Service

You can also start the server manually with the
following commands:

```
service hive-hcatalog-server start
systemctl start hive-hcatalog-server
su -l hive -c 'nohup hive --config /etc/hive-hcatalog/conf --service metastore >/var/log/hive-hcatalog/hcat.out 2>/var/log/hive-hcatalog/hcat.err & echo $! >/var/run/hive-hcatalog/hive-hcatalog.pid'
```

      @service.start
        header: 'Start service'
        name: 'hive-hcatalog-server'

# Module Dependencies

    db = require '@nikitajs/core/lib/misc/db'


# Hadoop HDFS JournalNode Wait

Exemple:

```
nikita.hadoop.hdfs_jn.wait({
    rpc: [
      { "host": "master1.ryba", "port": "8485" },
      { "host": "master2.ryba", "port": "8485" },
      { "host": "master3.ryba", "port": "8485" },
    ]
})
```

    module.exports = header: 'HDFS JN Wait', label_true: 'READY', handler: (options) ->

      @connection.wait
        servers: options.rpc


# Spark SQL Thrift server Start

Start the Spark SQL Thrift server. You can also start the server manually with the
following command:

```
service spark-thrift-server start
```

    module.exports = header: 'Spark SQL Thrift Server Start', handler: (options) ->
      @call once:true, '@rybajs/metal/hive/hcatalog/wait'
      @service.start
        name: 'spark-thrift-server'


# Spark Livy Server Wait

Wait for the Livy Server.

    module.exports = header: 'Spark Livy ServerWait', handler: ->
      options = {}
      options.wait_tcp = for sls_ctx in @contexts modules: '@rybajs/metal/spark2/livy_server'
        host: sls_ctx.config.host
        port: sls_ctx.config.ryba.spark.livy.conf['livy.server.port']

## TCP Port

      @connection.wait
        header: 'TCP'
        servers: options.wait_tcp


# Hadoop HDFS NameNode Wait

    module.exports = header: 'HDFS HttpFS Wait', handler: (options) ->

## HTTP Port

      @connection.wait
        header: 'HTTP'
        servers: options.http

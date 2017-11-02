 
# Redis Slave Wait
 
Wait for the Redis Slave to be up

    module.exports = header: 'Redis Slave Wait', label_true: 'READY', handler: ->
      
      @connection.wait
        port: @config.ryba.redis.slave.conf.port
        host: @config.ryba.redis.slave.host

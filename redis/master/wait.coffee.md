 
# Redis Master Wait
 
Wait for the Redis Master to be up

    module.exports = header: 'Redis Master Wait', label_true: 'READY', handler: ->
      [redis_master_ctx] = @contexts 'ryba/redis/master'
      @connection.wait
        port: redis_master_ctx.config.ryba.redis.master.conf.port
        host: redis_master_ctx.config.ryba.redis.master.host

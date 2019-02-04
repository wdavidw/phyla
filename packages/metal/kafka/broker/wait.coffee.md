
# HBase Master Wait

    module.exports =  header: 'Kafka Broker Wait', handler: ({options}) ->

## Broker Port

      @connection.wait
        header: 'PLAINTEXT'
        if: !!options['PLAINTEXT']
        servers: options['PLAINTEXT']
        
      @connection.wait
        header: 'SSL'
        if: !!options['SSL']
        servers: options['SSL']

      @connection.wait
        header: 'SASL_PLAINTEXT'
        if: !!options['SASL_PLAINTEXT']
        servers: options['SASL_PLAINTEXT']
              
      @connection.wait
        header: 'SASL_SSL'
        if: !!options['SASL_SSL']
        servers: options['SASL_SSL']


# Authconfig Intall

    module.exports = header: 'Authconfig Install', handler: ({options}) ->
    
      @service
        header: 'Package'
        name: 'authconfig'
      
      @system.authconfig
        header: 'Configuration'
        config: options.config

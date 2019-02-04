
# Shinken Commons Prepare

Download modules

    module.exports = header: 'Shinken Commons Prepare',  handler: (options) ->
      return unless options.prepare
        
## Python Modules

      @call header: 'Python Modules', ->
        for k, v of options.python_modules
          # @system.execute
          #   cmd: "curl -k https://pypi.python.org/simple/#{k}/"
          @file.cache
            header: k
            ssh: null
            location: true
            source: v.url
            cache_file: "#{v.archive}.#{v.format}"

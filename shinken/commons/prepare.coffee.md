
# Shinken Commons Prepare

Download modules

    module.exports =
      header: 'Shinken Prepare'
      if: -> @contexts('ryba/shinken/commons')[0]?.config.host is @config.host
      handler: ->
        {shinken} = @config.ryba

## Python Modules

        @call header: 'Python Modules', ->
          for k, v of shinken.python_modules
            @file.cache
              header: k
              source: v.url
              cache_file: "#{v.archive}.#{v.format}"

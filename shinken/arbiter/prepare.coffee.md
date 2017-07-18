
# Shinken Arbiter Prepare

Download modules

    module.exports =
      header: 'Shinken Arbiter Prepare'
      if: -> @contexts('ryba/shinken/arbiter')[0]?.config.host is @config.host
      handler: ->
        {arbiter} = @config.ryba.shinken

## Modules

        @call header: 'Modules', ->
          installmod = (name, mod) =>
            @file.cache
              source: mod.source
              cache_file: "#{mod.archive}.#{mod.format}"
            for subname, submod of mod.modules then installmod subname, submod
          for name, mod of arbiter.modules then installmod name, mod

## Python Modules

        @call header: 'Python Modules', ->
          for _, mod of arbiter.modules then for k,v of mod.python_modules
            @file.cache
                source: v.url
                cache_file: "#{v.archive}.#{v.format}"

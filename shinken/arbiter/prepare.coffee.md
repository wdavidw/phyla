
# Shinken Arbiter Prepare

Download modules

    module.exports =
      header: 'Shinken Arbiter Prepare'
      handler: (options) ->
        return unless options.prepare
## Modules

        @call header: 'Modules', ->
          installmod = (name, mod) =>
            @file.cache
              source: mod.source
              cache_file: "#{mod.archive}.#{mod.format}"
            for subname, submod of mod.modules then installmod subname, submod
          for name, mod of options.modules then installmod name, mod

## Python Modules

        @call header: 'Python Modules', ->
          for _, mod of options.modules then for k,v of mod.python_modules
            @file.cache
                source: v.url
                cache_file: "#{v.archive}.#{v.format}"

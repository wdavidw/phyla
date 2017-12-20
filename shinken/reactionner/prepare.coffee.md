
# Shinken Reactionner Prepare

    module.exports =
      header: 'Shinken Reactionner Prepare'
      handler: (options) ->

## Modules

        @call header: 'Modules', if: options.prepare, ->
          installmod = (name, mod) =>
            @file.cache
              source: mod.source
              cache_file: "#{mod.archive}.#{mod.format}"
            for subname, submod of mod.modules then installmod subname, submod
          for name, mod of options.modules then installmod name, mod

## Python Modules

        @call header: 'Python Modules', if: options.prepare, ->
          for _, mod of options.modules then for k,v of mod.python_modules
            @file.cache
                source: v.url
                cache_file: "#{v.archive}.#{v.format}"


# Apt Configure

## Options

* `packages` (object)   
   apt packages to install

    module.exports = (service) ->
      options = service.options

## Pip packages

      options.packages ?= {}
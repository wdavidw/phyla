
# Crontab Configure

## Options

* `purge` (boolean)   
   Should the module remove all pre existing crontabs before making sure provided ones are present
* `crontabs` (object)   
   K/V of arrays of crontab objects in the form `'user': [{when: "x x x x x", cmd: "foo bar"}]`

    module.exports = (service) ->
      options = service.options

## Crontabs purge

      options.purge ?= false

## Crontabs

      options.crontabs ?= {}
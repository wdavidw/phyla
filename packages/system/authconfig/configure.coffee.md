
# Authconfig Configure

## Options

* `config` (object, optional)   
  Key/value pairs of the properties to manage.

Example:

```json
{ "config": {
  mkhomedir: true
} }
```

    module.exports = ({options}) ->
      options.config ?= {}
      

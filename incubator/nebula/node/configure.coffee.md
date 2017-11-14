
# OpenNebula Node Configure

    module.exports = (service) ->
      options = service.options
      
      # throw Error "Required option: repo" unless options.repo
      # throw Error "Required option: server_public_key" unless options.server_public_key
      # options.server_public_key = options.server_public_key
      options.server_host = options.server_host

## Dependencies

    path = require 'path'

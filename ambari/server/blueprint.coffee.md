
# Ambari Server start

Ambari server is started with the service's syntax command.

    module.exports = header: 'Ambari Server Export', handler: (options) ->
      id = "#{Date.now()}"

## Blueprint

http://s07903v0.snm.snecma:8080/api/v1/blueprints

      clusters_url = url.format
        protocol: unless options.config['api.ssl'] is 'true'
        then 'http'
        else 'https'
        hostname: options.fqdn
        port: options.config['client.api.port']
        pathname: "/api/v1/clusters/#{options.cluster_nam}"
        query: 'format': 'blueprint'
      cred = "admin:#{options.admin_password}"
      @system.execute
        header: "Blueprint"
        cmd: """
        curl -f -k -u #{cred} #{clusters_url}
        """
      , (err, status, stdout) -> @call (_, callback) ->
        throw err if err
        fs.writeFile "doc/blueprints/#{Date.now()}_blueprint.json", stdout, callback

## Hosts

      clusters_url = url.format
        protocol: 'http'
        hostname: options.fqdn
        port: options.config['client.api.port']
        pathname: '/api/v1/clusters/dev_01/hosts'
      cred = "admin:#{options.admin_password}"
      @system.execute
        header: "Hosts"
        cmd: """
        curl -u #{cred} #{clusters_url}
        """
      , (err, status, stdout) -> @call (_, callback) ->
        throw err if err
        fs.writeFile "doc/blueprints/#{Date.now()}_hosts.json", stdout, callback

## Dependencies

    url = require 'url'
    fs = require 'fs'

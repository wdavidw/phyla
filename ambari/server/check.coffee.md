
# Ambari Server start

Ambari server is started with the service's syntax command.

    module.exports = header: 'Ambari Server Check', handler: (options) ->

Wait for the Ambari Server to be ready.

      @connection.assert
        header: 'Connection'
        host: options.fqdn
        port: unless options.config['api.ssl'] is true
        then options.config['client.api.port']
        else options.config['client.api.ssl.port']
        retry: 3
        sleep: 3000

## Check HTTP Server

      clusters_url = url.format
        protocol: if options.config['api.ssl'] is true
        then 'https'
        else 'http'
        hostname: options.fqdn
        port: if options.config['api.ssl'] is true
        then options.config['client.api.ssl.port']
        else options.config['client.api.port']
        pathname: '/api/v1/clusters'
      cred = "admin:#{options.admin_password}"
      @system.execute
        header: "Web"
        cmd: """
        curl -f -k -u #{cred} #{clusters_url}
        """

## Check Internal Port

      @connection.assert
        header: "REST Access"
        host: options.fqdn
        port: options.config['server.url_port'] # TODO: detect SSL

## Dependencies

    url = require 'url'

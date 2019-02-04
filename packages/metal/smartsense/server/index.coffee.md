# The Hortonworks SmartSense Tool (HST)

[The Hortonworks SmartSense Tool][hst] Collects cluster diagnostic information
to help you troubleshoot support cases.

    module.exports =
      use:
        iptables: module: 'masson/core/iptables', local: true
        java: module: 'masson/commons/java', local: true
        ssl: module: 'masson/core/ssl', local: true
      configure: '@rybajs/metal/smartsense/server/configure'
      commands:
        'install': ->
          options = @config.ryba.smartsense.server
          @call '@rybajs/metal/smartsense/server/install' , options
          @call '@rybajs/metal/smartsense/server/start' , options
          @call '@rybajs/metal/smartsense/server/wait' , options
          @call '@rybajs/metal/smartsense/server/check' , options
        'start': ->
          options = @config.ryba.smartsense.server
          @call '@rybajs/metal/smartsense/server/start', options
        'stop': ->
          options = @config.ryba.smartsense.server
          @call '@rybajs/metal/smartsense/server/start', options
        'check': ->
          options = @config.ryba.smartsense.server
          @call '@rybajs/metal/smartsense/server/wait', options
          @call '@rybajs/metal/smartsense/server/check', options

[hst]: (http://docs.hortonworks.com/HDPDocuments/SS1/SmartSense-1.3.0/bk_installation/content/architecture_overview.html)

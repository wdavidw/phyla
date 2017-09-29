# The Hortonworks SmartSense Tool (HST)

[The Hortonworks SmartSense Tool][hst] Collects cluster diagnostic information
to help you troubleshoot support cases.

    module.exports =
      use:
        iptables: module: 'masson/core/iptables', local: true
        java: module: 'masson/commons/java', local: true
        ssl: module: 'masson/core/ssl', local: true
      configure: 'ryba/smartsense/server/configure'
      commands:
        'install': ->
          options = @config.ryba.smartsense.server
          @call 'ryba/smartsense/server/install' , options
          @call 'ryba/smartsense/server/start' , options
          @call 'ryba/smartsense/server/wait' , options
          @call 'ryba/smartsense/server/check' , options
        'start': ->
          options = @config.ryba.smartsense.server
          @call 'ryba/smartsense/server/start', options
        'stop': ->
          options = @config.ryba.smartsense.server
          @call 'ryba/smartsense/server/start', options
        'check': ->
          options = @config.ryba.smartsense.server
          @call 'ryba/smartsense/server/wait', options
          @call 'ryba/smartsense/server/check', options

[hst]: (http://docs.hortonworks.com/HDPDocuments/SS1/SmartSense-1.3.0/bk_installation/content/architecture_overview.html)

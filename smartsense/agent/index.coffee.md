# The Hortonworks SmartSense Tool (HST)

[The Hortonworks SmartSense Tool][hst] Collects cluster diagnostic information
to help you troubleshoot support cases.

    module.exports =
      use:
        iptables: implicit: true, module: 'masson/core/iptables'
        java: implicit: true, module: 'masson/commons/java'
        smartsense_servers: 'ryba/smartsense/server'
      configure: 'ryba/smartsense/agent/configure'
      commands:
        'install': ->
          options = @config.ryba.smartsense.agent
          @call 'ryba/smartsense/agent/install', options
          @call 'ryba/smartsense/agent/check', options
        'check': ->
          options = @config.ryba.smartsense.agent
          @call 'ryba/smartsense/agent/check', options

[hst]: (http://docs.hortonworks.com/HDPDocuments/SS1/SmartSense-1.3.0/bk_installation/content/architecture_overview.html)

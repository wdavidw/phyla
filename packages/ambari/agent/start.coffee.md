
# Ambari Agent Start

Ambari Agent is started with the service's syntax command.

    module.exports = header: 'Ambari Agent Start', handler: ->

# Wait for Kerberos, Zookeeper, Hadoop and Hive.
# 
#       @call once: true, 'ryba-ambari-takeover/ambari/server/wait'

Start the service

      @service.start
        name: 'ambari-agent'

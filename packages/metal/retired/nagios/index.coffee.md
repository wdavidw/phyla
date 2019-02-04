
# Nagios

[Nagios][hdp] is an open source network monitoring system designed to monitor 
all aspects of your Hadoop cluster (such as hosts, services, and so forth) over 
the network. It can monitor many facets of your installation, ranging from 
operating system attributes like CPU and memory usage to the status of 
applications, files, and more. Nagios provides a flexible, customizable 
framework for collecting data on the state of your Hadoop cluster.

    module.exports =
      use:
        krb5_client: module: 'masson/core/krb5_client'
      configure:
        '@rybajs/metal/nagios/configure'
      commands:
        'backup': '@rybajs/metal/nagios/backup'
        'check': '@rybajs/metal/nagios/check'
        'install': [
          'masson/commons/httpd'
          'masson/commons/java'
          '@rybajs/metal/oozie/client/install'
          '@rybajs/metal/nagios/install'
          '@rybajs/metal/nagios/check' # Must be executed before start
          '@rybajs/metal/nagios/start'
        ]
        'start': '@rybajs/metal/nagios/start'
        'status': '@rybajs/metal/nagios/status'
        'stop': '@rybajs/metal/nagios/stop'

[hdp]: http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.1/bk_Monitoring_Hadoop_Book/content/monitor-chap3-1.html

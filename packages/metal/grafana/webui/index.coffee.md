
# grafana/webui Install

Grafan is a great WEB Ui to visualize metrics, and cluster operations data. it allow Users
to create dashboard and organize collected metrics.

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        ssl: module: 'masson/core/ssl', local: true
        db_admin: module: '@rybajs/metal/commons/db_admin', local: true, auto: true, implicit: true
        grafana_repo: module: '@rybajs/metal/grafana/repo'
        grafana_webui: module: '@rybajs/metal/grafana/webui'
        zookeeper_server: module: '@rybajs/metal/zookeeper/server'
        hadoop_core: module: '@rybajs/metal/hadoop/core'
        hdfs_dn: module: '@rybajs/metal/hadoop/hdfs_dn'
        hdfs_jn: module: '@rybajs/metal/hadoop/hdfs_jn'
        hdfs_nn: module: '@rybajs/metal/hadoop/hdfs_nn'
        yarn_nm: module: '@rybajs/metal/hadoop/yarn_nm'
        yarn_rm: module: '@rybajs/metal/hadoop/yarn_rm'
        hbase_master: module: '@rybajs/metal/hbase/master'
        collectd_exporter: module: '@rybajs/metal/prometheus/collectd_exporter'
        prometheus_monitor: '@rybajs/metal/prometheus/monitor'
      configure:
        '@rybajs/metal/grafana/webui/configure'
      commands:
        install: [
          '@rybajs/metal/grafana/webui/install'
          '@rybajs/metal/grafana/webui/start'
          '@rybajs/metal/grafana/webui/check'
          '@rybajs/metal/grafana/webui/setup'
        ]
        prepare:
          '@rybajs/metal/grafana/webui/prepare'

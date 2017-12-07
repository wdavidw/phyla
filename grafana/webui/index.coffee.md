
# grafana/webui Install

Grafan is a great WEB Ui to visualize metrics, and cluster operations data. it allow Users
to create dashboard and organize collected metrics.

    module.exports =
      deps:
        ssl: module: 'masson/core/ssl', local: true
        db_admin: module: 'ryba/commons/db_admin', local: true, auto: true, implicit: true
        grafana_repo: module: 'ryba/grafana/repo'
        grafana_webui: module: 'ryba/grafana/webui'
        zookeeper_server: module: 'ryba/zookeeper/server'
        hadoop_core: module: 'ryba/hadoop/core'
        hdfs_dn: module: 'ryba/hadoop/hdfs_dn'
        hdfs_jn: module: 'ryba/hadoop/hdfs_jn'
        hdfs_nn: module: 'ryba/hadoop/hdfs_nn'
        yarn_nm: module: 'ryba/hadoop/yarn_nm'
        yarn_rm: module: 'ryba/hadoop/yarn_rm'
        hbase_master: module: 'ryba/hbase/master'
        prometheus_monitor: 'ryba/prometheus/monitor'
      configure:
        'ryba/grafana/webui/configure'
      commands:
        install: [
          'ryba/grafana/webui/install'
          'ryba/grafana/webui/start'
          'ryba/grafana/webui/check'
          'ryba/grafana/webui/setup'
        ]
        prepare:
          'ryba/grafana/webui/prepare'

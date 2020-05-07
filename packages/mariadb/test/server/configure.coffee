normalize = require 'masson/lib/config/normalize'

describe 'MariaDB - server configuration', ->
    
  it 'default properties', () ->
    normalize
      nodes: 'my_local_lxd_container': ip: '10.0.0.1', tags: 'type': 'test_container'
      clusters: 'cluster_test':
        services: 'service_mariadb':
          module: './src/server'
          affinity: type: 'nodes', values: 'my_local_lxd_container'
          options: admin_password: "secret", ssl: enabled: false
    .clusters.cluster_test.services.service_mariadb.instances[0].options.should.eql
      admin_password: 'secret',
      ssl: enabled: false
      sql_on_install: [],
      current_password: '',
      admin_username: 'root',
      remove_anonymous: true,
      disallow_remote_root_login: false,
      remove_test_db: true,
      reload_privileges: true,
      fqdn: 'my_local_lxd_container',
      iptables: undefined,
      group: name: 'mysql'
      user: name: 'mysql', home: '/var/lib/mysql', gid: 'mysql'
      name: 'mariadb-server',
      srv_name: 'mariadb',
      chk_name: 'mariadb',
      my_cnf:
        mysqld:
          general_log: 'OFF',
          general_log_file: '/var/lib/mysql/log/log-general.log',
          'log-bin': '/var/lib/mysql/log/bin',
          binlog_format: 'mixed',
          port: '3306',
          'bind-address': '0.0.0.0',
          'pid-file': '/var/run/mariadb/mysql.pid',
          socket: '/var/lib/mysql/mysql.sock',
          datadir: '/var/lib/mysql/data',
          user: 'mysql',
          event_scheduler: 'ON',
          'character-set-server': 'latin1',
          'collation-server': 'latin1_swedish_ci',
          'skip-external-locking': '',
          key_buffer_size: '384M',
          max_allowed_packet: '1M',
          table_open_cache: '512',
          sort_buffer_size: '2M',
          read_buffer_size: '2M',
          read_rnd_buffer_size: '8M',
          myisam_sort_buffer_size: '64M',
          thread_cache_size: '8',
          query_cache_size: '32M',
          'secure-auth': '',
          'secure-file-priv': '/var/lib/mysql/upload',
          max_connections: '100',
          max_user_connections: '50',
          'log-error': '/var/log/mysqld/error.log',
          slow_query_log_file: '/var/lib/mysql/log/slow-queries.log',
          long_query_time: '4',
          expire_logs_days: '7',
          innodb_file_per_table: '',
          innodb_data_home_dir: '/var/lib/mysql/data',
          innodb_data_file_path: 'ibdata1:10M:autoextend',
          innodb_log_group_home_dir: '/var/lib/mysql/log',
          innodb_buffer_pool_size: '384M',
          innodb_log_file_size: '100M',
          innodb_log_buffer_size: '8M',
          innodb_flush_log_at_trx_commit: '1',
          innodb_lock_wait_timeout: '50'
        mysqldump: quick: '', max_allowed_packet: '16M'
        mysql: 'no-auto-rehash': ''
        myisamchk: key_buffer_size: '256M', sort_buffer_size: '256M', read_buffer: '2M', write_buffer: '2M'
        mysqlhotcopy: 'interactive-timeout': ''
        client: socket: '/var/lib/mysql/mysql.sock'
        mysqld_safe: 'pid-file': '/var/run/mariadb/mysql.pid'
      ha_enabled: false,
      journal_log_dir: '/var/lib/mysql/log',
      repo: source: null, target: '/etc/yum.repos.d/mariadb.repo', replace: 'mariadb*'
      wait_tcp: fqdn: 'my_local_lxd_container', port: '3306'

  it 'ssl properties', () ->
    config = normalize
      nodes: 'my_local_lxd_container': ip: '10.0.0.1', tags: 'type': 'test_container'
      clusters: 'cluster_test':
        services: 'service_mariadb':
          module: './src/server'
          affinity: type: 'nodes', values: 'my_local_lxd_container'
          options:
            admin_password: "secret"
            ssl:
              enabled: true,
              cacert: source: "/etc/mariadb/ca.pem"
              cert: source: "/etc/mariadb/cert.pem"
              key: source: "/etc/mariadb/key.pem"
    # Retrieving the service_mariadb object
    {ssl, my_cnf} = config.clusters.cluster_test.services.service_mariadb.instances[0].options
    ssl.should.eql
      enabled: true,
      cacert: source: '/etc/mariadb/ca.pem', local:false
      cert: source: '/etc/mariadb/cert.pem', local:false
      key: source: '/etc/mariadb/key.pem', local:false
    my_cnf.mysqld.should.containEql
      'ssl-ca' : '/var/lib/mysql/tls/ca.pem'
      'ssl-key' : '/var/lib/mysql/tls/key.pem'
      'ssl-cert' : '/var/lib/mysql/tls/cert.pem'
    
  it 'ha properties', () ->
    config = normalize
      nodes:
        'my_local_lxd_container': ip: '10.0.0.1', tags: 'type': 'test_container'
        'my_remote_lxd_container': ip: '10.0.0.2', tags: 'type': 'test_container'
      clusters: 'cluster_test':
        services: 'service_mariadb':
          module: './src/server'
          affinity: type: 'nodes', match: 'any', values: ['my_local_lxd_container', 'my_remote_lxd_container']
          options:
            admin_password: "secret"
            ssl: enabled: false
            repl_master: admin_password: 'passwd_one', password: 'passwd_two'
    # Retrieving options for node 1
    options = config.clusters.cluster_test.services.service_mariadb.instances[0].options
    options.should.containEql
      ha_enabled : true
      replication_dir : '/var/lib/mysql/replication'
      id : 1
    {repl_master, my_cnf} = config.clusters.cluster_test.services.service_mariadb.instances[0].options
    repl_master.should.eql
      admin_password: 'passwd_one',
      password: 'passwd_two',
      fqdn: 'my_remote_lxd_container',
      admin_username: 'root',
      username: 'repl'
    my_cnf.mysqld.should.containEql
      'server-id' : 1
      'relay-log' : '/var/lib/mysql/replication/mysql-relay-bin'
      'relay-log-index' : '/var/lib/mysql/replication/mysql-relay-bin.index'
      'master-info-file' : '/var/lib/mysql/replication/master.info'
      'relay-log-info-file' : '/var/lib/mysql/replication/relay-log.info'
      'log-slave-updates' : ''
      'replicate-same-server-id' : '0'
      'slave-skip-errors' : '1062'
    # Retrieving options for node 2
    options = config.clusters.cluster_test.services.service_mariadb.instances[1].options
    options.should.containEql
      ha_enabled : true
      replication_dir : '/var/lib/mysql/replication'
      id : 2
    {repl_master, my_cnf} = config.clusters.cluster_test.services.service_mariadb.instances[1].options
    repl_master.should.eql
      admin_password: 'passwd_one',
      password: 'passwd_two',
      fqdn: 'my_local_lxd_container',
      admin_username: 'root',
      username: 'repl'
    my_cnf.mysqld.should.containEql
      'server-id' : 2
      'relay-log' : '/var/lib/mysql/replication/mysql-relay-bin'
      'relay-log-index' : '/var/lib/mysql/replication/mysql-relay-bin.index'
      'master-info-file' : '/var/lib/mysql/replication/master.info'
      'relay-log-info-file' : '/var/lib/mysql/replication/relay-log.info'
      'log-slave-updates' : ''
      'replicate-same-server-id' : '0'
      'slave-skip-errors' : '1062'

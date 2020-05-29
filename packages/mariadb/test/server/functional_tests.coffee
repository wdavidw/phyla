path = require 'path'
nikita = require 'nikita'
build_env_script = path.join(__dirname, './../../env/build_env.coffee')
generate_script_path = path.join(__dirname, './../server/cert/generate')
each = require 'each'
store = require 'masson/lib/config/store'
multimatch = require 'masson/lib/utils/multimatch'
{merge} = require 'mixme'
array_get = require 'masson/lib/utils/array_get'
normalize = require 'masson/lib/config/normalize'

describe 'MariaDB installation - Functionnal tests (may take 10+ minutes)', ->

  @timeout 1500000 # Extended timeout for these lengthy test
      
  it 'default conf tests', () ->
    await nikita
    .call ->
      this
      .system.execute
        header: 'Test Environment Creation'
        cmd: "coffee #{build_env_script}"
      , (err, {status}) ->
        status.should.be.true() unless err
      .system.execute
        header: 'Verify node1 running'
        cmd: '[[ `lxc ls | grep "node1 | RUNNING"` ]] && echo "node1 running" || echo "node1 not running"'
      , (err, {stdout}) ->
        stdout.should.eql 'node1 running\n' unless err
      .system.execute
        header: 'Verify node1 IP'
        cmd: 'ping -c 1 11.10.10.11'
      , (err, {status}) ->
        status.should.be.true() unless err
      .promise()
    .call ->
      config = normalize
        clusters: 'cluster_test':
          services: './src/server':
            affinity: type: 'nodes', match: 'any', values: 'node1'
            options: admin_username: 'root', admin_password: 'secret', ssl: enabled: false
        nodes: 'node1': ip: '11.10.10.11', tags: 'type': 'node', cluster: 'cluster_test'
        nikita: ssh: username: 'nikita', private_key_path: path.join __dirname,"./../../env/assets/id_rsa"
      params = command: [ 'clusters', 'install' ], config: config
      command = params.command.slice(-1)[0]
      s = store(config)
      each s.nodes()
      .parallel(true)
      .call (node, callback) ->
        services = node.services
        config.nikita.no_ssh = true
        n = nikita merge config.nikita
        n.ssh.open
          header: 'SSH Open'
          host: node.ip or node.fqdn
        , node.ssh
        n.call ->
          for service in services
            service = s.service service.cluster, service.service
            instance = array_get service.instances, (instance) -> instance.node.id is node.id
            for module in service.commands[command]
              isRoot = config.nikita.ssh.username is 'root' or not config.nikita.ssh.username
              n.call module, merge instance.options, sudo: not isRoot
        n.next (err) ->
          n.ssh.close header: 'SSH Close'
          n.next -> callback err
      .promise()
    .call ->
      this
      .system.execute
        header: 'Check'
        cmd: """
        lxc exec node1 -- bash -c 'mysql --password=secret -e "SHOW DATABASES;"'
        """
      , (err, {stdout}) ->
        stdout.should.eql 'Database\ninformation_schema\nmysql\nperformance_schema\n' unless err
      .promise()
    .promise()
      
  it 'Replication conf tests', () ->
    await nikita
    .call ->
      this
      .system.execute
        header: 'Test Environment Creation'
        cmd: "coffee #{build_env_script}"
      , (err, {status}) ->
        status.should.be.true() unless err
      .system.execute
        header: 'Verify node1 running'
        cmd: '[[ `lxc ls | grep "node1 | RUNNING"` ]] && echo "node1 running" || echo "node1 not running"'
      , (err, {stdout}) ->
        stdout.should.eql 'node1 running\n' unless err
      .system.execute
        header: 'Verify node2 running'
        cmd: '[[ `lxc ls | grep "node2 | RUNNING"` ]] && echo "node2 running" || echo "node2 not running"'
      , (err, {stdout}) ->
        stdout.should.eql 'node2 running\n' unless err
      .system.execute
        header: 'Verify node1 IP'
        cmd: 'ping -c 1 11.10.10.11'
      , (err, {status}) ->
        status.should.be.true() unless err
      .system.execute
        header: 'Verify node2 IP'
        cmd: 'ping -c 1 11.10.10.12'
      , (err, {status}) ->
        status.should.be.true() unless err
      .promise()
    .call ->
      config = normalize
        clusters: 'cluster_test':
          services: './src/server':
            affinity: type: 'nodes', match: 'any', values: ['node1', 'node2']
            options: admin_username: 'root', admin_password: 'secret', ssl: (enabled: false), repl_master: (admin_password: 'secret', password: 'secret')
        nodes: 'node1': (ip: '11.10.10.11', tags: 'type': 'node', cluster: 'cluster_test'), 'node2': (ip: '11.10.10.12', tags: 'type': 'node', cluster: 'cluster_test')
        nikita: ssh: username: 'nikita', private_key_path: path.join __dirname,"./../../env/assets/id_rsa"
      params = command: [ 'clusters', 'install' ], config: config
      command = params.command.slice(-1)[0]
      s = store(config)
      each s.nodes()
      .parallel(true)
      .call (node, callback) ->
        services = node.services
        config.nikita.no_ssh = true
        n = nikita merge config.nikita
        n.ssh.open
          header: 'SSH Open'
          host: node.ip or node.fqdn
        , node.ssh
        n.call ->
          for service in services
            service = s.service service.cluster, service.service
            instance = array_get service.instances, (instance) -> instance.node.id is node.id
            for module in service.commands[command]
              isRoot = config.nikita.ssh.username is 'root' or not config.nikita.ssh.username
              n.call module, merge instance.options, sudo: not isRoot
        n.next (err) ->
          n.ssh.close header: 'SSH Close'
          n.next -> callback err
      .promise()
    .call ->
      this
      .system.execute
        header: 'Check'
        cmd: """
        lxc exec node1 -- bash -c 'mysql --password=secret -e "CREATE DATABASE MyData"'
        lxc exec node2 -- bash -c 'mysql --password=secret -e "SHOW DATABASES;"'
        """
      , (err, {stdout}) ->
        stdout.should.eql 'Database\ninformation_schema\nMyData\nmysql\nperformance_schema\n' unless err
      .promise()
    .promise()
      
  it 'ssl conf tests', () ->
    await nikita
    .call ->
      this
      .system.execute
        header: 'Test Environment Creation'
        cmd: "coffee #{build_env_script}"
      , (err, {status}) ->
        status.should.be.true() unless err
      .system.execute
        header: 'Verify node1 running'
        cmd: '[[ `lxc ls | grep "node1 | RUNNING"` ]] && echo "node1 running" || echo "node1 not running"'
      , (err, {stdout}) ->
        stdout.should.eql 'node1 running\n' unless err
      .system.execute
        header: 'Verify node2 running'
        cmd: '[[ `lxc ls | grep "node2 | RUNNING"` ]] && echo "node2 running" || echo "node2 not running"'
      , (err, {stdout}) ->
        stdout.should.eql 'node2 running\n' unless err
      .system.execute
        header: 'Verify node1 IP'
        cmd: 'ping -c 1 11.10.10.11'
      , (err, {status}) ->
        status.should.be.true() unless err
      .system.execute
        header: 'Verify node2 IP'
        cmd: 'ping -c 1 11.10.10.12'
      , (err, {status}) ->
        status.should.be.true() unless err
      # Generate all the necessary files
      .system.execute
        header: 'Create Certificates'
        cmd: """
        sh #{generate_script_path} cacert
        sh #{generate_script_path} cert server
        sh #{generate_script_path} cert client
        """
      , (err, {status}) ->
        status.should.be.true() unless err
      .file.assert
        header: 'server.cert created'
        source: path.join(__dirname,"./cert/server.cert.pem")
      .file.assert
        header: 'client.cert created'
        source: path.join(__dirname,"/cert/client.cert.pem")
      # Sevrer SSL files
      .lxd.file.push
        header: 'Copy server cert'
        container: "node1"
        gid: 'root'
        uid: 'root'
        source: path.join(__dirname,"./cert/server.cert.pem")
        target: '/etc/ssl/server.cert.pem'
      , (err, {status}) ->
        status.should.be.true() unless err
      .lxd.file.push
        header: 'Copy server key'
        container: "node1"
        gid: 'root'
        uid: 'root'
        source: path.join(__dirname,"./cert/server.key.pem")
        target: '/etc/ssl/server.key.pem'
      , (err, {status}) ->
        status.should.be.true() unless err
      .lxd.file.push
        header: 'Copy server ca-cert'
        container: "node1"
        gid: 'root'
        uid: 'root'
        source: path.join(__dirname,"./cert/ca.cert.pem")
        target: '/etc/ssl/ca.cert.pem'
      , (err, {status}) ->
        status.should.be.true() unless err
      # Client SSL files
      .lxd.file.push
        header: 'Copy client cert'
        container: "node2"
        gid: 'root'
        uid: 'root'
        source: path.join(__dirname,"/cert/client.cert.pem")
        target: '/etc/ssl/client.cert.pem'
      , (err, {status}) ->
        status.should.be.true() unless err
      .lxd.file.push
        header: 'Copy client key'
        container: "node2"
        gid: 'root'
        uid: 'root'
        source: path.join(__dirname,"./cert/client.key.pem")
        target: '/etc/ssl/client.key.pem'
      , (err, {status}) ->
        status.should.be.true() unless err
      .lxd.file.push
        header: 'Copy client ca-cert'
        container: "node2"
        gid: 'root'
        uid: 'root'
        source: path.join(__dirname,"./cert/ca.cert.pem")
        target: '/etc/ssl/ca.cert.pem'
      , (err, {status}) ->
        status.should.be.true() unless err
      .system.execute
        header: 'Local cert deletion'
        cmd: """
        cd ./test/server/cert
        rm -rf ca.cert.pem ca.key.pem ca.seq client.cert.pem client.key.pem server.cert.pem server.key.pem
        """
      , (err, {status}) ->
        status.should.be.true() unless err
      .promise()
    .call ->
      config = normalize
        clusters: 'cluster_test':
          services: './src/server':
            affinity: type: 'nodes', match: 'any', values: 'node1'
            options:
              admin_username: 'root'
              admin_password: 'secret'
              ssl:
                enabled: true
                cacert: source: '/etc/ssl/ca.cert.pem'
                cert: source: '/etc/ssl/server.cert.pem'
                key: source: '/etc/ssl/server.key.pem'
        nodes: 'node1': ip: '11.10.10.11', tags: 'type': 'node', cluster: 'cluster_test'
        nikita: ssh: username: 'nikita', private_key_path: path.join __dirname,'/../../env/assets/id_rsa'
      params = command: [ 'clusters', 'install' ], config: config
      command = params.command.slice(-1)[0]
      s = store(config)
      each s.nodes()
      .parallel(true)
      .call (node, callback) ->
        services = node.services
        config.nikita.no_ssh = true
        n = nikita merge config.nikita
        n.ssh.open
          header: 'SSH Open'
          host: node.ip or node.fqdn
        , node.ssh
        n.call ->
          for service in services
            service = s.service service.cluster, service.service
            instance = array_get service.instances, (instance) -> instance.node.id is node.id
            for module in service.commands[command]
              isRoot = config.nikita.ssh.username is 'root' or not config.nikita.ssh.username
              n.call module, merge instance.options, sudo: not isRoot
        n.next (err) ->
          n.ssh.close header: 'SSH Close'
          n.next -> callback err
      .promise()
    .call ->
      config = normalize
        clusters: 'cluster_test':
          services: './src/client':
            affinity: type: 'nodes', match: 'any', values: 'node2'
            options: admin_username: 'root', admin_password: 'secret'
        nodes: 'node2': ip: '11.10.10.12', tags: 'type': 'node', cluster: 'cluster_test'
        nikita: ssh: username: 'nikita', private_key_path: path.join(__dirname,"./../../env/assets/id_rsa")
      params = command: [ 'clusters', 'install' ], config: config
      command = params.command.slice(-1)[0]
      s = store(config)
      each s.nodes()
      .parallel(true)
      .call (node, callback) ->
        services = node.services
        config.nikita.no_ssh = true
        n = nikita merge config.nikita
        n.ssh.open
          header: 'SSH Open'
          host: node.ip or node.fqdn
        , node.ssh
        n.call ->
          for service in services
            service = s.service service.cluster, service.service
            instance = array_get service.instances, (instance) -> instance.node.id is node.id
            for module in service.commands[command]
              isRoot = config.nikita.ssh.username is 'root' or not config.nikita.ssh.username
              n.call module, merge instance.options, sudo: not isRoot
        n.next (err) ->
          n.ssh.close header: 'SSH Close'
          n.next -> callback err
      .promise()
    .call ->
      this
      .system.execute
        header: 'Give privileges'
        cmd: """
        lxc exec node2 -- bash -c 'echo "ssl-ca=/etc/ssl/ca.cert.pem">>/etc/my.cnf.d/client.cnf'
        lxc exec node2 -- bash -c 'echo "ssl-cert=/etc/ssl/client.cert.pem">>/etc/my.cnf.d/client.cnf'
        lxc exec node2 -- bash -c 'echo "ssl-key=/etc/ssl/client.key.pem">>/etc/my.cnf.d/client.cnf'
        """
      , (err, {status}) ->
        status.should.be.true() unless err
      .system.execute
        header: 'Check SSL'
        cmd: """
        lxc exec node2 -- bash -c 'mysql --password=secret -h node1 -e "STATUS"'
        """
      , (err, {stdout}) ->
        stdout.should.containEql 'Cipher in use' unless err
      .system.execute
        header: 'SSH keys deletion'
        cmd: """
        cd ./env/assets
        rm -rf id_rsa id_rsa.pub
        cd ./../../log
        rm -rf node1.log node2.log
        """
      , (err, {status}) ->
        status.should.be.true() unless err
      .promise()
    .promise()

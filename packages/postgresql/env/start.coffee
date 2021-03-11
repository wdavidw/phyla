nikita = require 'nikita'
path = require 'path'

nikita(
  $debug: true,
  () ->
    await @log.cli()
    # .log.md "#{process.env.PWD}/log"
    # This works
    .execute
      trap: false
      command: [
        "cat <<'NIKITALXDEXEC' | lxc exec ryba-pg-test-1 -- sh"
        'set -e'
        'command -v openssl && exit 42'
        'if command -v yum >/dev/null 2>&1; then'
        '  yum -y install openssl'
        'elif command -v apt-get >/dev/null 2>&1; then'
        '  apt-get -y install openssl'
        'else'
        '  echo "Unsupported Package Manager" >&2 && exit 2'
        'fi'
        'command -v openssl'
        'NIKITALXDEXEC'
      ].join '\n'
    # This fails at openssl install
    .lxc.cluster
      $header: 'Create PostgreSQL test cluster'
      networks:
        rybapgtestpub:
          'ipv4.address': '192.168.255.1/28'
          'ipv4.nat': true
          'ipv6.address': 'none'
          'dns.domain': 'ryba.pg.test.local'
        rybapgtestpriv:
          'ipv4.address': '10.10.10.1/28'
          'ipv4.nat': false
          'ipv6.address': 'none'
      containers:
        'ryba-pg-test-1':
          image: 'images:centos/7'
          disk:
            nikitadir:
              path: '/ryba'
              source: path.join __dirname, "./../../../"
          nic:
            eth0:
              nictype: 'bridged'
              parent: 'rybapgtestpub'
            eth1:
              nictype: 'bridged'
              parent: 'rybapgtestpriv'
              ip: '10.10.10.11'
              netmask: '255.255.255.0'
          proxy:
            ssh: listen: 'tcp:0.0.0.0:2550', connect: 'tcp:127.0.0.1:22'
          ssh:
            enabled: true
          user:
            nikita:
              sudo: true
              authorized_keys: path.join __dirname, "./assets/id_rsa.pub"

).catch console.log

  # prevision: () ->
  #   @tools.ssh.keygen
  #     header: 'SSH key'
  #     target: path.join __dirname, "./assets/id_rsa"
  #     bits: 2048
  #     key_format: 'PEM'
  #     comment: 'nikita'

# await console.log(status)

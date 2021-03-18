path = require 'path'

module.exports =
  config:
    networks:
      rybapgtestpub:
        'ipv4.address': '192.168.255.1/28'
        'ipv4.nat': true
        'ipv6.address': 'none'
        'dns.domain': 'standolone.pgsql.ryba'
      rybapgtestprv:
        'ipv4.address': '10.10.10.1/28'
        'ipv4.nat': false
        'ipv6.address': 'none'
    containers:
      'ryba-pg-test-1':
        image: 'images:centos/7'
        # disk:
        #   nikitadir:
        #     path: '/ryba'
        #     source: path.join __dirname, "../../../"
        nic:
          eth0:
            nictype: 'bridged'
            parent: 'rybapgtestpub'
          eth1:
            nictype: 'bridged'
            parent: 'rybapgtestprv'
            ip: '10.10.10.11'
            netmask: '255.255.255.0'
        ssh: enabled: true
        user:
          nikita:
            sudo: true
            authorized_keys: path.join __dirname, ".assets/id_rsa.pub"
    prevision: ({ options }) ->
      @tools.ssh.keygen
        header: 'Generate SSH key'
        target: path.join __dirname, ".assets/id_rsa"
        bits: 2048
        key_format: 'PEM'
        comment: 'nikita'

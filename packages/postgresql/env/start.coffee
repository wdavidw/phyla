nikita = require 'nikita'
path = require 'path'

nikita
.log.cli()
.log.md basedir: path.join __dirname, "/.log"
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
          source: path.join __dirname, "/../../../"
      nic:
        eth0:
          nictype: 'bridged'
          parent: 'rybapgtestpub'
        eth1:
          nictype: 'bridged'
          parent: 'rybapgtestpriv'
          ip: '10.10.10.11'
          netmask: '255.255.255.0'
      ssh: enabled: true
      user:
        nikita:
          sudo: true
          authorized_keys: path.join __dirname, "/.assets/id_rsa.pub"
    'ryba-pg-test-2':
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
          ip: '10.10.10.12'
          netmask: '255.255.255.0'
      ssh: enabled: true
      user:
        nikita:
          sudo: true
          authorized_keys: path.join __dirname, "/.assets/id_rsa.pub"
  prevision: ({ options }) ->
    @tools.ssh.keygen
      header: 'Generate SSH key'
      target: path.join __dirname, "/.assets/id_rsa"
      bits: 2048
      key_format: 'PEM'
      comment: 'nikita'

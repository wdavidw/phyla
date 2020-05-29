nikita = require 'nikita'
path = require 'path'

# Notes:
# SSH private and public keys will be generated in an "assets" directory
# inside the current working directory.
nikita
.log.cli pad: host: 20, header: 60
# Delete existing test containers
.lxd.delete
  header: 'Remove existing node1'
  if_exec: '[[ `lxc ls | grep node1` ]] && exit 0 || exit 1'
  force: true
  container: 'node1'
.lxd.delete
  header: 'Remove existing node2'
  if_exec: '[[ `lxc ls | grep node2` ]] && exit 0 || exit 1'
  force: true
  container: 'node2'
.lxd.network.delete
  header: 'Remove existing Network PubRybMarTest'
  if_exec: '[[ `lxc network ls | grep PubRybMarTest` ]] && exit 0 || exit 1'
  network: 'PubRybMarTest'
.lxd.network.delete
  header: 'Remove existing Network PrivRybMarTest'
  if_exec: '[[ `lxc network ls | grep PrivRybMarTest` ]] && exit 0 || exit 1'
  network: 'PrivRybMarTest'
# Create new test containers
.lxd.cluster
  header: 'Create new test Containers'
  networks:
    PubRybMarTest:
      'ipv4.address': '172.16.0.1/24'
      'ipv4.nat': true
      'ipv6.address': 'none'
      'dns.domain': 'nikita'
    PrivRybMarTest:
      'ipv4.address': '11.10.10.1/24'
      'ipv4.nat': false
      'ipv6.address': 'none'
      'dns.domain': 'nikita'
  containers:
    node1:
      image: 'images:centos/7'
      disk:
        nikitadir:
          path: '/ryba'
          source: path.join(__dirname,"./../../../")
      nic:
        eth0:
          config: name: 'eth0', nictype: 'bridged', parent: 'PubRybMarTest'
        eth1:
          config: name: 'eth1', nictype: 'bridged', parent: 'PrivRybMarTest'
          ip: '11.10.10.11', netmask: '255.255.255.0'
      proxy:
        ssh: listen: 'tcp:0.0.0.0:2201', connect: 'tcp:127.0.0.1:22'
      ssh: enabled: true
      user:
        nikita: sudo: true, authorized_keys: path.join(__dirname,"./assets/id_rsa.pub")
    node2:
      image: 'images:centos/7'
      disk:
        nikitadir:
          path: '/ryba'
          source: path.join(__dirname,"./../../../")
      nic:
        eth0:
          config: name: 'eth0', nictype: 'bridged', parent: 'PubRybMarTest'
        eth1:
          config: name: 'eth1', nictype: 'bridged', parent: 'PrivRybMarTest'
          ip: '11.10.10.12', netmask: '255.255.255.0'
      proxy:
        ssh: listen: 'tcp:0.0.0.0:2202', connect: 'tcp:127.0.0.1:22'
      ssh: enabled: true
      user:
        nikita: sudo: true, authorized_keys: path.join(__dirname,"./assets/id_rsa.pub")
  prevision: ({options}) ->
    @tools.ssh.keygen
      header: 'SSH key'
      target: path.join(__dirname,"./assets/id_rsa")
      bits: 2048
      key_format: 'PEM'
      comment: 'nikita'
  provision_container: ({options}) ->
    nikita
    .system.execute
      header: 'Keys permissions'
      debug: true
      cmd: """
      cd ./env/assets
      chmod 777 id_rsa id_rsa.pub
      """
    @lxd.exec
      header: 'Node.js'
      container: options.container
      cmd: """
      command -v node && exit 42
      curl -L https://raw.githubusercontent.com/tj/n/master/bin/n -o n
      bash n lts
      """
      trap: true
      code_skipped: 42
    @lxd.file.push
      header: 'User Private Key'
      container: options.container
      gid: 'nikita'
      uid: 'nikita'
      source: path.join(__dirname,"./assets/id_rsa")
      target: '/home/nikita/.ssh/id_rsa'
    @lxd.exec
      header: 'Root SSH dir'
      container: options.container
      cmd: 'mkdir -p /root/.ssh && chmod 700 /root/.ssh'
    @lxd.file.push
      header: 'Root SSH Private Key'
      container: options.container
      gid: 'root'
      uid: 'root'
      source: path.join(__dirname,"./assets/id_rsa")
      target: '/root/.ssh/id_rsa'
.next (err) ->
  throw err if err

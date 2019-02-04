
# Hadoop ZKFC Check

    module.exports = header: 'HDFS ZKFC Check', handler: ({options}) ->

## Test SSH Fencing

The sshfence option SSHes to the target node and uses fuser to kill the process
listening on the service's TCP port. In order for this fencing option to work,
it must be able to SSH to the target node without providing a passphrase. Thus,
one must also configure the "dfs.ha.fencing.ssh.private-key-files" option, which
is a comma-separated list of SSH private key files.

Strict host key checking is disabled during this check with the
"StrictHostKeyChecking" argument set to "no".

        source = options.active_nn_host
        target = options.standby_nn_host
        [target, source] = [source, target] unless options.fqdn is options.active_nn_host
        @system.execute
          header: 'SSH Fencing'
          retry: 100
          cmd: "su -l #{options.user.name} -c \"ssh -q -o StrictHostKeyChecking=no #{options.user.name}@#{target} hostname\""

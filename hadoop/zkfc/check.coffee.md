
# Hadoop ZKFC Check

    module.exports = header: 'HDFS ZKFC Check', handler: ->
        {hdfs} = @config.ryba
        nn_ctxs = @contexts 'ryba/hadoop/hdfs_nn'

## Test SSH Fencing

The sshfence option SSHes to the target node and uses fuser to kill the process
listening on the service's TCP port. In order for this fencing option to work,
it must be able to SSH to the target node without providing a passphrase. Thus,
one must also configure the "dfs.ha.fencing.ssh.private-key-files" option, which
is a comma-separated list of SSH private key files.

Strict host key checking is disabled during this check with the
"StrictHostKeyChecking" argument set to "no".

        for nn_ctx in nn_ctxs
          source = nn_ctx.config.host if nn_ctx.config.host is @config.host
          target = nn_ctx.config.host if nn_ctx.config.host isnt @config.host
        @system.execute
          header: 'SSH Fencing'
          if: -> nn_ctxs.length > 1
          retry: 100
          cmd: "su -l #{hdfs.user.name} -c \"ssh -q -o StrictHostKeyChecking=no #{hdfs.user.name}@#{target} hostname\""

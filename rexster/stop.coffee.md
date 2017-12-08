
# Rexster Stop

Run the command `./bin/ryba stop -m ryba/titan/rexster` to stop the Rexster
server using Ryba. 
You can also stop the server manually with the following command:

```
ps aux | grep "rexster"
kill ...
```

    module.exports = header: 'Rexster Stop', handler: ->
      {titan, rexster} = @config.ryba
      @system.execute
        cmd: """
        p=`ps aux | grep "com.tinkerpop.rexster.Application" | grep -v grep`
        if [ -z "$p" ]; then exit 3; fi
        pid=`echo $p | sed 's/rexter \\([0-9]*\\) .*/\\1/'`
        echo 'Kill'
        #{titan.home}/bin/rexster.sh --stop --wait -rp #{rexster.config['shutdown-port']} | grep 'Rexster Server shutdown complete'
        if [ $0 == 0 ]; then exit 0; fi
        echo 'Force Kill'
        kill -9 $pid
        """
        code_skipped: 3
        if_exists: '/opt/titan/current/bin/rexster.sh'

## Stop Clean Logs

      @system.execute
        header: 'Clean Logs'
        cmd: "rm #{rexster.log_dir}/*"
        code_skipped: 1
        if: @config.ryba.clean_logs

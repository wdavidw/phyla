
# Oozie Server Status

Run the command `./bin/ryba status -m ryba/oozie/server` to retrieve the status
of the Oozie server using Ryba.

By default, the pid of the running server is stored in
"/var/run/oozie/oozie.pid".

Discover the server status.

    module.exports = header: 'Oozie Server Status', handler: (options) ->
      @system.execute
        cmd: """
        if [ ! -f #{options.pid_dir}/oozie.pid ]; then exit 3; fi
        if ! kill -0 >/dev/null 2>&1 `cat #{options.pid_dir}/oozie.pid`; then exit 3; fi
        """
        code_skipped: 3


# Oozie Server Stop

Run the command `./bin/ryba stop -m ryba/oozie/server` to stop the Oozie
server using Ryba.

The file storing the PID is "/var/run/oozie/oozie.pid".

    module.exports = header: 'Oozie Server Stop', label_true: 'STOPPED', handler: (options) ->

## Service

Stop the Oozie service. You can also stop the server manually with the
following commands:

```
service oozie stop
systemctl stop oozie
su -l oozie -c "/usr/hdp/current/oozie-server/bin/oozied.sh stop"
```

      @service.stop
        name: 'oozie'
        if_exists: '/etc/init.d/oozie'

## Stop Clean Logs

      @system.execute
        header: 'Stop Clean Logs'
        if: options.clean_logs
        cmd: 'rm /var/log/oozie/*'
        code_skipped: 1

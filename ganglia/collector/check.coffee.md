
# Ganglia Collector Check

Call the "checkGmetad.sh" deployed by the Ganglia HDP package and check if the
"/usr/bin/rrdcached" and "/usr/sbin/gmetad" daemons are running.

    module.exports = header: 'Ganglia Collector Check Services', handler: ->
      @system.execute
        cmd: "/usr/libexec/hdp/ganglia/checkGmetad.sh"

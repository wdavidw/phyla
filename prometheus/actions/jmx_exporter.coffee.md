
# Prometheus Agent Configuration

Download the jmx_exporter jar and render the configuration file. Accepts all file.write
options

* `agent_source` (string)   
  The jmx_exporter agent jar source.
* `agent_target` (string)   
  The jmx_exporter agent jar target.
* `port` (string)   
  The port on which the agent will be listening. Mandatory if iptables is enabled.
* `config` (object)
  the config of the yaml configuration file.
* `target` (string)   
  The target destination of the configuration file.
* `iptables` (boolean)
  If iptables is enabled on the host.
* `title` (string)   
  The JMX Exporter name Mandatory
* `user` (object)   
  user Object should contain name. Mandatory.
* `group` (object)   
  group object should contain name property. Mandatory.


## Exemple

```js
nikita
.jmx_exporter({
  "agent_source": '/home/bakalian/ryba-env-metal/cache/jmx_exporter.jar',
  "agent_target": '/usr/hdp/current/zookeeper-server/lib/jmx_exporter_agent.jar',
  "port": "5556",
  "config": {
    "startDelaySeconds": 0,
    "hostPort": "master01.metal.ryba:5556",
  },
  "target": '/etc/zookeeper/conf/zookeeper.yaml',
  "type": 'zookeeper'
}, function(err, status){
  console.log( err ? err.message : "Policy Created: " + status)
})
```

    module.exports = ({options}) ->
      throw Error 'Required Options: jar_source' unless options.jar_source
      throw Error 'Required Options: jar_target' unless options.jar_target
      throw Error 'Required Options: config' unless options.config
      throw Error 'Required Options: target' unless options.target
      throw Error 'Required Options: title' unless options.title
      throw Error 'Required Options: Port' if options.iptables and !options.port?
      options.backup ?= true
      options.merge ?= false
      @tools.iptables
        header: "IPtables JMX #{options.title}"
        if: options.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.port, protocol: 'tcp', state: 'NEW', comment: "JMX Exporter #{options.title}" }
        ]
      @file.download
        source: options.jar_source
        target: options.jar_target
      @file.yaml
        target: options.target
        content: options.config
        uid: options.user.name
        gid: options.group.name
      , options

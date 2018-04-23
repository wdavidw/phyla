
# Prometheus Password File creation

Write the JMX password file required for enabling authentication

* `password` (string)   
  The authentication password.
* `username` (string)   
  The authentication username.
* `target` (string)   
  The target of the password file.

## Exemple

```js
nikita
.jmx_password({
  "username": 'monitor',
  "password": 'password',
  "target": "/etc/security/jmxPassword/hdfs-datanode.password",
  "uid": 'hdfs'
  "gid": 'hdfs'
}, function(err, status){
  console.log( err ? err.message : "Policy Created: " + status)
})
```

    module.exports = (options) ->
      throw Error 'Required Options: password' unless options.password
      throw Error 'Required Options: username' unless options.username
      throw Error 'Required Options: target' unless options.target
      throw Error 'Required Options: uid' unless options.uid
      throw Error 'Required Options: gid' unless options.gid
      # controlRole #{options.password}
      options.backup ?= true
      options.merge ?= false
      @system.mkdir
        target: path.dirname options.target
      @file
        target: options.target
        content: """
        # specify actual password instead of the text password
        #{options.username} #{options.password}
        """
        mode: 0o600
        uid: options.uid
        gid: options.gid

## Dependencies

    path = require 'path'
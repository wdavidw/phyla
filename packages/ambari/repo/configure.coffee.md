
# Ambari Repo Configuration

## Exemple using a local file

```yaml
ambari:
  source: ./conf/repos/ambari-2.7.3.0.repo
  target: ambari-2.7.3.0.repo
hdp:
  source: ./conf/repos/hdp-3.1.0.0.repo
  target: hdp-3.1.0.0.repo
```

    module.exports = ({options}) ->
    
      options.ambari ?= {}
      options.ambari.source ?= null
      options.ambari.target ?= 'ambari.repo'
      options.ambari.target = path.resolve '/etc/yum.repos.d', options.ambari.target
      options.ambari.replace ?= 'ambari*'
      
      options.hdp ?= {}
      options.hdp.source ?= null
      options.hdp.target ?= 'hdp.repo'
      options.hdp.target = path.resolve '/etc/yum.repos.d', options.hdp.target
      options.hdp.replace ?= 'hdp*'

## Dependencies

    path = require('path').posix

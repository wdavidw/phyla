

## Configure
Solr accepts differents sources:
 - HDP to use HDP lucidworks repos

```cson
ryba:
  solr:
    source: 'HDP'
    jre_home: '/usr/java/jdk1.8.0_91/jre'
    env:
      'SOLR_JAVA_HOME': '/usr/java/jdk1.8.0_91'
```
 - apache community edition to use the official release:   
 in this case you can choose the version

```cson
ryba:
  solr:
    jre_home: '/usr/java/jdk1.8.0_91/jre'
    env:
      'SOLR_JAVA_HOME': '/usr/java/jdk1.8.0_91'
    version: '6.0.0'
    source: 'http://mirrors.ircam.fr/pub/apache/lucene/solr/6.0.0/solr-6.0.0.tgz'
```

    module.exports = (service) ->
      options = service.options

## Environment

      options.version ?= '6.6.1'
      options.host ?= service.node.fqdn # need for rendering xml
      options.source ?= "http://apache.mirrors.ovh.net/ftp.apache.org/dist/lucene/solr/#{options.version}/solr-#{options.version}.tgz"
      options.root_dir ?= '/usr'
      options.install_dir ?= "#{options.root_dir}/solr/#{options.version}"
      options.latest_dir ?= "#{options.root_dir}/solr/current"
      options.latest_dir = '/opt/lucidworks-hdpsearch/solr' if options.source is 'HDP'
      options.pid_dir ?= '/var/run/solr'
      options.log_dir ?= '/var/log/solr'
      options.conf_dir ?= '/etc/solr/conf'

## Configuration

      options.jaas_path ?= "#{options.conf_dir}/solr-client.jaas"

## Dependencies

    {merge} = require 'nikita/lib/misc'

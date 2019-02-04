
# Changelog

## Trunk

* package: convert to monorepo

## Version 0.3.0

* nikita: monorepos

## Version 0.2.0

* nikita: collect - options as destructuring assignment
* nikita: ambari agent, server - options as destructuring assignment
* nikita: phoenix, opentsdb - options as destructuring assignment
* nikita: knox - options as destructuring assignment
* nikita: mongodb - options as destructuring assignment
* nikita: oozie - options as destructuring assignment
* nikita: kafka - options as destructuring assignment
* nikita: tez - options as destructuring assignment
* nikita: solr,pig - options as destructuring assignment
* nikita: zookeeper - options as destructuring assignment
* nikita: hive - options as destructuring assignment
* nikita: ranger - options as destructuring assignment
* nikita: prometheus - options as destructuring assignment
* nikita: hbase, hdp - options as destructuring assignment
* nikita: lib - options as destructuring assignment
* nikita: hadoop - options as destructuring assignment
* nikita: atlas - options as destructuring assignment
* nikita: commons - options as destructuring assignment

## Version 0.1.1

* nikita: callback 2nd argument is an object

## Version 0.1.0

* hconfigure: remove deprecated options
* nikita: rename then to next
* package: ignore yarn lock
* druid: support for non-UTC timezone
* druid: various fixes
* oozie/client: added retry in hive check
* phoenix/client: stronger check
* package: centralize identity definition in configuration
* knox: improve proxyusers configuration for hdfs_nn and yarn_rm
* druid: fix installation of packages
* shinken: ssl support
* lib/capacity: fixed yarn.app.mapreduce.am.resource.mb calculation
* hdfs/dn: use nikita sysctl
* phoenix/client: fixed check
* hive/beeline: retry in check
* ranger/admin: typos
* ambari: initial commit for ambari views (standalone)
* hive: fix group permission error when using ranger
* monitoring: isolate objects conf (common to nagios/shinken/alignak)
* hive: isolate metastore
* HBase: UI security through SPNEGO
* registry: initial commit for Schema Registry

## Version 0.0.7

* hadoop/core: moved core-site.xml rendering to hadoop/core
* ranger/solr: wait for solr to run before creating collection
* hive/server2: MySQL connector for embedded metastore
* oozie/client: load config from hiveserver2's context
* phoenix/client: wait for hbase table to be created
* ranger/hiveserver2: load config from hiveserver2's context
* ranger: add Solr Embedded
* ambari repo: fix
* ambari: optionnal hdf dependency
* hdf: rename repo to source
* ambari: use repo
* repo: default to null, rename repo to source
* hdp: rename repo to source
* knox: fixed webhcat check url
* ambari: ssl and cluster_name support in blueprint
* ambari: ranger
* hive hcatalog: esthetic
* spark: add policy for hive database
* krb5: migrate usage of admin
* src: remove usage of timeout
* ambari: use options
* resources: normilize permissions to 644
* bin: remove prepare in favor of ryba prepare
* ambari: new hdf server & agent
* nifi: new ambari pre-configuration
* ambari server: fix certificate registration when remote
* ambari server: mpack registration
* ambari agent: use options
* nifi: comment redundant CA registration
* hdf & hdp: target and replace from config
* ambari server: handle exit code 7 in wait
* refactor hdp and initial commit for hdf
* ambari: reliable wait and check
* ambari: prevent ambari principal collision
* spark historyserver: configure heapsize
* hadoop: add systemd scripts
* knox: add HBase WebUI service
* hcatalog: autoconfig when mariadb is installed
* shinken: add tests for Phoenix QS, Atlas, Ranger, WebHCat
* ambari: new standalone service
* package: latest dependencies
* ambari server: ssl, truststore and jaas
* hdfs: validate hostnames
* ambari agent: dont wait for ambari server
* ambari server: create hadoop group
* druid: default values for max direct memory size
* ambari server: wait before check
* oozie: improve and isolate checks
* src: refactor wait to prepare options
* huedocker: update docker files preparation
* huedocker: password required
* huedocker: refactor ssl usage
* webhcat: fix metastore principal
* webhcat: fix log4j
* yarn: config normalisation when site not defined
* hdfs: krb5 password now required
* ambari server: re-ordonnate ambari-server init and security
* src: factor multi string indentation
* yarn rm: retry ha check 3 times
* kafka: refactor and sleep 1s before producers
* src: fix backup renamed as remove
* yarn: cgroup labels
* lib mkcmd: generic command
* hadoop: move distributed shell into mapreduce
* hive hcatalog: port defined in configuration
* hadoop: honors user environmental variables #74
* hdfs: fix log cleanup in jn and zkfc
* pig: disabled old fix
* druid: database password now required
* oozie: database password now required
* hive: database password now required
* src: normalize identies creation
* hdfs nn: fix fsck check by using nn config
* benchmark: first refactor
* ambari server: desactivate sudo
* ambari server: master key support
* ambari server: export blueprint definition
* ambari server: write urls based on ssl activation
* yarn nm: enforce memory check #70
* src: remove depracated usage of destination
* oozie: fix lzo package incompatibility
* hdfs dn: fix lzo package incompatibility
* ambari server: fix typos
* druid: mysql support
* druid: upgrade to version 0.10.0
* druid: init script support for rh7
* druid: remove calls to base install
* ambari: remove jdbc options from setup
* ambari: set default https port
* kafka broker: add log and run dirs in layout
* replace system.discover by if_os condition
* ambari: update admin password
* huedocker: ssh configuration from configuration
* ambari server: check
* ambari: agents wait for server


normalize = require 'masson/lib/config/normalize'
store = require 'masson/lib/config/store'
nikita = require 'nikita'
fs = require 'fs'

describe 'hadoop.hdfs_dn', ->

  tmp = '/tmp/masson-test'
  beforeEach ->
    require('module')._cache = {}
    nikita
    .system.mkdir target: tmp
    .promise()
  afterEach ->
    nikita
    .system.remove tmp
    .promise()
  
  it 'validate heapsize and newsize', ->
    services = []
    store normalize
      clusters: 'ryba': services:
        'java':
          module: 'masson/commons/java'
          affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'b.fqdn', 'c.fqdn']
        'krb5_client':
          module: 'masson/core/krb5_client'
          affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'b.fqdn', 'c.fqdn']
          options:
            admin:
              'HADOOP.RYBA':
                kadmin_principal: 'admin/admin@HADOOP.RYBA'
                kadmin_password: 'test'
                kdc: ['a.fqdn']
                admin_server: ['a.fqdn']
                kpasswd_server: 'a.fqdn'
                principals: []
            etc_krb5_conf:
              libdefaults: 'default_realm': 'HADOOP.RYBA'
              realms:
                'HADOOP.RYBA':
                  kdc: ['a.fqdn']
                  admin_server: ['a.fqdn']
                  kpasswd_server: 'a.fqdn'
        'test_user':
          module: 'ryba/commons/test_user'
          affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'b.fqdn', 'c.fqdn']
          options:
            krb5: user:
              password: 'test123'
              password_sync: true
        'zookeeper':
          module: 'ryba/zookeeper/server'
          affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'b.fqdn', 'c.fqdn']
        'core':
          module: "ryba/hadoop/core"
          affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'b.fqdn', 'c.fqdn']
          options: hdfs:
            user: {}
            group: {}
            krb5_user:
              password: 'test123'
        'namenode':
          module: "ryba/hadoop/hdfs_nn"
          affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'b.fqdn']
          options: nameservice: 'rybak', hdfs_site: {}, hdfs:
            user: {}
            group: {}
            krb5_user:
              password: 'test123'
        'journalnode':
          module: 'ryba/hadoop/hdfs_jn'
          affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'b.fqdn', 'c.fqdn']
          options: hdfs_site: 'dfs.journalnode.edits.dir': '/var/hdfs/jn'
        'datanode':
          module: "ryba/hadoop/hdfs_dn"
          affinity: type: 'nodes', match: 'any', values: ['c.fqdn']
          options:
            heapsize: '1024m'
            newsize: '200m'
      nodes:
        'a.fqdn': ip: '10.10.10.1'
        'b.fqdn': ip: '10.10.10.2'
        'c.fqdn': ip: '10.10.10.3'
    .chain()
    .service 'ryba', "datanode", (service) ->
      service.options.heapsize.should.match /([0-9]*)([mMgGkK])/
      service.options.newsize.should.match /([0-9]*)([mMgGkK])/

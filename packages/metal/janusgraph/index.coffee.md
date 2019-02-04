
# JanusGraph

[JanusGraph][website] is a scalable graph database optimized for storing and 
querying graphs containing hundreds of billions of vertices and edges distributed
across a  multi-machine cluster. JanusGraph is a transactional database that can
support thousands of concurrent users executing complex graph traversals in real time.
JanusGraph is a project under The Linux Foundation, and includes participants
from Expero, Google, GRAKN.AI, Hortonworks, and IBM. 

    module.exports =
      deps:
        java: module: 'masson/commons/java', local: true, auto: true, implicit: true
        test_user: module: '@rybajs/metal/commons/test_user', local: true, auto: true
        zookeeper_server: '@rybajs/metal/zookeeper/server'
        hbase_client: implicit: true, module: '@rybajs/metal/hbase/client'
        elasticsearch: '@rybajs/metal/elasticsearch'
        solr: '@rybajs/metal/solr'
      configure:
        '@rybajs/metal/janusgraph/configure'
      commands:
        'prepare':
          '@rybajs/metal/janusgraph/prepare'
        'install': [
          '@rybajs/metal/janusgraph/install'
          '@rybajs/metal/janusgraph/check'
        ]
        'check':
          '@rybajs/metal/janusgraph/check'

## Resources

*   [JanusGraph: Documentation](http://docs.janusgraph.org/0.1.1/)
*   [TinkerPop](http://www.tinkerpop.com/)

[website]: http://janusgraph.org/

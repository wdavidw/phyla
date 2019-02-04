
# Schema Registry

Hortonworks Schema Registry is a shared repository of schemas that allows
applications to flexibly interact with each other – in order to save or retrieve
schemas for the data they need to access. Having a common Schema Registry provides
end to end data governance and introduce operational efficiency by providing
reusable schema,defining relationships between schemas and enabling data providers
and consumers to evolve at different speed.

      module.exports =
        use:
          db_admin: implicit: true, module: '@rybajs/metal/commons/db_admin'
          hdf: '@rybajs/metal/hdf'
        configure:
          '@rybajs/metal/hdf/registry/configure'
        commands:
          'install': [
            '@rybajs/metal/hdf/registry/install'
            '@rybajs/metal/hdf/registry/start'
            '@rybajs/metal/hdf/registry/check'
          ]
          'check':
            '@rybajs/metal/hdf/registry/check'
          'status':
            '@rybajs/metal/hdf/registry/status'
          'start':
            '@rybajs/metal/hdf/registry/start'
          'stop':
            '@rybajs/metal/hdf/registry/stop'

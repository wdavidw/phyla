
# Schema Registry

Hortonworks Schema Registry is a shared repository of schemas that allows
applications to flexibly interact with each other – in order to save or retrieve
schemas for the data they need to access. Having a common Schema Registry provides
end to end data governance and introduce operational efficiency by providing
reusable schema,defining relationships between schemas and enabling data providers
and consumers to evolve at different speed.

      module.exports =
        use:
          db_admin: implicit: true, module: 'ryba/commons/db_admin'
          hdf: 'ryba/hdf'
        configure:
          'ryba/hdf/registry/configure'
        commands:
          'install': [
            'ryba/hdf/registry/install'
            'ryba/hdf/registry/start'
            'ryba/hdf/registry/check'
          ]
          'check':
            'ryba/hdf/registry/check'
          'status':
            'ryba/hdf/registry/status'
          'start':
            'ryba/hdf/registry/start'
          'stop':
            'ryba/hdf/registry/stop'

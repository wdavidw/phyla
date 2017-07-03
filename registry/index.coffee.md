
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
          'ryba/registry/configure'
        commands:
          'install': [
            'ryba/registry/install'
            'ryba/registry/start'
            'ryba/registry/check'
          ]
          'check':
            'ryba/registry/check'
          'status':
            'ryba/registry/status'
          'start':
            'ryba/registry/start'
          'stop':
            'ryba/registry/stop'

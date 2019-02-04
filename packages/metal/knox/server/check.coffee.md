
# Knox Check

Validating Service Connectivity, based on [Hortonworks Documentation][doc].

    module.exports = header: 'Knox Check', handler: ({options}) ->
      return unless options.test.user?.name? and options.test.user?.password?

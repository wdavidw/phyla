
# NagVis

NagVis is a visualization addon for the well known network managment system Nagios.

NagVis can be used to visualize Nagios Data, e.g. to display IT processes like a
mail system or a network infrastructure.

NagVis is also compliant with shinken.

    module.exports =
      deps:
        yum: module: 'masson/core/yum', local: true
        iptables: module: 'masson/core/iptables', local: true
        broker: module: 'ryba/shinken/broker'
        httpd: module: 'masson/commons/httpd', local: true, required: true
      'configure':
        'ryba/nagvis/configure'
      'install': [
        'ryba/nagvis/install'
      ]

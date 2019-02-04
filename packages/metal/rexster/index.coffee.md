
# TinkerPop Rexster (Titan Server)

[Rexster](https://github.com/tinkerpop/rexster/wiki) is a graph server that exposes
any Blueprints graph through REST and a binary protocol called RexPro.
The HTTP web service provides standard low-level GET, POST, PUT, and DELETE methods,
a flexible extensions model which allows plug-in like development for external 
services an’s modular architecture allows it to interoperate with a wide range of
storage, index, and client technologies; it also eases the process of extending
Titan to support new ones.
server-side “stored procedures” written in Gremlin, and a browser-based interface
called The Dog House. 
Rexster Console makes it possible to do remote script evaluation against configured
graphs inside of a Rexster Server.


    module.exports =
      use:
        krb5_client: module: 'masson/core/krb5_client'
      configure:
        '@rybajs/metal/rexster/configure'
      commands:
        'install': [
          'masson/core/iptables'
          'masson/core/yum'
          'masson/commons/java'
          '@rybajs/metal/rexster/install'
          '@rybajs/metal/rexster/start'
          '@rybajs/metal/rexster/check'
        ]
        'check': [
          '@rybajs/metal/rexster/check'
        ]
        'start':
          '@rybajs/metal/rexster/start'
        'stop':
          '@rybajs/metal/rexster/stop'
        'status':
          '@rybajs/metal/rexster/status'

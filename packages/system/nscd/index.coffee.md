
# nscd

Configures the name service cache daemon (nscd). 

    module.exports =
      configure:
        '@rybajs/system/nscd/configure'
      commands:
        'install':
          '@rybajs/system/nscd/install'
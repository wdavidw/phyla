
# Crontab

Deploys crontab to a given user

    module.exports =
      configure:
        '@rybajs/system/crontab/configure'
      commands:
        'install':
          '@rybajs/system/crontab/install'

## Resources

*   [Crontab Guru](https://crontab.guru/)
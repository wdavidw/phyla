
# Open Nebula Front Prepare

Ruby version 2.0.0 must be available on the host machine either directly from
the path or through RVM. If RVM is found, Ruby in version 2.0.0 doesn't need to 
be installed, it will be directly downloaded.

To install RVM:

```
curl -L get.rvm.io > rvm-install
bash < ./rvm-install
echo '# Source RVM' >> ~/.profile
echo '[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"' >> ~/.profile
echo 'if which ruby >/dev/null && which gem >/dev/null; then PATH="$(ruby -rubygems -e 'puts Gem.user_dir')/bin:$PATH"; fi' >> ~/.profile
. ~/.profile
# Arch specific
sudo pacman -S openssl-1.0 # Probably already installed
PKG_CONFIG_PATH=/usr/lib/openssl-1.0/pkgconfig:/usr/lib/pkgconfig rvm install 2.0.0

```

    module.exports =
      header: 'Nebula Front Prepare'
      if: -> @contexts('./lib/nebula/front')[0]?.config.host is @config.host
      ssh: null
      handler: (options) ->
        @system.execute
          header: 'Ruby'
          cmd: """
          [[ `ruby -v | sed 's/ruby \\([0-9]\\.[0-9]\\.[0-9]\\).*/\\1/'` == '2.0.0' ]] && exit 3
          command -v rvm || exit 4
          rvm use 2.0.0 && exit 3
          rvm install 2.0.0
          """
          code_skipped: 3
          trap: true
        , (err) ->
          throw Error "Ruby version 2.0.0 or RVM must be installed" if err?.code is 4
        @system.mkdir
          target: options.gem_dir
        @file
          header: 'Gems'
          target: path.resolve options.gem_dir, 'Gemfile'
          content: """
          source 'https://rubygems.org'
          gem 'rack', '< 2.0.0'
          gem 'sinatra', '< 2.0.0'
          gem 'thin'
          gem 'memcache-client'
          gem 'zendesk_api', '< 1.14.0'
          gem 'builder'
          """
        @system.execute
          header: 'Download'
          if: -> @status -1
          cwd: path.resolve options.cache_dir, 'nebula'
          cmd: """
          gem install --user-install bundler
          bundler package
          """

## Dependencies

    path = require 'path'

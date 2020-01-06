
# Node.js installation with N

N is a Node.js binary management system, similar to nvm and nave.

Note, dec 2015: Accoring to the tests, proxy env var aren't used by ssh exec.

    module.exports = ({options}) ->
    
      options.config ?= {}

## N installation

      env = {}
      env.http_proxy = options.config['proxy'] if options.config['proxy']
      env.https_proxy = options.config['https-proxy'] if options.config['https-proxy']
      @system.execute
        env: env
        cmd: """
        export http_proxy=#{options.config['proxy'] or ''}
        export https_proxy=#{options.config['https-proxy'] or ''}
        cd /tmp
        git clone https://github.com/visionmedia/n.git
        cd n
        make install
        """
        unless_exists: '/usr/local/bin/n'

## Node.js activation

Multiple installation of Node.js may coexist with N.

      @system.execute
        cmd: "n #{options.version}"

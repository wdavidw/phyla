
###

Select the version of a package distributed by HDP.

Options include
*   `name` (string)
    Name of the package, required.
*   `version` (string)
    Version will be the latest auto-discovered version unless provided and can
    be a valid version, "latest" or "current".

###

module.exports = (options, callback) ->
  options.name = options.argument if options.argument?
  options.version ?= 'latest'
  if options.version and options.version not in ['latest', 'current']
    options.store['hdp_select.version.default'] = options.version
  @call (_, callback) ->
    # Get the current or latest version
    @system.execute
      cmd: """
      code=3
      if [ "#{options.version}" == "latest" ]; then
        version=`hdp-select versions | tail -1`
      elif [ "#{options.version}" == "current" ]; then
        version=`hdp-select status #{options.name} | sed 's/.* \\(.*\\)/\\1/'`*
        if [ "$version" == "None" ]; then
          version=`hdp-select versions | tail -1`
        fi
      else
        version='#{options.version}'
      fi
      if [ ! -d "/usr/hdp/$version" ]; then
        echo 'Failed to detect the latest HDP version'
        exit 1
      fi
      echo $version
      """
      unless: options.store['hdp_select.version.default']
      shy: true
    , (err, executed, stdout, stderr) ->
      return callback err if err
      options.store['hdp_select.version.default'] = stdout.trim() if executed
      callback()
  @call (_, callback) ->
    version = options.store['hdp_select.version.default']
    # Set the service to its expected version
    @system.execute
      cmd: """
      version=`hdp-select status #{options.name} | sed 's/.* \\(.*\\)/\\1/'`
      if [ $version == '#{version}' ]; then exit 3; fi
      hdp-select set #{options.name} #{version}
      """
      code_skipped: 3
    @next callback
  @next callback

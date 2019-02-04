
# Elasticsearch (Docker) Prepare

Download Elasticsearch Plugins.

    module.exports =
      header: 'Elasticsearch Plugins'
      handler: (options) ->
        return unless options.prepare
        for es_name,es of options.clusters then do (es_name,es) =>
          @each es.plugins_urls, (plugins_options,  plugins_callback) ->
            downloaded = false
            @each plugins_options.value, (plugin_options,callback) ->
              if !downloaded
                console.log "Trying to download #{plugins_options.key} using #{plugin_options.key}.."
                @file.cache
                  ssh: false
                  location: true
                  fail: true
                  header: "Accept: application/zip"
                  source: plugin_options.key
                  ,(err,status) ->
                    if err
                      console.log "error: #{err}"
                    else
                      console.log "#{plugins_options.key} downloaded using #{plugin_options.key}.."
                      clusters["#{es_name}"].downloaded_urls["#{plugins_options.key}"]= plugin_options.key
                      downloaded=true
                    callback null
            @next (err) ->
              throw Error "failed to download #{plugins_options.key} out of all possible locations..." unless downloaded is true
              plugins_callback null

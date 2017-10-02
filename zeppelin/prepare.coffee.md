
# Zeppelin Prepare

Builds Zeppelin from as [required][zeppelin-build]. For now it's the single way to get Zeppelin.
It uses several containers. One to build zeppelin and an other for deploying zeppelin.
Requires Internet to download repository & maven.
Zeppelin 0.6 builds for Hadoop Cluster on Yarn with Spark.
Version:
  - Spark: 1.3
  - Hadoop: 2.7 (HDP 2.3)


    module.exports = header: 'Zeppelin Prepare', ssh: null, handler: (options) ->

## Prepare Build

Intermetiate container to build zeppelin from source. Builds ryba/zeppelin-build
image.

      @docker.build
        header: 'Build Image'
        image: options.build.tag
        cwd: options.build.cwd
      @docker.run
        image: options.build.tag
        rm: true
        volume: "#{options.cache_dir}:/target"
      @system.mkdir
        target: "#{options.cache_dir}/zeppelin"
      @system.copy
        source: "#{options.prod.cwd}/Dockerfile"
        target: "#{options.cache_dir}/zeppelin"
      @system.copy
        source: "#{options.cache_dir}/zeppelin-build.tar.gz"
        target: "#{options.cache_dir}/zeppelin"

## Prepare Container

Build the Docker container and place it inside the cache directory.

      @docker.build
        header: 'Build Container'
        tag: "#{options.prod.tag}"
        cwd: "#{options.cache_dir}/zeppelin"
      @docker_save
        header: 'Export Container'
        image: "#{options.prod.tag}"
        target: "#{options.cache_dir}/zeppelin.tar"

## Instructions

[zeppelin-build]:http://zeppelin.incubator.apache.org/docs/install/install.html
[github-instruction]:https://github.com/apache/incubator-zeppelin
[hortonwork-instruction]:http://fr.hortonworks.com/blog/introduction-to-data-science-with-apache-spark/
